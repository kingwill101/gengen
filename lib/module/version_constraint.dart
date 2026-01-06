/// Represents a semantic version
class Version implements Comparable<Version> {
  final int major;
  final int minor;
  final int patch;
  final String? prerelease;
  final String? build;

  const Version(
    this.major,
    this.minor,
    this.patch, {
    this.prerelease,
    this.build,
  });

  static final _versionRegex = RegExp(
    r'^v?(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z\-\.]+))?(?:\+([0-9A-Za-z\-\.]+))?$',
  );

  factory Version.parse(String version) {
    final match = _versionRegex.firstMatch(version.trim());
    if (match == null) {
      throw FormatException('Invalid version format: $version');
    }

    return Version(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      prerelease: match.group(4),
      build: match.group(5),
    );
  }

  static Version? tryParse(String version) {
    try {
      return Version.parse(version);
    } catch (_) {
      return null;
    }
  }

  @override
  int compareTo(Version other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);

    // Prerelease versions have lower precedence
    if (prerelease == null && other.prerelease != null) return 1;
    if (prerelease != null && other.prerelease == null) return -1;
    if (prerelease != null && other.prerelease != null) {
      return prerelease!.compareTo(other.prerelease!);
    }

    return 0;
  }

  bool operator <(Version other) => compareTo(other) < 0;
  bool operator <=(Version other) => compareTo(other) <= 0;
  bool operator >(Version other) => compareTo(other) > 0;
  bool operator >=(Version other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is Version &&
      major == other.major &&
      minor == other.minor &&
      patch == other.patch &&
      prerelease == other.prerelease;

  @override
  int get hashCode => Object.hash(major, minor, patch, prerelease);

  @override
  String toString() {
    var result = '$major.$minor.$patch';
    if (prerelease != null) result += '-$prerelease';
    if (build != null) result += '+$build';
    return result;
  }
}

/// Represents a version constraint for module dependencies
abstract class VersionConstraint {
  const VersionConstraint();

  /// Parse a version constraint string
  factory VersionConstraint.parse(String constraint) {
    final trimmed = constraint.trim();

    if (trimmed.isEmpty || trimmed == 'any') {
      return const AnyVersionConstraint();
    }

    // Git ref constraints
    if (trimmed.startsWith('branch:')) {
      return GitRefConstraint(type: GitRefType.branch, ref: trimmed.substring(7));
    }
    if (trimmed.startsWith('tag:')) {
      return GitRefConstraint(type: GitRefType.tag, ref: trimmed.substring(4));
    }
    if (trimmed.startsWith('commit:')) {
      return GitRefConstraint(type: GitRefType.commit, ref: trimmed.substring(7));
    }

    // Caret constraint: ^1.0.0
    if (trimmed.startsWith('^')) {
      final version = Version.parse(trimmed.substring(1));
      return CaretConstraint(version);
    }

    // Range constraint: >=1.0.0 <2.0.0
    if (trimmed.contains(' ')) {
      return RangeConstraint.parse(trimmed);
    }

    // Comparison constraint: >=1.0.0, <2.0.0, etc.
    if (trimmed.startsWith('>=') ||
        trimmed.startsWith('<=') ||
        trimmed.startsWith('>') ||
        trimmed.startsWith('<')) {
      return ComparisonConstraint.parse(trimmed);
    }

    // Exact version: 1.2.3
    return ExactConstraint(Version.parse(trimmed));
  }

  /// Check if a version satisfies this constraint
  bool allows(Version version);

  /// Check if this is a git ref constraint
  bool get isGitRef => false;
}

/// Allows any version
class AnyVersionConstraint extends VersionConstraint {
  const AnyVersionConstraint();

  @override
  bool allows(Version version) => true;

  @override
  String toString() => 'any';
}

/// Exact version match
class ExactConstraint extends VersionConstraint {
  final Version version;

  const ExactConstraint(this.version);

  @override
  bool allows(Version v) => v == version;

  @override
  String toString() => version.toString();
}

/// Caret constraint: ^1.0.0 means >=1.0.0 <2.0.0
class CaretConstraint extends VersionConstraint {
  final Version minVersion;

  const CaretConstraint(this.minVersion);

  @override
  bool allows(Version version) {
    if (version < minVersion) return false;

    // ^0.x.y is more restrictive
    if (minVersion.major == 0) {
      if (minVersion.minor == 0) {
        return version.major == 0 &&
            version.minor == 0 &&
            version.patch == minVersion.patch;
      }
      return version.major == 0 && version.minor == minVersion.minor;
    }

    return version.major == minVersion.major;
  }

  @override
  String toString() => '^$minVersion';
}

/// Comparison constraint: >=, <=, >, <
class ComparisonConstraint extends VersionConstraint {
  final String operator;
  final Version version;

  const ComparisonConstraint(this.operator, this.version);

  factory ComparisonConstraint.parse(String constraint) {
    String op;
    String versionStr;

    if (constraint.startsWith('>=')) {
      op = '>=';
      versionStr = constraint.substring(2);
    } else if (constraint.startsWith('<=')) {
      op = '<=';
      versionStr = constraint.substring(2);
    } else if (constraint.startsWith('>')) {
      op = '>';
      versionStr = constraint.substring(1);
    } else if (constraint.startsWith('<')) {
      op = '<';
      versionStr = constraint.substring(1);
    } else {
      throw FormatException('Invalid comparison constraint: $constraint');
    }

    return ComparisonConstraint(op, Version.parse(versionStr.trim()));
  }

  @override
  bool allows(Version v) {
    switch (operator) {
      case '>=':
        return v >= version;
      case '<=':
        return v <= version;
      case '>':
        return v > version;
      case '<':
        return v < version;
      default:
        return false;
    }
  }

  @override
  String toString() => '$operator$version';
}

/// Range constraint: >=1.0.0 <2.0.0
class RangeConstraint extends VersionConstraint {
  final List<ComparisonConstraint> constraints;

  const RangeConstraint(this.constraints);

  factory RangeConstraint.parse(String constraint) {
    final parts = constraint.split(RegExp(r'\s+'));
    final constraints = parts
        .where((p) => p.isNotEmpty)
        .map((p) => ComparisonConstraint.parse(p))
        .toList();

    return RangeConstraint(constraints);
  }

  @override
  bool allows(Version version) {
    return constraints.every((c) => c.allows(version));
  }

  @override
  String toString() => constraints.map((c) => c.toString()).join(' ');
}

enum GitRefType { branch, tag, commit }

/// Git ref constraint: branch:main, tag:v1.0.0, commit:abc123
class GitRefConstraint extends VersionConstraint {
  final GitRefType type;
  final String ref;

  const GitRefConstraint({required this.type, required this.ref});

  @override
  bool allows(Version version) => true; // Git refs don't use semver

  @override
  bool get isGitRef => true;

  @override
  String toString() => '${type.name}:$ref';
}

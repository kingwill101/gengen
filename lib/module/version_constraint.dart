import 'package:gengen/exceptions.dart';

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
    final trimmed = version.trim();
    if (trimmed.isEmpty) {
      throw VersionException(
        'Version string cannot be empty',
        version: version,
      );
    }

    final match = _versionRegex.firstMatch(trimmed);
    if (match == null) {
      throw VersionException(
        'Invalid semantic version format. Expected format: MAJOR.MINOR.PATCH[-prerelease][+build]',
        version: version,
      );
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
  ///
  /// Supported formats:
  /// - `any` or empty: matches any version
  /// - `1.2.3`: exact version match
  /// - `^1.2.3`: caret constraint (compatible versions)
  /// - `>=1.0.0`, `<2.0.0`, `>1.0.0`, `<=2.0.0`: comparison constraints
  /// - `>=1.0.0 <2.0.0`: range constraint
  /// - `branch:main`, `tag:v1.0.0`, `commit:abc123`: git ref constraints
  ///
  /// Throws [VersionException] if the constraint is invalid.
  factory VersionConstraint.parse(String constraint) {
    final trimmed = constraint.trim();

    if (trimmed.isEmpty || trimmed == 'any') {
      return const AnyVersionConstraint();
    }

    // Git ref constraints
    if (trimmed.startsWith('branch:')) {
      final ref = trimmed.substring(7);
      if (ref.isEmpty) {
        throw VersionException(
          'Branch name cannot be empty',
          constraint: constraint,
        );
      }
      return GitRefConstraint(type: GitRefType.branch, ref: ref);
    }
    if (trimmed.startsWith('tag:')) {
      final ref = trimmed.substring(4);
      if (ref.isEmpty) {
        throw VersionException(
          'Tag name cannot be empty',
          constraint: constraint,
        );
      }
      return GitRefConstraint(type: GitRefType.tag, ref: ref);
    }
    if (trimmed.startsWith('commit:')) {
      final ref = trimmed.substring(7);
      if (ref.isEmpty) {
        throw VersionException(
          'Commit SHA cannot be empty',
          constraint: constraint,
        );
      }
      return GitRefConstraint(type: GitRefType.commit, ref: ref);
    }

    // Caret constraint: ^1.0.0
    if (trimmed.startsWith('^')) {
      final versionStr = trimmed.substring(1);
      if (versionStr.isEmpty) {
        throw VersionException(
          'Caret constraint requires a version (e.g., ^1.0.0)',
          constraint: constraint,
        );
      }
      try {
        final version = Version.parse(versionStr);
        return CaretConstraint(version);
      } on VersionException catch (e) {
        throw VersionException(
          'Invalid version in caret constraint',
          constraint: constraint,
          cause: e,
        );
      }
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
    try {
      return ExactConstraint(Version.parse(trimmed));
    } on VersionException catch (e) {
      throw VersionException(
        'Invalid version constraint',
        constraint: constraint,
        cause: e,
      );
    }
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
    final trimmed = constraint.trim();
    String op;
    String versionStr;

    if (trimmed.startsWith('>=')) {
      op = '>=';
      versionStr = trimmed.substring(2);
    } else if (trimmed.startsWith('<=')) {
      op = '<=';
      versionStr = trimmed.substring(2);
    } else if (trimmed.startsWith('>')) {
      op = '>';
      versionStr = trimmed.substring(1);
    } else if (trimmed.startsWith('<')) {
      op = '<';
      versionStr = trimmed.substring(1);
    } else {
      throw VersionException(
        'Invalid comparison operator. Expected >=, <=, >, or <',
        constraint: constraint,
      );
    }

    versionStr = versionStr.trim();
    if (versionStr.isEmpty) {
      throw VersionException(
        'Comparison constraint requires a version (e.g., >=1.0.0)',
        constraint: constraint,
      );
    }

    try {
      return ComparisonConstraint(op, Version.parse(versionStr));
    } on VersionException catch (e) {
      throw VersionException(
        'Invalid version in comparison constraint',
        constraint: constraint,
        cause: e,
      );
    }
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
    final nonEmpty = parts.where((p) => p.isNotEmpty).toList();

    if (nonEmpty.isEmpty) {
      throw VersionException(
        'Range constraint cannot be empty',
        constraint: constraint,
      );
    }

    if (nonEmpty.length < 2) {
      throw VersionException(
        'Range constraint requires at least two parts (e.g., >=1.0.0 <2.0.0)',
        constraint: constraint,
      );
    }

    try {
      final constraints = nonEmpty
          .map((p) => ComparisonConstraint.parse(p))
          .toList();
      return RangeConstraint(constraints);
    } on VersionException catch (e) {
      throw VersionException(
        'Invalid range constraint',
        constraint: constraint,
        cause: e,
      );
    }
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

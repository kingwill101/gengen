/// Represents a single module import declaration from gengen.yaml
class ModuleImport {
  final String path;
  final String? version;
  final ModuleType type;

  const ModuleImport({
    required this.path,
    this.version,
    required this.type,
  });

  factory ModuleImport.parse(Map<String, dynamic> data) {
    final path = data['path'] as String? ?? '';
    final version = data['version'] as String?;
    final type = ModuleType.fromPath(path);

    return ModuleImport(
      path: path,
      version: version,
      type: type,
    );
  }

  /// The module name extracted from the path
  String get name {
    if (type == ModuleType.pub) {
      return path.substring(4); // Remove 'pub:' prefix
    }
    if (type == ModuleType.local) {
      return path.split('/').last;
    }
    // Git: github.com/user/repo -> repo
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : path;
  }

  Map<String, dynamic> toJson() => {
        'path': path,
        if (version != null) 'version': version,
        'type': type.name,
      };

  @override
  String toString() => 'ModuleImport($path${version != null ? '@$version' : ''})';
}

/// Represents a module replacement for local development
class ModuleReplacement {
  final String path;
  final String local;

  const ModuleReplacement({
    required this.path,
    required this.local,
  });

  factory ModuleReplacement.parse(Map<String, dynamic> data) {
    return ModuleReplacement(
      path: data['path'] as String? ?? '',
      local: data['local'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'path': path,
        'local': local,
      };
}

/// The type of module source
enum ModuleType {
  local,
  git,
  pub;

  static ModuleType fromPath(String path) {
    if (path.startsWith('./') ||
        path.startsWith('../') ||
        path.startsWith('/')) {
      return ModuleType.local;
    }
    if (path.startsWith('pub:')) {
      return ModuleType.pub;
    }
    if (path.startsWith('github.com/') ||
        path.startsWith('gitlab.com/') ||
        path.startsWith('bitbucket.org/')) {
      return ModuleType.git;
    }
    // Default to local for unknown patterns
    return ModuleType.local;
  }
}

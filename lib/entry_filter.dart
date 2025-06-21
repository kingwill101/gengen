import 'dart:io';

import 'package:gengen/site.dart';
import 'package:path/path.dart' as path_utils;
import 'package:glob/glob.dart';

class EntryFilter {
  final Set<String> excludeSet;
  final Set<String> includeSet;
  final String source;

  EntryFilter()
      : excludeSet = Set.from(Site.instance.exclude),
        includeSet = Set.from(Site.instance.include),
        source = Site.instance.config.source;

  List<String> filter(List<String> entries) {
    return entries.where((entry) {
      if (entry.endsWith('.')) return false;
      if (isSymlink(entry)) return false;

      final relativePath = path_utils.relative(entry, from: source);

      final included = isIncluded(relativePath);
      final excluded = isExcluded(relativePath);

      if (excluded && !included) return false;
      if (included) return true;

      return !isSpecial(relativePath) && !isBackup(relativePath);
    }).toList();
  }

  bool isIncluded(String entry) {
    return globInclude(includeSet, entry) ||
        globInclude(includeSet, path_utils.basename(entry));
  }

  bool isSpecial(String entry) {
    RegExp specialCharRegex = RegExp(r'^[._#~]');
    var basename = path_utils.basename(entry);

    return specialCharRegex.hasMatch(basename);
  }

  bool isBackup(String entry) {
    return entry.endsWith('~');
  }

  bool isExcluded(String entry) {
    return globInclude(excludeSet.difference(includeSet), entry);
  }

  bool isSymlink(String entry) {
    return FileSystemEntity.isLinkSync(entry) &&
        !FileSystemEntity.identicalSync(entry, Site.instance.inSourceDir(entry));
  }

  bool globInclude(Set<String> patterns, String entry) {
    for (var pattern in patterns) {
      final glob = Glob(pattern, caseSensitive: false);
      if (glob.matches(entry)) {
        return true;
      }
      
      // Also check if the pattern matches a parent directory
      // For example, pattern "secret" should match "secret/file.txt"
      if (entry.startsWith('$pattern/')) {
        return true;
      }
    }

    return false;
  }
}

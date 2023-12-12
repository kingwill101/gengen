import 'dart:io';

import 'package:gengen/site.dart';
import 'package:path/path.dart' as path_utils;

class EntryFilter {
  final Site site;
  late String baseDirectory;

  EntryFilter(this.site, [String? baseDirectory]) {
    this.baseDirectory = deriveBaseDirectory(site, baseDirectory ?? '');
  }

  String getBaseDirectory() => baseDirectory;

  String deriveBaseDirectory(Site site, String baseDir) {
    var source = site.config.source;
    if (baseDir.startsWith(source)) {
      baseDir = baseDir.replaceFirst(source, '');
    }

    return baseDir;
  }

  String relativeToSource(String entry) {
    return path_utils.join(baseDirectory, entry);
  }

  List<String> filter(List<String> entries) {
    return entries.where((e) {
      if (e.endsWith('.')) return false;

      bool included = isIncluded(e);
      if (isExcluded(e) && !included) return false;
      if (isSymlink(e)) return false;
      if (included) return true;

      return !isSpecial(e) && !isBackup(e);
    }).toList();
  }

  bool isIncluded(String entry) {
    return globInclude(site.include, entry) ||
        globInclude(site.include, path_utils.basename(entry));
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
    Set<String> excludeSet = Set.from(site.exclude);
    Set<String> includeSet = Set.from(site.include);

    return globInclude(
      excludeSet.difference(includeSet),
      relativeToSource(entry),
    );
  }

  bool isSymlink(String entry) {
    return FileSystemEntity.isLinkSync(entry) &&
        !FileSystemEntity.identicalSync(entry, site.inSourceDir(entry));
  }

  bool globInclude(Set<String> patterns, String entry) {
    for (var pattern in patterns) {
      RegExp regex = RegExp(globToRegExp(pattern));
      if (regex.hasMatch(entry)) {
        return true;
      }
    }

    return false;
  }

  String globToRegExp(String pattern) {
    var buffer = StringBuffer();
    for (var i = 0; i < pattern.length; i++) {
      var char = pattern[i];
      switch (char) {
        case '*':
          buffer.write('.*');
          break;
        case '?':
          buffer.write('.');
          break;
        case '[':
          buffer.write('[');
          break;
        case ']':
          buffer.write(']');
          break;
        default:
          if (RegExp(r'[.(){}+|^$]').hasMatch(char)) {
            buffer.write('\\');
          }
          buffer.write(char);
      }
    }

    return buffer.toString();
  }
}

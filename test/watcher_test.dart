import 'dart:io';

import 'package:gengen/watcher.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class TestWatcher with WatcherMixin {
  TestWatcher(this.source);

  @override
  final String source;

  bool didChange = false;

  @override
  void onFileChange() {
    didChange = true;
  }
}

void main() {
  group('WatcherMixin.shouldReload', () {
    test('returns false when file is missing', () {
      final tempDir = Directory.systemTemp.createTempSync('gengen-watch');
      final missingPath = p.join(tempDir.path, 'missing.txt');
      final watcher = TestWatcher(missingPath);

      expect(watcher.shouldReload(), isFalse);

      tempDir.deleteSync(recursive: true);
    });

    test('returns false when metadata matches file stats', () {
      final tempDir = Directory.systemTemp.createTempSync('gengen-watch');
      final file = File(p.join(tempDir.path, 'watched.txt'))
        ..writeAsStringSync('a');

      final watcher = TestWatcher(file.path);
      final stat = file.statSync();
      watcher.metadata['size'] = stat.size;
      watcher.metadata['last_modified'] = stat.modified.millisecondsSinceEpoch;

      expect(watcher.shouldReload(), isFalse);

      tempDir.deleteSync(recursive: true);
    });

    test('returns true when file changes', () {
      final tempDir = Directory.systemTemp.createTempSync('gengen-watch');
      final file = File(p.join(tempDir.path, 'watched.txt'))
        ..writeAsStringSync('a');

      final watcher = TestWatcher(file.path);
      final stat = file.statSync();
      watcher.metadata['size'] = stat.size;
      watcher.metadata['last_modified'] = stat.modified.millisecondsSinceEpoch;

      file.writeAsStringSync('ab');

      expect(watcher.shouldReload(), isTrue);

      tempDir.deleteSync(recursive: true);
    });
  });
}

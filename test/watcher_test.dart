import 'dart:async';
import 'dart:io';

import 'package:gengen/watcher.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

class TestWatcherMixin with WatcherMixin {
  TestWatcherMixin(this.source);

  @override
  final String source;

  @override
  void onFileChange() {}
}

void main() {
  group('WatcherMixin.shouldReload', () {
    test('returns false when file is missing', () {
      final tempDir = Directory.systemTemp.createTempSync('gengen-watch');
      final missingPath = p.join(tempDir.path, 'missing.txt');
      final watcher = TestWatcherMixin(missingPath);

      expect(watcher.shouldReload(), isFalse);

      tempDir.deleteSync(recursive: true);
    });

    test('returns false when metadata matches file stats', () {
      final tempDir = Directory.systemTemp.createTempSync('gengen-watch');
      final file = File(p.join(tempDir.path, 'watched.txt'))
        ..writeAsStringSync('a');

      final watcher = TestWatcherMixin(file.path);
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

      final watcher = TestWatcherMixin(file.path);
      final stat = file.statSync();
      watcher.metadata['size'] = stat.size;
      watcher.metadata['last_modified'] = stat.modified.millisecondsSinceEpoch;

      file.writeAsStringSync('ab');

      expect(watcher.shouldReload(), isTrue);

      tempDir.deleteSync(recursive: true);
    });
  });

  group('SiteWatcher', () {
    late Directory tempDir;
    late List<WatchEvent> receivedEvents;
    late SiteWatcher siteWatcher;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('gengen-sitewatcher');
      receivedEvents = [];
    });

    tearDown(() async {
      await siteWatcher.dispose();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('detects new file creation', () async {
      final completer = Completer<void>();

      siteWatcher = SiteWatcher(
        directories: [tempDir.path],
        onEvent: (event) {
          receivedEvents.add(event);
          if (event.type == ChangeType.ADD) {
            completer.complete();
          }
        },
        debounce: const Duration(milliseconds: 50),
      );

      await siteWatcher.start();

      // Give watcher time to initialize
      await Future.delayed(const Duration(milliseconds: 100));

      // Create a new file
      File(p.join(tempDir.path, 'new_file.txt')).writeAsStringSync('content');

      // Wait for event with timeout
      await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => fail('Timeout waiting for file creation event'),
      );

      expect(
        receivedEvents.any((e) => e.type == ChangeType.ADD),
        isTrue,
        reason: 'Should detect file creation',
      );
    });

    test('detects file modification', () async {
      // Create file before starting watcher
      final file = File(p.join(tempDir.path, 'existing.txt'))
        ..writeAsStringSync('initial');

      final completer = Completer<void>();

      siteWatcher = SiteWatcher(
        directories: [tempDir.path],
        onEvent: (event) {
          receivedEvents.add(event);
          if (event.type == ChangeType.MODIFY) {
            completer.complete();
          }
        },
        debounce: const Duration(milliseconds: 50),
      );

      await siteWatcher.start();
      await Future.delayed(const Duration(milliseconds: 100));

      // Modify the file
      file.writeAsStringSync('modified');

      await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => fail('Timeout waiting for file modification event'),
      );

      expect(
        receivedEvents.any((e) => e.type == ChangeType.MODIFY),
        isTrue,
        reason: 'Should detect file modification',
      );
    });

    test('detects file deletion', () async {
      // Create file before starting watcher
      final file = File(p.join(tempDir.path, 'to_delete.txt'))
        ..writeAsStringSync('delete me');

      final completer = Completer<void>();

      siteWatcher = SiteWatcher(
        directories: [tempDir.path],
        onEvent: (event) {
          receivedEvents.add(event);
          if (event.type == ChangeType.REMOVE) {
            completer.complete();
          }
        },
        debounce: const Duration(milliseconds: 50),
      );

      await siteWatcher.start();
      await Future.delayed(const Duration(milliseconds: 100));

      // Delete the file
      file.deleteSync();

      await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => fail('Timeout waiting for file deletion event'),
      );

      expect(
        receivedEvents.any((e) => e.type == ChangeType.REMOVE),
        isTrue,
        reason: 'Should detect file deletion',
      );
    });

    test('handles multiple directories', () async {
      final subDir1 = Directory(p.join(tempDir.path, 'dir1'))..createSync();
      final subDir2 = Directory(p.join(tempDir.path, 'dir2'))..createSync();

      final completer = Completer<void>();
      var eventCount = 0;

      siteWatcher = SiteWatcher(
        directories: [subDir1.path, subDir2.path],
        onEvent: (event) {
          receivedEvents.add(event);
          eventCount++;
          if (eventCount >= 2) {
            completer.complete();
          }
        },
        debounce: const Duration(milliseconds: 50),
      );

      await siteWatcher.start();
      await Future.delayed(const Duration(milliseconds: 100));

      // Create files in both directories
      File(p.join(subDir1.path, 'file1.txt')).writeAsStringSync('content1');
      await Future.delayed(const Duration(milliseconds: 100));
      File(p.join(subDir2.path, 'file2.txt')).writeAsStringSync('content2');

      await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => fail('Timeout waiting for events from multiple dirs'),
      );

      expect(receivedEvents.length, greaterThanOrEqualTo(2));
    });

    test('stop cleans up resources', () async {
      siteWatcher = SiteWatcher(
        directories: [tempDir.path],
        onEvent: (event) {
          receivedEvents.add(event);
        },
      );

      await siteWatcher.start();
      await siteWatcher.stop();

      // Create a file after stopping - should not trigger event
      File(p.join(tempDir.path, 'after_stop.txt')).writeAsStringSync('ignored');
      await Future.delayed(const Duration(milliseconds: 200));

      expect(receivedEvents, isEmpty);
    });

    test('skips non-existent directories', () async {
      final nonExistent = p.join(tempDir.path, 'does_not_exist');

      siteWatcher = SiteWatcher(
        directories: [nonExistent, tempDir.path],
        onEvent: (event) {
          receivedEvents.add(event);
        },
      );

      // Should not throw
      await siteWatcher.start();

      // Verify it still watches the existing directory
      final completer = Completer<void>();
      siteWatcher = SiteWatcher(
        directories: [nonExistent, tempDir.path],
        onEvent: (event) {
          receivedEvents.add(event);
          completer.complete();
        },
        debounce: const Duration(milliseconds: 50),
      );

      await siteWatcher.start();
      await Future.delayed(const Duration(milliseconds: 100));

      File(p.join(tempDir.path, 'test.txt')).writeAsStringSync('test');

      await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => fail('Timeout'),
      );

      expect(receivedEvents, isNotEmpty);
    });
  });
}

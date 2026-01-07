import 'dart:async';
import 'dart:io' as io;

import 'package:gengen/fs.dart';
import 'package:rxdart/rxdart.dart';
import 'package:watcher/watcher.dart';

/// Unified directory watcher using the battle-tested `watcher` package.
/// Handles file additions, modifications, and deletions in watched directories.
class SiteWatcher {
  final List<String> directories;
  final void Function(WatchEvent event) onEvent;
  final Duration debounce;

  final List<DirectoryWatcher> _watchers = [];
  final List<StreamSubscription<WatchEvent>> _subscriptions = [];
  final _eventController = StreamController<WatchEvent>.broadcast();

  SiteWatcher({
    required this.directories,
    required this.onEvent,
    this.debounce = const Duration(milliseconds: 300),
  });

  /// Start watching all configured directories
  Future<void> start() async {
    await stop(); // Clear any existing watchers

    // Set up debounced event handler
    _eventController.stream.debounceTime(debounce).listen(onEvent);

    for (final dir in directories) {
      // Use dart:io directly for existence check since watcher package uses it
      if (!io.Directory(dir).existsSync()) continue;

      final watcher = DirectoryWatcher(dir);
      _watchers.add(watcher);

      final subscription = watcher.events.listen((event) {
        _eventController.add(event);
      });
      _subscriptions.add(subscription);
    }
  }

  /// Stop all watchers and clean up resources
  Future<void> stop() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _watchers.clear();
  }

  /// Dispose of all resources
  Future<void> dispose() async {
    await stop();
    await _eventController.close();
  }
}

/// Mixin for individual file change detection (used for metadata tracking)
mixin WatcherMixin {
  final Map<String, dynamic> metadata = <String, dynamic>{};

  bool shouldReload() {
    var stat = FileStat.statSync(source);
    if (stat.type == FileSystemEntityType.notFound) return false;

    if (metadata.containsKey("size") && stat.size != metadata["size"]) {
      return true;
    }

    if (metadata.containsKey("last_modified") &&
        stat.modified.millisecondsSinceEpoch != metadata["last_modified"]) {
      return true;
    }

    if ((metadata.containsKey("last_modified") &&
            metadata.containsKey("size")) &&
        stat.modified.millisecondsSinceEpoch == metadata["last_modified"] &&
        stat.size == metadata["size"]) {
      return false;
    }

    return true;
  }

  String get source;

  void onFileChange();
}

import 'package:file/memory.dart';
import 'package:gengen/site.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/logging.dart';
import 'package:gengen/configuration.dart';
import 'package:gengen/hook.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

// Test plugin to track hook execution
class TestHookPlugin extends BasePlugin {
  static List<String> executionLog = [];
  static int instanceCounter = 0;
  
  final String identifier;
  
  TestHookPlugin([String? id]) : identifier = id ?? 'plugin${++instanceCounter}';
  
  static void clearLog() {
    executionLog.clear();
    instanceCounter = 0;
  }
  
  void _log(String event) {
    executionLog.add('$identifier:$event');
  }

  @override
  void afterInit() {
    _log('afterInit');
  }

  @override
  void beforeRead() {
    _log('beforeRead');
  }

  @override
  void afterRead() {
    _log('afterRead');
  }

  @override
  void beforeGenerate() {
    _log('beforeGenerate');
  }

  @override
  Future<void> generate() async {
    _log('generate');
  }

  @override
  void afterGenerate() {
    _log('afterGenerate');
  }

  @override
  void beforeRender() {
    _log('beforeRender');
  }

  @override
  void afterRender() {
    _log('afterRender');
  }

  @override
  void beforeWrite() {
    _log('beforeWrite');
  }

  @override
  void afterWrite() {
    _log('afterWrite');
  }
}

// Plugin that throws an exception for testing error handling
class ExceptionPlugin extends BasePlugin {
  @override
  void afterInit() {
    throw Exception('Test exception in hook');
  }
}

// Plugin that modifies site state during hooks
class StateModifyingPlugin extends BasePlugin {
  static Map<String, dynamic> siteData = {};
  
  static void clearData() {
    siteData.clear();
  }

  @override
  void afterInit() {
    siteData['afterInit'] = 'Site initialized';
  }

  @override
  void afterRead() {
    // Access site data and store information
    final site = Site.instance;
    siteData['postsCount'] = site.posts.length;
    siteData['pagesCount'] = site.pages.length;
  }

  @override
  void beforeWrite() {
    siteData['beforeWrite'] = 'Ready to write files';
  }
}

void main() {
  initLog();
  late MemoryFileSystem memoryFileSystem;
  late String projectRoot;

  setUp(() {
    TestHookPlugin.clearLog();
    memoryFileSystem = MemoryFileSystem();
    gengen_fs.fs = memoryFileSystem;
    projectRoot = memoryFileSystem.currentDirectory.path;

    // Create a minimal site structure
    final sourcePath = p.join(projectRoot, 'source');
    final sourceDir = memoryFileSystem.directory(sourcePath);
    sourceDir.createSync(recursive: true);

    // Create minimal required files
    memoryFileSystem
        .file(p.join(sourcePath, 'index.md'))
        .writeAsStringSync('---\ntitle: Home\n---\nHello World');

    final layoutsPath = p.join(sourcePath, '_layouts');
    memoryFileSystem.directory(layoutsPath).createSync(recursive: true);
    memoryFileSystem.file(p.join(layoutsPath, 'default.html')).writeAsStringSync('''
<!DOCTYPE html>
<html>
<head>
  <title>{{ page.title }}</title>
</head>
<body>
  {{ content }}
</body>
</html>
''');

    final postsPath = p.join(sourcePath, '_posts');
    memoryFileSystem.directory(postsPath).createSync();
    memoryFileSystem.file(p.join(postsPath, '2024-01-01-test-post.md'))
        .writeAsStringSync('''
---
title: Test Post
layout: default
date: 2024-01-01
---
Test content
''');

    // Theme structure (minimal)
    final themePath = p.join(sourcePath, '_themes', 'default', '_layouts');
    memoryFileSystem.directory(themePath).createSync(recursive: true);
    memoryFileSystem.file(p.join(themePath, 'default.html')).writeAsStringSync('{{ content }}');
  });

  group('Site Hook System', () {
    tearDown(() {
      memoryFileSystem.directory(projectRoot).deleteSync(recursive: true);
      Configuration.resetConfig();
      Site.resetInstance();
      TestHookPlugin.clearLog();
    });

    test('should execute hooks in the correct order during site processing', () async {
      Site.init(overrides: {
        'source': p.join(projectRoot, 'source'),
        'destination': p.join(projectRoot, 'public'),
        'theme': 'default',
      });

      final site = Site.instance;
      
      // Add a test plugin to track hook execution
      final testPlugin = TestHookPlugin('main');
      site.plugins.add(testPlugin);

      await site.process();

      // Verify the complete hook execution order
      final expectedOrder = [
        'main:afterInit',
        'main:beforeRead',
        'main:afterRead',
        'main:beforeGenerate',
        'main:generate',
        'main:afterGenerate',
        'main:beforeRender',
        'main:afterRender',
        'main:beforeWrite',
        'main:afterWrite',
      ];

      expect(TestHookPlugin.executionLog, equals(expectedOrder));
    });

    test('should execute hooks from multiple plugins in registration order', () async {
      Site.init(overrides: {
        'source': p.join(projectRoot, 'source'),
        'destination': p.join(projectRoot, 'public'),
        'theme': 'default',
      });

      final site = Site.instance;
      
      // Add multiple test plugins
      final plugin1 = TestHookPlugin('first');
      final plugin2 = TestHookPlugin('second');
      final plugin3 = TestHookPlugin('third');
      
      site.plugins.addAll([plugin1, plugin2, plugin3]);

      await site.process();

      // Verify that each hook event runs for all plugins in order
      final log = TestHookPlugin.executionLog;
      
      // Check afterInit hooks run in order
      final afterInitHooks = log.where((entry) => entry.endsWith(':afterInit')).toList();
      expect(afterInitHooks, equals(['first:afterInit', 'second:afterInit', 'third:afterInit']));
      
      // Check beforeRead hooks run in order
      final beforeReadHooks = log.where((entry) => entry.endsWith(':beforeRead')).toList();
      expect(beforeReadHooks, equals(['first:beforeRead', 'second:beforeRead', 'third:beforeRead']));
      
      // Check afterWrite hooks run in order (last hooks)
      final afterWriteHooks = log.where((entry) => entry.endsWith(':afterWrite')).toList();
      expect(afterWriteHooks, equals(['first:afterWrite', 'second:afterWrite', 'third:afterWrite']));
    });

    test('should execute individual hook events correctly', () async {
      Site.init(overrides: {
        'source': p.join(projectRoot, 'source'),
        'destination': p.join(projectRoot, 'public'),
        'theme': 'default',
      });

      final site = Site.instance;
      final testPlugin = TestHookPlugin('test');
      site.plugins.add(testPlugin);

      // Test individual hook methods
      await site.runHook(HookEvent.afterInit);
      expect(TestHookPlugin.executionLog, contains('test:afterInit'));

      TestHookPlugin.clearLog();
      await site.runHook(HookEvent.beforeRead);
      expect(TestHookPlugin.executionLog, contains('test:beforeRead'));

      TestHookPlugin.clearLog();
      await site.runHook(HookEvent.afterRead);
      expect(TestHookPlugin.executionLog, contains('test:afterRead'));

      TestHookPlugin.clearLog();
      await site.runHook(HookEvent.beforeGenerate);
      expect(TestHookPlugin.executionLog, contains('test:beforeGenerate'));

      TestHookPlugin.clearLog();
      await site.runHook(HookEvent.afterGenerate);
      expect(TestHookPlugin.executionLog, contains('test:afterGenerate'));

      TestHookPlugin.clearLog();
      await site.runHook(HookEvent.beforeRender);
      expect(TestHookPlugin.executionLog, contains('test:beforeRender'));

      TestHookPlugin.clearLog();
      await site.runHook(HookEvent.afterRender);
      expect(TestHookPlugin.executionLog, contains('test:afterRender'));

      TestHookPlugin.clearLog();
      await site.runHook(HookEvent.beforeWrite);
      expect(TestHookPlugin.executionLog, contains('test:beforeWrite'));

      TestHookPlugin.clearLog();
      await site.runHook(HookEvent.afterWrite);
      expect(TestHookPlugin.executionLog, contains('test:afterWrite'));
    });

    test('should handle hooks with no plugins gracefully', () async {
      Site.init(overrides: {
        'source': p.join(projectRoot, 'source'),
        'destination': p.join(projectRoot, 'public'),
        'theme': 'default',
      });

      final site = Site.instance;
      
      // Clear all plugins (including built-ins)
      site.plugins.clear();

      // Should not throw when running hooks with no plugins
      expect(() async => await site.runHook(HookEvent.afterInit), returnsNormally);
      expect(() async => await site.runHook(HookEvent.beforeRead), returnsNormally);
      expect(() async => await site.runHook(HookEvent.afterWrite), returnsNormally);
    });

    test('should execute generator hooks separately from lifecycle hooks', () async {
      Site.init(overrides: {
        'source': p.join(projectRoot, 'source'),
        'destination': p.join(projectRoot, 'public'),
        'theme': 'default',
      });

      final site = Site.instance;
      final testPlugin = TestHookPlugin('gen');
      site.plugins.add(testPlugin);

      // Test runGenerators method
      await site.runGenerators();
      
      expect(TestHookPlugin.executionLog, equals(['gen:generate']));
    });

    test('should maintain hook execution order even with built-in plugins', () async {
      Site.init(overrides: {
        'source': p.join(projectRoot, 'source'),
        'destination': p.join(projectRoot, 'public'),
        'theme': 'default',
      });

      final site = Site.instance;
      
      // Count built-in plugins
      final builtInCount = site.plugins.length;
      expect(builtInCount, greaterThan(0), reason: 'Should have built-in plugins');
      
      // Add our test plugin
      final testPlugin = TestHookPlugin('custom');
      site.plugins.add(testPlugin);

      // Run a single hook
      await site.runHook(HookEvent.afterInit);
      
      // Our custom plugin should have executed its hook
      expect(TestHookPlugin.executionLog, contains('custom:afterInit'));
      expect(TestHookPlugin.executionLog.length, equals(1), 
          reason: 'Only our test plugin should be logged');
    });

    test('should handle hook exceptions gracefully', () async {
      Site.init(overrides: {
        'source': p.join(projectRoot, 'source'),
        'destination': p.join(projectRoot, 'public'),
        'theme': 'default',
      });

      final site = Site.instance;
      site.plugins.add(ExceptionPlugin());

      // Hook should throw the exception (hooks don't catch exceptions)
      expect(() async => await site.runHook(HookEvent.afterInit), throwsException);
    });

    test('should execute hooks at the right phases of site processing', () async {
      Site.init(overrides: {
        'source': p.join(projectRoot, 'source'),
        'destination': p.join(projectRoot, 'public'),
        'theme': 'default',
      });

      final site = Site.instance;
      final testPlugin = TestHookPlugin('phase');
      site.plugins.add(testPlugin);

      // Process the site and verify hook timing
      await site.process();

      final log = TestHookPlugin.executionLog;
      
      // Verify the sequence includes all expected phases
      expect(log, contains('phase:afterInit'));
      expect(log, contains('phase:beforeRead'));
      expect(log, contains('phase:afterRead'));
      expect(log, contains('phase:beforeGenerate'));
      expect(log, contains('phase:generate'));
      expect(log, contains('phase:afterGenerate'));
      expect(log, contains('phase:beforeRender'));
      expect(log, contains('phase:afterRender'));
      expect(log, contains('phase:beforeWrite'));
      expect(log, contains('phase:afterWrite'));

      // Verify logical ordering (afterInit comes before beforeRead, etc.)
      final afterInitIndex = log.indexOf('phase:afterInit');
      final beforeReadIndex = log.indexOf('phase:beforeRead');
      final afterReadIndex = log.indexOf('phase:afterRead');
      final beforeWriteIndex = log.indexOf('phase:beforeWrite');
      final afterWriteIndex = log.indexOf('phase:afterWrite');

      expect(afterInitIndex, lessThan(beforeReadIndex));
      expect(beforeReadIndex, lessThan(afterReadIndex));
      expect(beforeWriteIndex, lessThan(afterWriteIndex));
      expect(afterReadIndex, lessThan(beforeWriteIndex));
    });

    test('should allow plugins to access and modify site state during hooks', () async {
      Site.init(overrides: {
        'source': p.join(projectRoot, 'source'),
        'destination': p.join(projectRoot, 'public'),
        'theme': 'default',
      });

      final site = Site.instance;
      final statePlugin = StateModifyingPlugin();
      site.plugins.add(statePlugin);

      StateModifyingPlugin.clearData();

      await site.process();

      // Verify that the plugin was able to access and store site information
      expect(StateModifyingPlugin.siteData['afterInit'], equals('Site initialized'));
      expect(StateModifyingPlugin.siteData['beforeWrite'], equals('Ready to write files'));
      
      // Verify the plugin accessed actual site data
      expect(StateModifyingPlugin.siteData['postsCount'], isA<int>());
      expect(StateModifyingPlugin.siteData['pagesCount'], isA<int>());
      expect(StateModifyingPlugin.siteData['postsCount'], greaterThan(0), 
          reason: 'Should have found the test post');
      expect(StateModifyingPlugin.siteData['pagesCount'], greaterThan(0),
          reason: 'Should have found the index page');
    });
  });
} 
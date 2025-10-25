import 'package:file/memory.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/reader.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Reader with basic setup', () {
    late MemoryFileSystem memoryFileSystem;
    late String projectRoot;
    late Site site;
    late Reader reader;

    setUpAll(() {
      // Reset the Site singleton before this test group starts
      Site.resetInstance();
    });

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      gengen_fs.fs = memoryFileSystem;
      projectRoot = memoryFileSystem.currentDirectory.path;
      final sourcePath = p.join(projectRoot, 'source');
      memoryFileSystem.directory(sourcePath).createSync(recursive: true);

      // layouts
      final siteLayoutsPath = p.join(sourcePath, '_layouts');
      memoryFileSystem.directory(siteLayoutsPath).createSync(recursive: true);
      memoryFileSystem
          .file(p.join(siteLayoutsPath, 'default.html'))
          .writeAsStringSync('Site default layout');

      // posts
      final postsPath = p.join(sourcePath, '_posts');
      memoryFileSystem.directory(postsPath).createSync();
      memoryFileSystem
          .file(p.join(postsPath, '2024-01-01-my-post.md'))
          .writeAsStringSync('---\ntitle: My Post\n---');

      // data
      final dataPath = p.join(sourcePath, '_data');
      memoryFileSystem.directory(dataPath).createSync();
      memoryFileSystem
          .file(p.join(dataPath, 'members.yml'))
          .writeAsStringSync('- name: John Doe\n- name: Jane Doe');

      // pages
      memoryFileSystem
          .file(p.join(sourcePath, 'about.md'))
          .writeAsStringSync('---\ntitle: About Us\n---');

      // static files
      memoryFileSystem
          .file(p.join(sourcePath, 'robots.txt'))
          .writeAsStringSync('User-agent: *');

      // theme
      final themesPath = p.join(sourcePath, '_themes');
      final themePath = p.join(themesPath, 'my-theme');
      final themeLayoutsPath = p.join(themePath, '_layouts');
      memoryFileSystem.directory(themeLayoutsPath).createSync(recursive: true);
      memoryFileSystem
          .file(p.join(themeLayoutsPath, 'page.html'))
          .writeAsStringSync('Theme page layout');

      final themeAssetsPath = p.join(themePath, 'assets');
      memoryFileSystem.directory(themeAssetsPath).createSync();
      memoryFileSystem
          .file(p.join(themeAssetsPath, 'style.css'))
          .writeAsStringSync('body { color: blue; }');

      // plugins
      final pluginsPath = p.join(sourcePath, '_plugins');
      final myPluginPath = p.join(pluginsPath, 'my_plugin');
      memoryFileSystem.directory(myPluginPath).createSync(recursive: true);

      memoryFileSystem
          .file(p.join(myPluginPath, 'main.lua'))
          .writeAsStringSync('function init_plugin(metadata)\n  return {\n    after_generate = function() end\n  }\nend');

      memoryFileSystem
          .file(p.join(myPluginPath, 'config.yaml'))
          .writeAsStringSync('name: MyPlugin\nentrypoint: main.lua:init_plugin');

      Site.init(overrides: {
        'source': sourcePath,
        'destination': p.join(projectRoot, 'public'),
        'theme': 'my-theme',
      });
      site = Site.instance;
      reader = site.reader;
    });

    tearDown(() {
      // Reset the Site singleton to ensure clean state between test groups
      Site.resetInstance();
    });

    test('should load layouts', () async {
      await reader.read();
      expect(site.layouts.length, 2);
      expect(site.layouts.containsKey('default'), isTrue);
      expect(site.layouts.containsKey('page'), isTrue);
    });

    test('should load data', () async {
      await reader.read();
      expect(site.data['members'], isA<List>());
      expect(site.data['members'].length, 2);
    });

    test('should load posts', () async {
      await reader.read();
      expect(site.posts.length, 1);
      expect(site.posts.first.config['title'], 'My Post');
    });

    test('should load pages', () async {
      await reader.read();
      expect(site.pages.length, 1);
      expect(site.pages.first.config['title'], 'About Us');
    });

    test('should load static files', () async {
      await reader.read();
      expect(site.staticFiles.length, 2);
      expect(
          site.staticFiles.any((file) => file.name == 'robots.txt'), isTrue);
      expect(
          site.staticFiles.any((file) => p.basename(file.name) == 'style.css'),
          isTrue);
    });

    test('should load plugins', () async {
      await reader.read();
      // The built-in plugins are always there, so we check for +1
      expect(site.plugins.length, 6,
          reason: 'Should load built-in plugins plus my_plugin.lua');
      expect(site.plugins.any((p) => p.metadata.name == 'MyPlugin'), isTrue);
    });
  });

  group('Reader with exclude/include', () {
    late MemoryFileSystem memoryFileSystem;
    late String projectRoot;
    late Site site;
    late Reader reader;

    setUpAll(() {
      // Reset the Site singleton before this test group starts
      Site.resetInstance();
    });

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      gengen_fs.fs = memoryFileSystem;
      projectRoot = memoryFileSystem.currentDirectory.path;
      final sourcePath = p.join(projectRoot, 'source');
      memoryFileSystem.directory(sourcePath).createSync(recursive: true);

      // Normal files
      memoryFileSystem
          .file(p.join(sourcePath, 'index.md'))
          .writeAsStringSync('---\ntitle: Home\n---');

      // theme
      final themesPath = p.join(sourcePath, '_themes');
      final themePath = p.join(themesPath, 'my-theme');
      final themeLayoutsPath = p.join(themePath, '_layouts');
      memoryFileSystem.directory(themeLayoutsPath).createSync(recursive: true);
      memoryFileSystem
          .file(p.join(themeLayoutsPath, 'page.html'))
          .writeAsStringSync('Theme page layout');

      final themeAssetsPath = p.join(themePath, 'assets');
      memoryFileSystem.directory(themeAssetsPath).createSync();
      memoryFileSystem
          .file(p.join(themeAssetsPath, 'style.css'))
          .writeAsStringSync('body { color: blue; }');

      // Excluded files
      final excludedDir = p.join(sourcePath, 'excluded_dir');
      memoryFileSystem.directory(excludedDir).createSync(recursive: true);
      memoryFileSystem
          .file(p.join(excludedDir, 'excluded.md'))
          .writeAsStringSync('---\ntitle: Excluded\n---');
      memoryFileSystem
          .file(p.join(sourcePath, 'excluded_file.md'))
          .writeAsStringSync('---\ntitle: Excluded File\n---');

      // For complex patterns
      memoryFileSystem
          .file(p.join(sourcePath, 'secret.txt'))
          .writeAsStringSync('secret content');
      final notesDir = p.join(sourcePath, 'notes');
      memoryFileSystem.directory(notesDir).createSync(recursive: true);
      memoryFileSystem
          .file(p.join(notesDir, 'meeting_notes.md'))
          .writeAsStringSync('---\ntitle: Meeting Notes\n---');
      memoryFileSystem
          .file(p.join(notesDir, 'important_notes.md'))
          .writeAsStringSync('---\ntitle: Important Notes\n---');
      final draftsDir = p.join(sourcePath, '_drafts');
      memoryFileSystem.directory(draftsDir).createSync(recursive: true);
      memoryFileSystem
          .file(p.join(draftsDir, 'new_post.md'))
          .writeAsStringSync('---\ntitle: New Post Draft\n---');

      Site.init(overrides: {
        'source': sourcePath,
        'destination': p.join(projectRoot, 'public'),
        'theme': 'my-theme',
        'exclude': [
          'excluded_dir/**',
          'excluded_file.md',
          '*.txt',
          'notes/**',
          '_drafts/**',
          '*_notes.md',
        ],
        'include': [
          'notes/important_notes.md',
        ]
      });
      site = Site.instance;
      reader = site.reader;
    });

    tearDown(() {
      // Reset the Site singleton to ensure clean state between test groups
      Site.resetInstance();
    });

    test('should not load excluded files and directories with various patterns',
        () async {
      await reader.read();

      expect(site.pages.length, 2,
          reason: "Only index.md and important_notes.md should be loaded");

      // Simple exclude
      expect(site.pages.any((page) => page.name == 'excluded_dir/excluded.md'), isFalse,
          reason: "excluded_dir/excluded.md should not be loaded");
      expect(
          site.pages.any((page) => page.name == 'excluded_file.md'), isFalse,
          reason: "excluded_file.md should not be loaded");

      // Wildcard exclude
      expect(site.staticFiles.any((file) => file.name == 'secret.txt'), isFalse,
          reason: "secret.txt should be excluded by wildcard");

      // Directory exclude with include override
      expect(site.pages.any((page) => page.name == 'notes/meeting_notes.md'), isFalse,
          reason: "files in notes/ should be excluded");

      // Drafts exclude (treated as posts but should be excluded)
      expect(site.posts.any((post) => post.name == '_drafts/new_post.md'), isFalse,
          reason: "drafts should be excluded");

      // Complex wildcard
      expect(site.pages.any((page) => page.name == 'notes/meeting_notes.md'), isFalse,
          reason:
              "notes/meeting_notes.md should be excluded by complex wildcard '*_notes.md'");
    });

    test(
        'should include files that are explicitly included even if parent is excluded',
        () async {
      await reader.read();
      
      expect(
          site.pages.any((page) => page.name == 'notes/important_notes.md'), isTrue,
          reason: "notes/important_notes.md should be included");
      expect(
          site.pages.any((page) => page.name == 'notes/meeting_notes.md'), isFalse,
          reason: "notes/meeting_notes.md should remain excluded");
    });

    test('should exclude directory contents when directory name is excluded (without /**)', () async {
      // Create additional test structure in memory
      final sourcePath = site.config.source;
      
      // Create a simple directory structure to test directory exclusion
      final secretDir = p.join(sourcePath, 'secret');
      memoryFileSystem.directory(secretDir).createSync(recursive: true);
      memoryFileSystem
          .file(p.join(secretDir, 'file.txt'))
          .writeAsStringSync('secret content');
      memoryFileSystem
          .file(p.join(secretDir, 'config.json'))
          .writeAsStringSync('{"secret": true}');
      
      // Create a nested directory within the excluded directory
      final nestedDir = p.join(secretDir, 'nested');
      memoryFileSystem.directory(nestedDir).createSync(recursive: true);
      memoryFileSystem
          .file(p.join(nestedDir, 'deep.md'))
          .writeAsStringSync('---\ntitle: Deep Secret\n---');

      // Update site config to exclude just the directory name (not secret/**)
      Site.resetInstance();
      Site.init(overrides: {
        'source': sourcePath,
        'destination': p.join(site.config.destination),
        'theme': 'my-theme',
        'exclude': [
          'secret',  // Just the directory name, should exclude everything inside
        ],
        'include': []
      });
      
      final newSite = Site.instance;
      final newReader = newSite.reader;
      await newReader.read();

      // Verify that excluding 'secret' excludes all files within the secret directory
      expect(newSite.staticFiles.any((file) => file.name == 'secret/file.txt'), isFalse,
          reason: "secret/file.txt should be excluded when 'secret' directory is excluded");
      expect(newSite.staticFiles.any((file) => file.name == 'secret/config.json'), isFalse,
          reason: "secret/config.json should be excluded when 'secret' directory is excluded");
      expect(newSite.pages.any((page) => page.name == 'secret/nested/deep.md'), isFalse,
          reason: "secret/nested/deep.md should be excluded when 'secret' directory is excluded");
      
      // Verify that other files are still included
      expect(newSite.pages.any((page) => page.name == 'index.md'), isTrue,
          reason: "index.md should still be included");
    });

    test('should handle complex exclude-then-include patterns', () async {
      // Create additional test structure in memory
      final sourcePath = site.config.source;
      
      // Create node_modules structure
      final nodeModulesDir = p.join(sourcePath, 'node_modules');
      memoryFileSystem.directory(nodeModulesDir).createSync(recursive: true);
      memoryFileSystem
          .file(p.join(nodeModulesDir, 'package.json'))
          .writeAsStringSync('{"name": "test"}');
      memoryFileSystem
          .file(p.join(nodeModulesDir, 'index.js'))
          .writeAsStringSync('console.log("test");');
      
      // Create a deeply nested structure
      final deepDir = p.join(nodeModulesDir, 'some-package', 'dist');
      memoryFileSystem.directory(deepDir).createSync(recursive: true);
      memoryFileSystem
          .file(p.join(deepDir, 'important.css'))
          .writeAsStringSync('body { margin: 0; }');
      memoryFileSystem
          .file(p.join(deepDir, 'other.js'))
          .writeAsStringSync('// other code');

      // Update site config to exclude node_modules but include specific files
      Site.resetInstance();
      Site.init(overrides: {
        'source': sourcePath,
        'destination': p.join(site.config.destination),
        'theme': 'my-theme',
        'exclude': [
          'excluded_dir/**',
          'excluded_file.md', 
          '*.txt',
          'notes/**',
          '_drafts/**',
          '*_notes.md',
          'node_modules/**',  // Exclude entire node_modules
        ],
        'include': [
          'notes/important_notes.md',
          'node_modules/package.json',  // But include package.json
          'node_modules/some-package/dist/important.css',  // And this specific CSS
        ]
      });
      
      final newSite = Site.instance;
      final newReader = newSite.reader;
      await newReader.read();

      // Verify exclusions work
      expect(newSite.staticFiles.any((file) => file.name == 'node_modules/index.js'), isFalse,
          reason: "node_modules/index.js should be excluded");
      expect(newSite.staticFiles.any((file) => file.name == 'node_modules/some-package/dist/other.js'), isFalse,
          reason: "node_modules/some-package/dist/other.js should be excluded");

      // Verify specific includes work even within excluded directories
      expect(newSite.staticFiles.any((file) => file.name == 'node_modules/package.json'), isTrue,
          reason: "node_modules/package.json should be included despite node_modules/** being excluded");
      expect(newSite.staticFiles.any((file) => file.name == 'node_modules/some-package/dist/important.css'), isTrue,
          reason: "node_modules/some-package/dist/important.css should be included despite node_modules/** being excluded");
      
      // Verify the original include still works
      expect(newSite.pages.any((page) => page.name == 'notes/important_notes.md'), isTrue,
          reason: "notes/important_notes.md should still be included");
    });
  });
} 

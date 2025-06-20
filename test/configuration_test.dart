import 'package:gengen/configuration.dart';
import 'package:gengen/di.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart' as yaml_parser; // Import with alias for YamlException

void main() {
  late MemoryFileSystem memoryFileSystem;
  // This captures the actual current working directory of the Dart process (where 'gengen' is running).
  // All mock file creations and path assertions will be based on this real path, mirrored in MemoryFileSystem.
  final String realProjectRoot = p.current;

  setUp(() {
    memoryFileSystem = MemoryFileSystem();

    // Inject the in-memory file system into gengen's fs global variable.
    // This ensures all gengen's file operations (e.g., in Configuration.read)
    // use our mock filesystem instead of the real one.
    gengen_fs.fs = memoryFileSystem;

    // Reset Configuration's static state before each test.
    // This is crucial for test isolation as Configuration holds static data.
    Configuration.resetConfig();

    // Mirror the real project root directory structure within the in-memory file system.
    // This allows Configuration to find mock config files at their expected p.current locations.
    memoryFileSystem.directory(realProjectRoot).createSync(recursive: true);
    // Setting currentDirectory here ensures that any subsequent p.current calls
    // within the test execution environment (even though gengen's Configuration
    // uses the real p.current) will correspond to realProjectRoot in our mocked file system.
    memoryFileSystem.currentDirectory = memoryFileSystem.directory(realProjectRoot);

    // Note: Site.init() is deliberately NOT called here as Configuration tests
    // should be isolated and not depend on Site's global state or its config loading.
  });

  group('Configuration Tests', () {
    test('1. Default values are applied correctly when no config is provided', () {
      final config = Configuration();
      config.read(); // Read with no overrides or config files

      expect(config.get<String>('title'), 'My GenGen Site');
      expect(config.get<String>('url'), 'http://gengen.local');
      expect(config.get<String>('theme'), 'default');
      // Destination is resolved relative to the source, which defaults to p.current (realProjectRoot).
      expect(config.get<String>('destination'), equals(p.join(realProjectRoot, 'public')));
      expect(config.get<List<String>>('exclude'), contains('config.yaml'));
      expect(config.get<List<String>>('include'), isEmpty);
      expect(config.get<String>('post_dir'), '_posts');
      expect(config.get<String>('draft_dir'), '_draft');
      expect(config.get<String>('themes_dir'), '_themes');
      expect(config.get<String>('layout_dir'), '_layouts');
      expect(config.get<String>('plugin_dir'), '_plugins');
      expect(config.get<String>('sass_dir'), '_sass');
      expect(config.get<String>('data_dir'), '_data');
      expect(config.get<String>('asset_dir'), 'assets');
      expect(config.get<String>('template_dir'), '_templates');
      expect(config.get<String>('include_dir'), '_includes');
      expect(config.get<List<String>>('block_list'), isEmpty);
      expect(config.get<List<String>>('markdown_extensions'), isEmpty);
      expect(config.get<String>('permalink'), 'date');
      expect(config.get<bool>('publish_drafts'), isFalse);
      expect(config.get<String>('date_format'), 'yyyy-MM-dd HH:mm:ss');
      expect(config.get<Map<String, dynamic>>('output')!['posts_dir'], 'posts');
      expect(config.get<Map<String, dynamic>>('data'), {});

      // Source should be the realProjectRoot as that's p.current when Configuration reads defaults.
      expect(config.source, equals(realProjectRoot));
    });

    test('2. Single config file values are read and override defaults', () {
      // Create the config file relative to the real project root in the mock filesystem.
      final configFilePath = p.join(realProjectRoot, '_config.yaml');
      memoryFileSystem.file(configFilePath).writeAsStringSync('''
title: My Custom Site
description: A custom site description.
url: http://custom.com
theme: custom_theme # Add theme to override default
''');

      final config = Configuration();
      config.read(); // Read with default config file (_config.yaml)

      expect(config.get<String>('title'), 'My Custom Site');
      expect(config.get<String>('description'), 'A custom site description.');
      expect(config.get<String>('url'), 'http://custom.com');
      expect(config.get<String>('theme'), 'custom_theme'); // Should be overridden
    });

    test('3. Multiple config files are merged correctly with precedence (later overrides earlier)', () {
      // Create config files relative to the real project root in the mock filesystem.
      final configFilePath1 = p.join(realProjectRoot, '_config1.yaml');
      final configFilePath2 = p.join(realProjectRoot, '_config2.yaml');

      memoryFileSystem.file(configFilePath1).writeAsStringSync('''
title: Site One
author: John Doe
plugins:
  - plugin_a
social:
  twitter: handle1
''');

      memoryFileSystem.file(configFilePath2).writeAsStringSync('''
title: Site Two
email: two@example.com
plugins:
  - plugin_b
social:
  github: handle2
''');

      final config = Configuration();
      // Pass the config files as an override to simulate CLI behavior.
      // Note: `Configuration.read` consumes the 'config' override for processing; it's not stored in the final config map.
      config.read({'config': ['_config1.yaml', '_config2.yaml']});

      expect(config.get<String>('title'), 'Site Two'); // config2 overrides config1 for 'title'
      expect(config.get<String>('author'), 'John Doe'); // 'author' only in config1
      expect(config.get<String>('email'), 'two@example.com'); // 'email' only in config2
      // For lists like 'plugins', the behavior is replacement.
      expect(config.get<List<dynamic>>('plugins'), ['plugin_b']); 
      final social = config.get<Map<String,dynamic>>('social');
      expect(social, {'twitter': 'handle1', 'github': 'handle2'});
    });

    test('4. Command-line overrides take highest precedence', () {
      final configFilePath = p.join(realProjectRoot, '_config.yaml');
      memoryFileSystem.file(configFilePath).writeAsStringSync('''
title: File Title
theme: dark
description: From file
plugins:
  - plugin_file
''');

      final config = Configuration();
      config.read({
        'title': 'CLI Title',
        'destination': 'cli_output',
        'theme': 'cli_theme', // CLI overrides file for theme
        'plugins': ['plugin_cli'], // CLI overrides file for plugins
      });

      expect(config.get<String>('title'), 'CLI Title'); // CLI overrides file
      expect(config.get<String>('theme'), 'cli_theme'); // CLI overrides file
      expect(config.get<String>('description'), 'From file'); // File value remains, not overridden by CLI
      // CLI override for destination is relative to `realProjectRoot`.
      expect(config.get<String>('destination'), equals(p.join(realProjectRoot, 'cli_output')));
      // CLI override for plugins replaces the file list.
      expect(config.get<List<dynamic>>('plugins'), ['plugin_cli']);
    });

    test('5. Data type handling is correct', () {
      final configFilePath = p.join(realProjectRoot, '_config.yaml');
      memoryFileSystem.file(configFilePath).writeAsStringSync('''
count: 123
enabled: true
items:
  - item1
  - item2
data:
  key: value
''');

      final config = Configuration();
      config.read();

      expect(config.get<int>('count'), 123);
      expect(config.get<bool>('enabled'), isTrue);
      expect(config.get<List<dynamic>>('items'), ['item1', 'item2']);
      expect(config.get<Map<String, dynamic>>('data'), {'key': 'value'});
    });

    test('6. Nested configuration values are accessible', () {
      final configFilePath = p.join(realProjectRoot, '_config.yaml');
      memoryFileSystem.file(configFilePath).writeAsStringSync('''
social:
  twitter: myhandle
  github: mygithub
output:
  posts_dir: my_posts
''');

      final config = Configuration();
      config.read();

      final socialConfig = config.get<Map<String, dynamic>>('social');
      expect(socialConfig, isNotNull);
      expect(socialConfig!['twitter'], 'myhandle');
      expect(socialConfig['github'], 'mygithub');

      final outputConfig = config.get<Map<String, dynamic>>('output');
      expect(outputConfig, isNotNull);
      expect(outputConfig!['posts_dir'], 'my_posts');
    });

    test('7. `include` and `exclude` validation prevents non-list types', () {
      final configFilePath = p.join(realProjectRoot, '_config.yaml');
      final config = Configuration();

      // Test invalid include (not a list)
      memoryFileSystem.file(configFilePath).writeAsStringSync('''
include: some_string
''');
      // Configuration.read calls checkIncludeExclude internally, which should now throw FormatException
      expect(() => config.read(), throwsA(isA<FormatException>()));

      Configuration.resetConfig(); // Reset config for the next test
      // Test invalid exclude (not a list)
      memoryFileSystem.file(configFilePath).writeAsStringSync('''
exclude: another_string
''');
      final config2 = Configuration();
      expect(() => config2.read(), throwsA(isA<FormatException>()));
    });

    test('8. Path resolution for source and destination is correct', () {
      // Create dummy source and destination directories in the in-memory file system.
      // These directories need to be created relative to realProjectRoot (our mock p.current).
      memoryFileSystem.directory(p.join(realProjectRoot, 'src')).createSync(recursive: true);
      // Destination does not need to pre-exist for Configuration to resolve its path.

      // Test with relative source and relative destination
      final config1 = Configuration();
      config1.read({'source': 'src', 'destination': 'output'});
      expect(config1.source, equals(p.join(realProjectRoot, 'src')));
      expect(config1.destination, equals(p.join(realProjectRoot, 'src', 'output')));

      // Test with absolute source and relative destination
      final absoluteSourcePath = '/absolute_src'; // This is an absolute path within the MemoryFileSystem
      memoryFileSystem.directory(absoluteSourcePath).createSync();
      final config2 = Configuration();
      config2.read({'source': absoluteSourcePath, 'destination': 'build'});
      expect(config2.source, equals(absoluteSourcePath));
      expect(config2.destination, equals(p.join(absoluteSourcePath, 'build')));

      // Test with absolute source and absolute destination
      final absoluteDestPath = '/absolute_output'; // This is an absolute path within the MemoryFileSystem
      memoryFileSystem.directory(absoluteDestPath).createSync();
      final config3 = Configuration();
      config3.read({'source': absoluteSourcePath, 'destination': absoluteDestPath});
      expect(config3.source, equals(absoluteSourcePath));
      expect(config3.destination, equals(absoluteDestPath));
    });

    test('9. Reading non-existent config file should not throw, but log warning and use defaults/overrides', () {
      final config = Configuration();
      // Do not create the config file '_non_existent_config.yaml'

      // Configuration.read is expected to log a warning and proceed with defaults/overrides.
      // `returnsNormally` confirms no exception is thrown.
      expect(() => config.read({'config': ['_non_existent_config.yaml']}), returnsNormally);
      expect(config.get<String>('title'), 'My GenGen Site'); // Should still load defaults
    });

    test('10. Reading malformed config file should throw YamlException', () {
      final malformedConfigPath = p.join(realProjectRoot, '_malformed_config.yaml');
      memoryFileSystem.file(malformedConfigPath).writeAsStringSync('''
title: My Site
  invalid_key: value # Incorrect indentation
''');

      final config = Configuration();
      // Expects YamlException due to malformed YAML.
      expect(() => config.read({'config': ['_malformed_config.yaml']}), throwsA(isA<yaml_parser.YamlException>()));
    });

    test('11. Reading config file with invalid extension should throw FormatException', () {
      final invalidExtConfigPath = p.join(realProjectRoot, '_config.txt');
      memoryFileSystem.file(invalidExtConfigPath).writeAsStringSync('''
title: Invalid Extension
''');

      final config = Configuration();
      // Expects FormatException because the extension is not .yaml or .yml.
      expect(() => config.read({'config': ['_config.txt']}), throwsA(isA<FormatException>()));
    });
  });
}
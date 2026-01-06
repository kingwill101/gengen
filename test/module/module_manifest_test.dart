import 'package:gengen/module/module_import.dart';
import 'package:gengen/module/module_manifest.dart';
import 'package:test/test.dart';

void main() {
  group('ModuleImport', () {
    test('parses local path import', () {
      final import_ = ModuleImport.parse({
        'path': '../my-theme',
        'version': '1.0.0',
      });

      expect(import_.path, '../my-theme');
      expect(import_.version, '1.0.0');
      expect(import_.type, ModuleType.local);
      expect(import_.name, 'my-theme');
    });

    test('parses absolute path import', () {
      final import_ = ModuleImport.parse({
        'path': '/home/user/themes/custom',
      });

      expect(import_.type, ModuleType.local);
      expect(import_.name, 'custom');
    });

    test('parses github import', () {
      final import_ = ModuleImport.parse({
        'path': 'github.com/user/gengen-theme-minimal',
        'version': '^1.0.0',
      });

      expect(import_.type, ModuleType.git);
      expect(import_.name, 'gengen-theme-minimal');
    });

    test('parses gitlab import', () {
      final import_ = ModuleImport.parse({
        'path': 'gitlab.com/org/theme',
      });

      expect(import_.type, ModuleType.git);
      expect(import_.name, 'theme');
    });

    test('parses pub import', () {
      final import_ = ModuleImport.parse({
        'path': 'pub:gengen_theme_aurora',
        'version': '^0.5.0',
      });

      expect(import_.type, ModuleType.pub);
      expect(import_.name, 'gengen_theme_aurora');
    });
  });

  group('ModuleReplacement', () {
    test('parses replacement', () {
      final replacement = ModuleReplacement.parse({
        'path': 'github.com/user/theme',
        'local': '../my-fork',
      });

      expect(replacement.path, 'github.com/user/theme');
      expect(replacement.local, '../my-fork');
    });
  });

  group('ModuleManifest', () {
    test('parses empty manifest', () {
      final manifest = ModuleManifest.parse(null);
      expect(manifest.isEmpty, true);
      expect(manifest.hasImports, false);
    });

    test('parses manifest with imports', () {
      final manifest = ModuleManifest.parse({
        'imports': [
          {'path': 'github.com/user/theme', 'version': '^1.0.0'},
          {'path': '../local-plugin'},
          {'path': 'pub:gengen_seo', 'version': '>=2.0.0'},
        ],
      });

      expect(manifest.imports.length, 3);
      expect(manifest.imports[0].type, ModuleType.git);
      expect(manifest.imports[1].type, ModuleType.local);
      expect(manifest.imports[2].type, ModuleType.pub);
    });

    test('parses manifest with replacements', () {
      final manifest = ModuleManifest.parse({
        'imports': [
          {'path': 'github.com/user/theme', 'version': '^1.0.0'},
        ],
        'replacements': [
          {'path': 'github.com/user/theme', 'local': '../my-fork'},
        ],
      });

      expect(manifest.imports.length, 1);
      expect(manifest.replacements.length, 1);
      expect(
        manifest.getReplacementFor('github.com/user/theme'),
        '../my-fork',
      );
      expect(manifest.getReplacementFor('other/path'), null);
    });

    test('hasImports returns correct value', () {
      final empty = ModuleManifest.parse({});
      expect(empty.hasImports, false);

      final withImports = ModuleManifest.parse({
        'imports': [
          {'path': 'github.com/user/theme'},
        ],
      });
      expect(withImports.hasImports, true);
    });
  });
}

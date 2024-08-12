import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:gengen/di.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:gengen/site.dart';
import 'package:test/test.dart';

void main() {
  setUp(() async {
    if (!getIt.isRegistered<FileSystem>()) {
      getIt.registerLazySingleton<FileSystem>(() => LocalFileSystem());
    }
    Site.init(overrides: {
      'source': 'examples/plugins',
      'destination': 'build',
    });
    site.read();
  });

  test("correct plugin count", () {
    expect(site.plugins.length, equals(1));
  });

  test("plugin metadata", () {
    final plugin = site.plugins.first;
    expect(plugin.name, equals("metadata"));
    expect(plugin.entrypoint, equals("metadata:Plugin"));
    expect(plugin.className, equals("Plugin"));
    expect(plugin.classFilePath, equals("metadata.dart"));
    expect(plugin.dartFiles.length, equals(3));
    expect(plugin.assets.length, equals(1));
    expect(plugin.imports().length, equals(3));
    expect(
        plugin.imports().keys,
        equals([
          "metadata.dart",
          "helpers/hello.dart",
          "helpers/world.dart",
        ]));
  });
}

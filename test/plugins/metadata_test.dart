import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:gengen/di.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/site.dart';
import 'package:test/test.dart';

void main() {
  setUp(() async {
    if (!getIt.isRegistered<FileSystem>()) {
      getIt.registerLazySingleton<FileSystem>(() => LocalFileSystem());
    }
    initLog();
    Site.init(
      overrides: {'source': 'examples/plugins', 'destination': 'build'},
    );
    site.read();
  });

  test("correct plugin count", () {
    expect(site.plugins.length, equals(5));
  });
}

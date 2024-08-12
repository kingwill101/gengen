import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:gengen/di.dart';
import 'package:gengen/site.dart';
import 'package:test/test.dart';

void main() {
  setUp(() async {
    if (!getIt.isRegistered<FileSystem>()) {
      getIt.registerLazySingleton<FileSystem>(() => LocalFileSystem());
    }
    Site.init(overrides: {
      'source': 'examples/data',
    });
    site.read();
  });

  test("loads data", () {
    expect(
        site.config.get<Map<String, dynamic>>("data", defaultValue: {}),
        equals({
          'users': {
            'dick': {'name': 'Dick'},
            'harry': {'name': 'Harry'},
            'tom': {'name': 'Tom'},
          },
          'pages': [
            'home',
            'about',
            'contact',
          ]
        }));
  });
}

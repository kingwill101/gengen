import 'package:file/memory.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/liquid/template.dart';
import 'package:gengen/site.dart';
import 'package:liquify/liquify.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late MemoryFileSystem memoryFileSystem;
  late String projectRoot;

  setUp(() async {
    memoryFileSystem = MemoryFileSystem();
    gengen_fs.fs = memoryFileSystem;
    projectRoot = memoryFileSystem.currentDirectory.path;

    // Create a basic site structure
    final sourcePath = p.join(projectRoot, 'source');
    final sourceDir = memoryFileSystem.directory(sourcePath);
    sourceDir.createSync(recursive: true);

    // Create _data directory
    final dataPath = p.join(sourcePath, '_data');
    memoryFileSystem.directory(dataPath).createSync(recursive: true);

    // Create users.yml file
    memoryFileSystem.file(p.join(dataPath, 'users.yml')).writeAsStringSync('''
dick:
  name: Dick
harry:
  name: Harry
tom:
  name: Tom
''');

    // Create pages.yml file
    memoryFileSystem.file(p.join(dataPath, 'pages.yml')).writeAsStringSync('''
- home
- about
- contact
''');

    // Create profiles.yml file (mentioned in the original test expectation)
    memoryFileSystem.file(p.join(dataPath, 'profiles.yml')).writeAsStringSync(
      '''
- name: Profile 1
- name: Profile 2
''',
    );

    // Create basic layouts directory (required for proper site initialization)
    final layoutsPath = p.join(sourcePath, '_layouts');
    memoryFileSystem.directory(layoutsPath).createSync(recursive: true);
    memoryFileSystem
        .file(p.join(layoutsPath, 'default.html'))
        .writeAsStringSync('''
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

    // Create posts directory (to satisfy site structure requirements)
    final postsPath = p.join(sourcePath, '_posts');
    memoryFileSystem.directory(postsPath).createSync();

    // Create static file for complete test structure
    memoryFileSystem
        .file(p.join(sourcePath, 'robots.txt'))
        .writeAsStringSync('User-agent: *');

    Site.init(
      overrides: {
        'source': sourcePath,
        'destination': p.join(projectRoot, 'public'),
      },
    );
    await site.read();
  });

  tearDown(() {
    // Clean up
    Site.resetInstance();
  });

  test("loads data", () {
    final data = site.data;
    expect(data.keys, unorderedEquals(['users', 'pages', 'profiles']));
    expect(
      data['users'],
      equals({
        'dick': {'name': 'Dick'},
        'harry': {'name': 'Harry'},
        'tom': {'name': 'Tom'},
      }),
    );

    expect(data['pages'], equals(['home', 'about', 'contact']));
  });

  test("loads in templates", () async {
    final root = MapRoot({});

    var template = GenGenTempate.r(
      r'''
{{site.data.users.tom.name}}
{{site.data.users.dick.name}}
{{site.data.users.harry.name}}
{% for page in site.data.pages %}
{{page}}
{% endfor %}
''',
      contentRoot: root,
      data: {
        "site": {"data": site.data},
      },
    );
    var result = await template.render();
    expect(
      result,
      equals(r'''
Tom
Dick
Harry

home

about

contact

'''),
    );
  });
}

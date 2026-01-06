import 'package:gengen/models/base.dart';
import 'package:liquify/liquify.dart';
import 'package:path/path.dart' as p;

class StaticFileDrop extends Drop {
  final Base file;

  StaticFileDrop(this.file) {
    invokable = const [
      #path,
      #relative_path,
      #extname,
      #name,
      #basename,
      #collection,
      #url,
    ];

    attrs = {
      'path': file.relativePath,
      'relative_path': file.relativePath,
      'extname': p.extension(file.source),
      'name': p.basename(file.source),
      'basename': p
          .basenameWithoutExtension(file.source)
          .replaceAll(RegExp(r'\.*$'), ''),
      'collection': file.collectionLabel,
      'url': _url(),
    };
  }

  String _url() {
    var link = file.link();
    if (link.startsWith('/')) {
      link = link.substring(1);
    }
    if (link.endsWith('/index.html')) {
      final trimmed = link.substring(0, link.length - 'index.html'.length);
      return '/$trimmed';
    }
    return '/$link';
  }
}

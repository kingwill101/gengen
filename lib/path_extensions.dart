import 'package:gengen/fs.dart';
import 'package:path/path.dart';

extension PathExtension on Directory {
  bool hasFile(String name) {
    var file = fs.file(join(path, name));
    return file.existsSync();
  }

  File file(String name) {
    return fs.file(join(path, name));
  }
}

extension FileOpenExtension on String {
  File openFile() {
    return fs.file(this);
  }
}

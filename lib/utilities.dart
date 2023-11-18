import 'dart:io';

Future<bool> isDir(String path) {
  return Directory(path).exists();
}

Future<String?> readFile(String path) async {
  var file = File(path);
  if (!await file.exists()) {
    return null;
  }

  return file.readAsString();
}

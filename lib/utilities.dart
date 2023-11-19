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

String slugify(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'[^\w-]'), '');
}

String slugifyList(List<String> items) {
  return items.map((item) => slugify(item)).join('/');
}

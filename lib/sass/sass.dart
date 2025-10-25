import 'package:sass/sass.dart';

CompileResult compileSass(
  String inputPath, {
  List<String> importPaths = const [],
}) {
  
  return compileToResult(
    inputPath,
    loadPaths: importPaths,
  );
}

import 'dart:async';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:more/collection.dart';
import 'package:path/path.dart' as path;

Builder bundleFileBuilder(BuilderOptions options) => FileBundler(options);

class FileBundler extends Builder {
  FileBundler(BuilderOptions options);

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    // This map will hold directory names and their file contents
    Map<String, Map<String, List<int>>> fileContents = {};

    // Process each file in the bundle directory
    await for (final input in buildStep.findAssets(Glob('bundle/**'))) {
      final relativeFilePath = path.relative(input.path, from: 'bundle');
      final directoryName = path.split(relativeFilePath).first;

      if (relativeFilePath != directoryName) {
        // Exclude root directory files
        fileContents[directoryName] ??= {};
        fileContents[directoryName]![relativeFilePath.removePrefix(
          "$directoryName/",
        )] = await buildStep.readAsBytes(
          input,
        );
      }
    }

    // Generate the output file path under lib/bundle
    final outputId = AssetId(
      buildStep.inputId.package,
      'lib/bundle/bundle_data.dart',
    );

    // Create Dart code for the nested map
    final buffer = StringBuffer()
      ..writeln('// Generated bundle data')
      ..writeln('final Map<String, Map<String, List<int>>> bundleData = {');

    fileContents.forEach((dirName, files) {
      buffer.writeln('  "$dirName": {');
      files.forEach((relativePath, bytes) {
        buffer.writeln('    "$relativePath": <int>[${bytes.join(', ')}],');
      });
      buffer.writeln('  },');
    });

    buffer.writeln('};');

    // Write the Dart file
    await buildStep.writeAsString(outputId, buffer.toString());
  }

  @override
  Map<String, List<String>> get buildExtensions => {
    r'$lib$': ['bundle/bundle_data.dart'],
  };
}

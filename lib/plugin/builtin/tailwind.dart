import 'dart:io';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;

/// [TailwindPlugin] that runs Tailwind CSS against the project's source files.
///
/// This plugin depends on the presence of the Tailwind binary tool. By default,
/// that tool is expected to be named `tailwindcss` and to sit at the root of the
/// website project directory.
///
/// Learn more about the standalone Tailwind tool: https://tailwindcss.com/blog/standalone-cli
class TailwindPlugin extends BasePlugin {
  /// Path and name of the Tailwind executable.
  final String tailwindPath;

  /// File path to the Tailwind input file, which contains Tailwind code.
  ///
  /// Unlike typical CSS, there only needs to be a single input file for
  /// Tailwind, and that file is mostly (or entirely) a configuration of
  /// Tailwind, itself. For example, the following might be used as the
  /// content of a file at `/styles/tailwind.css`.
  ///
  /// ```
  /// @tailwind base;
  /// @tailwind components;
  /// @tailwind utilities;
  /// ```
  final String input;

  /// File path to the desired Tailwind output file, where Tailwind
  /// should write the compiled CSS.
  ///
  /// In general, this output file holds all styles for your website.
  /// You might choose to place it at `/styles/styles.css` in the
  /// build output directory. Any HTML file that wants to use these
  /// styles need to reference this output stylesheet file location.
  ///
  /// ```
  ///<link href="styles/styles.css" rel="stylesheet">
  /// ```
  final String output;

  TailwindPlugin({
    this.tailwindPath = "./tailwindcss",
    this.input = "assets/css/tailwind.css",
    this.output = "assets/css/styles.css",
  });

  @override
  PluginMetadata get metadata => PluginMetadata(
        name: 'TailwindPlugin',
        version: '1.0.0',
        description: 'Compiles Tailwind CSS files in GenGen',
      );

  @override
  Future<void> afterRender() async {
    try {
      logger.info('(${metadata.name}) Generating Tailwind CSS');
      
      final inputPath = p.isAbsolute(input) ? input : p.join(site.config.source, input);
      final outputPath = p.isAbsolute(output) ? output : p.join(site.config.destination, output);
      final tailwindExecutable = p.isAbsolute(tailwindPath) ? tailwindPath : p.join(site.config.source, tailwindPath);

      if (!File(inputPath).existsSync()) {
        logger.warning('(${metadata.name}) Input file not found: $inputPath');
        return;
      }

      if (!File(tailwindExecutable).existsSync()) {
        logger.warning('(${metadata.name}) Tailwind executable not found: $tailwindExecutable');
        logger.info('(${metadata.name}) Download the standalone Tailwind CLI from: https://tailwindcss.com/blog/standalone-cli');
        return;
      }

      final outputDir = p.dirname(outputPath);
      await Directory(outputDir).create(recursive: true);

      final result = await Process.run(
        tailwindExecutable,
        ["-i", inputPath, "-o", outputPath],
        workingDirectory: site.config.source,
      );

      if (result.exitCode != 0) {
        logger.warning('(${metadata.name}) Failed to compile - exit code: ${result.exitCode}');
        logger.warning('(${metadata.name}) Error: ${result.stderr}');
        return;
      }

      logger.info('(${metadata.name}) Successfully generated: $outputPath');
      
      if (result.stdout.toString().isNotEmpty) {
        logger.info('(${metadata.name}) Tailwind output: ${result.stdout}');
      }
      
    } catch (exception, stacktrace) {
      logger.severe('(${metadata.name}) Failed to run Tailwind CSS compilation!');
      logger.severe('(${metadata.name}) Exception: $exception');
      logger.severe('(${metadata.name}) Stacktrace: $stacktrace');
    }
  }

  @override
  Future<void> beforeRender() async {
    logger.info('(${metadata.name}) Preparing to compile Tailwind CSS...');
  }
} 
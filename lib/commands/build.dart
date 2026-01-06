import 'package:gengen/commands/abstract_command.dart';
import 'package:gengen/commands/arg_extension.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/performance/benchmark.dart';
import 'package:gengen/site.dart';

class Build extends AbstractCommand {
  @override
  String get description => "Build static site";

  @override
  String get name => "build";

  Build() {
    argParser.addFlag(
      'benchmark',
      abbr: 'b',
      help: 'Enable detailed performance benchmarking',
      defaultsTo: false,
    );
    argParser.addFlag(
      'parallel',
      abbr: 'p',
      help: 'Enable parallel processing',
      defaultsTo: true,
    );
    argParser.addFlag(
      'future',
      help: 'Include content with future dates',
      defaultsTo: false,
    );
    argParser.addFlag(
      'unpublished',
      help: 'Include unpublished content',
      defaultsTo: false,
    );
    argParser.addFlag(
      'drafts',
      help: 'Include drafts in the build',
      defaultsTo: false,
    );
    argParser.addOption(
      'concurrency',
      abbr: 'c',
      help: 'Maximum number of concurrent operations',
      defaultsTo: '4',
    );
  }

  @override
  Future<void> start() async {
    final enableBenchmark = argResults?['benchmark'] as bool? ?? false;
    final enableParallel = argResults?['parallel'] as bool? ?? true;
    final concurrency =
        int.tryParse(argResults?['concurrency'] as String? ?? '4') ?? 4;

    // Configure benchmarking
    Benchmark.setEnabled(enableBenchmark);
    Benchmark.reset();
    Benchmark.start();

    log.info(" Starting build\n");
    if (enableBenchmark) {
      log.info("Benchmarking enabled");
    }
    if (enableParallel) {
      log.info("Parallel processing enabled (concurrency: $concurrency)");
    }

    try {
      final overrides = {...argResults?.map ?? <String, dynamic>{}};
      overrides['parallel'] = enableParallel;
      overrides['concurrency'] = concurrency;

      final includeDrafts = argResults?['drafts'] as bool? ?? false;
      if (includeDrafts) {
        overrides['publish_drafts'] = true;
      }

      // Check if a positional argument was provided as source directory
      if (argResults?.rest.isNotEmpty == true) {
        final sourceDir = argResults!.rest.first;
        log.info("Using source directory: $sourceDir");
        overrides['source'] = sourceDir;
      }

      Site.resetInstance();
      Site.init(overrides: overrides);

      await site.process();

      if (site.posts.isNotEmpty) {
        final sample = site.posts.first.renderer.content;
        log.fine(
          'Sample renderer content: '
          '${sample.substring(0, sample.length > 80 ? 80 : sample.length)}',
        );
      }

      Benchmark.stop();
      log.info("Build complete\n");

      if (enableBenchmark) {
        Benchmark.printReport();
      }
    } on Exception catch (e, s) {
      Benchmark.stop();
      if (enableBenchmark) {
        Benchmark.printReport();
      }
      log.severe(e.toString(), e, s);
    }
  }
}

import 'package:gengen/commands/abstract_command.dart';
import 'package:gengen/commands/arg_extension.dart';
import 'package:gengen/configuration.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/module/module_lockfile.dart';
import 'package:gengen/module/module_manifest.dart';
import 'package:gengen/module/module_resolver.dart';
import 'package:gengen/performance/benchmark.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;

class Build extends AbstractCommand {
  @override
  String get description => "Build static site";

  @override
  String get name => "build";

  @override
  bool get skipAutoInit => true; // We handle init after fetching modules

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
    argParser.addOption(
      'baseurl',
      help: 'Base URL path for the site (e.g. /gengen)',
    );
    argParser.addOption(
      'url',
      help: 'Canonical site URL (e.g. https://example.com)',
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
      final overrides = {...argResults?.map ?? <String, dynamic>{}}
        ..removeWhere((key, value) => value == null || value == '');
      overrides['parallel'] = enableParallel;
      overrides['concurrency'] = concurrency;

      final includeDrafts = argResults?['drafts'] as bool? ?? false;
      if (includeDrafts) {
        overrides['publish_drafts'] = true;
      }

      // Check if a positional argument was provided as source directory
      String siteRoot = '.';
      if (argResults?.rest.isNotEmpty == true) {
        final sourceDir = argResults!.rest.first;
        log.info("Using source directory: $sourceDir");
        overrides['source'] = sourceDir;
        siteRoot = p.isAbsolute(sourceDir) ? sourceDir : p.absolute(sourceDir);
      }

      // Auto-fetch modules if needed
      await _ensureModules(siteRoot);

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

  /// Ensure all declared modules are fetched before building
  Future<void> _ensureModules(String siteRoot) async {
    final configFiles = ['gengen.yaml', 'config.yaml', '_config.yaml'];
    Map<String, dynamic>? configData;

    for (final configFile in configFiles) {
      final configPath = p.join(siteRoot, configFile);
      final file = fs.file(configPath);
      if (file.existsSync()) {
        configData = readConfigFile(configPath) as Map<String, dynamic>?;
        if (configData != null && configData.containsKey('module')) {
          break;
        }
      }
    }

    if (configData == null || !configData.containsKey('module')) {
      return; // No modules declared
    }

    final manifest =
        ModuleManifest.parse(configData['module'] as Map<String, dynamic>?);
    if (!manifest.hasImports) {
      return;
    }

    final lockfile = ModuleLockfile.load(siteRoot);
    final resolver = ModuleResolver(
      siteRoot: siteRoot,
      manifest: manifest,
      lockfile: lockfile,
    );

    // Check if any modules need to be fetched
    var needsFetch = false;
    for (final import_ in manifest.imports) {
      if (!lockfile.hasPackage(import_.path)) {
        needsFetch = true;
        break;
      }
      // Check if cached module exists
      final locked = lockfile.getPackage(import_.path);
      if (locked != null) {
        final cachePath = locked.resolved;
        if (!fs.directory(cachePath).existsSync()) {
          needsFetch = true;
          break;
        }
      }
    }

    if (needsFetch) {
      log.info('Fetching modules...');
      final resolved = await resolver.resolveAll();
      if (resolved.isNotEmpty) {
        resolver.saveLockfile();
        for (final module in resolved) {
          log.info('  ✓ ${module.path}@${module.resolvedVersion}');
        }
      }
    }
  }
}

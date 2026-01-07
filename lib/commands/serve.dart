import 'dart:async';

import 'package:gengen/commands/abstract_command.dart';
import 'package:gengen/commands/arg_extension.dart';
import 'package:gengen/configuration.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/module/module_lockfile.dart';
import 'package:gengen/module/module_manifest.dart';
import 'package:gengen/module/module_resolver.dart';
import 'package:gengen/router.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;

class Serve extends AbstractCommand {
  @override
  String get description => "Build and serve static site with live reload";

  @override
  String get name => "serve";

  @override
  bool get skipAutoInit => true; // We handle init after fetching modules

  Serve() {
    argParser.addOption(
      'port',
      abbr: 'p',
      help: 'Port to serve on',
      defaultsTo: '4000',
    );
    argParser.addOption(
      'host',
      abbr: 'H',
      help: 'Host to bind to',
      defaultsTo: 'localhost',
    );
  }

  @override
  Future<FutureOr<void>?> start() async {
    try {
      // Determine site root and prepare overrides
      final overrides = <String, dynamic>{...?argResults?.map};
      String siteRoot = '.';
      if (argResults?.rest.isNotEmpty == true) {
        final sourceDir = argResults!.rest.first;
        overrides['source'] = sourceDir;
        siteRoot = p.isAbsolute(sourceDir) ? sourceDir : p.absolute(sourceDir);
      }

      // Auto-fetch modules if needed
      await _ensureModules(siteRoot);

      // Initialize site after modules are fetched
      Site.resetInstance();
      Site.init(overrides: overrides);

      Site.instance.process();
      site.watch();
      route();
    } on Exception catch (e, _) {
      log.severe(e.toString());
    }
  }

  /// Ensure all declared modules are fetched before serving
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
      return;
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

    var needsFetch = false;
    for (final import_ in manifest.imports) {
      if (!lockfile.hasPackage(import_.path)) {
        needsFetch = true;
        break;
      }
      final locked = lockfile.getPackage(import_.path);
      if (locked != null && !fs.directory(locked.resolved).existsSync()) {
        needsFetch = true;
        break;
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

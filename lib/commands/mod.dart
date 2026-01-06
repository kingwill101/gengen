import 'dart:async';

import 'package:artisanal/args.dart';
import 'package:gengen/configuration.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/module/module.dart';
import 'package:path/path.dart' as p;

/// Parent command for module management (gengen mod)
class ModCommand extends Command<void> {
  @override
  String get name => 'mod';

  @override
  String get description => 'Manage site modules (themes, plugins)';

  ModCommand() {
    addSubcommand(ModGetCommand());
    addSubcommand(ModUpdateCommand());
    addSubcommand(ModListCommand());
    addSubcommand(ModTidyCommand());
    addSubcommand(ModVerifyCommand());
  }

  @override
  void run() {
    printUsage();
  }
}

/// Base class for mod subcommands
abstract class ModSubCommand extends Command<void> {
  ModSubCommand() {
    argParser.addOption(
      'source',
      abbr: 's',
      help: 'Site source directory',
      defaultsTo: '.',
    );
  }

  String get siteRoot {
    final source = argResults?['source'] as String? ?? '.';
    return p.isAbsolute(source) ? source : p.absolute(source);
  }

  ModuleManifest loadManifest() {
    final configFiles = ['gengen.yaml', 'config.yaml', '_config.yaml'];

    for (final configFile in configFiles) {
      final configPath = p.join(siteRoot, configFile);
      if (fs.file(configPath).existsSync()) {
        final config = readConfigFile(configPath) as Map<String, dynamic>?;
        if (config != null && config.containsKey('module')) {
          return ModuleManifest.parse(config['module'] as Map<String, dynamic>?);
        }
      }
    }

    return const ModuleManifest();
  }

  ModuleResolver createResolver() {
    final manifest = loadManifest();
    final lockfile = ModuleLockfile.load(siteRoot);
    return ModuleResolver(
      siteRoot: siteRoot,
      manifest: manifest,
      lockfile: lockfile,
    );
  }
}

/// gengen mod get - Fetch all declared modules
class ModGetCommand extends ModSubCommand {
  @override
  String get name => 'get';

  @override
  String get description => 'Fetch all declared modules and update lockfile';

  @override
  Future<void> run() async {
    final resolver = createResolver();

    if (resolver.manifest.isEmpty) {
      log.info('No modules declared in configuration');
      return;
    }

    log.info('Resolving ${resolver.manifest.imports.length} module(s)...');

    final resolved = await resolver.resolveAll();

    for (final module in resolved) {
      log.info('  ✓ ${module.path}@${module.resolvedVersion}');
    }

    resolver.saveLockfile();
    log.info('Updated gengen.lock');
  }
}

/// gengen mod update - Update modules to latest versions
class ModUpdateCommand extends ModSubCommand {
  @override
  String get name => 'update';

  @override
  String get description => 'Update modules to latest versions matching constraints';

  ModUpdateCommand() {
    argParser.addFlag(
      'all',
      abbr: 'a',
      help: 'Update all modules',
      defaultsTo: false,
    );
  }

  @override
  Future<void> run() async {
    final resolver = createResolver();
    final updateAll = argResults?['all'] as bool? ?? false;
    final specificModules = argResults?.rest;

    if (resolver.manifest.isEmpty) {
      log.info('No modules declared in configuration');
      return;
    }

    List<String>? toUpdate;
    if (!updateAll && specificModules != null && specificModules.isNotEmpty) {
      toUpdate = specificModules;
    }

    log.info('Updating modules...');
    final updated = await resolver.update(toUpdate);

    for (final module in updated) {
      log.info('  ✓ ${module.path}@${module.resolvedVersion}');
    }

    resolver.saveLockfile();
    log.info('Updated gengen.lock');
  }
}

/// gengen mod list - List resolved modules
class ModListCommand extends ModSubCommand {
  @override
  String get name => 'list';

  @override
  String get description => 'List all resolved modules';

  ModListCommand() {
    argParser.addFlag(
      'locked',
      abbr: 'l',
      help: 'Show locked versions from gengen.lock',
      defaultsTo: false,
    );
  }

  @override
  Future<void> run() async {
    final showLocked = argResults?['locked'] as bool? ?? false;
    final manifest = loadManifest();
    final lockfile = ModuleLockfile.load(siteRoot);

    if (showLocked) {
      if (lockfile.isEmpty) {
        log.info('No locked modules (gengen.lock is empty or missing)');
        return;
      }

      log.info('Locked modules:');
      for (final entry in lockfile.packages.entries) {
        final module = entry.value;
        log.info('  ${entry.key}@${module.version}');
        if (module.sha != null) {
          log.info('    sha: ${module.sha}');
        }
      }
    } else {
      if (manifest.isEmpty) {
        log.info('No modules declared in configuration');
        return;
      }

      log.info('Declared modules:');
      for (final import_ in manifest.imports) {
        final version = import_.version ?? 'any';
        final locked = lockfile.getPackage(import_.path);
        final lockedInfo = locked != null ? ' (locked: ${locked.version})' : '';
        log.info('  ${import_.path}@$version$lockedInfo');
      }

      if (manifest.replacements.isNotEmpty) {
        log.info('');
        log.info('Replacements:');
        for (final replacement in manifest.replacements) {
          log.info('  ${replacement.path} -> ${replacement.local}');
        }
      }
    }
  }
}

/// gengen mod tidy - Remove unused modules from lockfile
class ModTidyCommand extends ModSubCommand {
  @override
  String get name => 'tidy';

  @override
  String get description => 'Remove unused modules from lockfile and cache';

  @override
  Future<void> run() async {
    final resolver = createResolver();

    log.info('Tidying modules...');
    await resolver.tidy();
    resolver.saveLockfile();

    log.info('Done');
  }
}

/// gengen mod verify - Verify cached modules match lockfile
class ModVerifyCommand extends ModSubCommand {
  @override
  String get name => 'verify';

  @override
  String get description => 'Verify cached modules match lockfile checksums';

  @override
  Future<void> run() async {
    final resolver = createResolver();

    if (resolver.lockfile.isEmpty) {
      log.info('No locked modules to verify');
      return;
    }

    log.info('Verifying modules...');
    final valid = await resolver.verify();

    if (valid) {
      log.info('All modules verified successfully');
    } else {
      log.severe('Some modules failed verification');
    }
  }
}

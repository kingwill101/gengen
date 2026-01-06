import 'package:file/file.dart' show FileSystem;
import 'package:file/local.dart';
import 'package:gengen/di.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/hook.dart';
import 'package:gengen/site.dart';
import 'package:test/test.dart';

class HookOwnerAlpha {}

class HookOwnerBeta {}

class HookOwnerGamma {}

class HookOwnerDelta {}

void main() {
  setUpAll(() {
    if (!getIt.isRegistered<FileSystem>()) {
      getIt.registerSingleton<FileSystem>(const LocalFileSystem());
    }
    gengen_fs.fs = const LocalFileSystem();
  });

  test('Hook triggers in priority order', () {
    final site = Site.instance;
    final calls = <String>[];
    final owner = HookOwnerAlpha();

    Hook.register(
      owner,
      HookEvent.afterInit,
      (_) => calls.add('low'),
      priority: HookPriority.low,
    );
    Hook.register(
      owner,
      HookEvent.afterInit,
      (_) => calls.add('high'),
      priority: HookPriority.high,
    );
    Hook.register(owner, HookEvent.afterInit, (_) => calls.add('normal'));

    Hook.trigger(owner, HookEvent.afterInit, site);

    expect(calls, ['high', 'normal', 'low']);
  });

  test('Hook registry is scoped to owner', () {
    final site = Site.instance;
    final calls = <String>[];
    final ownerOne = HookOwnerGamma();
    final ownerTwo = HookOwnerDelta();

    Hook.register(ownerOne, HookEvent.afterRender, (_) => calls.add('one'));
    Hook.register(ownerTwo, HookEvent.afterRender, (_) => calls.add('two'));

    Hook.trigger(ownerOne, HookEvent.afterRender, site);

    expect(calls, ['one']);
  });
}

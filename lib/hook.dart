import 'package:gengen/site.dart';

enum HookEvent {
  afterInit,
  afterReset,
  beforeRead,
  beforeRender,
  afterRead,
  beforeConvert,
  afterConvert,
  beforeGenerate,
  afterGenerate,
  afterRender,
  beforeWrite,
  afterWrite,
  convert
}

enum HookPriority {
  low(10),
  normal(20),
  high(30);

  final int value;
  const HookPriority(this.value);
}

typedef HookFunc = void Function(Site site);

class Hook {
  static Hook? _instance;

  final Map<String, Map<HookEvent, List<HookFunc>>> _registry = {};
  final Map<HookFunc, List<int>> _hookPriority = {};

  Hook._internal();

  static Hook get instance {
    _instance ??= Hook._internal();
    return _instance!;
  }

  void _register(Object owner, HookEvent event, HookFunc handler,
      {HookPriority priority = HookPriority.normal}) {
    String ownerKey = owner.runtimeType.toString();
    _registry[ownerKey] ??= {};
    _registry[ownerKey]![event] ??= [];

    _hookPriority[handler] = [-priority.value, _hookPriority.length];
    _registry[ownerKey]![event]!.add(handler);
  }

  void _trigger(Object owner, HookEvent event, Site site) {
    String ownerKey = owner.runtimeType.toString();
    var hooks = _registry[ownerKey]?[event];
    if (hooks == null || hooks.isEmpty) return;

    hooks.sort((a, b) => _hookPriority[a]![0].compareTo(_hookPriority[b]![0]));
    for (var hook in hooks) {
      hook(site);
    }
  }

  static void register(Object owner, HookEvent event, HookFunc handler,
          {HookPriority priority = HookPriority.normal}) =>
      Hook.instance._register(owner, event, handler, priority: priority);

  static void trigger(Object owner, HookEvent event, Site site) =>
      Hook.instance._trigger(owner, event, site);
}

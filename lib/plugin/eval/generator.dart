import 'dart:async';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';

class $Plugin$bridge with $Bridge<BasePlugin> implements BasePlugin {
  static final $type = BridgeTypeSpec(
    'package:gengen/plugin/plugin.dart',
    'BasePlugin',
  ).ref;

  /// Again, we map out all the fields and methods for the compiler.
  static final $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: false),
    constructors: {
      // Even though this class is abstract, we currently need to define
      // the default constructor anyway.
      '': BridgeFunctionDef(returns: $type.annotate).asConstructor
    },
    methods: {
      'generate': BridgeFunctionDef(
        returns: CoreTypes.voidType.ref.annotate,
        params: [],
      ).asMethod,
      'convert': BridgeFunctionDef(
        returns: CoreTypes.string.ref.annotate,
        params: [
          'content'.param(CoreTypes.string.ref.annotate),
          BridgeParameter(
              'page',
              BridgeTypeAnnotation(BridgeTypeRef(
                  BridgeTypeSpec('package:gengen/models/base.dart', 'Base'))),
              true)
        ],
      ).asMethod,
      'afterInit': BridgeFunctionDef(
        returns: CoreTypes.voidType.ref.annotate,
        params: [],
      ).asMethod,
      'beforeRead': BridgeFunctionDef(
        returns: CoreTypes.voidType.ref.annotate,
        params: [],
      ).asMethod,
      'afterRead': BridgeFunctionDef(
        returns: CoreTypes.voidType.ref.annotate,
        params: [],
      ).asMethod,
      'beforeGenerate': BridgeFunctionDef(
        returns: CoreTypes.voidType.ref.annotate,
        params: [],
      ).asMethod,
      'afterGenerate': BridgeFunctionDef(
        returns: CoreTypes.voidType.ref.annotate,
        params: [],
      ).asMethod,
      'beforeRender': BridgeFunctionDef(
        returns: CoreTypes.voidType.ref.annotate,
        params: [],
      ).asMethod,
      'afterRender': BridgeFunctionDef(
        returns: CoreTypes.voidType.ref.annotate,
        params: [],
      ).asMethod,
      'beforeWrite': BridgeFunctionDef(
        returns: CoreTypes.voidType.ref.annotate,
        params: [],
      ).asMethod,
      'afterWrite': BridgeFunctionDef(
        returns: CoreTypes.voidType.ref.annotate,
        params: [],
      ).asMethod,
    },
    bridge: true,
  );

  /// Define static [EvalCallableFunc] functions for all static methods and
  /// constructors. This is for the default constructor and is what the runtime
  /// will use to create an instance of this class.
  static $Value? $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Plugin$bridge();
  }

  /// [$bridgeGet] works differently than [$getProperty] - it's only called
  /// if the Eval subclass hasn't provided an override implementation.
  @override
  $Value? $bridgeGet(String identifier) {
    // [WorldTimeTracker] is abstract, so if we haven't overridden all of its
    // methods that's an error.
    // If it were concrete, this implementation would look like [$getProperty]
    // except you'd access fields and invoke methods on 'super'.
    final lifecycleHooks = [
      'afterInit',
      'beforeRead',
      'afterRead',
      'beforeGenerate',
      'afterGenerate',
      'beforeRender',
      'afterRender',
      'beforeWrite',
      'afterWrite',
      'generate',
      'convert',
      'beforeConvert',
      'afterConvert',
    ];

    if (lifecycleHooks.contains(identifier)) {
      log.info("Plugin lifecycle hook: $identifier called");
      return null;
    }

    throw UnimplementedError(
      'Cannot get property "$identifier" on abstract class BasePlugin',
    );
  }

  @override
  void $bridgeSet(
    String identifier,
    $Value value,
  ) {
    /// Same idea here.
    throw UnimplementedError(
      'Cannot set property "$identifier" on abstract class BasePlugin',
    );
  }

  /// In a bridge class, override all fields and methods with [invoke],
  /// [$_get], and [$_set]. This allows us to override the methods by extending
  /// the class in dart_eval.

  @override
  void generate() {
    invoke(
      'generate',
      [],
    );
  }

  @override
  void afterGenerate() {
    invoke(
      'afterGenerate',
      [],
    );
  }

  @override
  void afterInit() {
    invoke(
      'afterInit',
      [],
    );
  }

  @override
  void afterRead() {
    invoke(
      'afterRead',
      [],
    );
  }

  @override
  void afterRender() {
    invoke(
      'afterRender',
      [],
    );
  }

  @override
  void afterWrite() {
    invoke(
      'afterWrite',
      [],
    );
  }


  @override
  void beforeGenerate() {
    invoke(
      'beforeGenerate',
      [],
    );
  }

  @override
  void beforeRead() {
    invoke(
      'beforeRead',
      [],
    );
  }

  @override
  void beforeRender() {
    invoke(
      'beforeRender',
      [],
    );
  }

  @override
  void beforeWrite() {
    invoke(
      'beforeWrite',
      [],
    );
  }

  dynamic invoke(String method, List<$Value?> args) {
    try {
      return $_invoke(
        method,
        args,
      );
    } catch (e) {
      log.info("Error invoking $method: $e");
    }
  }

  @override
  String convert(String content, Base page) {
    return invoke(
      'convert',
      [$String(content), $Object(page)],
    ) as String;
  }

  @override
  // TODO: implement metadata
  PluginMetadata get metadata => throw UnimplementedError();

  @override
  // TODO: implement isWrapper
  bool get isWrapper => true;

  @override
  FutureOr<void> afterConvert() {
    invoke(
      'afterConvert',
      [],
    );
  }

  @override
  FutureOr<void> beforeConvert() {
    invoke(
      'beforeConvert',
      [],
    );
  }
}

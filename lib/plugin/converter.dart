import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:gengen/plugin/plugin.dart';


class $Converter$bridge with $Bridge<Converter> implements Converter {
  static final $type = BridgeTypeSpec(
    'package:gengen/plugin/plugin.dart',
    'Convertor',
  ).ref;

  /// Again, we map out all the fields and methods for the compiler.
  static final $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true),
    constructors: {
      // Even though this class is abstract, we currently need to define
      // the default constructor anyway.
      '': BridgeFunctionDef(returns: $type.annotate).asConstructor
    },
    methods: {
      'convert': BridgeFunctionDef(
        returns: CoreTypes.string.ref.annotate,
        params: ['content'.param(CoreTypes.string.ref.annotate)],
      ).asMethod
    },
    bridge: true,
  );

  /// Define static [EvalCallableFunc] functions for all static methods and
  /// constructors. This is for the default constructor and is what the runtime
  /// will use to create an instance of this class.
  static $Value? $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Converter$bridge();
  }

  /// [$bridgeGet] works differently than [$getProperty] - it's only called
  /// if the Eval subclass hasn't provided an override implementation.
  @override
  $Value? $bridgeGet(String identifier) {
    // [Convertor] is abstract, so if we haven't overridden all of its
    // methods that's an error.
    // If it were concrete, this implementation would look like [$getProperty]
    // except you'd access fields and invoke methods on 'super'.
    throw UnimplementedError(
      'Cannot get property "$identifier" on abstract class Convertor',
    );
  }

  @override
  void $bridgeSet(
    String identifier,
    $Value value,
  ) {
    /// Same idea here.
    throw UnimplementedError(
      'Cannot set property "$identifier" on abstract class Convertor',
    );
  }

  /// In a bridge class, override all fields and methods with [$_invoke],
  /// [$_get], and [$_set]. This allows us to override the methods by extending
  /// the class in dart_eval.

  @override
  String convert(String content) {
    return $_invoke(
      'convert',
      [$String(content)],
    ) as String;
  }
}

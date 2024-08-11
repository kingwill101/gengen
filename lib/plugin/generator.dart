import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';
import 'package:gengen/plugin/plugin.dart';

class $Generator$bridge with $Bridge<Generator> implements Generator {
  static final $type = BridgeTypeSpec(
    'package:gengen/plugin/plugin.dart',
    'Generator',
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
      'generate': BridgeFunctionDef(
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
    return $Generator$bridge();
  }

  /// [$bridgeGet] works differently than [$getProperty] - it's only called
  /// if the Eval subclass hasn't provided an override implementation.
  @override
  $Value? $bridgeGet(String identifier) {
    switch (identifier) {
      case 'generate':
        return $Function((_, target, args) {
          generate();
          return null;
        });
      default:
        throw UnimplementedError(
          'Cannot get property "$identifier" on abstract class Generator',
        );
    }
  }

  @override
  void $bridgeSet(
    String identifier,
    $Value value,
  ) {
    /// Same idea here.
    throw UnimplementedError(
      'Cannot set property "$identifier" on abstract class Generator',
    );
  }

  /// In a bridge class, override all fields and methods with [$_invoke],
  /// [$_get], and [$_set]. This allows us to override the methods by extending
  /// the class in dart_eval.

  @override
  void generate() {
    $_invoke(
      'generate',
      [],
    );
  }
}

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:gengen/models/base.dart';

class $Base extends Base implements $Instance {
  $Base.wrap(this.$value)
      : _superclass = $Object($value),
        super($value.source);

  static final $type = BridgeTypeSpec(
    'package:gengen/models/base.dart',
    'Base',
  ).ref;

  static final $declaration = BridgeClassDef(
    BridgeClassType($type),
    constructors: {
      // Define the default constructor with an empty string
      '': BridgeFunctionDef(returns: $type.annotate).asConstructor
    },
    getters: {
      'config': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
              BridgeTypeRef(CoreTypes.map, [
                BridgeTypeRef(CoreTypes.string),
                BridgeTypeRef(CoreTypes.dynamic)
              ]),
              nullable: false),
          namedParams: [],
          params: [],
        ),
      ),
    },
    fields: {
      'name': BridgeFieldDef(CoreTypes.string.ref.annotate),
      'source': BridgeFieldDef(CoreTypes.string.ref.annotate),
      'content': BridgeFieldDef(CoreTypes.string.ref.annotate),
      'isSass': BridgeFieldDef(CoreTypes.bool.ref.annotate),
      'isHtml': BridgeFieldDef(CoreTypes.bool.ref.annotate),
      'isMarkdown': BridgeFieldDef(CoreTypes.bool.ref.annotate),
      'hasLiquid': BridgeFieldDef(CoreTypes.bool.ref.annotate),
      'isAsset': BridgeFieldDef(CoreTypes.bool.ref.annotate),
      'isIndex': BridgeFieldDef(CoreTypes.bool.ref.annotate),
      'ext': BridgeFieldDef(CoreTypes.string.ref.annotate),
      'date': BridgeFieldDef(CoreTypes.dateTime.ref.annotate),
      'data': BridgeFieldDef(CoreTypes.map.ref.annotate),
      'config': BridgeFieldDef(CoreTypes.map.ref.annotate),
    },
    wrap: true,
  );

  static $Value? $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Base.wrap(Base(
      "",
    ));
  }

  /// The underlying Dart instance that this wrapper wraps
  @override
  final Base $value;

  /// In most cases [$reified] should just return [$value], but collection
  /// types like Lists should use it to recursively reify their contents.
  @override
  Base get $reified => $value;

  /// [$getProperty] is how dart_eval accesses a wrapper's properties and methods,
  /// so map them out here. In the default case, fall back to our [_superclass]
  /// implementation. For methods, you would return a [$Function] with a closure.
  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case "name":
        return $String($value.name);
      case "source":
        return $String($value.source);
      case "content":
        return $String($value.content);
      case "isSass":
        return $bool($value.isSass);
      case "isHtml":
        return $bool($value.isHtml);
      case "isMarkdown":
        return $bool($value.isMarkdown);
      case "hasLiquid":
        return $bool($value.hasLiquid);
      case "isAsset":
        return $bool($value.isAsset);
      case "isIndex":
        return $bool($value.isIndex);
      case "ext":
        return $String($value.ext);
      case "date":
        return $DateTime.wrap($value.date);
      case "data":
        return $Map.wrap($value.config);
      case "config":
        return $Map.wrap($value.config);
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  /// Although not required, creating a superclass field allows you to inherit
  /// basic properties from [$Object], such as == and hashCode.
  final $Instance _superclass;

  /// Lookup the runtime type ID
  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  /// Map out non-final fields with [$setProperty]. We don't have any here,
  /// so just fallback to the Object implementation.
  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

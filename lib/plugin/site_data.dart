import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:gengen/plugin/model.dart';
import 'package:gengen/site.dart';

class $Site implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
        'package:gengen/plugin/site_data.dart', 'Site.', $Site.$new);
  }

  /// Compile-time type declaration of [$Site]
  static const $type = BridgeTypeRef(
    BridgeTypeSpec(
      'package:gengen/site.dart',
      'Site',
    ),
  );

  /// Compile-time class declaration of [$Site]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: false,
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [],
        ),
        isFactory: false,
      ),
    },
    methods: {
      'relativeToRoot': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          namedParams: [],
          params: [
            BridgeParameter(
              'path',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              true,
            ),
          ],
        ),
      ),
    },
    getters: {
      'includesPath': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          namedParams: [],
          params: [],
        ),
      ),
      'layoutsPath': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          namedParams: [],
          params: [],
        ),
      ),
      'sassPath': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          namedParams: [],
          params: [],
        ),
      ),
      'assetsPath': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          namedParams: [],
          params: [],
        ),
      ),
      'postPath': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          namedParams: [],
          params: [],
        ),
      ),
      'dataPath': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          namedParams: [],
          params: [],
        ),
      ),
      'themesDir': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          namedParams: [],
          params: [],
        ),
      ),
      'postOutputPath': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          namedParams: [],
          params: [],
        ),
      ),
      'data': BridgeMethodDef(
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
      'posts': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
              BridgeTypeRef(CoreTypes.list, [
                BridgeTypeRef(
                    BridgeTypeSpec('package:gengen/models/base.dart', 'Base')),
              ]),
              nullable: false),
          namedParams: [],
          params: [],
        ),
      ),
      'pages': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
              BridgeTypeRef(CoreTypes.list, [
                BridgeTypeRef(
                    BridgeTypeSpec('package:gengen/models/base.dart', 'Base')),
              ]),
              nullable: false),
          namedParams: [],
          params: [],
        ),
      ),
      'staticFiles': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
              BridgeTypeRef(CoreTypes.list, [
                BridgeTypeRef(
                    BridgeTypeSpec('package:gengen/models/base.dart', 'Base')),
              ]),
              nullable: false),
          namedParams: [],
          params: [],
        ),
      ),
      'instance': BridgeMethodDef(
        isStatic: true,
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
              BridgeTypeRef(
                BridgeTypeSpec('package:gengen/site.dart', 'Site'),
              ),
              nullable: true),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
  );

  /// Wrapper for the [Site.new] constructor
  static $Value? $new(Runtime runtime, $Value? thisValue, List<$Value?> args) {
    return $Site.wrap(
      site,
    );
  }

  final $Instance _superclass;

  @override
  final Site $value;

  @override
  Site get $reified => $value;

  /// Wrap a [Site] in a [$Site]
  $Site.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'includesPath':
        final includesPath = $value.includesPath;
        return $String(includesPath);

      case 'layoutsPath':
        final layoutsPath = $value.layoutsPath;
        return $String(layoutsPath);

      case 'sassPath':
        final sassPath = $value.sassPath;
        return $String(sassPath);

      case 'assetsPath':
        final assetsPath = $value.assetsPath;
        return $String(assetsPath);

      case 'postPath':
        final postPath = $value.postPath;
        return $String(postPath);

      case 'dataPath':
        final dataPath = $value.dataPath;
        return $String(dataPath);

      case 'themesDir':
        final themesDir = $value.themesDir;
        return $String(themesDir);

      case 'postOutputPath':
        final postOutputPath = $value.postOutputPath;
        return $String(postOutputPath);
      case 'relativeToRoot':
        return __relativeToRoot;
      case 'data':
        return $Map.wrap($value.data);
      case 'pages':
        return $Iterable.wrap($value.pages.map((p) => $Base.wrap(p)).toList());
      case 'posts':
        return $List.wrap($value.posts.map((p) => $Base.wrap(p)).toList());
      case 'staticFiles':
        return $List
            .wrap($value.staticFiles.map((p) => $Base.wrap(p)).toList());
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __relativeToRoot = $Function(_relativeToRoot);

  static $Value? _relativeToRoot(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $Site;
    final result = self.$value.relativeToRoot(args[0]!.$value as String);
    return $String(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  static $Value? $instance(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $Site.wrap(site);
  }
}

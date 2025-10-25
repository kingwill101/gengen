/// # GenGen Static Site Generator Library
///
/// A powerful, extensible static site generator library for Dart that provides
/// Jekyll-compatible features with modern Dart architecture.
///
/// ## Quick Start
///
/// ### Basic Site Generation
/// 
/// ```dart
/// import 'package:gengen/gengen.dart';
///
/// void main() async {
///   final generator = GenGen();
///   
///   // Initialize with default configuration
///   await generator.init();
///   
///   // Generate the site
///   await generator.build();
///   
///   print('Site generated successfully!');
/// }
/// ```

library gengen;

// Core library exports
export 'gengen_library.dart';

// Model exports for advanced usage
export 'models/base.dart';
export 'models/post.dart'; 
export 'models/page.dart';

// Plugin system exports
export 'plugin/plugin.dart';
export 'plugin/plugin_metadata.dart';
export 'plugin/builtin.dart';
export 'plugin/lua/lua_plugin.dart';

// Configuration exports
export 'configuration.dart';

// Exception exports  
export 'exceptions.dart';

// Site exports for advanced access
export 'site.dart' show Site;

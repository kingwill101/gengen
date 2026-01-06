import 'package:gengen/plugin/plugin.dart';

class Plugin extends BasePlugin {
  @override
  Never get metadata =>
      throw UnimplementedError('Metadata is handled by the plugin system');

  @override
  String getHeadInjection() {
    return '''
    <!-- Demo Plugin Head Injection -->
    <meta name="demo-plugin" content="enabled">
    <meta name="demo-plugin-version" content="1.0.0">
    ''';
  }

  @override
  String getBodyInjection() {
    return '''
    <!-- Demo Plugin Body Injection -->
    <script>
      console.log('Demo Plugin loaded successfully!');
      document.addEventListener('DOMContentLoaded', function() {
        console.log('Demo Plugin: DOM ready');
      });
    </script>
    ''';
  }

  @override
  List<String> getCssAssets() {
    return ['plugin-styles.css'];
  }

  @override
  List<String> getJsAssets() {
    return ['plugin-main.js'];
  }

  @override
  Map<String, String> getMetaTags() {
    return {
      'demo-plugin-feature': 'asset-injection',
      'demo-plugin-author': 'GenGen Team',
    };
  }
}

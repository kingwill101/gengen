// ignore_for_file: uri_does_not_exist

import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:gengen/site.dart';

// import 'package:plugin/helpers/hello.dart';
// import 'package:plugin/helpers/world.dart';

import 'helpers/hello.dart';
import 'helpers/world.dart';

class Plugin extends BasePlugin {
  @override
  PluginMetadata get metadata => PluginMetadata(
        name: 'MetadataPlugin',
        version: '1.0.0',
        description: 'Demonstrates accessing site metadata from a plugin.',
      );

  @override
  void generate() {
    print(Site.instance.assetsPath);
    print(Site.instance.dataPath);
    print(Site.instance.includesPath);

    print(Site.instance.posts.length);

    for (final post in Site.instance.posts) {
      print(post.name);
    }

    print(hello("Gengen"));
    print(world());
  }
}

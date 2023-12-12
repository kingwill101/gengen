import 'dart:io';

import 'package:gengen/models/base.dart';
import 'package:gengen/models/permalink_structure.dart';
import 'package:more/collection.dart';
import 'package:path/path.dart';

class Post extends Base {
  Post.fromYaml(
    super.frontMatter,
    super.source,
    super.content, [
    super.dirConfig,
    super.destination,
  ]) : super.fromYaml();

  bool isDraft() {
    if (config.containsKey("draft") && config["draft"] is bool) {
      return config["draft"] as bool;
    }

    return false;
  }

  Post(super.source, super._site) {
    defaultMatter.addAll({"permalink": PermalinkStructure.post});
  }

  @override
  String get name =>
      source.removePrefix(join(site.config.source, "_posts") + separator);

  @override
  void write(Directory destination) {
    return super.write(Directory(joinAll(
      [
        destination.path,
        site.postOutputPath,
      ],
    )));
  }
}

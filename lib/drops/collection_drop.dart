import 'package:gengen/drops/static_file_drop.dart';
import 'package:gengen/models/collection.dart';
import 'package:liquify/liquify.dart';

class CollectionDrop extends Drop {
  final ContentCollection collection;

  CollectionDrop(this.collection) {
    invokable = const [
      #label,
      #docs,
      #files,
      #output,
      #directory,
      #relative_directory,
    ];

    attrs = {
      ...collection.metadata,
      'label': collection.label,
      'output': collection.output,
      'docs': collection.docs.map((doc) => doc.to_liquid).toList(),
      'files': collection.files.map((file) => StaticFileDrop(file)).toList(),
      'directory': collection.directory,
      'relative_directory': collection.relativeDirectory,
    };
  }

  String get label => collection.label;

  @override
  String toString() {
    return attrs['docs'].toString();
  }
}

import 'package:gengen/front_matter_defaults.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/models/collection.dart';
import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart';
import 'package:path/path.dart';

class CollectionReader {
  CollectionReader();

  Map<String, ContentCollection> read() {
    final collections = _loadCollectionsConfig();
    if (collections.isEmpty) return collections;

    final defaultsConfig =
        Site.instance.config.get<List<dynamic>>('defaults', defaultValue: []) ??
        const [];
    final defaultsResolver = FrontMatterDefaults(defaultsConfig);

    for (final collection in collections.values) {
      _readCollectionItems(collection, defaultsResolver);
      collection.sortDocs();
      collection.assignPreviousNext();
    }

    return collections;
  }

  Map<String, ContentCollection> _loadCollectionsConfig() {
    final raw = Site.instance.config.get<dynamic>(
      'collections',
      defaultValue: const <String, dynamic>{},
    );
    final collections = <String, ContentCollection>{};

    if (raw is List) {
      for (final entry in raw) {
        final label = entry.toString().trim();
        if (label.isEmpty) continue;
        if (_isSpecialCollection(label)) continue;
        collections[label] = ContentCollection.fromConfig(label, {});
      }
      return collections;
    }

    if (raw is Map) {
      for (final entry in raw.entries) {
        final label = entry.key.toString().trim();
        if (label.isEmpty) continue;
        if (_isSpecialCollection(label)) continue;
        collections[label] = ContentCollection.fromConfig(
          label,
          entry.value as Object,
        );
      }
    }

    return collections;
  }

  void _readCollectionItems(
    ContentCollection collection,
    FrontMatterDefaults defaultsResolver,
  ) {
    final dir = join(Site.instance.collectionsDir, '_${collection.label}');
    final entries = Site.instance.reader.getEntries(dir);

    for (final entry in entries) {
      final filePath = Site.instance.inSourceDir(join(dir, entry));
      final filename = withoutExtension(basename(entry));
      if (filename == '_index') {
        continue;
      }

      final hasFrontMatter = hasYamlHeader(filePath);
      final Base item = hasFrontMatter
          ? CollectionItem(filePath, collectionConfig: collection)
          : CollectionStatic(filePath, collectionConfig: collection);

      final sourceRelativePath = relative(
        filePath,
        from: Site.instance.config.source,
      );
      final relativePath = item.relativePath;
      final collectionRelativePath = relative(
        filePath,
        from: Site.instance.inSourceDir(dir),
      );

      final defaults = defaultsResolver.resolve(
        paths: [
          sourceRelativePath,
          relativePath,
          collectionRelativePath,
          withoutExtension(collectionRelativePath),
        ],
        type: collection.label,
      );

      if (defaults.isNotEmpty) {
        item.defaultMatter = deepMerge(item.defaultMatter, defaults);
      }

      if (hasFrontMatter) {
        if (Site.instance.config.get<bool>(
              'unpublished',
              defaultValue: false,
            )! ||
            item.isPublished) {
          collection.docs.add(item);
        }
      } else {
        collection.files.add(item);
      }
    }
  }

  bool _isSpecialCollection(String label) {
    return label == 'posts' || label == 'data';
  }
}

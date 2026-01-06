import 'package:gengen/logging.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/models/permalink_structure.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;

class ContentCollection {
  ContentCollection({
    required this.label,
    required this.metadata,
    List<Base>? docs,
    List<Base>? files,
  }) : docs = docs ?? <Base>[],
       files = files ?? <Base>[];

  factory ContentCollection.fromConfig(String label, Object config) {
    final metadata = <String, dynamic>{};

    if (config is Map) {
      metadata.addAll(Map<String, dynamic>.from(config));
    } else if (config is bool) {
      metadata['output'] = config;
    }

    return ContentCollection(label: label, metadata: metadata);
  }

  final String label;
  final Map<String, dynamic> metadata;
  final List<Base> docs;
  final List<Base> files;

  bool get output => metadata['output'] == true;

  String get permalink {
    final rawPermalink = metadata['permalink']?.toString();
    if (rawPermalink != null && rawPermalink.isNotEmpty) {
      return rawPermalink;
    }
    return '/:collection/:path';
  }

  String? get sortBy => metadata['sort_by']?.toString();

  List<String> get order {
    final value = metadata['order'];
    if (value is List) {
      return value.map((entry) => entry.toString()).toList();
    }
    return const <String>[];
  }

  String get relativeDirectory => '_$label';

  String get directory {
    final collectionsDir = site.collectionsDir;
    final path = collectionsDir.isEmpty
        ? relativeDirectory
        : p.join(collectionsDir, relativeDirectory);
    return site.inSourceDir(path);
  }

  Iterable<Base> get items => docs.followedBy(files);

  Iterable<Base> get itemsToWrite => items;

  void sortDocs() {
    final manualOrder = order;
    if (manualOrder.isNotEmpty) {
      _rearrangeDocs(manualOrder);
      return;
    }

    final sortKey = sortBy;
    if (sortKey != null && sortKey.isNotEmpty) {
      _sortDocsByKey(sortKey);
      return;
    }

    docs.sort(_defaultCompare);
  }

  void assignPreviousNext() {
    for (var i = 0; i < docs.length; i++) {
      final doc = docs[i];
      doc.previous = i > 0 ? docs[i - 1] : null;
      doc.next = i < docs.length - 1 ? docs[i + 1] : null;
    }
  }

  int _defaultCompare(Base a, Base b) {
    final dateCompare = a.date.compareTo(b.date);
    if (dateCompare != 0) return dateCompare;
    return a.relativePath.compareTo(b.relativePath);
  }

  void _sortDocsByKey(String key) {
    docs.sort((a, b) {
      final aValue = a.config[key];
      final bValue = b.config[key];

      if (aValue == null && bValue != null) {
        log.warning("Sort warning: '$key' not defined in ${a.relativePath}");
        return 1;
      }
      if (aValue != null && bValue == null) {
        log.warning("Sort warning: '$key' not defined in ${b.relativePath}");
        return -1;
      }

      int? order;
      if (aValue is Comparable && bValue is Comparable) {
        order = aValue.compareTo(bValue);
      } else if (aValue != null && bValue != null) {
        order = aValue.toString().compareTo(bValue.toString());
      }

      if (order == null || order == 0) {
        return _defaultCompare(a, b);
      }
      return order;
    });
  }

  void _rearrangeDocs(List<String> manualOrder) {
    final normalizedDocs = List<Base>.from(docs)..sort(_defaultCompare);
    final docsByPath = <String, Base>{};
    for (final doc in normalizedDocs) {
      docsByPath[doc.relativePath] = doc;
    }

    final result = <Base>[];
    final seen = <String>{};
    for (final entry in manualOrder) {
      final key = p.join(relativeDirectory, entry);
      final doc = docsByPath[key];
      if (doc == null) continue;
      result.add(doc);
      seen.add(key);
    }

    for (final doc in normalizedDocs) {
      if (seen.contains(doc.relativePath)) continue;
      result.add(doc);
    }

    docs
      ..clear()
      ..addAll(result);
  }
}

class CollectionItem extends Base {
  CollectionItem(
    super.source, {
    required this.collectionConfig,
    super.name,
    super.frontMatter,
    super.dirConfig,
    super.destination,
  }) {
    collection = collectionConfig.label;
    outputEnabled = collectionConfig.output;
    if (collectionConfig.permalink.isNotEmpty &&
        !frontMatter.containsKey('permalink')) {
      frontMatter['permalink'] = collectionConfig.permalink;
    }
    populateDerivedFrontMatter();
  }

  final ContentCollection collectionConfig;

  @override
  String get pathPlaceholder {
    final collectionRoot = collectionConfig.directory;
    final relativePath = p.relative(source, from: collectionRoot);
    var withoutExtension = p.withoutExtension(relativePath);
    withoutExtension = withoutExtension.replaceAll(RegExp(r'\.*$'), '');
    return withoutExtension == '.' ? '' : withoutExtension;
  }
}

class CollectionStatic extends Base {
  CollectionStatic(
    super.source, {
    required this.collectionConfig,
    super.name,
    super.frontMatter,
    super.dirConfig,
    super.destination,
  }) {
    collection = collectionConfig.label;
    outputEnabled = collectionConfig.output;
    if (collectionConfig.permalink.isNotEmpty &&
        !frontMatter.containsKey('permalink')) {
      frontMatter['permalink'] = collectionConfig.permalink;
    }
    populateDerivedFrontMatter();
  }

  final ContentCollection collectionConfig;

  @override
  bool get isStatic => true;

  @override
  String link() {
    var path = buildPermalink(collectionConfig.permalink);
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    final ext = p.extension(source);
    if (ext.isNotEmpty && !path.endsWith(ext)) {
      path = '$path$ext';
    }
    return p.normalize(path);
  }

  @override
  String get pathPlaceholder {
    final collectionRoot = collectionConfig.directory;
    final relativePath = p.relative(source, from: collectionRoot);
    var withoutExtension = p.withoutExtension(relativePath);
    withoutExtension = withoutExtension.replaceAll(RegExp(r'\.*$'), '');
    return withoutExtension == '.' ? '' : withoutExtension;
  }

  @override
  Future<void> render() async {
    return;
  }
}

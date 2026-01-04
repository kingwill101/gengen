import 'package:gengen/drops/document_drop.dart';
import 'package:liquify/liquify.dart';

class PaginatedCollectionDrop extends Drop {
  final Map<String, String> _pagePaths;

  PaginatedCollectionDrop({
    required List<DocumentDrop> items,
    required int currentPage,
    required int totalPages,
    required int itemsPerPage,
    required int totalItems,
    required bool hasPrevious,
    required bool hasNext,
    required List<dynamic> pageTrail,
    required Map<String, String> pagePaths,
    String? pagePath,
    String? previousPagePath,
    String? nextPagePath,
    String? firstPagePath,
    String? lastPagePath,
  }) : _pagePaths = Map<String, String>.from(pagePaths) {
    invokable = const [#path_for];
    final featured = items.isNotEmpty ? items.first : null;
    final remaining = items.length > 1 ? items.sublist(1) : <DocumentDrop>[];

    attrs = {
      'items': items,
      'posts': items,
      'current_page': currentPage,
      'page_num': currentPage,
      'total_pages': totalPages,
      'items_per_page': itemsPerPage,
      'total_items': totalItems,
      'has_previous': hasPrevious,
      'has_next': hasNext,
      'page_trail': pageTrail,
      'page_paths': _pagePaths,
      'page_path': pagePath,
      'current_page_path': pagePath,
      'first_page_path': firstPagePath,
      'last_page_path': lastPagePath,
      'previous_page_path': previousPagePath,
      'next_page_path': nextPagePath,
      'previous_page': hasPrevious ? currentPage - 1 : null,
      'next_page': hasNext ? currentPage + 1 : null,
      'featured': featured,
      'hero': featured,
      'list_items': remaining,
      'items_without_featured': remaining,
      'has_items': items.isNotEmpty,
      'has_list_items': remaining.isNotEmpty,
      'is_first_page': currentPage == 1,
      'is_last_page': currentPage == totalPages,
    };
  }

  String? path_for(dynamic pageNumber) {
    final key = pageNumber.toString();
    return _pagePaths[key];
  }
}

/// # GenGen Pagination Plugin
///
/// This plugin provides powerful Jekyll-compatible pagination features for GenGen
/// static sites. It mirrors the functionality of Jekyll's paginate-v2 plugin,
/// enabling seamless migration and familiar usage patterns.
///
/// ## Features
///
/// - **Jekyll Compatibility**: Uses identical template variables and patterns
/// - **Smart URL Generation**: Creates clean URLs like `/page/2/`, `/page/3/`
/// - **Page Trail Logic**: Intelligent pagination navigation (1, 2, ..., 8, 9, 10)
/// - **Flexible Configuration**: Customizable items per page, URL patterns, collections
/// - **Performance Optimized**: Only loads content for current page
/// - **SEO Friendly**: Proper pagination metadata and clean URLs
///
/// ## Configuration
///
/// Configure pagination in your `config.yaml`:
///
/// ```yaml
/// pagination:
///   enabled: true              # Enable pagination (default: true)
///   items_per_page: 8          # Posts per page (default: 5)
///   collection: posts          # Collection to paginate (default: posts)
///   permalink: '/page/:num/'   # URL pattern (default: /page/:num/)
///   indexpage: index           # Template file (default: index)
/// ```
///
/// ## Template Variables
///
/// When pagination is active, these variables are available in templates:
///
/// ### Core Variables
/// - `page.paginate.items` - Array of posts/pages for current page
/// - `page.paginate.current_page` - Current page number (1, 2, 3...)
/// - `page.paginate.total_pages` - Total number of pages
/// - `page.paginate.items_per_page` - Items per page setting
/// - `page.paginate.total_items` - Total number of items being paginated
///
/// ### Navigation Variables
/// - `page.paginate.has_previous` - Boolean: has previous page
/// - `page.paginate.has_next` - Boolean: has next page
/// - `page.paginate.page_trail` - Array for navigation (e.g., [1,2,3,4,5])
///
/// ## Usage Examples
///
/// ### Basic Post Loop
/// ```liquid
/// {% for post in page.paginate.items %}
///   <article>
///     <h2><a href="{{ post.url }}">{{ post.title }}</a></h2>
///     <time>{{ post.date | date: '%B %d, %Y' }}</time>
///     <p>{{ post.excerpt }}</p>
///   </article>
/// {% endfor %}
/// ```
///
/// ### Pagination Navigation
/// ```liquid
/// <!-- Previous Page -->
/// {% if page.paginate.has_previous %}
///   <a href="{% if page.paginate.current_page == 2 %}/{% else %}/page/{{ page.paginate.current_page | minus: 1 }}/{% endif %}">
///     ← Previous
///   </a>
/// {% endif %}
///
/// <!-- Page Numbers -->
/// {% for page_num in page.paginate.page_trail %}
///   {% if page_num == page.paginate.current_page %}
///     <span class="current">{{ page_num }}</span>
///   {% else %}
///     <a href="{% if page_num == 1 %}/{% else %}/page/{{ page_num }}/{% endif %}">
///       {{ page_num }}
///     </a>
///   {% endif %}
/// {% endfor %}
///
/// <!-- Next Page -->
/// {% if page.paginate.has_next %}
///   <a href="/page/{{ page.paginate.current_page | plus: 1 }}/">
///     Next →
///   </a>
/// {% endif %}
/// ```
///
/// ### Pagination Information
/// ```liquid
/// <p>
///   Page {{ page.paginate.current_page }} of {{ page.paginate.total_pages }}
///   ({{ page.paginate.items.size }} of {{ page.paginate.total_items }} posts)
/// </p>
/// ```
///
/// ## How It Works
///
/// 1. **Collection Reading**: Reads posts/pages from the specified collection
/// 2. **Sorting**: Sorts items by date (newest first)
/// 3. **Page Creation**: Creates pagination pages as needed
/// 4. **URL Generation**: Generates clean URLs following the permalink pattern
/// 5. **Template Integration**: Makes pagination data available to templates
///
/// ## Advanced Configuration Examples
///
/// ### Custom Blog Section
/// ```yaml
/// pagination:
///   enabled: true
///   items_per_page: 12
///   collection: posts
///   permalink: '/blog/page/:num/'
///   indexpage: blog-index
/// ```
///
/// ### Archive Pages
/// ```yaml
/// pagination:
///   enabled: true
///   items_per_page: 20
///   collection: posts
///   permalink: '/archive/page/:num/'
///   indexpage: archive
/// ```
///
/// ## Performance Considerations
///
/// - Only the current page's items are loaded into `page.paginate.items`
/// - Total counts are calculated efficiently without loading all content
/// - Page trail is generated algorithmically for optimal navigation
/// - Memory usage scales with items per page, not total items
///
/// ## Compatibility Notes
///
/// This plugin is designed to be 100% compatible with Jekyll's paginate-v2:
/// - Same variable names and structure
/// - Identical template syntax
/// - Compatible URL patterns
/// - Same configuration options
///
/// This enables easy migration from Jekyll to GenGen without template changes.
///
/// ## See Also
///
/// - [GenGen Pagination Example](../../examples/pagination/) - Complete working example
/// - [Jekyll paginate-v2 docs](https://github.com/sverrirs/jekyll-paginate-v2) - Original plugin
/// - [Liquid Templates](https://shopify.github.io/liquid/) - Template syntax reference
library;

import 'dart:async';
import 'package:collection/collection.dart';
import 'package:gengen/drops/document_drop.dart';
import 'package:gengen/drops/paginated_collection_drop.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/models/page.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;

/// Pagination data model that handles pagination calculations and data
class Pagination {
  final int itemsPerPage;
  final List<Base> items;
  final int currentPage;

  Pagination({
    required this.itemsPerPage,
    required this.items,
    required this.currentPage,
  });

  /// Get items for the current page
  List<Base> get currentPageItems {
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, items.length);
    return items.sublist(startIndex, endIndex);
  }

  /// Total number of pages
  int get totalPages => (items.length / itemsPerPage).ceil();

  /// Check if there's a previous page
  bool get hasPrevious => currentPage > 1;

  /// Check if there's a next page
  bool get hasNext => currentPage < totalPages;

  /// Convert to map for template usage
  Map<String, dynamic> toMap() {
    final liquidItems = currentPageItems.map((item) => item.to_liquid).toList();

    return {
      'items': liquidItems,
      'current_page': currentPage,
      'total_pages': totalPages,
      'items_per_page': itemsPerPage,
      'total_items': items.length,
      'has_previous': hasPrevious,
      'has_next': hasNext,
    };
  }
}

/// A specialized page class for pagination pages following Jekyll's approach.
///
/// This class creates proper page objects for pagination instead of manipulating
/// the permalink system. Each pagination page (e.g., /page/2/, /page/3/) is
/// represented as a distinct PaginationPage instance with its own pagination data.
///
/// ## Key Features
/// - Extends the base Page class for full integration
/// - Contains pagination-specific data and metadata
/// - Generates clean URLs without .html extensions
/// - Preserves all standard page functionality
class PaginationPage extends Page {
  /// Pagination data specific to this page (items, page numbers, etc.)
  final Map<String, dynamic> paginationData;

  /// Optional custom permalink path for this pagination page
  final String? permalinkPath;

  PaginationPage({
    required String source,
    required this.paginationData,
    this.permalinkPath,
    Map<String, dynamic> frontMatter = const {},
  }) : super(source, frontMatter: frontMatter);

  @override
  String link() {
    // Use the permalink path directly if provided
    if (permalinkPath != null) {
      // Remove leading slash to make it a relative path
      String relativePath = permalinkPath!.startsWith('/')
          ? permalinkPath!.substring(1)
          : permalinkPath!;

      // Ensure it ends with index.html for proper directory structure
      if (relativePath.endsWith('/')) {
        return p.join(relativePath, 'index.html');
      }
      return relativePath;
    }
    return super.link();
  }

  @override
  DocumentDrop get to_liquid => PaginationPageDrop(this);
}

/// Custom DocumentDrop for pagination pages that includes pagination data
class PaginationPageDrop extends DocumentDrop {
  final PaginationPage paginationPage;

  PaginationPageDrop(this.paginationPage) : super(paginationPage);

  @override
  List<Symbol> get invokable => [...super.invokable, #paginate];

  @override
  dynamic invoke(Symbol symbol) {
    switch (symbol) {
      case #paginate:
        return paginationPage.paginationData;
      default:
        return super.invoke(symbol);
    }
  }
}

/// The main pagination plugin that provides Jekyll-compatible pagination features.
///
/// This plugin automatically processes your site's posts/pages and creates
/// paginated views with proper navigation. It supports all major Jekyll
/// pagination features including:
///
/// - Multi-page post/page listings
/// - Configurable items per page
/// - Smart navigation with page trails
/// - Clean URL generation
/// - SEO-friendly pagination metadata
///
/// The plugin registers itself with the site and runs during the generation
/// phase to create pagination pages as needed.
class PaginationPlugin extends BasePlugin {
  /// Cached pagination drop for the first page (index)
  PaginatedCollectionDrop? _paginationData;

  /// Cached list of paginated items for performance
  List<Base>? _paginatedItems;

  @override
  PluginMetadata get metadata => PluginMetadata(
    name: 'PaginationPlugin',
    version: '1.0.0',
    description: 'Generates paginated pages',
  );

  /// Main generation method that creates all pagination pages.
  ///
  /// This method:
  /// 1. Reads pagination configuration from config.yaml
  /// 2. Collects and sorts items to paginate (posts or pages)
  /// 3. Calculates how many pages are needed
  /// 4. Creates pagination page objects for pages 2, 3, 4, etc.
  /// 5. Stores pagination data for template access
  ///
  /// The first page (page 1) uses the existing index template,
  /// while additional pages are created as separate PaginationPage instances.
  @override
  Future<void> generate() async {
    logger.info('(${metadata.name}) Starting pagination generation');

    // Get pagination configuration
    final paginationConfig = site.config.get<Map<String, dynamic>>(
      'pagination',
      defaultValue: {},
    )!;

    // Skip if pagination is disabled
    if (paginationConfig['enabled'] == false) {
      logger.info('(${metadata.name}) Pagination disabled in config');
      return;
    }

    final itemsPerPage = paginationConfig['items_per_page'] as int? ?? 5;
    final collection = paginationConfig['collection'] as String? ?? 'posts';
    final permalink = paginationConfig['permalink'] as String? ?? '/page/:num/';
    final indexname = paginationConfig['indexpage'] as String? ?? 'index';

    // Get items to paginate
    List<Base> items;
    switch (collection) {
      case 'posts':
        items = site.posts.where((post) => !post.isIndex).toList();
        // Sort posts by date (newest first)
        items.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'pages':
        items = site.pages;
        break;
      default:
        logger.warning('(${metadata.name}) Unknown collection: $collection');
        return;
    }

    if (items.isEmpty) {
      logger.info('(${metadata.name}) No items to paginate');
      return;
    }

    // Find index pages for pagination
    // For posts collection, prefer _posts/index.html over root index
    Page? indexPage;
    Page? postsIndexPage;

    // Check for index page in _posts/ directory (for posts collection)
    if (collection == 'posts') {
      final pagesInPosts = site.posts.whereType<Page>().toList();
      postsIndexPage = pagesInPosts.firstWhereOrNull(
        (page) =>
            page.isIndex &&
            (page.source.contains('_posts/') || page.source.contains('_posts\\')),
      );
    }

    // Check site.pages for the configured index page
    indexPage = site.pages.whereType<Page>().firstWhereOrNull(
      (page) =>
          p.basenameWithoutExtension(page.source) == indexname ||
          p.basename(page.source) == '$indexname.html',
    );

    // Also check posts for index pages if not found in pages
    indexPage ??= site.posts.whereType<Page>().firstWhereOrNull(
      (page) =>
          p.basenameWithoutExtension(page.source) == indexname ||
          p.basename(page.source) == '$indexname.html',
    );

    if (indexPage == null && postsIndexPage == null) {
      logger.warning(
        '(${metadata.name}) No index page found for pagination template. '
        'Skipping pagination generation. Create an index.html file with '
        '{% for post in page.paginate.items %} to enable pagination.',
      );
      return;
    }

    // Use posts index page as primary if available and we're paginating posts
    if (postsIndexPage != null && collection == 'posts') {
      indexPage = postsIndexPage;
      logger.info('(${metadata.name}) Using _posts/index as pagination template');
    }

    // At this point we must have an index page
    final paginationIndexPage = indexPage!;

    final totalPages = (items.length / itemsPerPage).ceil();
    logger.info(
      '(${metadata.name}) Creating $totalPages pages for ${items.length} items',
    );

    // Generate pagination pages
    final pagePaths = <int, String>{
      for (int i = 1; i <= totalPages; i++) i: _pagePathFor(i, permalink),
    };
    final firstPagePath = pagePaths[1] ?? '/';
    final lastPagePath =
        pagePaths[totalPages] ?? _pagePathFor(totalPages, permalink);

    for (int pageNum = 1; pageNum <= totalPages; pageNum++) {
      final pagination = Pagination(
        itemsPerPage: itemsPerPage,
        items: items,
        currentPage: pageNum,
      );

      final pagePath = pagePaths[pageNum] ?? _pagePathFor(pageNum, permalink);

      final previousPage = pagination.hasPrevious ? pageNum - 1 : null;
      final nextPage = pagination.hasNext ? pageNum + 1 : null;

      final previousPagePath = previousPage != null
          ? pagePaths[previousPage]
          : null;
      final nextPagePath = nextPage != null
          ? pagePaths[nextPage] ?? _pagePathFor(nextPage, permalink)
          : null;

      final pagePathMap = Map.fromEntries(
        pagePaths.entries.map(
          (entry) => MapEntry(entry.key.toString(), entry.value),
        ),
      );

      final currentItems = pagination.currentPageItems
          .map((item) => item.to_liquid)
          .toList();
      final pageTrail = _generatePageTrail(pageNum, totalPages);

      final paginationDrop = PaginatedCollectionDrop(
        items: currentItems,
        currentPage: pageNum,
        totalPages: totalPages,
        itemsPerPage: itemsPerPage,
        totalItems: items.length,
        hasPrevious: pagination.hasPrevious,
        hasNext: pagination.hasNext,
        pageTrail: pageTrail,
        pagePaths: pagePathMap,
        pagePath: pagePath,
        previousPagePath: previousPagePath,
        nextPagePath: nextPagePath,
        firstPagePath: firstPagePath,
        lastPagePath: lastPagePath,
      );

      final pageData = Map<String, dynamic>.from(paginationDrop.attrs);

      // Store pagination data for the first page (index)
      if (pageNum == 1) {
        _paginationData = paginationDrop;
        _paginatedItems = pagination.currentPageItems;
        paginationIndexPage.frontMatter = {
          ...paginationIndexPage.frontMatter,
          'paginate': paginationDrop,
          'pagination': paginationDrop,
        };
      }

      // Generate additional pagination pages (page 2, 3, etc.)
      if (pageNum > 1) {
        await _createPaginationPage(
          pageNum,
          paginationDrop,
          pageData,
          permalink,
          paginationIndexPage,
        );
      }
    }

    logger.info('(${metadata.name}) Pagination generation complete');
  }

  /// Generates page trail for navigation (e.g., [1, 2, 3, 4, 5]).
  ///
  /// The page trail provides an array of page numbers for navigation links.
  /// For simplicity, this implementation shows the first 5 pages when the
  /// total pages is greater than 5. More sophisticated implementations could
  /// show ellipsis and smart ranges.
  ///
  /// Examples:
  /// - 4 total pages: [1, 2, 3, 4]
  /// - 10 total pages: [1, 2, 3, 4, 5]
  ///
  /// @param currentPage The current page number (1-based)
  /// @param totalPages The total number of pages available
  /// @returns List of page numbers to show in navigation
  List<dynamic> _generatePageTrail(int currentPage, int totalPages) {
    const int window = 2;
    const int maxVisible = 7;
    final trail = <dynamic>[];

    if (totalPages <= maxVisible) {
      for (int i = 1; i <= totalPages; i++) {
        trail.add(i);
      }
      return trail;
    }

    trail.add(1);

    var start = currentPage - window;
    var end = currentPage + window;

    if (start < 2) {
      end += 2 - start;
      start = 2;
    }

    if (end > totalPages - 1) {
      start -= end - (totalPages - 1);
      end = totalPages - 1;
    }

    if (start > 2) {
      trail.add('gap');
    } else {
      start = 2;
    }

    for (int i = start; i <= end; i++) {
      if (i > 1 && i < totalPages) {
        trail.add(i);
      }
    }

    if (end < totalPages - 1) {
      trail.add('gap');
    }

    trail.add(totalPages);

    final deduped = <dynamic>[];
    for (final entry in trail) {
      if (deduped.isEmpty || deduped.last != entry) {
        deduped.add(entry);
      }
    }
    return deduped;
  }

  /// Creates a pagination page for the given page number following Jekyll's approach.
  ///
  /// This method creates a new PaginationPage instance that represents a single
  /// page in the pagination sequence (e.g., /page/2/, /page/3/). Each page:
  ///
  /// 1. Uses the same template as the index page
  /// 2. Gets its own URL based on the permalink pattern
  /// 3. Contains pagination data specific to that page
  /// 4. Is added to the site's page collection for rendering
  ///
  /// @param pageNum The page number (2, 3, 4, etc. - page 1 is handled separately)
  /// @param pageData The pagination data for this specific page
  /// @param permalink The URL pattern (e.g., '/page/:num/')
  /// @param indexname The name of the index template to use
  Future<void> _createPaginationPage(
    int pageNum,
    PaginatedCollectionDrop paginationDrop,
    Map<String, dynamic> pageData,
    String permalink,
    Page indexPage,
  ) async {
    // Generate the permalink for this page
    String pagePath = permalink.replaceAll(':num', pageNum.toString());

    // Create a proper pagination page using our custom class
    final paginationPage = PaginationPage(
      source: indexPage.source,
      paginationData: pageData,
      permalinkPath: pagePath,
    );

    // Set the same content as the index page
    paginationPage.content = indexPage.content;

    // IMPORTANT: Set frontMatter AFTER constructor because Base.read() overwrites it
    paginationPage.frontMatter = {
      ...indexPage.frontMatter,
      'paginate': paginationDrop,
      'pagination': paginationDrop,
      'page_num': pageNum,
      'layout': indexPage.frontMatter['layout'], // Preserve layout
    };

    // Add to site pages
    site.pages.add(paginationPage);

    logger.info(
      '(${metadata.name}) Created pagination page $pageNum at $pagePath',
    );
  }

  /// Provides pagination data for backward compatibility (deprecated).
  ///
  /// Note: This method is kept for backward compatibility but is no longer
  /// the primary way pagination data is accessed. Each pagination page now
  /// provides its own data through `page.paginate` via the PaginationPageDrop.
  ///
  ///
  /// @returns Pagination data map for page 1 only, or null if pagination is not active
  PaginatedCollectionDrop? get paginationData => _paginationData;

  /// Provides paginated items for the current page (used by site map)
  List<Base>? get paginatedItems => _paginatedItems;

  String _pagePathFor(int pageNum, String permalink) {
    if (pageNum <= 1) {
      return '/';
    }

    var path = permalink.replaceAll(':num', pageNum.toString());

    if (!path.startsWith('/')) {
      path = '/$path';
    }

    if (!path.endsWith('/')) {
      path = '$path/';
    }

    return path;
  }
}

import 'dart:core';

import 'package:gengen/models/base.dart';
import 'package:gengen/models/url.dart';
import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../logging.dart';

class PermalinkStructure {
  static const String date = ":categories/:year/:month/:day/:title:output_ext";
  static const String pretty = ":categories/:year/:month/:day/:title/";

  static const String ordinal = ":categories/:year/:y_day/:title:output_ext";
  static const String weekdate =
      ":categories/:year/W:week/:short_day/:title:output_ext";
  static const String none = ":categories/:title:output_ext";
  static const String post = ":path/:basename:output_ext";

  static Map<String, String> map() {
    return {
      "date": PermalinkStructure.date,
      "pretty": PermalinkStructure.pretty,
      "ordinal": PermalinkStructure.ordinal,
      "weekdate": PermalinkStructure.weekdate,
      "post": PermalinkStructure.post,
      "none": PermalinkStructure.none,
    };
  }
}

extension PermalinkExtension on Base {
  String permalink() {
    if (config.isEmpty || !config.containsKey("permalink")) {
      return p.normalize(buildPermalink());
    }

    String entryPermalink = config["permalink"] as String? ?? "";

    // Only apply date-based permalinks to posts
    // Pages and other files should use simpler permalink structures
    if (!isPost && entryPermalink == "date") {
      // Special handling for index pages in _posts directory
      if (isIndex && name.startsWith('_posts/')) {
        // For _posts/index.html, use "posts/index.html"
        return 'posts/index.html';
      }
      // For other non-posts, use the 'none' structure
      return p.normalize(buildPermalink(PermalinkStructure.none));
    }

    var structures = PermalinkStructure.map();
    if (structures.containsKey(entryPermalink)) {
      entryPermalink = structures[entryPermalink]!;
      
      // Check if the pattern ends with '/' BEFORE calling buildPermalink
      bool endsWithSlash = entryPermalink.endsWith('/');
      
      String processedPermalink = buildPermalink(entryPermalink);
      
      // If the original pattern ended with '/', add index.html
      if (endsWithSlash) {
        processedPermalink = processedPermalink + 'index.html';
      }
      
      return p.normalize(processedPermalink);
    }
    
    // If it contains tokens, process it as a template
    if (entryPermalink.contains(':')) {
      // Check if the pattern ends with '/' BEFORE processing
      bool endsWithSlash = entryPermalink.endsWith('/');
      
      String processedPermalink = buildPermalink(entryPermalink);
      
      // If the original pattern ended with '/', add index.html
      if (endsWithSlash) {
        processedPermalink = processedPermalink + 'index.html';
      } else if (!processedPermalink.contains('.') && processedPermalink.isNotEmpty) {
        // If no extension and not empty, treat as directory and add index.html
        processedPermalink = processedPermalink + '/index.html';
      }
      
      return p.normalize(processedPermalink);
    }
    
    // If it's not a known structure and has no tokens, treat it as a literal path
    // Remove leading slash if present to ensure relative path
    String literalPath = entryPermalink.startsWith('/')
        ? entryPermalink.substring(1)
        : entryPermalink;

    if (literalPath.isEmpty) {
      return 'index.html';
    }

    // Handle clean URLs: if permalink ends with '/' or has no extension, 
    // append 'index.html' to create proper directory structure
    if (literalPath.endsWith('/')) {
      literalPath = literalPath + 'index.html';
    } else if (!literalPath.contains('.') && literalPath.isNotEmpty) {
      // If no extension and not empty, treat as directory and add index.html
      literalPath = literalPath + '/index.html';
    }
    
    return literalPath;
  }

  URL permalinkURL() {
    return URL(
      template: config["permalink"] as String? ?? PermalinkStructure.none,
      placeholders: permalinkPlaceholders(),
    );
  }

  String buildPermalink([String permalink = PermalinkStructure.none]) {
    Map<String, dynamic> config = this.config;

    // For title, only use frontMatter and defaultMatter, not site-wide config
    String? title = (frontMatter['title'] ?? defaultMatter['title']) as String? ?? "";
    String? slug = config['slug'] as String? ?? "";

    if (slug.isNotEmpty) {
      title = slug;
    } else if (title.isEmpty) {
      title = p.withoutExtension(p.basename(name));
    }

    String normalizedTitle = normalize(title);

    List<String> tags = config.containsKey("tags")
        ? List<String>.from(config['tags'] as List)
        : <String>[];

    // Check for explicit categories first, then default to "posts" for posts
    String categories = "";
    if (config.containsKey("categories") && config['categories'] != null) {
      List<String> categoryList = List<String>.from(config['categories'] as List);
      categories = categoryList.isNotEmpty ? categoryList.first : "";
    }
    
    // For posts without explicit categories, default to "posts"
    // Tags should NOT be used as categories
    if (isPost && categories.isEmpty) {
      categories = "posts";
    }

    permalink = permalink
        .replaceAll(':categories', categories)
        .replaceAll(':slugified_categories', slugifyList(tags))
        .replaceAll(':title', normalizedTitle)
        .replaceAll(':path', p.relative(p.dirname(source), from: site.root))
        .replaceAll(
          ':basename',
          normalize(p.withoutExtension(p.basename(source))),
        )
        .replaceAll(':output_ext', '.html');

    // Clean up any leading slashes that might be created by empty categories
    if (permalink.startsWith('/')) {
      permalink = permalink.substring(1);
    }

    if (config.containsKey('date') && config['date'] != null) {
      try {
        DateTime parsedDate = parseDate(
          config['date'] as String,
          format: site.config.get("date_format"),
        );

        permalink = permalink
            .replaceAll(':year', parsedDate.year.toString())
            .replaceAll(':month', parsedDate.month.toString().padLeft(2, '0'))
            .replaceAll(':day', parsedDate.day.toString().padLeft(2, '0'))
            .replaceAll(':short_year', parsedDate.year.toString().substring(2))
            .replaceAll(':i_month', parsedDate.month.toString())
            .replaceAll(':short_month', DateFormat('MMM').format(parsedDate))
            .replaceAll(':long_month', DateFormat('MMMM').format(parsedDate))
            .replaceAll(':i_day', parsedDate.day.toString())
            .replaceAll(
              ':y_day',
              int.parse(
                DateFormat('D').format(parsedDate),
              ).toString().padLeft(3, '0'),
            )
            .replaceAll(':w_year', DateFormat('kk').format(parsedDate))
            .replaceAll(':w_day', parsedDate.weekday.toString())
            .replaceAll(':short_day', DateFormat('E').format(parsedDate))
            .replaceAll(':long_day', DateFormat('EEEE').format(parsedDate))
            .replaceAll(':hour', DateFormat('HH').format(parsedDate))
            .replaceAll(':minute', DateFormat('mm').format(parsedDate))
            .replaceAll(':second', DateFormat('ss').format(parsedDate));

        // Calculate the first day of the year
        DateTime firstDayOfYear = DateTime(parsedDate.year, 1, 1);

        // Calculate the number of days from the first day of the year
        int dayOfYear = parsedDate.difference(firstDayOfYear).inDays;

        // Determine the week number (week 1 starts on January 1st)
        int weekNumber = (dayOfYear / 7).ceil() + 1;
        String formattedWeekNumber = weekNumber.toString().padLeft(2, '0');
        permalink = permalink.replaceAll(':week', formattedWeekNumber);
      } catch (e, stack) {
        log.warning('Error parsing date for ${source}: $e', e, stack);
        // For files without valid dates, fall back to a simpler permalink structure
        // Manually build the 'none' structure without date tokens
        String fallbackPermalink = PermalinkStructure.none
            .replaceAll(':categories', categories)
            .replaceAll(':title', normalizedTitle)
            .replaceAll(':output_ext', '.html');
        return fallbackPermalink;
      }
    }

    return permalink;
  }

  Map<String, String> permalinkPlaceholders([
    String permalink = PermalinkStructure.none,
  ]) {
    Map<String, String> placeholders = {};

    Map<String, dynamic> config = this.config;

    String? title = config['title'] as String? ?? "";
    String? slug = config['slug'] as String? ?? "";

    if (slug.isNotEmpty) {
      title = slug;
    } else if (title.isEmpty) {
      title = p.withoutExtension(p.basename(name));
    }

    String normalizedTitle = normalize(title);

    placeholders['title'] = normalizedTitle;

    List<String> tags = config.containsKey("tags")
        ? List<String>.from(config['tags'] as List)
        : <String>[];

    // Check for explicit categories first, then default to "posts" for posts
    String categories = "";
    if (config.containsKey("categories") && config['categories'] != null) {
      List<String> categoryList = List<String>.from(config['categories'] as List);
      categories = categoryList.isNotEmpty ? categoryList.first : "";
    }
    
    // For posts without explicit categories, default to "posts"
    // Tags should NOT be used as categories
    if (isPost && categories.isEmpty) {
      categories = "posts";
    }

    placeholders['categories'] = categories;
    placeholders['slugified_categories'] = slugifyList(tags);
    placeholders['path'] = p.relative(p.dirname(source), from: site.root);
    placeholders['basename'] = normalize(
      p.withoutExtension(p.basename(source)),
    );
    placeholders['output_ext'] = '.html';

    if (config.containsKey('date') && config['date'] != null) {
      try {
        DateTime parsedDate = DateTime.parse(config['date'] as String? ?? "");
        placeholders['year'] = parsedDate.year.toString();
        placeholders['month'] = parsedDate.month.toString().padLeft(2, '0');
        placeholders['day'] = parsedDate.day.toString().padLeft(2, '0');
        placeholders['short_year'] = parsedDate.year.toString().substring(2);
        placeholders['i_month'] = parsedDate.month.toString();
        placeholders['short_month'] = DateFormat('MMM').format(parsedDate);
        placeholders['long_month'] = DateFormat('MMMM').format(parsedDate);
        placeholders['i_day'] = parsedDate.day.toString();
        placeholders['y_day'] = int.parse(
          DateFormat('D').format(parsedDate),
        ).toString().padLeft(3, '0');
        placeholders['hour'] = parsedDate.hour.toString().padLeft(2, '0');
        placeholders['minute'] = parsedDate.minute.toString().padLeft(2, '0');
        placeholders['second'] = parsedDate.second.toString().padLeft(2, '0');
        placeholders['w_year'] = parsedDate.year.toString().substring(2);
        placeholders['w_day'] = parsedDate.weekday.toString();
        placeholders['short_day'] = DateFormat('E').format(parsedDate);
        placeholders['long_day'] = DateFormat('EEEE').format(parsedDate);
        placeholders['hour'] = parsedDate.hour.toString().padLeft(2, '0');
        placeholders['minute'] = parsedDate.minute.toString().padLeft(2, '0');
        placeholders['second'] = parsedDate.second.toString().padLeft(2, '0');

        // Calculate the first day of the year
        DateTime firstDayOfYear = DateTime(parsedDate.year, 1, 1);

        // Calculate the number of days from the first day of the year
        int dayOfYear = parsedDate.difference(firstDayOfYear).inDays;

        // Determine the week number (week 1 starts on January 1st)
        int weekNumber = (dayOfYear / 7).ceil() + 1;
        String formattedWeekNumber = weekNumber.toString().padLeft(2, '0');
        placeholders['week'] = formattedWeekNumber;
      } catch (e, stack) {
        log.warning('Error parsing date: $e', e, stack);
      }
    }

    return placeholders;
  }
}

import 'dart:core';

import 'package:gengen/logging.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart';
import 'package:intl/intl.dart';
import 'package:more/collection.dart';
import 'package:path/path.dart' as p;

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
      return buildPermalink();
    }

    String entryPermalink = config["permalink"] as String? ?? "";

    //If permalink doesn't include partition then it should be
    //an hard coded path
    if (entryPermalink.isNotEmpty && !entryPermalink.contains(':')) {
      return entryPermalink.removePrefix('/');
    }

    var structures = PermalinkStructure.map();

    if (structures.containsKey(entryPermalink)) {
      return buildPermalink(structures[entryPermalink]!);
    }

    return p.normalize(buildPermalink(entryPermalink));
  }

  String buildPermalink([String permalink = PermalinkStructure.none]) {
    Map<String, dynamic> config = this.config;

    String? title = config['title'] as String? ?? "";

    if (title.isEmpty) {
      title = p.withoutExtension(p.basename(name));
    }

    String normalizedTitle = normalize(title);

    List<String> tags = config.containsKey("tags")
        ? List<String>.from(config['tags'] as List)
        : <String>[];

    String categories = tags.isNotEmpty ? tags.join("/") : "";
    categories = !isPost ? categories : "uncategorized";

    permalink = permalink
        .replaceAll(
          ':categories',
          categories,
        )
        .replaceAll(':slugified_categories', slugifyList(tags))
        .replaceAll(':title', normalizedTitle)
        .replaceAll(
            ':path', p.relative(p.dirname(source), from: Site.instance.root))
        .replaceAll(
          ':basename',
          normalize(p.withoutExtension(p.basename(source))),
        )
        .replaceAll(':output_ext', '.html');

    if (config.containsKey('date') && config['date'] != null) {
      try {
        DateTime parsedDate = DateTime.parse(config['date'] as String? ?? "");

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
              int.parse(DateFormat('D').format(parsedDate))
                  .toString()
                  .padLeft(3, '0'),
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

        // Determine the week number
        int weekNumber = (dayOfYear / 7).ceil();
        String formattedWeekNumber = weekNumber.toString().padLeft(2, '0');
        permalink = permalink.replaceAll(':week', formattedWeekNumber);
      } catch (e) {
        log.warning('Error parsing date: $e');
      }
    }

    return permalink;
  }
}

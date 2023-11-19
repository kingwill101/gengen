import 'dart:io';
import 'package:gengen/utilities.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';

class Base {
  Directory? destination;

  final Map<String, dynamic> dirConfig;

  late String source;

  late String content;
  Map<String, dynamic> frontMatter;

  Map<String, dynamic> get config => _config();

  Map<String, dynamic> _config() {
    Map<String, dynamic> config = Map.from(dirConfig);

    frontMatter.forEach((key, value) {
      if (config[key] == null) {
        config[key] = value;
      }
    });

    return config;
  }

  Base.fromYaml(this.frontMatter, this.source, this.content,
      [this.dirConfig = const {}, this.destination]);

  String link() {
    return joinAll([destination!.path, permalink()]);
  }
}

extension PermalinkExtension on Base {
  String permalink() {
    if (config.isEmpty || !config.containsKey("permalink")) {
      return buildPermalink();
    }

    String permalink = config["permalink"];

    var structures = PermalinkStructure.map();
    if (structures.containsKey(permalink)) {
      return buildPermalink(structures[permalink]!);
    }

    return normalize(buildPermalink(permalink));
  }

  String buildPermalink([String permalink = PermalinkStructure.none]) {
    Map<String, dynamic> config = this.config;

    String? title = config['title'];

    if (title == null || title.isEmpty) {
      title = withoutExtension(basename(source));
    }

    String normalizedTitle = slugify(title)
        .toLowerCase()
        .replaceAll(' ', '-')
        .replaceAll(RegExp(r'[^\w-]'), '');

    List<String> tags =
        config['tags'] != null ? List<String>.from(config['tags']) : [];

    permalink = permalink
        .replaceAll(
            ':categories', tags.isNotEmpty ? tags.join('/') : 'uncategorized')
        .replaceAll(':slugified_categories', slugifyList(tags))
        .replaceAll(':title', normalizedTitle)
        .replaceAll(':path', relative(dirname(source), from: current))
        .replaceAll(':basename', withoutExtension(basename(source)))
        .replaceAll(':output_ext', '.html');

    if (config.containsKey('date') && config['date'] != null) {
      try {
        DateTime parsedDate = DateTime.parse(config['date']);

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
                    .padLeft(3, '0'))
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
        print('Error parsing date: $e');
      }
    }

    return permalink;
  }
}

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

class Post extends Base {
  Post.fromYaml(super.frontMatter, super.source, super.content,
      [super.dirConfig, super.destination])
      : super.fromYaml();
}

class Page extends Base {
  Page.fromYaml(super.frontMatter, super.source, super.content,
      [super.dirConfig, super.destination])
      : super.fromYaml();
}

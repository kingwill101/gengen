// import 'package:build/build.dart'; // Removed for AOT compatibility
import 'dart:convert';

import 'package:gengen/data/social_graph.dart';
import 'package:gengen/logging.dart';
import 'package:liquify/liquify.dart';
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;
import 'package:intl/intl.dart';

/// Converts a strftime format string to a DateFormat pattern.
/// Supports common strftime specifiers used in Jekyll/Liquid templates.
String _strftimeToDateFormat(String strftimeFormat) {
  // Map of strftime specifiers to DateFormat patterns
  const strftimeToIntl = {
    '%Y': 'yyyy', // 4-digit year
    '%y': 'yy', // 2-digit year
    '%m': 'MM', // Month as zero-padded number
    '%-m': 'M', // Month as number (no zero-padding)
    '%B': 'MMMM', // Full month name
    '%b': 'MMM', // Abbreviated month name
    '%d': 'dd', // Day of month as zero-padded number
    '%-d': 'd', // Day of month (no zero-padding)
    '%e': 'd', // Day of month, space-padded (we use non-padded)
    '%j': 'DDD', // Day of year
    '%H': 'HH', // Hour (24-hour) zero-padded
    '%-H': 'H', // Hour (24-hour) no padding
    '%I': 'hh', // Hour (12-hour) zero-padded
    '%-I': 'h', // Hour (12-hour) no padding
    '%M': 'mm', // Minute zero-padded
    '%-M': 'm', // Minute no padding
    '%S': 'ss', // Second zero-padded
    '%-S': 's', // Second no padding
    '%p': 'a', // AM/PM
    '%P': 'a', // am/pm (lowercase in some systems)
    '%A': 'EEEE', // Full weekday name
    '%a': 'E', // Abbreviated weekday name
    '%w': 'c', // Weekday as number (0=Sunday)
    '%u': 'c', // Weekday as number (1=Monday)
    '%Z': 'z', // Timezone abbreviation
    '%z': 'Z', // Timezone offset
    '%%': '%', // Literal percent
    '%n': '\n', // Newline
    '%t': '\t', // Tab
  };

  var result = strftimeFormat;

  // Sort by length descending to handle longer patterns first (e.g., '%-m' before '%m')
  final sortedKeys = strftimeToIntl.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  for (final key in sortedKeys) {
    result = result.replaceAll(key, strftimeToIntl[key]!);
  }

  return result;
}

/// Parses a date value from various formats
DateTime? _parseInputDate(dynamic value) {
  if (value == null) return null;

  if (value is DateTime) {
    return value;
  }

  if (value == 'now' || value == 'today') {
    return DateTime.now();
  }

  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000);
  }

  if (value is String) {
    // Try parsing as Unix timestamp
    if (RegExp(r'^\d+$').hasMatch(value)) {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(value) * 1000);
    }

    // Try standard DateTime parse
    try {
      return DateTime.parse(value);
    } catch (_) {
      // Try common date formats
      final formats = [
        'yyyy-MM-dd HH:mm:ss',
        'yyyy-MM-dd',
        'MM/dd/yyyy',
        'dd/MM/yyyy',
        'MMMM d, yyyy',
        'MMM d, yyyy',
      ];

      for (final fmt in formats) {
        try {
          return DateFormat(fmt).parse(value);
        } catch (_) {
          continue;
        }
      }
    }
  }

  return null;
}

/// Date filter function that supports both strftime and DateFormat patterns.
/// Can be registered directly with FilterRegistry.register for priority.
dynamic dateFilter(
  dynamic input,
  List<dynamic> args,
  Map<String, dynamic> namedArgs,
) {
  final date = _parseInputDate(input);
  if (date == null) {
    log.warning('dateFilter: could not parse date from input: $input');
    return input?.toString() ?? '';
  }

  // Default format if none provided
  String format = args.isNotEmpty ? args[0].toString() : 'yyyy-MM-dd';

  // Convert strftime format to DateFormat if it contains % specifiers
  if (format.contains('%')) {
    format = _strftimeToDateFormat(format);
  }

  try {
    return DateFormat(format).format(date);
  } catch (e) {
    log.warning('date filter: invalid format "$format": $e');
    return date.toIso8601String();
  }
}

class DataModule extends Module {
  @override
  void register() {
    // Override the date filter to support strftime format strings
    filters['date'] = dateFilter;

    filters['get_json'] = (input, args, namedArgs) async {
      if (input == null) {
        return <String, dynamic>{};
      }

      try {
        final response = await http.get(
          Uri.parse(input as String),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
          return {'value': decoded};
        }

        log.warning(
          'get_json request failed (${response.statusCode} ${response.reasonPhrase}) for $input',
        );
      } catch (error, stack) {
        log.severe('get_json error for $input', error, stack);
      }

      return <String, dynamic>{};
    };

    filters['social_graph'] = (input, args, namedArgs) async {
      if (input != null) {
        try {
          var result = await fetchPageAndExtractSocialGraph(input as String);
          return result;
        } catch (e, s) {
          log.severe('social_graph error', e, s);
          return <String, dynamic>{};
        }
      }

      return <String, dynamic>{};
    };

    filters['append'] = (input, args, namedArgs) {
      if (input != null) {
        return '$input${args[0]}';
      }

      return '';
    };

    filters['array_to_sentence_string'] = (input, args, namedArgs) {
      return input.toString();
    };

    filters['date_to_string'] = (input, args, namedArgs) {
      return input.toString();
    };

    filters['modulo'] = (input, args, namedArgs) {
      return input.toString();
    };

    filters['group_by'] = (input, args, namedArgs) {
      return input;
    };

    filters['markdownify'] = (input, args, namedArgs) {
      if (input == null) {
        return '';
      }
      final source = input.toString();
      return md.markdownToHtml(
        source,
        extensionSet: md.ExtensionSet.gitHubFlavored,
      );
    };
  }
}

// import 'package:build/build.dart'; // Removed for AOT compatibility
import 'dart:convert';

import 'package:gengen/data/social_graph.dart';
import 'package:gengen/logging.dart';
import 'package:liquify/liquify.dart';
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;

class DataModule extends Module {
  @override
  void register() {
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
          return {
            'value': decoded,
          };
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

    // filters['date'] = (input, args, namedArgs) {
    //   if (input != null) {
    //     if (args.isEmpty) {
    //       return DateFormat().format(input as DateTime);
    //     }
    //     return DateFormat((args[0] as String).replaceAll("%", ""))
    //         .format(input as DateTime);
    //   }
    //   return '';
    // };

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

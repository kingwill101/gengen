import 'package:build/build.dart';
import 'package:gengen/data/data_fetcher.dart';
import 'package:gengen/data/social_graph.dart';
import 'package:liquid_engine/liquid_engine.dart' as liquid;

class DataModule implements liquid.Module {
  @override
  void register(liquid.Context context) {
    context.filters['get_json'] = (input, args) {
      if (input != null) {
        return DataFetcher.getJSON(input as String);
      }

      return <String, dynamic>{};
    };

    context.filters['social_graph'] = (input, args) async {
      if (input != null) {
        try {
          var result = await fetchPageAndExtractSocialGraph(input as String);
          return result;
        } catch (e) {
          log.severe(e);
          return <String, dynamic>{};
        }
      }

      return <String, dynamic>{};
    };

    context.filters['append'] = (input, args) {
      if (input != null) {
        return '$input${args[0]}';
      }

      return '';
    };
  }
}

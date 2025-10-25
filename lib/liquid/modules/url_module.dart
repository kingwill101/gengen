import 'package:gengen/site.dart';
import 'package:liquify/liquify.dart';
import 'package:path/path.dart';

class UrlModule extends Module {
  @override
  void register() {
    filters['relative_url'] = (input, args, namedArgs) {
      if (input != null) {
        return site.relativeToDestination(input as String);
      }
      return <String, dynamic>{};
    };

    filters['absolute_url'] = (input, args, namedArgs) {
      if (input != null) {
        return join(site.destination.path, input as String);
        // return site.relativeToDestination(input as String);
      }
      return <String, dynamic>{};
    };
  }
}

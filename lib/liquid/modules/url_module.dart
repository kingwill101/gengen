import 'package:gengen/site.dart';
import 'package:liquify/liquify.dart';
import 'package:path/path.dart' as p;

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
        return p.join(site.destination.path, input as String);
        // return site.relativeToDestination(input as String);
      }
      return <String, dynamic>{};
    };

    filters['asset_url'] = (input, args, namedArgs) {
      if (input == null) {
        return '';
      }

      final value = input.toString();
      if (value.startsWith('http://') || value.startsWith('https://')) {
        return value;
      }

      final normalized = value.startsWith('/') ? value.substring(1) : value;
      final absolute = p.join(site.destination.path, normalized);
      var relative = site.relativeToDestination(absolute);
      if (relative.isEmpty) {
        relative = normalized;
      }
      if (!relative.startsWith('/')) {
        relative = '/$relative';
      }
      return relative;
    };
  }
}

import 'package:gengen/site.dart';
import 'package:liquify/liquify.dart';
import 'package:path/path.dart' as p;

String _normalizedBaseUrl() {
  final raw = site.config.get<String>('baseurl', defaultValue: '') ?? '';
  if (raw.isEmpty || raw == '/') return '';
  var base = raw;
  if (!base.startsWith('/')) {
    base = '/$base';
  }
  if (base.endsWith('/')) {
    base = base.substring(0, base.length - 1);
  }
  return base;
}

String _normalizeWebPath(String value) {
  if (value.isEmpty) return '';
  if (value.startsWith('#')) return value;
  if (value.startsWith('http://') ||
      value.startsWith('https://') ||
      value.startsWith('mailto:') ||
      value.startsWith('tel:')) {
    return value;
  }
  return value.startsWith('/') ? value : '/$value';
}

String _coerceDestinationRelative(String value) {
  if (!p.isAbsolute(value)) return value;

  final destinationPath = site.destination.path;
  if (p.isWithin(destinationPath, value)) {
    return '/${p.relative(value, from: destinationPath)}';
  }

  return value;
}

String _joinUrl(String base, String path) {
  if (base.isEmpty) return path;
  if (path.isEmpty) return base;
  if (base.endsWith('/') && path.startsWith('/')) {
    return '${base.substring(0, base.length - 1)}$path';
  }
  if (!base.endsWith('/') && !path.startsWith('/')) {
    return '$base/$path';
  }
  return '$base$path';
}

class UrlModule extends Module {
  @override
  void register() {
    filters['relative_url'] = (input, args, namedArgs) {
      if (input == null) return '';

      final raw = _coerceDestinationRelative(input.toString());
      final normalized = _normalizeWebPath(raw);
      final baseurl = _normalizedBaseUrl();

      if (normalized.isEmpty ||
          normalized.startsWith('http://') ||
          normalized.startsWith('https://') ||
          normalized.startsWith('mailto:') ||
          normalized.startsWith('tel:') ||
          normalized.startsWith('#')) {
        return normalized;
      }

      return baseurl.isEmpty ? normalized : '$baseurl$normalized';
    };

    filters['absolute_url'] = (input, args, namedArgs) {
      if (input == null) return '';

      final relative = filters['relative_url']!(input, args, namedArgs) as String;
      if (relative.startsWith('http://') ||
          relative.startsWith('https://') ||
          relative.startsWith('mailto:') ||
          relative.startsWith('tel:')) {
        return relative;
      }

      final siteUrl = site.config.get<String>('url', defaultValue: '') ?? '';
      return siteUrl.isEmpty ? relative : _joinUrl(siteUrl, relative);
    };

    filters['asset_url'] = (input, args, namedArgs) {
      if (input == null) {
        return '';
      }

      final value = input.toString();
      if (value.startsWith('http://') || value.startsWith('https://')) {
        return value;
      }
      final normalized = value.startsWith('/') ? value : '/$value';
      return filters['relative_url']!(normalized, args, namedArgs) as String;
    };
  }
}

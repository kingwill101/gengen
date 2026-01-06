class ShortcodeParts {
  ShortcodeParts(this.name, this.attributes);

  final String name;
  final Map<String, String> attributes;
}

final RegExp _shortcodePattern = RegExp(
  r'''\[\s*shortcode\s+(?:"([^"]+)"|'([^']+)'|(\S+))((?:\s+[\w-]+\s*(?:=|:)\s*(?:"[^"]*"|'[^']*'|[^\s\]]+))*)\s*\]''',
  multiLine: true,
);

final RegExp _shortcodeArgsPattern = RegExp(
  r'''^\s*(?:"([^"]+)"|'([^']+)'|(\S+))(.*)$''',
);

final RegExp _shortcodeAttributePattern = RegExp(
  r'''([\w-]+)\s*(?:=|:)\s*(?:"([^"]*)"|'([^']*)'|([^\s"']+))''',
);

final RegExp _fencePattern = RegExp(r'^\s*(```|~~~)');
final RegExp _rawStartPattern = RegExp(r'{%\s*raw\s*%}');
final RegExp _rawEndPattern = RegExp(r'{%\s*endraw\s*%}');

bool containsShortcode(String content) {
  if (content.isEmpty) return false;
  return _shortcodePattern.hasMatch(content);
}

String replaceShortcodesWithLiquid(String content) {
  if (content.isEmpty) return content;

  final lines = content.split('\n');
  final buffer = StringBuffer();
  var inFence = false;
  var fenceMarker = '';
  var inRaw = false;

  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    final fenceMatch = _fencePattern.firstMatch(line);
    if (fenceMatch != null && !inRaw) {
      final marker = fenceMatch.group(1) ?? '';
      if (!inFence) {
        inFence = true;
        fenceMarker = marker;
      } else if (marker == fenceMarker) {
        inFence = false;
        fenceMarker = '';
      }
      buffer.write(line);
      if (i < lines.length - 1) buffer.write('\n');
      continue;
    }

    if (inFence) {
      buffer.write(line);
      if (i < lines.length - 1) buffer.write('\n');
      continue;
    }

    buffer.write(
      _replaceShortcodesOutsideRaw(line, inRaw, (value) {
        inRaw = value;
      }),
    );
    if (i < lines.length - 1) buffer.write('\n');
  }

  return buffer.toString();
}

String _replaceShortcodesOutsideRaw(
  String line,
  bool inRaw,
  void Function(bool value) setInRaw,
) {
  var remaining = line;
  final buffer = StringBuffer();

  if (inRaw) {
    final endMatch = _rawEndPattern.firstMatch(remaining);
    if (endMatch == null) {
      buffer.write(remaining);
      return buffer.toString();
    }
    buffer.write(remaining.substring(0, endMatch.end));
    remaining = remaining.substring(endMatch.end);
    setInRaw(false);
  }

  while (true) {
    final startMatch = _rawStartPattern.firstMatch(remaining);
    if (startMatch == null) {
      buffer.write(_replaceShortcodesInSegment(remaining));
      break;
    }

    final before = remaining.substring(0, startMatch.start);
    buffer.write(_replaceShortcodesInSegment(before));

    final afterStart = remaining.substring(startMatch.start);
    final endMatch = _rawEndPattern.firstMatch(afterStart);
    if (endMatch == null) {
      buffer.write(afterStart);
      setInRaw(true);
      break;
    }

    buffer.write(afterStart.substring(0, endMatch.end));
    remaining = afterStart.substring(endMatch.end);
  }

  return buffer.toString();
}

String _replaceShortcodesInSegment(String segment) {
  return segment.replaceAllMapped(_shortcodePattern, (match) {
    final name = match[1] ?? match[2] ?? match[3];
    if (name == null || name.isEmpty) return match[0] ?? '';
    final attributes = parseShortcodeAttributes(match[4]);
    return buildShortcodeTag(name, attributes);
  });
}

ShortcodeParts parseShortcodeArgs(String raw) {
  final match = _shortcodeArgsPattern.firstMatch(raw);
  if (match == null) {
    throw FormatException('Invalid shortcode syntax: $raw');
  }
  final name = match[1] ?? match[2] ?? match[3];
  if (name == null || name.isEmpty) {
    throw FormatException('Shortcode name is required: $raw');
  }
  final attributes = parseShortcodeAttributes(match[4]);
  return ShortcodeParts(name, attributes);
}

Map<String, String> parseShortcodeAttributes(String? attributesString) {
  final attributes = <String, String>{};

  if (attributesString == null || attributesString.trim().isEmpty) {
    return attributes;
  }

  for (final match in _shortcodeAttributePattern.allMatches(attributesString)) {
    final key = match[1];
    if (key == null || key.isEmpty) continue;
    final value = match[2] ?? match[3] ?? match[4] ?? '';
    attributes[key] = value;
  }

  return attributes;
}

String buildShortcodeTag(String name, Map<String, String> attributes) {
  final buffer = StringBuffer("{% shortcode '${_escapeName(name)}'");
  for (final entry in attributes.entries) {
    buffer.write(' ${entry.key}=${_quoteValue(entry.value)}');
  }
  buffer.write(' %}');
  return buffer.toString();
}

String buildRenderTag(String name, Map<String, String> attributes) {
  final buffer = StringBuffer("{%- render '${_escapeName(name)}'");
  for (final entry in attributes.entries) {
    buffer.write(', ${entry.key}: ${_quoteValue(entry.value)}');
  }
  buffer.write(' -%}');
  return buffer.toString();
}

String _quoteValue(String value) {
  if (!value.contains("'")) {
    return "'$value'";
  }
  final escaped = value.replaceAll('"', '\\"');
  return '"$escaped"';
}

String _escapeName(String name) {
  return name.replaceAll("'", "\\'");
}

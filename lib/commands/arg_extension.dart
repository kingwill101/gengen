import 'package:artisanal/args.dart';

extension ArgResultExtension on ArgResults {
  Map<String, dynamic> get map => _config();

  Map<String, dynamic> _config() {
    final results = <String, dynamic>{};

    for (var element in options) {
      if (element == "help") continue;
      if (!wasParsed(element)) continue;

      final value = this[element];
      if (value == null) continue;

      if (element == "config") {
        final raw = value.toString().trim();
        if (raw.isEmpty) continue;
        results[element] = raw
            .split(",")
            .map((entry) => entry.trim())
            .where((entry) => entry.isNotEmpty)
            .toList();
        continue;
      }

      results[element] = value;
    }

    return results;
  }
}

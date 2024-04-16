import 'package:args/args.dart';

extension ArgResultExtension on ArgResults {
  Map<String, dynamic> get map => _config();

  Map<String, dynamic> _config() {
    Map<String, dynamic> results = {};

    for (var element in options) {
      if (element == "help") continue;
      results[element] =
          element == "config" ? this[element].split(",") : this[element];
    }

    return results;
  }
}

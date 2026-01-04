import 'package:lualike/lualike.dart';

Value wrapDynamic(dynamic value) {
  if (value is Value) return value;
  if (value == null) return Value(null);
  if (value is num || value is String || value is bool) return Value(value);

  if (value is List) {
    return Value(value.map(wrapDynamic).toList(growable: false));
  }

  if (value is Map) {
    return Value(
      Map<String, dynamic>.fromEntries(
        value.entries.map(
          (entry) => MapEntry(entry.key.toString(), wrapDynamic(entry.value)),
        ),
      ),
    );
  }

  return Value(value.toString());
}

Object? unwrapValue(Object? value) {
  if (value is Value) {
    return unwrapValue(value.raw);
  }
  if (value is LuaString) {
    return value.toString();
  }
  if (value is List) {
    return value.map(unwrapValue).toList();
  }
  if (value is Map) {
    return Map<String, dynamic>.fromEntries(
      value.entries.map(
        (entry) => MapEntry(entry.key.toString(), unwrapValue(entry.value)),
      ),
    );
  }
  return value;
}

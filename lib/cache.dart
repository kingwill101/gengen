import 'dart:convert'; // For converting strings to bytes
import 'package:crypto/crypto.dart';

Map<String, String> _cache = {};

mixin CacheMixin {
  // final _cache = <String, String>{};

  String? getFromCache(String key) {
    return _cache[key];
  }

  void cache(String key, String value) {
    // Convert value to a list of bytes and compute SHA-256 hash
    var bytes = utf8.encode(value);
    var digest = sha256.convert(bytes);

    // Store the SHA-256 hash as a string in the cache
    _cache[key] = digest.toString();
  }

  void invalidateCache(String key) {
    _cache.remove(key);
  }

  bool hasContentChanged(String key, String newValue) {
    // Convert newValue to a list of bytes and compute SHA-256 hash
    var newBytes = utf8.encode(newValue);
    var newDigest = sha256.convert(newBytes);

    // Retrieve the old hash from the cache
    var oldHash = getFromCache(key);

    // Compare the new hash with the old hash
    return oldHash != null && newDigest.toString() != oldHash;
  }
}

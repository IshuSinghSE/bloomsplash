import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SearchProvider extends ChangeNotifier {
  static const String _cacheBoxName = 'search_cache';
  Box? _cacheBox;

  Future<void> init() async {
    _cacheBox = await Hive.openBox(_cacheBoxName);
  }

  /// Returns cached results if available, otherwise calls [searchFn] and caches the result.
  /// Duration for cache expiry (default: 1 hour)
  Duration cacheExpiry = const Duration(hours: 1);

  Future<List<Map<String, dynamic>>> search(
    String query,
    Future<List<Map<String, dynamic>>> Function(String) searchFn,
  ) async {
    if (_cacheBox == null) await init();
    final cached = _cacheBox!.get(query);
    if (cached != null && cached is Map) {
      final dynamic data = cached['data'];
      final int? timestamp = cached['timestamp'];
      if (data != null && timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (DateTime.now().difference(cacheTime) < cacheExpiry) {
          // Cache is valid
          if (data is List<Map<String, dynamic>>) {
            return data;
          } else if (data is List) {
            // Convert each item to Map<String, dynamic>
            return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        } else {
          // Cache expired, remove
          await _cacheBox!.delete(query);
        }
      }
    }
    // Perform search and cache result with timestamp
    final result = await searchFn(query);
    await _cacheBox!.put(query, {
      'data': result,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    return result;
  }

  /// Optionally, clear cache for a query or all
  Future<void> clearCache([String? query]) async {
    if (_cacheBox == null) await init();
    if (query != null) {
      await _cacheBox!.delete(query);
    } else {
      await _cacheBox!.clear();
    }
    notifyListeners();
  }
}

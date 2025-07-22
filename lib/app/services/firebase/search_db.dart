import 'package:cloud_firestore/cloud_firestore.dart';

class SearchDb {
  /// Unified search across colors, tags, category, and name.
  /// Optimized for single-value search and case-insensitive matching.
  static Future<List<Map<String, dynamic>>> searchAllFields(String query, {int limit = 20}) async {
    final normalized = query.trim().toLowerCase();
    final List<Future<List<Map<String, dynamic>>>> futures = [
      searchByColor(normalized, limit: limit),
      searchByTag(normalized, limit: limit),
      searchByCategory(normalized, limit: limit),
      searchByName(normalized, limit: limit),
    ];
    final resultsList = await Future.wait(futures);
    // Merge and deduplicate by id
    final Map<String, Map<String, dynamic>> merged = {};
    for (var results in resultsList) {
      for (var wallpaper in results) {
        merged[wallpaper['id']] = wallpaper;
      }
    }
    return merged.values.toList();
  }

  /// Optimized: use arrayContains for single color value
  static Future<List<Map<String, dynamic>>> searchByColor(String color, {int limit = 20}) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('wallpapers')
        .where('colors', arrayContains: color)
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {'id': doc.id, ...data};
    }).toList();
  }

  /// Optimized: use arrayContains for single tag value
  static Future<List<Map<String, dynamic>>> searchByTag(String tag, {int limit = 20}) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('wallpapers')
        .where('tags', arrayContains: tag)
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {'id': doc.id, ...data};
    }).toList();
  }

  /// Optimized: lowercase for category
  static Future<List<Map<String, dynamic>>> searchByCategory(String category, {int limit = 20}) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('wallpapers')
        .where('category', isEqualTo: category.toLowerCase())
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {'id': doc.id, ...data};
    }).toList();
  }

  /// Optimized: lowercase for name
  static Future<List<Map<String, dynamic>>> searchByName(String name, {int limit = 20}) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('wallpapers')
        .where('name', isEqualTo: name.toLowerCase())
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {'id': doc.id, ...data};
    }).toList();
  }
  static Future<List<Map<String, dynamic>>> fetchWallpapers({int limit = 20}) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('wallpapers')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          return {'id': doc.id, ...data};
        })
        .where((wallpaper) => wallpaper['status'] == 'approved')
        .toList();
  }
}

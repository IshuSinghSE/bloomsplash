import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class CacheService {
  /// Calculates the total size of the temporary cache directory.
  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        final size = cacheDir
            .listSync(recursive: true)
            .whereType<File>()
            .fold<int>(0, (sum, file) => sum + file.lengthSync());
        return size;
      }
      return 0;
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      return 0; // Return 0 on error
    }
  }

  /// Deletes the temporary cache directory and all its contents.
  /// Returns true if successful, false otherwise.
  static Future<bool> clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        return true;
      }
      return true; // Directory didn't exist, so it's "cleared"
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      return false;
    }
  }
}
import 'dart:io'; // Import for Directory and File
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// A utility function to cache a list of image URLs using `flutter_cache_manager`.
Future<void> cacheImages(List<String> imageUrls) async {
  final cacheManager = DefaultCacheManager();
  for (var url in imageUrls) {
    if (url.startsWith('http')) {
      await cacheManager.getSingleFile(url);
    }
  }
}

/// A utility function to clear the image cache.
Future<void> clearImageCache() async {
  final cacheManager = DefaultCacheManager();
  await cacheManager.emptyCache();
}

/// A utility function to calculate the size of the image cache.
Future<int> calculateCacheSize() async {
  final cacheManager = DefaultCacheManager();
  final fileInfo = await cacheManager.getFileFromCache(''); // Retrieve the cache file info
  final cacheDirectory = fileInfo != null ? Directory(fileInfo.file.path) : null; // Use Directory from dart:io

  if (cacheDirectory != null && await cacheDirectory.exists()) {
    return cacheDirectory
        .listSync(recursive: true)
        .whereType<File>() // Use File from dart:io
        .fold<int>(0, (sum, file) => sum + file.lengthSync());
  }
  return 0;
}

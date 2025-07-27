// import 'dart:convert';
import 'package:csv/csv.dart';
// import 'package:path/path.dart' as p;
import '../../models/wallpaper_model.dart';

List<Wallpaper> parseWallpapersFromCsv(String csvContent) {
  final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
      .convert(csvContent, eol: '\n');
  final headers = rows.first.cast<String>();
  final wallpapers = <Wallpaper>[];

  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    final data = Map<String, String>.fromIterables(
      headers,
      row.map((e) => e.toString()),
    );

    // Generate image path (assume .jpg, adjust if needed)
    final filename = data['filename'] ?? '';
    final imagePath = 'wallpapers/${filename.padLeft(3, '0')}.jpg';

    wallpapers.add(
      Wallpaper(
        id: '', // Generate or assign as needed
        name: data['title'] ?? '',
        imageUrl: imagePath,
        thumbnailUrl: '', // Generate or assign as needed
        downloads: 0,
        likes: 0,
        size: 0,
        resolution: '',
        orientation: '',
        category: data['category'] ?? '',
        tags: (data['tags'] ?? '').split(',').map((e) => e.trim()).toList(),
        colors: [],
        author: '',
        authorImage: '',
        description: data['description'] ?? '',
        isPremium: false,
        isAIgenerated: false,
        status: 'active',
        createdAt: DateTime.now().toIso8601String(),
        license: '',
        hash: '',
        collectionId: null,
      ),
    );
  }
  return wallpapers;
}
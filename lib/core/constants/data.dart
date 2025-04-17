import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';

late final List<Map<String, dynamic>> wallpapers;
/* {
    "id": "cbaf80ef-c597-47a0-9d02-2816699ae78c",
    "name": "Wallpaper 98",
    "image": "assets/sample/1744480268300.png",
    "thumbnail": "assets/sample/1744480268300.png",
    "preview": "assets/sample/1744480268300.png",
    "downloads": 1970,
    "size": "2.5 MB",
    "resolution": "2560x1440",
    "category": "Urban",
    "author": "Author 98",
    "authorImage": "assets/avatar/WeatherBug.png",
    "description": "A mesmerizing view of the night sky."
  },
*/
Future<void> loadWallpapers() async {
  try {
    log('Loading wallpapers...');
    final jsonString = await rootBundle.loadString('assets/wallpapers.json');
    log('JSON file loaded successfully.');

    wallpapers = List<Map<String, dynamic>>.from(jsonDecode(jsonString));
    log('Wallpapers parsed successfully. Count: ${wallpapers.length}');

    categoryWallpapers.addAll({
      for (var category in ["Nature", "Abstract", "Urban", "Adventure", "Space"])
        category: wallpapers.where((wallpaper) => wallpaper["category"] == category).toList(),
    });
    log('Category wallpapers generated successfully.');
  } catch (e) {
    log('Error loading wallpapers: $e'); // Debugging statement
    wallpapers = []; // Fallback to an empty list
  }
}

final Map<String, List<Map<String, dynamic>>> categoryWallpapers = {};

final List<Map<String, String>> categories = [
  {
    "title": "Nature",
    "image": "assets/sample/1744480267976.png",
  },
  {
    "title": "Abstract",
    "image": "assets/sample/1744480267990.png",
  },
  {
    "title": "Urban",
    "image": "assets/sample/1744480268003.png",
  },
  {
    "title": "Adventure",
    "image": "assets/sample/1744480268028.png",
  },
  {
    "title": "Space",
    "image": "assets/sample/1744480268040.png",
  },
];



final Map<String, List<Map<String, dynamic>>> collections = {
  "Featured": [
    {
      "title": "Autumn Hues",
      "image": "assets/sample/1744480267976.png",
      "author": "Author 1",
      "wallpapers": wallpapers.take(4).toList(), // Dynamically take up to 4 wallpapers
    },
    {
      "title": "Monochrome Series",
      "image": "assets/sample/1744480267990.png",
      "author": "Author 2",
      "wallpapers": wallpapers.skip(4).take(5).toList(), // Skip first 4, take next 5
    },
    {
      "title": "Dreamy Landscapes",
      "image": "assets/sample/1744480268003.png",
      "author": "Author 3",
      "wallpapers": wallpapers.skip(9).take(5).toList(), // Skip first 9, take next 5
    },
    {
      "title": "Urban Vibes",
      "image": "assets/sample/1744480268028.png",
      "author": "Author 4",
      "wallpapers": wallpapers.skip(14).take(5).toList(), // Skip first 14, take next 5
    },
    {
      "title": "Abstract Art",
      "image": "assets/sample/1744480268040.png",
      "author": "Author 5",
      "wallpapers": wallpapers.skip(19).take(5).toList(), // Skip first 19, take next 5
    },
  ],
  "Popular": [
    {
      "title": "Nature Escapes",
      "image": "assets/sample/1744480268053.png",
      "author": "Author 6",
      "wallpapers": wallpapers.skip(24).take(5).toList(), // Skip first 24, take next 5
    },
    {
      "title": "Cyber Aesthetic",
      "image": "assets/sample/1744480268070.png",
      "author": "Author 7",
      "wallpapers": wallpapers.skip(29).take(5).toList(), // Skip first 29, take next 5
    },
    {
      "title": "Space Wonders",
      "image": "assets/sample/1744480268085.png",
      "author": "Author 8",
      "wallpapers": wallpapers.skip(34).take(5).toList(), // Skip first 34, take next 5
    },
    {
      "title": "Minimalist Designs",
      "image": "assets/sample/1744480268103.png",
      "author": "Author 9",
      "wallpapers": wallpapers.skip(39).take(5).toList(), // Skip first 39, take next 5
    },
    {
      "title": "Colorful Patterns",
      "image": "assets/sample/1744480268117.png",
      "author": "Author 10",
      "wallpapers": wallpapers.skip(44).take(5).toList(), // Skip first 44, take next 5
    },
  ],
  "Monochrome": [
    {
      "title": "Black & White",
      "image": "assets/sample/1744480268142.png",
      "author": "Author 11",
      "wallpapers": wallpapers.skip(49).take(5).toList(), // Skip first 49, take next 5
    },
    {
      "title": "Shades of Grey",
      "image": "assets/sample/1744480268170.png",
      "author": "Author 12",
      "wallpapers": wallpapers.skip(54).take(5).toList(), // Skip first 54, take next 5
    },
    {
      "title": "Classic Monochrome",
      "image": "assets/sample/1744480268188.png",
      "author": "Author 13",
      "wallpapers": wallpapers.skip(59).take(5).toList(), // Skip first 59, take next 5
    },
    {
      "title": "Dark Elegance",
      "image": "assets/sample/1744480268211.png",
      "author": "Author 14",
      "wallpapers": wallpapers.skip(64).take(5).toList(), // Skip first 64, take next 5
    },
    {
      "title": "Light & Shadow",
      "image": "assets/sample/1744480268231.png",
      "author": "Author 15",
      "wallpapers": wallpapers.skip(69).take(5).toList(), // Skip first 69, take next 5
    },
  ],
};


/////////////////////////////////////////////////////////////////////////////////////////////////

// TODO: Add more curated collections as needed
final List<Map<String, String>> curatedCollections = [
  {
    "title": "Bloom Vibes",
    "image": "assets/sample/1744480267976.png", // Replace with actual image paths
  },
  {
    "title": "Cyber Aesthetic",
    "image": "assets/sample/1744480267990.png", // Replace with actual image paths
  },
  {
    "title": "Nature Escapes",
    "image": "assets/sample/1744480268003.png", // Replace with actual image paths
  },
  {
    "title": "Abstract Art",
    "image": "assets/sample/1744480268028.png", // Replace with actual image paths
  },
  {
    "title": "Urban Vibes",
    "image": "assets/sample/1744480268040.png", // Replace with actual image paths
  },
  {
    "title": "Adventure Awaits",
    "image": "assets/sample/1744480268053.png", // Replace with actual image paths
  },
  {
    "title": "Space Wonders",
    "image": "assets/sample/1744480268070.png", // Replace with actual image paths
  },
  {
    "title": "Minimalist Designs",
    "image": "assets/sample/1744480268085.png", // Replace with actual image paths
  },
  {
    "title": "Colorful Patterns",
    "image": "assets/sample/1744480268103.png", // Replace with actual image paths
  },
  {
    "title": "Vintage Aesthetic",
    "image": "assets/sample/1744480268117.png", // Replace with actual image paths
  },
  {
    "title": "Fantasy Worlds",
    "image": "assets/sample/1744480268142.png", // Replace with actual image paths
  },
  {
    "title": "Dark Themes",
    "image": "assets/sample/1744480268170.png", // Replace with actual image paths
  },
  {
    "title": "Light Themes",
    "image": "assets/sample/1744480268188.png", // Replace with actual image paths
  },
  {
    "title": "Nature's Beauty",
    "image": "assets/sample/1744480268211.png", // Replace with actual image paths
  },
  {
    "title": "Artistic Expressions",
    "image": "assets/sample/1744480268231.png", // Replace with actual image paths
  },
  {
    "title": "Tech Inspirations",
    "image": "assets/sample/1744480268259.png", // Replace with actual image paths
  },  
  {
    "title": "Dreamy Landscapes",
    "image": "assets/sample/1744480268279.png", // Replace with actual image paths
  },
  {
    "title": "Ocean Views",
    "image": "assets/sample/1744480268300.png", // Replace with actual image paths
  },
  {
    "title": "Mountain Peaks",
    "image": "assets/sample/1744480268319.png", // Replace with actual image paths
  },
  {
    "title": "City Lights",
    "image": "assets/sample/1744480268333.png", // Replace with actual image paths
  },
];

final Map<String, List<Map<String, dynamic>>> curatedCollectionsWallpapers = {
  "Bloom Vibes": List.generate(10, (index) {
    return {
      "title": "Boom Vibes ${index + 1}",
      "image": "assets/sample/17444802680${10 + index}.png",
    };
  }),
  "Cyber Aesthetic": List.generate(10, (index) {
    return {
      "title": "Cyber Wallpaper ${index + 1}",
      "image": "assets/sample/17444802680${10 + index}.png",
    };
  }),
  "Nature Escapes": List.generate(10, (index) {
    return {
      "title": "Nature Wallpaper ${index + 1}",
      "image": "assets/sample/17444802681${10 + index}.png",
    };
  }),
  "Abstract Art": List.generate(10, (index) {
    return {
      "title": "Abstract Wallpaper ${index + 1}",
      "image": "assets/sample/17444802682${10 + index}.png",
    };
  }),
  "Urban Vibes": List.generate(10, (index) {
    return {
      "title": "Urban Wallpaper ${index + 1}",
      "image": "assets/sample/17444802683${10 + index}.png",
    };
  }),
};

//////////////////////////////////////////////////////////////////////////////////////////////////
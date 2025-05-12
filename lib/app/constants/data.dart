import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';

List<Map<String, dynamic>> wallpapers = []; // Remove 'final' to allow reassignment

Future<void> loadWallpapers() async {
  try {
    log('Loading wallpapers...');
    final jsonString = await rootBundle.loadString('assets/wallpapers.json');
    log('JSON file loaded successfully.');

    wallpapers = List<Map<String, dynamic>>.from(jsonDecode(jsonString)).take(10).toList();
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
    "image": "assets/images/placeholder.webp",
  },
  {
    "title": "Abstract",
    "image": "assets/images/placeholder.webp",
  },
  {
    "title": "Urban",
    "image": "assets/images/placeholder.webp",
  },
  {
    "title": "Adventure",
    "image": "assets/images/placeholder.webp",
  },
  {
    "title": "Space",
    "image": "assets/images/placeholder.webp",
  },
];



final Map<String, List<Map<String, dynamic>>> collections = {
  "Featured": [
    {
      "title": "Autumn Hues",
      "image": "assets/images/placeholder.webp",
      "author": "Author 1",
      "wallpapers": wallpapers.take(4).toList(), // Dynamically take up to 4 wallpapers
    },
    {
      "title": "Monochrome Series",
      "image": "assets/images/placeholder.webp",
      "author": "Author 2",
      "wallpapers": wallpapers.skip(4).take(5).toList(), // Skip first 4, take next 5
    },
    {
      "title": "Dreamy Landscapes",
      "image": "assets/images/placeholder.webp",
      "author": "Author 3",
      "wallpapers": wallpapers.skip(9).take(5).toList(), // Skip first 9, take next 5
    },
    {
      "title": "Urban Vibes",
      "image": "assets/images/placeholder.webp",
      "author": "Author 4",
      "wallpapers": wallpapers.skip(14).take(5).toList(), // Skip first 14, take next 5
    },
    {
      "title": "Abstract Art",
      "image": "assets/images/placeholder.webp",
      "author": "Author 5",
      "wallpapers": wallpapers.skip(19).take(5).toList(), // Skip first 19, take next 5
    },
  ],
  "Popular": [
    {
      "title": "Nature Escapes",
      "image": "assets/images/placeholder.webp",
      "author": "Author 6",
      "wallpapers": wallpapers.skip(24).take(5).toList(), // Skip first 24, take next 5
    },
    {
      "title": "Cyber Aesthetic",
      "image": "assets/images/placeholder.webp",
      "author": "Author 7",
      "wallpapers": wallpapers.skip(29).take(5).toList(), // Skip first 29, take next 5
    },
    {
      "title": "Space Wonders",
      "image": "assets/images/placeholder.webp",
      "author": "Author 8",
      "wallpapers": wallpapers.skip(34).take(5).toList(), // Skip first 34, take next 5
    },
    {
      "title": "Minimalist Designs",
      "image": "assets/images/placeholder.webp",
      "author": "Author 9",
      "wallpapers": wallpapers.skip(39).take(5).toList(), // Skip first 39, take next 5
    },
    {
      "title": "Colorful Patterns",
      "image": "assets/images/placeholder.webp",
      "author": "Author 10",
      "wallpapers": wallpapers.skip(44).take(5).toList(), // Skip first 44, take next 5
    },
  ],
  "Monochrome": [
    {
      "title": "Black & White",
      "image": "assets/images/placeholder.webp",
      "author": "Author 11",
      "wallpapers": wallpapers.skip(49).take(5).toList(), // Skip first 49, take next 5
    },
    {
      "title": "Shades of Grey",
      "image": "assets/images/placeholder.webp",
      "author": "Author 12",
      "wallpapers": wallpapers.skip(54).take(5).toList(), // Skip first 54, take next 5
    },
    {
      "title": "Classic Monochrome",
      "image": "assets/images/placeholder.webp",
      "author": "Author 13",
      "wallpapers": wallpapers.skip(59).take(5).toList(), // Skip first 59, take next 5
    },
    {
      "title": "Dark Elegance",
      "image": "assets/images/placeholder.webp",
      "author": "Author 14",
      "wallpapers": wallpapers.skip(64).take(5).toList(), // Skip first 64, take next 5
    },
    {
      "title": "Light & Shadow",
      "image": "assets/images/placeholder.webp",
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
    "image": "assets/images/placeholder.webp", // Replace with actual image paths
  },
  {
    "title": "Cyber Aesthetic",
    "image": "assets/images/placeholder.webp", // Replace with actual image paths
  },
  {
    "title": "Nature Escapes",
    "image": "assets/images/placeholder.webp", // Replace with actual image paths
  },
  {
    "title": "Abstract Art",
    "image": "assets/images/placeholder.webp", // Replace with actual image paths
  },
  {
    "title": "Urban Vibes",
    "image": "assets/images/placeholder.webp", // Replace with actual image paths
  },
  {
    "title": "Adventure Awaits",
    "image": "assets/images/placeholder.webp", // Replace with actual image paths
  },
  {
    "title": "Space Wonders",
    "image": "assets/images/placeholder.webp", // Replace with actual image paths
  },
  {
    "title": "Minimalist Designs",
    "image": "assets/images/placeholder.webp", // Replace with actual image paths
  },
  {
    "title": "Colorful Patterns",
    "image": "assets/images/placeholder.webp", // Replace with actual image paths
  },
  {
    "title": "Vintage Aesthetic",
    "image": "assets/images/placeholder.webp", // Replace with actual image paths
  },
  {
    "title": "Fantasy Worlds",
    "image": "assets/images/placeholder.webp", // Replace with actual image paths
  },
  {
    "title": "Dark Themes",
    "image": "assets/images/placeholder.webp", // Replace with actual image paths
  },
  {
    "title": "Light Themes",
    "image": "assets/images/placeholder.webp", // Replace with actual image paths
  },
  {
    "title": "Nature's Beauty",
    "image": "assets/images/placeholder.webp", // Replace with actual image paths
  },
  {
    "title": "Artistic Expressions",
    "image": "assets/images/placeholder.webp", // Replace with actual image paths
  },
  {
    "title": "Tech Inspirations",
    "image": "assets/images/placeholder.webp", // Replace with actual image paths
  },  
  {
    "title": "Dreamy Landscapes",
    "image": "assets/images/placeholder.webp", // Replace with actual image paths
  },
  {
    "title": "Ocean Views",
    "image": "assets/images/placeholder.webp", // Replace with actual image paths
  },
  {
    "title": "Mountain Peaks",
    "image": "assets/images/placeholder.webp", // Replace with actual image paths
  },
  {
    "title": "City Lights",
    "image": "assets/images/placeholder.webp", // Replace with actual image paths
  },
];

final Map<String, List<Map<String, dynamic>>> curatedCollectionsWallpapers = {
  "Bloom Vibes": List.generate(10, (index) {
    return {
      "title": "Boom Vibes ${index + 1}",
      "image": "assets/images/placeholder.webp",
    };
  }),
  "Cyber Aesthetic": List.generate(10, (index) {
    return {
      "title": "Cyber Wallpaper ${index + 1}",
      "image": "assets/images/placeholder.webp",
    };
  }),
  "Nature Escapes": List.generate(10, (index) {
    return {
      "title": "Nature Wallpaper ${index + 1}",
      "image": "assets/images/placeholder.webp",
    };
  }),
  "Abstract Art": List.generate(10, (index) {
    return {
      "title": "Abstract Wallpaper ${index + 1}",
      "image": "assets/images/placeholder.webp",
    };
  }),
  "Urban Vibes": List.generate(10, (index) {
    return {
      "title": "Urban Wallpaper ${index + 1}",
      "image": "assets/images/placeholder.webp",
    };
  }),
};

//////////////////////////////////////////////////////////////////////////////////////////////////
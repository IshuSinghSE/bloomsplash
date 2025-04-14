import 'dart:convert';
import 'dart:io';

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
  // Load the JSON file
  final file = File('/home/ashu/Code/flutter/flutter_application_1/lib/constants/wallpapers.json');
  final jsonString = await file.readAsString();

  // Parse the JSON string into a list of wallpapers
  wallpapers = List<Map<String, dynamic>>.from(jsonDecode(jsonString));
}

// Generate wallpapers for each category
final Map<String, List<Map<String, dynamic>>> categoryWallpapers = {
  for (var category in ["Nature", "Abstract", "Urban", "Adventure", "Space"])
    category: wallpapers.where((wallpaper) => wallpaper["category"] == category).toList(),
};

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
      "wallpapers": wallpapers.sublist(0, 5), // Wallpapers to display
    },
    {
      "title": "Monochrome Series",
      "image": "assets/sample/1744480267990.png",
      "author": "Author 2",
      "wallpapers": wallpapers.sublist(5, 10), // Wallpapers to display
    },
    {
      "title": "Dreamy Landscapes",
      "image": "assets/sample/1744480268003.png",
      "author": "Author 3",
      "wallpapers": wallpapers.sublist(10, 15), // Wallpapers to display
    },
    {
      "title": "Urban Vibes",
      "image": "assets/sample/1744480268028.png",
      "author": "Author 4",
      "wallpapers": wallpapers.sublist(15, 20), // Wallpapers to display
    },
    {
      "title": "Abstract Art",
      "image": "assets/sample/1744480268040.png",
      "author": "Author 5",
      "wallpapers": wallpapers.sublist(20, 25), // Wallpapers to display
    },
  ],
  "Popular": [
    {
      "title": "Nature Escapes",
      "image": "assets/sample/1744480268053.png",
      "author": "Author 6",
      "wallpapers": wallpapers.sublist(25, 30), // Wallpapers to display
    },
    {
      "title": "Cyber Aesthetic",
      "image": "assets/sample/1744480268070.png",
      "author": "Author 7",
      "wallpapers": wallpapers.sublist(30, 35), // Wallpapers to display
    },
    {
      "title": "Space Wonders",
      "image": "assets/sample/1744480268085.png",
      "author": "Author 8",
      "wallpapers": wallpapers.sublist(35, 40), // Wallpapers to display
    },
    {
      "title": "Minimalist Designs",
      "image": "assets/sample/1744480268103.png",
      "author": "Author 9",
      "wallpapers": wallpapers.sublist(40, 45), // Wallpapers to display
    },
    {
      "title": "Colorful Patterns",
      "image": "assets/sample/1744480268117.png",
      "author": "Author 10",
      "wallpapers": wallpapers.sublist(45, 50), // Wallpapers to display
    },
  ],
  "Monochrome": [
    {
      "title": "Black & White",
      "image": "assets/sample/1744480268142.png",
      "author": "Author 11",
      "wallpapers": wallpapers.sublist(50, 55), // Wallpapers to display
    },
    {
      "title": "Shades of Grey",
      "image": "assets/sample/1744480268170.png",
      "author": "Author 12",
      "wallpapers": wallpapers.sublist(55, 60), // Wallpapers to display
    },
    {
      "title": "Classic Monochrome",
      "image": "assets/sample/1744480268188.png",
      "author": "Author 13",
      "wallpapers": wallpapers.sublist(60, 65), // Wallpapers to display
    },
    {
      "title": "Dark Elegance",
      "image": "assets/sample/1744480268211.png",
      "author": "Author 14",
      "wallpapers": wallpapers.sublist(65, 70), // Wallpapers to display
    },
    {
      "title": "Light & Shadow",
      "image": "assets/sample/1744480268231.png",
      "author": "Author 15",
      "wallpapers": wallpapers.sublist(70, 75), // Wallpapers to display
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

// TODO: Add more curated collections as needed
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
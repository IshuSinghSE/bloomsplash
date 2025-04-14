import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';

void main() {
  generateWallpapersJson();
}


void generateWallpapersJson() {
  // Add the method body here or move this function outside the class if it doesn't belong to 'FavoritesProvider'.
  final uuid = Uuid();

  final sampleImages = [
    "assets/sample/1744480267976.png",
    "assets/sample/1744480267990.png",
    "assets/sample/1744480268003.png",
    "assets/sample/1744480268028.png",
    "assets/sample/1744480268040.png",
    "assets/sample/1744480268053.png",
    "assets/sample/1744480268070.png",
    "assets/sample/1744480268085.png",
    "assets/sample/1744480268103.png",
    "assets/sample/1744480268117.png",
    "assets/sample/1744480268142.png",
    "assets/sample/1744480268170.png",
    "assets/sample/1744480268188.png",
    "assets/sample/1744480268211.png",
    "assets/sample/1744480268231.png",
    "assets/sample/1744480268259.png",
    "assets/sample/1744480268279.png",
    "assets/sample/1744480268300.png",
    "assets/sample/1744480268319.png",
    "assets/sample/1744480268333.png",
  ];

  final categories = [
    "Nature",
    "Abstract",
    "Urban",
    "Adventure",
    "Space",
  ];

  final descriptions = [
    "A beautiful and serene wallpaper to enhance your screen.",
    "A vibrant and colorful design to brighten your day.",
    "A mesmerizing view of the night sky.",
    "A breathtaking view of nature's beauty.",
    "A relaxing and calming wallpaper for your device.",
  ];

  final authorImages = [
    "assets/avatar/Balsamiq.png",
    "assets/avatar/Bear.png",
    "assets/avatar/BlueJ.png",
    "assets/avatar/Itsycal.png",
    "assets/avatar/Carto.png",
    "assets/avatar/Cyberduck.png",
    "assets/avatar/HandShaker.png",
    "assets/avatar/HazeOver.png",
    "assets/avatar/Ivory.png",
    "assets/avatar/LanScan.png",
    "assets/avatar/NightOwl.png",
    "assets/avatar/PopcornTime.png",
    "assets/avatar/Vysor.png",
    "assets/avatar/WeatherBug.png",
  ];

  // Generate 100 wallpapers
  final wallpapers = List.generate(100, (index) {
    return {
      "id": uuid.v4(), // Generate a unique UUID for each wallpaper
      "name": "Wallpaper ${index + 1}",
      "image": sampleImages[index % sampleImages.length],
      "thumbnail": sampleImages[index % sampleImages.length],
      "preview": sampleImages[index % sampleImages.length],
      "downloads": (500 + index * 10) % 5000 + 500, // Random downloads
      "size": "${(1.5 + (index % 5) * 0.5).toStringAsFixed(1)} MB", // Random size
      "resolution": "${1920 + (index % 3) * 640}x${1080 + (index % 3) * 360}", // Random resolution
      "category": categories[index % categories.length],
      "author": "Author ${index + 1}",
      "authorImage": authorImages[index % authorImages.length],
      "description": descriptions[index % descriptions.length],
    };
  });

  // Convert the wallpapers list to JSON
  final jsonString = jsonEncode(wallpapers);

  // Write the JSON string to a file
  final file = File('/home/ashu/Code/flutter/flutter_application_1/lib/constants/wallpapers.json');
  file.writeAsStringSync(jsonString);

  print('wallpapers.json has been generated successfully!');
}



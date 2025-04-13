import 'package:flutter/material.dart';

final List<Map<String, dynamic>> wallpapers = List.generate(100, (index) {
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

  final authorImages = [
    "assets/avatar/Itsycal.png",
    "assets/avatar/Bear.png",
    "assets/avatar/Carto.png",
    "assets/avatar/BlueJ.png",
    "assets/avatar/Cyberduck.png",
    "assets/avatar/DuckieTV.png",
    "assets/avatar/NightOwl.png",
    "assets/avatar/PopcornTIme.png",
    "assets/avatar/Vysor.png",
    "assets/avatar/WeatherBug.png",
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

  return {
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
    "favorites": (100 + index * 5) % 1000 + 100, // Random favorites
    "paletteColors": [
      const Color(0xFFFFA726), // Orange
      const Color(0xFFFB8C00), // Deep Orange
      const Color(0xFFEF6C00), // Dark Orange
    ],
  };
});
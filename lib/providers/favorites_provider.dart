import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class FavoritesProvider extends ChangeNotifier {
  final Box<Map> _favoritesBox = Hive.box<Map>('favorites');

  // Getter to access the favorites
  List<Map<String, dynamic>> get favorites =>
      _favoritesBox.values.map((e) => Map<String, dynamic>.from(e)).toList();

  // Method to add a wallpaper to favorites
  void addFavorite(Map<String, dynamic> wallpaper) {
    if (!_favoritesBox.values.any((fav) => fav['id'] == wallpaper['id'])) {
      _favoritesBox.add(wallpaper);
      notifyListeners(); // Notify listeners about the change
    }
  }

  // Method to remove a wallpaper from favorites
  void removeFavorite(Map<String, dynamic> wallpaper) {
    final key = _favoritesBox.keys.firstWhere(
      (k) => _favoritesBox.get(k)?['id'] == wallpaper['id'],
      orElse: () => null,
    );
    if (key != null) {
      _favoritesBox.delete(key);
      notifyListeners(); // Notify listeners about the change
    }
  }

  // Method to toggle a wallpaper's favorite status
  void toggleFavorite(Map<String, dynamic> wallpaper) {
    if (_favoritesBox.values.any((fav) => fav['id'] == wallpaper['id'])) {
      removeFavorite(wallpaper);
    } else {
      addFavorite(wallpaper);
    }
  }

  // Method to check if a wallpaper is a favorite
  bool isFavorite(Map<String, dynamic> wallpaper) {
    return _favoritesBox.values.any((fav) => fav['id'] == wallpaper['id']);
  }
}
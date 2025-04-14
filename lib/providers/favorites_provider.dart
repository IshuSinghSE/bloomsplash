import 'package:flutter/material.dart';

class FavoritesProvider extends ChangeNotifier {
  final Map<int, bool> _favorites = {}; // Store favorite states by wallpaper index

  bool isFavorite(int index) {
    return _favorites[index] ?? false; // Return false if the index is not in the map
  }

  void toggleFavorite(int index) {
    _favorites[index] = !(_favorites[index] ?? false); // Toggle the favorite state
    notifyListeners(); // Notify listeners about the state change
  }
}
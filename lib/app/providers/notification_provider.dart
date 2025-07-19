import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  String? _wallpaperTitle;

  String? get wallpaperTitle => _wallpaperTitle;

  void showWallpaperNotification(String title) {
    _wallpaperTitle = title;
    notifyListeners();
  }

  void clearNotification() {
    _wallpaperTitle = null;
    notifyListeners();
  }
}
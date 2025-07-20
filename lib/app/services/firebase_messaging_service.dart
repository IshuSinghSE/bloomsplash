import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize(Function(String wallpaperTitle) onNewWallpaper) async {
    await _messaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.data['wallpaper_title'] ?? 'New Wallpaper';
      onNewWallpaper(title);
    });
  }

  // For local testing: simulate a new wallpaper notification
  static void simulateNewWallpaper(Function(String wallpaperTitle) onNewWallpaper) {
    onNewWallpaper('Test Wallpaper');
  }
}
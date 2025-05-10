import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, PlatformException;
import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:media_scanner/media_scanner.dart';
import 'shared_widgets.dart'; // For buildPillButton

enum WallpaperType { home, lock, both }

Future<String> _getFilePath(BuildContext context, String url) async {
  try {
    Directory bloomsplashDir;
    if (Platform.isLinux) {
      final homeDir = Platform.environment['HOME'] ?? Directory.current.path;
      bloomsplashDir = Directory('$homeDir/Downloads/bloomsplash');
    } else if (Platform.isAndroid) {
      final directory = Directory('/storage/emulated/0/DCIM/bloomsplash');
      bloomsplashDir = directory;
    } else if (Platform.isMacOS || Platform.isWindows) {
      final downloadsDir = await getDownloadsDirectory();
      bloomsplashDir = Directory('${downloadsDir!.path}/bloomsplash');
    } else {
      final directory = await getApplicationDocumentsDirectory();
      bloomsplashDir = Directory('${directory.path}/bloomsplash');
    }

    if (!await bloomsplashDir.exists()) {
      await bloomsplashDir.create(recursive: true);
    }

    final date = DateTime.now();
    final formattedDate =
        '${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}${date.year}';
    final fileName = 'wallpaper_$formattedDate.jpg';
    final filePath = '${bloomsplashDir.path}/$fileName';

    if (url.startsWith('http')) {
      final dio = Dio();
      await dio.download(url, filePath);
    } else {
      final byteData = await rootBundle.load(url);
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());
    }

    return filePath;
  } catch (e) {
    throw Exception('Failed to get file path: $e');
  }
}

Future<void> downloadWallpaper(BuildContext context, String url) async {
  try {
    final filePath = await _getFilePath(context, url);
    String directoryName;

    if (Platform.isLinux) {
      directoryName = 'bloomsplash'; // For Linux, just show /bloomsplash
    } else if (Platform.isAndroid) {
      directoryName = 'DCIM/bloomsplash'; // For Android, show DCIM/bloomsplash
    } else if (Platform.isMacOS || Platform.isWindows) {
      directoryName =
          'bloomsplash'; // For macOS/Windows, just show /bloomsplash
    } else {
      directoryName = 'bloomsplash'; // Default fallback
    }

    if (Platform.isAndroid) {
      await MediaScanner.loadMedia(path: filePath);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Wallpaper downloaded to "$directoryName"',
            style: TextStyle(fontSize: 12),
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to download wallpaper',
            style: TextStyle(fontSize: 12),
          ),
        ),
      );
    }
  }
}

void showSetWallpaperDialog(BuildContext context, String wallpaperImage) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha:0.7),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Set Wallpaper',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose where to set the wallpaper:',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  buildPillButton(
                    context,
                    label: 'Home Screen',
                    onPressed: () {
                      Navigator.of(context).pop();
                      setWallpaper(context, WallpaperType.home, wallpaperImage);
                    },
                  ),
                  const SizedBox(height: 8),
                  buildPillButton(
                    context,
                    label: 'Lock Screen',
                    onPressed: () {
                      Navigator.of(context).pop();
                      setWallpaper(context, WallpaperType.lock, wallpaperImage);
                    },
                  ),
                  const SizedBox(height: 8),
                  buildPillButton(
                    context,
                    label: 'Both',
                    onPressed: () {
                      Navigator.of(context).pop();
                      setWallpaper(context, WallpaperType.both, wallpaperImage);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<void> setWallpaper(
  BuildContext context,
  WallpaperType type,
  String url,
) async {
  String result;
  bool goToHome = false; // Set to true or false based on your requirement
  String target = 'Unknown'; // Default value for target

  try {
    // Determine the wallpaper location
    int wallpaperLocation;
    switch (type) {
      case WallpaperType.home:
        wallpaperLocation = AsyncWallpaper.HOME_SCREEN;
        target = 'Home Screen';
        break;
      case WallpaperType.lock:
        wallpaperLocation = AsyncWallpaper.LOCK_SCREEN;
        target = 'Lock Screen';
        break;
      case WallpaperType.both:
        wallpaperLocation = AsyncWallpaper.BOTH_SCREENS;
        target = 'Both';
        break;
    }

    // Use the same logic as _downloadWallpaper to handle URL or asset
    final filePath = await _getFilePath(context, url);

    // Ensure the file exists
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Wallpaper file does not exist at $filePath');
    }

    // Set the wallpaper
    result =
        await AsyncWallpaper.setWallpaperFromFile(
              filePath: file.path,
              wallpaperLocation: wallpaperLocation,
              goToHome: goToHome,
              toastDetails: ToastDetails.success(),
              errorToastDetails: ToastDetails.error(),
            )
            ? 'Wallpaper set to $target'
            : 'Failed to set wallpaper.';
  } on PlatformException {
    result = 'Failed to set wallpaper.';
  } catch (e) {
    result = 'Error: $e';
  }

  // Show SnackBar for success or failure
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == 'Wallpaper set'
              ? 'Wallpaper set to successfully!'
              : 'Failed to set wallpaper: $result',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../../../app/services/firebase/wallpaper_db.dart';
import '../../../app/services/firebase/user_db.dart';

enum WallpaperType { home, lock, both }

// Helper to copy from content URI to app cache directory and return File
Future<File> _copyContentUriToFile(BuildContext context, String contentUri, String fileName) async {
  final cacheDir = await getTemporaryDirectory();
  final file = File('${cacheDir.path}/$fileName');
  final uri = Uri.parse(contentUri);
  final byteData = await _readBytesFromContentUri(context, uri);
  await file.writeAsBytes(byteData);
  return file;
}

// Helper to read bytes from a content URI using platform channel
Future<List<int>> _readBytesFromContentUri(BuildContext context, Uri uri) async {
  final MethodChannel channel = const MethodChannel('com.bloomsplash/media');
  try {
    final List<dynamic> bytes = await channel.invokeMethod('readBytesFromContentUri', {'uri': uri.toString()});
    return bytes.cast<int>();
  } catch (e) {
    debugPrint('[BloomSplash] Failed to read bytes from content URI: $e');
    throw Exception('Failed to read bytes from content URI: $e');
  }
}

Future<String> _getFilePath(
  BuildContext context,
  String url, {
  String? fileName,
}) async {
  try {
    Directory bloomsplashDir;
    String resolvedFileName;
    final date = DateTime.now();
    final formattedDate =
        '${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}${date.year}-${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}${date.second.toString().padLeft(2, '0')}';
    // Use wallpaperId if provided, else use timestamp
    final defaultFileName = fileName ?? 'wallpaper_$formattedDate.jpg';
    resolvedFileName = defaultFileName;

    if (Platform.isAndroid) {
      // Use MediaStore via platform channel for Android
      final bytes =
          url.startsWith('http')
              ? (await http.get(Uri.parse(url))).bodyBytes
              : (await rootBundle.load(url)).buffer.asUint8List();
      try {
        final MethodChannel channel = MethodChannel('com.bloomsplash/media');
        final String? savedPath = await channel.invokeMethod<String>(
          'saveImageToPictures',
          {'fileName': resolvedFileName, 'bytes': bytes},
        );
        if (savedPath == null || savedPath.isEmpty) {
          debugPrint('[BloomSplash] Failed to save image: empty path returned from MethodChannel');
          throw Exception('Failed to save image to Pictures/BloomSplash');
        }
        // If savedPath is a content URI, copy to app cache and return real file path
        if (savedPath.startsWith('content://')) {
          final file = await _copyContentUriToFile(context, savedPath, resolvedFileName);
          return file.path;
        }
        return savedPath;
      } catch (e) {
        debugPrint('[BloomSplash] Error using MethodChannel com.bloomsplash/media: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving image: MediaStore integration not available. ($e)'),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        throw Exception('MediaStore integration not available: $e');
      }
    } else if (Platform.isLinux) {
      final homeDir = Platform.environment['HOME'] ?? Directory.current.path;
      bloomsplashDir = Directory('$homeDir/Downloads/BloomSplash');
    } else if (Platform.isMacOS || Platform.isWindows) {
      final downloadsDir = await getDownloadsDirectory();
      bloomsplashDir = Directory('${downloadsDir!.path}/BloomSplash');
    } else {
      final directory = await getApplicationDocumentsDirectory();
      bloomsplashDir = Directory('${directory.path}/BloomSplash');
    }

    if (!Platform.isAndroid) {
      if (!await bloomsplashDir.exists()) {
        await bloomsplashDir.create(recursive: true);
      }
      final filePath = '${bloomsplashDir.path}/$resolvedFileName';
      if (url.startsWith('http')) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);
        } else {
          throw Exception('Failed to download file: ${response.statusCode}');
        }
      } else {
        final byteData = await rootBundle.load(url);
        final file = File(filePath);
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }
      return filePath;
    }
    throw Exception('Failed to get file path: Unknown platform or error');
  } catch (e) {
    throw Exception('Failed to get file path: $e');
  }
}

Future<void> downloadWallpaper(
  BuildContext context,
  String url, {
  String? fileName,
  String? wallpaperId,
}) async {
  // No permission required for download on Android 13+ and modern platforms

  try {
    await _getFilePath(context, url, fileName: fileName);
    String directoryName;
    if (Platform.isLinux) {
      directoryName = 'BloomSplash';
    } else if (Platform.isAndroid) {
      directoryName = 'Pictures/BloomSplash';
    } else if (Platform.isMacOS || Platform.isWindows) {
      directoryName = 'BloomSplash';
    } else {
      directoryName = 'BloomSplash';
    }

    // Efficiently increment download count after successful download using Firebase
    if (wallpaperId != null) {
      await FirestoreService.incrementDownloadCount(wallpaperId);
      // Fetch updated wallpaper data from Firebase using getImageDetailsFromFirestore
      try {
        final wallpaperData = await UserService().getImageDetailsFromFirestore(
          wallpaperId,
        );
        final newDownloads =
            wallpaperData?['downloads'] ?? wallpaperData?['download'] ?? 0;
        final box = await Hive.openBox('uploadedWallpapers');
        final wallpapers = box.get('wallpapers', defaultValue: []);
        if (wallpapers is List) {
          final updatedWallpapers =
              wallpapers.map((item) {
                if (item is Map && item['id'] == wallpaperId) {
                  final updatedItem = Map<String, dynamic>.from(item);
                  updatedItem['downloads'] = newDownloads;
                  return updatedItem;
                }
                return item;
              }).toList();
          await box.put('wallpapers', updatedWallpapers);
        }
      } catch (e) {
        debugPrint('Failed to update local cache for downloads: $e');
      }
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
                color: Colors.black.withValues(alpha: 0.7),
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
  String result = '';
  String target = 'Unknown';
  try {
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
        target = 'Both Screens';
        break;
    }
    final filePath = await _getFilePath(context, url);
    final file = File(filePath);
    if (!await file.exists()) {
      result = 'Wallpaper file does not exist.';
    } else {
      final success = await AsyncWallpaper.setWallpaperFromFile(
        filePath: file.path,
        wallpaperLocation: wallpaperLocation,
        goToHome: false,
        toastDetails: ToastDetails.success(),
        errorToastDetails: ToastDetails.error(),
      );
      if (success) {
        result = 'Wallpaper set to $target successfully!';
      } else {
        result = 'Failed to set wallpaper to $target.';
      }
    }
  } on PlatformException catch (e) {
    result = 'Platform error: $e';
  } catch (e) {
    result = 'Error: $e';
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

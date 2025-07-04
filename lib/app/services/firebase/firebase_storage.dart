import 'dart:developer';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../core/utils/image_utils.dart' as img_utils;
import 'dart:typed_data';
import '../external_api/image_optimization.dart';

final storageRef = FirebaseStorage.instance.ref();

Future<Map<String, dynamic>?> uploadFileToFirebase(File file) async {
  try {
    // Check file size before processing
    final maxFileSize = 4 * 1024 * 1024; // 4 MB in bytes
    if (file.lengthSync() > maxFileSize) {
      debugPrint(

        'Image file size is too large: \n  [33m[1m${file.lengthSync()} bytes (max 4 MB)[0m',
      );
      throw Exception('Image file size exceeds 4 MB.');
    }

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final originalRef = storageRef.child('wallpapers/original/$fileName');
    final thumbnailRef = storageRef.child('wallpapers/thumbnail/$fileName');

    // Get original image size and resolution
    final originalSize = file.lengthSync();
    final originalResolution = await img_utils.getImageResolution(file);
    final originalBytes = await file.readAsBytes();

    // Resize and fix orientation for wallpaper and thumbnail
    // For wallpaper (main image): 1400x3100 (maintain aspect ratio)

    // For thumbnail: 800x1420 (maintain aspect ratio)
    final thumbnailFile = await img_utils.resizeAndFixImage(
      file,
      targetWidth: 800,
      targetHeight: 1420,
      outputPath: '${file.parent.path}/thumbnail_$fileName.png',
      maintainAspectRatio: true,
    );
    debugPrint(
      'Thumbnail png file size: \n  ${thumbnailFile.lengthSync()} bytes \n  ${(thumbnailFile.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
    );

    // Convert thumbnail to webp using external API
    if (!thumbnailFile.existsSync() || thumbnailFile.lengthSync() == 0) {
      throw Exception('Thumbnail file is missing or empty');
    }
    final webpBytes = await convertImageToWebp(thumbnailFile);

    // Upload original and thumbnail (webp) to Firebase Storage
    final uploadTasks = [
      originalRef.putData(originalBytes),
      thumbnailRef.putData(Uint8List.fromList(webpBytes)),
    ];
    await Future.wait(uploadTasks);

    final originalUrl = await originalRef.getDownloadURL();
    final thumbnailUrl = await thumbnailRef.getDownloadURL();

    log('Original URL: $originalUrl');
    log('Thumbnail URL: $thumbnailUrl');

    // Clean up temporary files
    thumbnailFile.deleteSync();
    // Do NOT delete thumbnailWebpFile here, return its path for palette extraction

    return {
      'originalUrl': originalUrl,
      'thumbnailUrl': thumbnailUrl,
      'originalSize': originalSize,
      'originalResolution': originalResolution,
      'localThumbnailPath':
          thumbnailFile.path, // Add local webp path for palette extraction
    };
  } catch (e) {
    log('Error uploading file: $e');
    return null;
  }
}

Future<void> uploadFileFromAppDocumentsDirectory(fileName) async {
  try {
    final appDocDir = await getApplicationDocumentsDirectory();
    final filePath = '${appDocDir.path}/$fileName';
    final file = File(filePath);

    if (file.existsSync()) {
      await uploadFileToFirebase(file);
    } else {
      log('File does not exist at path: $filePath');
    }
  } catch (e) {
    log('Error accessing application documents directory: $e');
  }
}

Future<Map<String, dynamic>?> uploadFileToFirebaseWithProgress(
  File file,
  Function(double) onProgress,
) async {
  try {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final originalRef = storageRef.child('collections/$fileName');

    final uploadTask = originalRef.putFile(file);

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      onProgress(progress);
    });

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return {'downloadUrl': downloadUrl};
  } catch (e) {
    log('Error uploading file with progress: $e');
    return null;
  }
}

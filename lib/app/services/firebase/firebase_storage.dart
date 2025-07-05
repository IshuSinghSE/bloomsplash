import 'dart:developer';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
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

    // Read the original image
    final originalBytes = await file.readAsBytes();
    if (originalBytes.isEmpty) {
      throw Exception('File is empty: ${file.path}');
    }
    img.Image? _originalImage = img.decodeImage(originalBytes);
    if (_originalImage == null) {
      throw Exception('Failed to decode image: ${file.path}');
    }
    img.Image originalImage = _originalImage;

    // --- EXIF orientation fix ---
    // If the image has an orientation tag, fix it
    try {
      final exifData = img.JpegData()..read(originalBytes);
      final orientation = exifData.exif?.orientation ?? 0;
      if (orientation != 0 && orientation != 1) {
        originalImage = img.bakeOrientation(originalImage);
      }
    } catch (e) {
      debugPrint('EXIF orientation parse failed: $e');
    }
    // --- END EXIF orientation fix ---

    // Get original image size and resolution
    final originalSize = file.lengthSync();
    final originalResolution = '${originalImage.width}x${originalImage.height}';

    // Resize for thumbnail dynamically to maintain aspect ratio
    const int maxThumbWidth = 1440;
    const int maxThumbHeight = 870;
    img.Image thumbnailImage;
    if (originalImage.width > maxThumbWidth || originalImage.height > maxThumbHeight) {
      final double aspectRatio = originalImage.width / originalImage.height;
      int thumbWidth, thumbHeight;
      if (aspectRatio > 1) {
        // Landscape orientation
        thumbWidth = maxThumbWidth;
        thumbHeight = (maxThumbWidth / aspectRatio).round();
      } else {
        // Portrait or square orientation
        thumbHeight = maxThumbHeight;
        thumbWidth = (maxThumbHeight * aspectRatio).round();
      }
      thumbnailImage = img.copyResize(
        originalImage,
        width: thumbWidth,
        height: thumbHeight,
      );
    } else {
      thumbnailImage = originalImage;
    }

    // Use the same format as the user uploaded (JPEG/PNG)
    String ext = file.path.split('.').last.toLowerCase();
    List<int> thumbBytes;
    String thumbExt;
    if (ext == 'jpg' || ext == 'jpeg') {
      thumbBytes = img.encodeJpg(
        thumbnailImage,
        quality: 85,
      ); // Reduced quality from 95 to 85
      thumbExt = 'jpg';
    } else {
      thumbBytes = img.encodePng(thumbnailImage);
      thumbExt = 'png';
    }
    final thumbnailFile = File(
      '${file.parent.path}/thumbnail_$fileName.$thumbExt',
    );
    await thumbnailFile.writeAsBytes(thumbBytes);
    debugPrint(
      'Thumbnail $thumbExt file size: \n  ${thumbnailFile.lengthSync()} bytes \n  ${(thumbnailFile.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
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

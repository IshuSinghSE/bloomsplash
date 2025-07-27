import 'dart:developer';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../core/utils/image_utils.dart' as img_utils;
import 'dart:typed_data';
import '../external_api/image_optimization.dart';

final storageRef = FirebaseStorage.instance.ref();

Future<Map<String, dynamic>?> uploadFileToFirebase(
  File file, {
  Function(double progress)? onProgress,
}) async {
  try {
    // Check file size before processing
    final maxFileSize = 4 * 1024 * 1024; // 4 MB in bytes
    if (file.lengthSync() > maxFileSize) {
      debugPrint(
        'Image file size is too large: \n  \u001b[33m\u001b[1m${file.lengthSync()} bytes (max 4 MB)\u001b[0m',
      );
      throw Exception('Image file size exceeds 4 MB.');
    }

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final originalRef = storageRef.child('wallpapers/original/$fileName');
    final thumbnailRef = storageRef.child('wallpapers/thumbnail/$fileName');

    // Get original image size and resolution
    final originalSize = file.lengthSync();
    final originalResolution = await img_utils.getImageResolution(file);

    // For thumbnail: use external API to convert and compress to WebP
    final webpBytes = await convertImageToWebp(file);
    debugPrint(
      'Thumbnail webp bytes size: \n  ${webpBytes.length} bytes \n  ${(webpBytes.length / (1024 * 1024)).toStringAsFixed(2)} MB',
    );

    // Save webpBytes to a temp file for palette extraction
    final tempDir = await getTemporaryDirectory();
    final tempWebpFile = File('${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.webp');
    await tempWebpFile.writeAsBytes(webpBytes);

    // Upload original image with progress
    final originalUploadTask = originalRef.putFile(file);
    if (onProgress != null) {
      originalUploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        // Map to 0-0.5 for original upload
        onProgress(progress * 0.5);
      });
    }
    await originalUploadTask;

    // Upload thumbnail (webp) with progress
    final thumbUploadTask = thumbnailRef.putData(Uint8List.fromList(webpBytes));
    if (onProgress != null) {
      thumbUploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        // Map to 0.5-1.0 for thumbnail upload
        onProgress(0.5 + progress * 0.5);
      });
    }
    await thumbUploadTask;

    final originalUrl = await originalRef.getDownloadURL();
    final thumbnailUrl = await thumbnailRef.getDownloadURL();

    log('Original URL: $originalUrl');
    log('Thumbnail URL: $thumbnailUrl');

    // Clean up temporary files
    tempWebpFile.deleteSync();
    // Do NOT delete tempWebpFile here, return its path for palette extraction

    return {
      'originalUrl': originalUrl,
      'thumbnailUrl': thumbnailUrl,
      'originalSize': originalSize,
      'originalResolution': originalResolution,
      'localThumbnailPath': tempWebpFile.path,
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

import 'dart:developer';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

final storageRef = FirebaseStorage.instance.ref();

Future<Map<String, dynamic>?> uploadFileToFirebase(File file) async {
  try {
    // Check file size before processing
    final maxFileSize = 4 * 1024 * 1024; // 4 MB in bytes
    if (file.lengthSync() > maxFileSize) {
      debugPrint('Image file size is too large: \n  ${file.lengthSync()} bytes (max 4 MB)');
      throw Exception('Image file size exceeds 4 MB.');
    }

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final originalRef = storageRef.child('wallpapers/original/$fileName');
    final thumbnailRef = storageRef.child('wallpapers/thumbnail/$fileName');

    // Read the original image
    final originalBytes = await file.readAsBytes();
    final originalImage = img.decodeImage(originalBytes);

    if (originalImage == null) {
      throw Exception('Failed to decode image');
    }

    // Get original image size and resolution
    final originalSize = file.lengthSync();
    final originalResolution = '${originalImage.width}x${originalImage.height}';

    // Resize for thumbnail (optimized for list views, 800px max width)
    final maxThumbWidth = 800; // Reduced from 1080 for better performance
    final maxThumbHeight = 1420; // Reduced from 1920 for better performance
    final thumbAspect = originalImage.width / originalImage.height;
    int thumbWidth = maxThumbWidth;
    int thumbHeight = (maxThumbWidth / thumbAspect).round();
    if (thumbHeight > maxThumbHeight) {
      thumbHeight = maxThumbHeight;
      thumbWidth = (maxThumbHeight * thumbAspect).round();
    }
    final thumbnailImage = img.copyResize(
      originalImage,
      width: thumbWidth,
      height: thumbHeight,
    );

    // Use the same format as the user uploaded (JPEG/PNG)
    String ext = file.path.split('.').last.toLowerCase();
    List<int> thumbBytes;
    String thumbExt;
    if (ext == 'jpg' || ext == 'jpeg') {
      thumbBytes = img.encodeJpg(thumbnailImage, quality: 85); // Reduced quality from 95 to 85
      thumbExt = 'jpg';
    } else {
      thumbBytes = img.encodePng(thumbnailImage);
      thumbExt = 'png';
    }
    final thumbnailFile = File('${file.parent.path}/thumbnail_$fileName.$thumbExt');
    await thumbnailFile.writeAsBytes(thumbBytes);
    debugPrint('Thumbnail $thumbExt file size: \n  ${thumbnailFile.lengthSync()} bytes \n  ${(thumbnailFile.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB');

    // Convert thumbnail to webp using external API
    if (!thumbnailFile.existsSync() || thumbnailFile.lengthSync() == 0) {
      throw Exception('Thumbnail file is missing or empty');
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://image-optimization-sooty.vercel.app/convert?quality=80'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', thumbnailFile.path));
    debugPrint('Converting thumbnail to webp: ${thumbnailFile.path}');
    final streamedResponse = await request.send();
    if (streamedResponse.statusCode != 200) {
      final responseBody = await streamedResponse.stream.bytesToString();
      log('API error response: $responseBody');
      throw Exception('Failed to convert thumbnail to webp');
    }
    final webpBytes = await streamedResponse.stream.toBytes();
    final thumbnailWebpFile = File('${file.parent.path}/thumbnail_$fileName.webp');
    await thumbnailWebpFile.writeAsBytes(webpBytes);

    // Upload original and thumbnail (webp) to Firebase Storage
    final uploadTasks = [
      originalRef.putData(originalBytes),
      thumbnailRef.putData(webpBytes),
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
      'localThumbnailPath': thumbnailWebpFile.path, // Add local webp path for palette extraction
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
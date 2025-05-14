import 'dart:developer';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

final storageRef = FirebaseStorage.instance.ref();

Future<Map<String, dynamic>?> uploadFileToFirebase(File file) async {
  try {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final originalRef = storageRef.child('wallpapers/original/$fileName');
    final thumbnailRef = storageRef.child('wallpapers/thumbnail/$fileName.webp');

    // Read the original image
    final originalBytes = await file.readAsBytes();
    final originalImage = img.decodeImage(originalBytes);

    if (originalImage == null) {
      throw Exception('Failed to decode image');
    }

    // Get original image size and resolution
    final originalSize = file.lengthSync();
    final originalResolution = '${originalImage.width}x${originalImage.height}';

    // Resize for thumbnail (200 width while maintaining aspect ratio)
    final thumbnailImage = originalImage;
    final thumbnailPngFile = File('${file.parent.path}/thumbnail_$fileName.png');
    await thumbnailPngFile.writeAsBytes(img.encodePng(thumbnailImage));

    // Convert PNG thumbnail to webp using external API
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://image-optimization-sooty.vercel.app/convert?quality=100'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', thumbnailPngFile.path));
    final streamedResponse = await request.send();
    if (streamedResponse.statusCode != 200) {
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
    thumbnailPngFile.deleteSync();
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
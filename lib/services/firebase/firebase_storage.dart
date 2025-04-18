import 'dart:developer';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

final storageRef = FirebaseStorage.instance.ref();

Future<Map<String, dynamic>?> uploadFileToFirebase(File file) async {
  try {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final originalRef = storageRef.child('wallpapers/original/$fileName');
    final thumbnailRef = storageRef.child('wallpapers/thumbnail/$fileName');
    final previewRef = storageRef.child('wallpapers/preview/$fileName');

    // Read the original image
    final originalBytes = await file.readAsBytes();
    final originalImage = img.decodeImage(originalBytes);

    if (originalImage == null) {
      throw Exception('Failed to decode image');
    }

    // Get original image size and resolution
    final originalSize = file.lengthSync();
    final originalResolution = '${originalImage.width}x${originalImage.height}';

    // Resize for thumbnail (400x400)
    final thumbnailImage = img.copyResize(originalImage, width: 400, height: 400);
    final thumbnailFile = File('${file.parent.path}/thumbnail_$fileName.png');
    await thumbnailFile.writeAsBytes(img.encodePng(thumbnailImage));

    // Resize for preview (1080x720)
    final previewImage = img.copyResize(originalImage, width: 1080, height: 720);
    final previewFile = File('${file.parent.path}/preview_$fileName.png');
    await previewFile.writeAsBytes(img.encodePng(previewImage));

    // Upload original image
    await originalRef.putFile(file);
    final originalUrl = await originalRef.getDownloadURL();

    // Upload thumbnail image
    await thumbnailRef.putFile(thumbnailFile);
    final thumbnailUrl = await thumbnailRef.getDownloadURL();

    // Upload preview image
    await previewRef.putFile(previewFile);
    final previewUrl = await previewRef.getDownloadURL();

    log('Original URL: $originalUrl');
    log('Thumbnail URL: $thumbnailUrl');
    log('Preview URL: $previewUrl');

    // Clean up temporary files
    thumbnailFile.deleteSync();
    previewFile.deleteSync();

    return {
      'originalUrl': originalUrl,
      'thumbnailUrl': thumbnailUrl,
      'previewUrl': previewUrl,
      'originalSize': originalSize,
      'originalResolution': originalResolution,
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
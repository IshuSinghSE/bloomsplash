import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Get image resolution as a string (e.g., '1920x1080')
Future<String> getImageResolution(File file) async {
  final bytes = await file.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  return '${image.width}x${image.height}';
}

/// Resize an image file with custom width, height, quality, and format.
/// Returns a new File with the processed image (jpg or png). WebP is not supported in Dart image package.
Future<File> resizeAndFixImage(
  File file, {
  int? targetWidth,
  int? targetHeight,
  String? outputPath,
  bool maintainAspectRatio = false,
  int quality = 85,
  String format = 'jpg', // 'jpg', 'png', 'webp'
}) async {
  // Only resize if needed
  if (targetWidth != null || targetHeight != null) {
    int resizeWidth = targetWidth ?? 0;
    int resizeHeight = targetHeight ?? 0;
    CompressFormat compressFormat;
    String ext;
    if (format == 'jpg' || format == 'jpeg') {
      compressFormat = CompressFormat.jpeg;
      ext = 'jpg';
    } else if (format == 'png') {
      compressFormat = CompressFormat.png;
      ext = 'png';
    } else if (format == 'webp') {
      compressFormat = CompressFormat.webp;
      ext = 'webp';
    } else {
      throw Exception('Unsupported format: $format. Use "jpg", "png", or "webp".');
    }
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: resizeWidth,
      minHeight: resizeHeight,
      quality: quality,
      format: compressFormat,
    );
    if (result == null) throw Exception('Image compression failed');
    String outPath = outputPath ?? file.path.replaceFirst(RegExp(r'\.(jpg|jpeg|png|webp)$'), '_processed.$ext');
    if (!outPath.endsWith('.$ext')) outPath += '.$ext';
    final outFile = File(outPath);
    await outFile.writeAsBytes(result);
    return outFile;
  } else {
    // No resize needed, return original file
    return file;
  }
}

/// Compute perceptual hash (pHash) of an image file (8x8 grayscale, returns 64-bit string)
Future<String> computeImageHash(File imageFile) async {
  final bytes = await imageFile.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes, targetWidth: 8, targetHeight: 8);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final data = byteData!.buffer.asUint8List();

  // Convert to grayscale and compute average
  List<int> gray = [];
  for (int i = 0; i < data.length; i += 4) {
    int r = data[i];
    int g = data[i + 1];
    int b = data[i + 2];
    int v = ((r + g + b) / 3).round();
    gray.add(v);
  }
  int avg = gray.reduce((a, b) => a + b) ~/ gray.length;
  return gray.map((v) => v > avg ? '1' : '0').join();
}

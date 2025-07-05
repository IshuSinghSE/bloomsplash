import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Get image resolution as a string (e.g., '1920x1080')
Future<String> getImageResolution(File file) async {
  final bytes = await file.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  return '${image.width}x${image.height}';
}

/// Resize and fix orientation of an image file.
/// Returns a new File with the processed image (PNG format).
Future<File> resizeAndFixImage(
  File file, {
  int? targetWidth,
  int? targetHeight,
  String? outputPath,
  bool maintainAspectRatio = false,
}) async {
  final bytes = await file.readAsBytes();
  int? width = targetWidth;
  int? height = targetHeight;
  if (maintainAspectRatio && (targetWidth != null || targetHeight != null)) {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final originalWidth = image.width;
    final originalHeight = image.height;
    if (targetWidth != null && targetHeight != null) {
      final widthRatio = targetWidth / originalWidth;
      final heightRatio = targetHeight / originalHeight;
      final scale = widthRatio < heightRatio ? widthRatio : heightRatio;
      width = (originalWidth * scale).round();
      height = (originalHeight * scale).round();
    } else if (targetWidth != null) {
      width = targetWidth;
      height = (originalHeight * (targetWidth / originalWidth)).round();
    } else if (targetHeight != null) {
      height = targetHeight;
      width = (originalWidth * (targetHeight / originalHeight)).round();
    }
  }
  final codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: width,
    targetHeight: height,
  );
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List pngBytes = byteData!.buffer.asUint8List();

  final outFile = File(outputPath ?? file.path.replaceFirst('.jpg', '_processed.png'));
  await outFile.writeAsBytes(pngBytes);
  return outFile;
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

import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter/material.dart';

/// Generate a unique ID
String generateUuid() {
  return const Uuid().v4();
}

/// Extract dominant colors from a File (thumbnail image)
Future<List<String>> extractDominantColors(
  File imageFile, {
  int colorCount = 3,
}) async {
  final image = await imageFile.readAsBytes();
  final uiImage = await decodeImageFromList(image);
  final palette = await PaletteGenerator.fromImage(
    uiImage,
    maximumColorCount: colorCount,
  );
  return palette.colors
      .map((c) => '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}')
      .toList();
}

import 'dart:developer';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/constant/api_routes.dart';

Future<List<int>> convertImageToWebp(File imageFile,) async {
  final request = http.MultipartRequest(
    'POST',
    Uri.parse(imageOptimizationApi),
  );
  request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
  debugPrint('Converting image to webp: ${imageFile.path}');

  final streamedResponse = await request.send();
  if (streamedResponse.statusCode != 200) {
    final responseBody = await streamedResponse.stream.bytesToString();
    log('API error response: $responseBody');
    throw Exception('Failed to convert image to webp');
  }

  return await streamedResponse.stream.toBytes();
}

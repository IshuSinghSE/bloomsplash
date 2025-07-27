import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:bloomsplash/app/services/firebase/firebase_storage.dart';
import 'package:bloomsplash/app/services/firebase/wallpaper_db.dart';
import 'package:bloomsplash/core/constant/config.dart';
import 'package:bloomsplash/core/utils/hash_utils.dart';
import 'package:bloomsplash/core/utils/image_utils.dart' as img_utils;
import 'package:bloomsplash/features/settings/screens/info_card.dart';
import 'package:bloomsplash/models/wallpaper_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:uuid/uuid.dart';

// --- Ensure correct extractDominantColors implementation ---
Future<List<String>> extractDominantColors(
  File imageFile, {
  int colorCount = 3,
}) async {
  if (!imageFile.existsSync()) {
    throw Exception('Thumbnail file does not exist: ${imageFile.path}');
  }
  final imageBytes = await imageFile.readAsBytes();
  final codec = await ui.instantiateImageCodec(imageBytes);
  final frame = await codec.getNextFrame();
  final uiImage = frame.image;
  final palette = await PaletteGenerator.fromImage(
    uiImage,
    maximumColorCount: colorCount,
  );
  final colorList = palette.colors
      .map((c) => '#${c.value.toRadixString(16).padLeft(8, '0').substring(2)}')
      .toList();
  debugPrint('Palette colors for ${imageFile.path}: $colorList');
  return colorList;
}

class BulkUploadPage extends StatefulWidget {
  const BulkUploadPage({Key? key}) : super(key: key);

  @override
  State<BulkUploadPage> createState() => _BulkUploadPageState();
}

class _BulkUploadPageState extends State<BulkUploadPage> {
  // Parse wallpapers.csv in the given directory and update alreadyUploadedFilenames
  Future<void> _parseWallpapersCsv(String dirPath) async {
    final file = File('$dirPath/wallpapers.csv');
    final Set<String> uploaded = {};
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final rows = const CsvToListConverter().convert(content);
        if (rows.isNotEmpty) {
          final headers = rows.first.map((e) => e.toString()).toList();
          final filenameIdx = headers.indexOf('filename');
          final uploadedIdx = headers.indexOf('uploaded');
          for (var i = 1; i < rows.length; i++) {
            final row = rows[i];
            if (filenameIdx >= 0 && row.length > filenameIdx) {
              // If uploaded column exists, check value, else just add filename
              if (uploadedIdx >= 0 && row.length > uploadedIdx) {
                if (row[uploadedIdx].toString().toLowerCase() == 'yes') {
                  uploaded.add(row[filenameIdx].toString());
                }
              } else {
                uploaded.add(row[filenameIdx].toString());
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Failed to parse wallpapers.csv: $e');
      }
    }
    setState(() {
      alreadyUploadedFilenames = uploaded;
    });
  }
  // Track uploaded filenames from wallpapers.csv
  Set<String> alreadyUploadedFilenames = {};
  // Track failed uploads
  Set<int> failedUploads = {};
  bool isUploadingAll = false;
  int uploadedCount = 0;
  int failedCount = 0;

  Future<void> uploadAllWallpapers() async {
    if (isUploadingAll) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload All Wallpapers'),
        content: const Text('Are you sure you want to upload all wallpapers? This will upload all not-yet-uploaded wallpapers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Upload All'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      isUploadingAll = true;
      uploadedCount = 0;
      failedCount = 0;
      failedUploads.clear();
    });
    for (int i = 0; i < wallpapers.length; i++) {
      if (wallpapers[i]['uploaded'] == 'yes') {
        setState(() {
          uploadedCount++;
        });
        continue;
      }
      try {
        await uploadWallpaper(i, userData);
        setState(() {
          uploadedCount++;
        });
      } catch (e) {
        setState(() {
          failedUploads.add(i);
          failedCount++;
        });
      }
    }
    setState(() {
      isUploadingAll = false;
    });
  }

  Widget _buildStatusPill({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
  Map<String, dynamic> get userData => {'isAdmin': true, 'displayName': 'Admin', 'photoUrl': null};

  // Track upload progress for each wallpaper by index
  Map<int, double> uploadProgress = {};
  List<Map<String, dynamic>> wallpapers = [];
  String? csvPath;
  String? folderPath;
  int folderImageCount = 0;
  bool isLoading = false;
  List<String> csvHeaders = [];

  Future<void> pickCsvFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null && result.files.single.path != null) {
      setState(() {
        csvPath = result.files.single.path;
      });
      // Try to parse wallpapers.csv in the same folder as the CSV
      final csvDir = File(result.files.single.path!).parent;
      await _parseWallpapersCsv(csvDir.path);
      await loadCsv();
    }
  }

  Future<void> pickWallpapersFolder() async {
    // Request permission
    if (await Permission.manageExternalStorage.request().isGranted) {
      final result = await FilePicker.platform.getDirectoryPath();
      print('Selected folder: $result');
      if (result != null) {
        int count = 0;
        final dir = Directory(result);
        final exists = await dir.exists();
        print('Directory exists: $exists');
        if (exists) {
          final List<String> foundFiles = [];
          await for (final entity in dir.list(recursive: false, followLinks: false)) {
            if (entity is File) {
              final name = entity.path.toLowerCase();
              foundFiles.add(name);
              if (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png')) {
                count++;
              }
            }
          }
          print('Files found:');
          for (final f in foundFiles) {
            print(f);
          }
          print('Image count: $count');
        }
        setState(() {
          folderPath = result;
          folderImageCount = count;
        });
        // Parse wallpapers.csv in the selected folder
        await _parseWallpapersCsv(result);
        // Optionally reload CSV if already picked
        if (csvPath != null) {
          await loadCsv();
        }
      }
    } else {
      openAppSettings();
    }
  }

  Future<void> loadCsv() async {
    if (csvPath == null) return;
    setState(() { isLoading = true; });
    try {
      final file = File(csvPath!);
      String content = await file.readAsString();
      // Normalize line endings to \n
      content = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      // Remove empty lines
      content = content.split('\n').where((line) => line.trim().isNotEmpty).join('\n');
      final rows = const CsvToListConverter().convert(content, eol: '\n');
      if (rows.isEmpty) {
        setState(() {
          wallpapers = [];
          csvHeaders = [];
          isLoading = false;
        });
        return;
      }
      var firstRow = rows.first;
      List<String> headers = firstRow.cast<String>();
      debugPrint('Headers: $headers');
      // Add 'uploaded' column if not present
      bool hasUploaded = headers.contains('uploaded');
      if (!hasUploaded) headers = [...headers, 'uploaded'];
      final List<Map<String, dynamic>> data = [];
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final map = <String, dynamic>{};
        for (var j = 0; j < headers.length; j++) {
          if (j < row.length) {
            map[headers[j]] = row[j];
          } else if (headers[j] == 'uploaded') {
            map['uploaded'] = 'no';
          } else {
            map[headers[j]] = '';
          }
        }
        // If filename is in alreadyUploadedFilenames, mark as uploaded
        if (map['filename'] != null && alreadyUploadedFilenames.contains(map['filename'].toString())) {
          map['uploaded'] = 'yes';
        }
        data.add(map);
      }
      setState(() {
        wallpapers = data;
        csvHeaders = headers;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading CSV: $e');
      setState(() {
        wallpapers = [];
        csvHeaders = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to parse CSV: $e')),
      );
    }
  }

  Future<void> uploadWallpaper(int index, Map<String, dynamic> userData) async {
    setState(() {
      uploadProgress[index] = 0.0;
    });
    try {
      final w = wallpapers[index];
      // Find the image file in the folder
      File? imageFile;
      if (folderPath != null && w['filename'] != null) {
        String base = w['filename'].toString();
        final numVal = int.tryParse(base);
        if (numVal != null) {
          base = numVal.toString().padLeft(3, '0');
        }
        final jpg = File('$folderPath/$base.jpg');
        final png = File('$folderPath/$base.png');
        if (jpg.existsSync()) {
          imageFile = jpg;
        } else if (png.existsSync()) {
          imageFile = png;
        }
      }
      if (imageFile == null) {
        throw Exception('Image file not found for wallpaper: \\${w['filename']}');
      }

      // Check for duplicates
      final isDuplicate = await isDuplicateWallpaper(imageFile);
      if (isDuplicate) {
        debugPrint("Duplicate wallpaper detected for image: \\${imageFile.path}");
        setState(() {
          uploadProgress.remove(index);
        });
        return;
      }

      // Upload the file to Firebase Storage (preprocessing included)
      final result = await uploadFileToFirebase(
        imageFile,
        onProgress: (progress) {
          setState(() {
            uploadProgress[index] = progress;
          });
        },
      );

      if (result == null) {
        throw Exception('Failed to upload image: \\${imageFile.path}');
      }

      // Extract URLs, size, and resolution
      final originalUrl = result['originalUrl'];
      final thumbnailUrl = result['thumbnailUrl'];
      final originalSize = result['originalSize'];
      final originalResolution = result['originalResolution'];

      // Generate a unique ID for the document
      final id = const Uuid().v4();
      final imageHash = await img_utils.computeImageHash(imageFile);

      // Extract dominant colors from the thumbnail image (robust, like normal upload)
      List<String> colors = [];
      try {
        File? thumbFile;
        if (thumbnailUrl != null && thumbnailUrl is String && thumbnailUrl.toString().isNotEmpty) {
          final thumbPath = thumbnailUrl.toString();
          if (thumbPath.startsWith('http')) {
            final tempDir = Directory.systemTemp;
            final tempFile = File('${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg');
            final response = await HttpClient().getUrl(Uri.parse(thumbPath));
            final res = await response.close();
            await res.pipe(tempFile.openWrite());
            thumbFile = tempFile;
          } else {
            thumbFile = File(thumbPath);
          }
          colors = await extractDominantColors(thumbFile);
          debugPrint('Extracted colors for ${w['filename']}: $colors');
        }
      } catch (e) {
        debugPrint('Color extraction failed: $e');
      }

      // If colors is empty, log a warning
      if (colors.isEmpty) {
        debugPrint('No colors extracted for ${w['filename']}');
      }

      final wallpaper = Wallpaper(
        id: id,
        name: w['title'] ?? w['filename'] ?? 'untitled',
        imageUrl: originalUrl,
        thumbnailUrl: thumbnailUrl,
        downloads: 0,
        likes: 0,
        size: originalSize,
        resolution: originalResolution,
        orientation: 'portrait',
        category: w['category'] ?? 'Uncategorized',
        tags: (w['tags'] is List) ? w['tags'] : (w['tags']?.toString().split(',').map((e) => e.trim()).toList() ?? []),
        colors: colors,
        author: userData['isAdmin'] == true ? 'bloomsplash' : (userData['displayName'] ?? 'Unknown'),
        authorImage: userData['isAdmin'] == true ? AppConfig.adminImagePath : (userData['photoUrl'] ?? AppConfig.authorIconPath),
        description: w['description'] ?? '',
        isPremium: false,
        isAIgenerated: false,
        status: 'pending',
        createdAt: DateTime.now().toIso8601String(),
        license: 'free-commercial',
        hash: imageHash,
        collectionId: null,
      );

      // Add wallpaper to Firestore
      final firestoreService = FirestoreService();
      await firestoreService.addImageDetailsToFirestore(wallpaper);

      // Update the in-memory CSV row with new values
      setState(() {
        wallpapers[index]['uploaded'] = 'yes';
        wallpapers[index]['author'] = wallpaper.author;
        wallpapers[index]['thumbnailUrl'] = thumbnailUrl;
        wallpapers[index]['imageUrl'] = originalUrl;
        wallpapers[index]['hash'] = imageHash;
        wallpapers[index]['colors'] = colors.isNotEmpty ? colors.join(',') : '';
        uploadProgress.remove(index);
      });

      // Save to the original CSV (if present)
      await saveCsv();

      // Also append/update a new wallpapers.csv with all uploaded wallpapers
      await appendToWallpapersCsv(wallpapers[index]);
    } catch (e, stack) {
      debugPrint("Error during upload: $e");
      debugPrint("Stack trace: $stack");
      setState(() {
        uploadProgress.remove(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during upload: $e')),
      );
    }
  }

  // Append or update a new wallpapers.csv with the latest uploaded wallpaper row
  Future<void> appendToWallpapersCsv(Map<String, dynamic> row) async {
    final dir = folderPath ?? Directory.current.path;
    final file = File('$dir/wallpapers.csv');
    List<List<dynamic>> rows = [];
    List<String> headers = [];
    if (await file.exists()) {
      final content = await file.readAsString();
      final csvRows = const CsvToListConverter().convert(content);
      if (csvRows.isNotEmpty) {
        headers = csvRows.first.map((e) => e.toString()).toList();
        rows = csvRows.sublist(1);
      }
    }
    // If headers are empty, use current row keys
    if (headers.isEmpty) {
      headers = row.keys.toList();
    }
    // Check if row with same filename exists, update it, else append
    bool updated = false;
    for (int i = 0; i < rows.length; i++) {
      if (rows[i].length == headers.length &&
          rows[i][headers.indexOf('filename')] == row['filename']) {
        rows[i] = headers.map((h) => _csvValue(row[h], h)).toList();
        updated = true;
        break;
      }
    }
    if (!updated) {
      rows.add(headers.map((h) => _csvValue(row[h], h)).toList());
    }
    // Write back to wallpapers.csv
    final csv = const ListToCsvConverter().convert([headers, ...rows]);
    await file.writeAsString(csv);

  }

  // Helper to ensure colors is always a comma-separated string
  dynamic _csvValue(dynamic value, String key) {
    if (key == 'colors') {
      if (value is List) {
        return value.join(',');
      } else if (value is String) {
        return value;
      } else {
        return '';
      }
    }
    return value ?? '';
  }

  Future<void> saveCsv() async {
    if (csvPath == null) return;
    final headers = wallpapers.isNotEmpty ? wallpapers.first.keys.toList() : [];
    final rows = [headers] + wallpapers.map((e) => headers.map((h) => _csvValue(e[h], h)).toList()).toList();
    final csv = const ListToCsvConverter().convert(rows);
    final file = File(csvPath!);
    await file.writeAsString(csv);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Upload Wallpapers')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Pick Wallpaper'),
                    onPressed: pickWallpapersFolder,
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.file_open),
                    label: const Text('Pick CSV File'),
                    onPressed: pickCsvFile,
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Upload All'),
                    onPressed: uploadAllWallpapers,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatusPill(
                      label: 'Total',
                      value: wallpapers.length.toString(),
                      color: Colors.blueGrey.shade700,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusPill(
                      label: 'Uploaded',
                      value: (wallpapers.where((w) => w['uploaded'] == 'yes').length + uploadedCount).toString(),
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusPill(
                      label: 'Remaining',
                      value: (wallpapers.length - (wallpapers.where((w) => w['uploaded'] == 'yes').length + uploadedCount + failedUploads.length)).toString(),
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusPill(
                      label: 'Failed',
                      value: failedUploads.length.toString(),
                      color: Colors.red.shade700,
                    ),
                  ],
                ),
              ),
            ),
            // Show the progress of upload all wallpapers total/remaining uploaded, failed. 
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  SizedBox(
                    height: 120,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (folderPath != null)
                            InfoCard(
                              icon: Icons.folder,
                              color: Colors.blueGrey.shade800,
                              title: 'Folder',
                              value: folderPath!,
                              width: 220,
                              height: 200,
                            ),
                          if (folderPath != null)
                            const SizedBox(width: 8),
                          if (folderPath != null)
                            InfoCard(
                              icon: Icons.image,
                              color: Colors.lightBlue.shade700,
                              title: 'Images in Folder',
                              value: '$folderImageCount',
                              width: 220,
                              height: 200,
                            ),
                          if (folderPath != null)
                            const SizedBox(width: 8),
                          if (csvPath != null)
                            InfoCard(
                              icon: Icons.insert_drive_file,
                              color: Colors.orange.shade700,
                              title: 'CSV File',
                              value: csvPath!,
                              width: 220,
                              height: 200,
                            ),
                          if (csvPath != null)
                            const SizedBox(width: 8),
                          if (csvHeaders.isNotEmpty)
                            InfoCard(
                              icon: Icons.table_chart,
                              color: Colors.purple.shade700,
                              title: 'Fields',
                              value: csvHeaders.join(", "),
                              width: 220,
                              height: 200,
                            ),
                          if (csvHeaders.isNotEmpty)
                            const SizedBox(width: 8),
                          if (csvPath != null)
                            InfoCard(
                              icon: Icons.list_alt,
                              color: Colors.green.shade700,
                              title: 'Metadata Rows',
                              value: '${wallpapers.length}',
                              width: 220,
                              height: 200,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (isLoading) const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                  wallpapers.isEmpty
                      ? const Center(child: Text('No wallpapers loaded.'))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: wallpapers.length,
                          itemBuilder: (context, index) {
                            final w = wallpapers[index];
                            File? imageFile;
                            if (folderPath != null && w['filename'] != null) {
                              String base = w['filename'].toString();
                              // Pad to 3 digits if numeric
                              final numVal = int.tryParse(base);
                              if (numVal != null) {
                                base = numVal.toString().padLeft(3, '0');
                              }
                              final jpg = File('$folderPath/$base.jpg');
                              final png = File('$folderPath/$base.png');
                              if (jpg.existsSync()) {
                                imageFile = jpg;
                              } else if (png.existsSync()) {
                                imageFile = png;
                              }
                            }
                            // UI for upload progress and button
                            Widget trailingWidget;
                            if (uploadProgress[index] != null) {
                              // Show percentage progress as text
                              final percent = (uploadProgress[index]! * 100).clamp(0, 100).toInt();
                              trailingWidget = SizedBox(
                                width: 56,
                                child: Center(
                                  child: Text('$percent%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                ),
                              );
                            } else if (w['uploaded'] == 'yes' || (w['filename'] != null && alreadyUploadedFilenames.contains(w['filename'].toString()))) {
                              trailingWidget = const Icon(Icons.check, color: Colors.green);
                            } else {
                              trailingWidget = ElevatedButton(
                                onPressed: uploadProgress[index] != null ? null : () => uploadWallpaper(index, userData),
                                child: const Text('Upload'),
                              );
                            }
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: imageFile != null
                                        ? GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => Dialog(
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      if (imageFile != null)
                                                        Image.file(imageFile, fit: BoxFit.contain),
                                                      Padding(
                                                        padding: const EdgeInsets.all(8.0),
                                                        child: Text(
                                                          w['title'] ?? w['filename'] ?? 'Untitled',
                                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.all(8.0),
                                                        child: Text('Tags: ${w['tags'] ?? ''}\n${w['description'] ?? ''}'),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Image.file(imageFile, width: 56, height: 56, fit: BoxFit.contain),
                                          )
                                        : const Icon(Icons.image_not_supported),
                                    title: Text(w['title'] ?? w['filename'] ?? 'Untitled'),
                                    subtitle: Text('Tags: ${w['tags'] ?? ''}\nUploaded: ${w['uploaded']}'),
                                    trailing: trailingWidget,
                                  ),
                                  if (uploadProgress[index] != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: LinearProgressIndicator(value: uploadProgress[index]),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

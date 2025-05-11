import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../services/firebase/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase/firebase_firestore_service.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../models/wallpaper_model.dart';
import 'package:image/image.dart' as img; // Add this for image processing
import 'package:hive/hive.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _selectedImage;
  bool _isLoading = false; // Track loading state
  bool _isUploading = false; // Track upload state
  final TextEditingController _wallpaperNameController =
      TextEditingController();
  bool _termsAccepted = false; // Track terms acceptance

  Future<File> _fixImageOrientation(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw the image with correct orientation
    canvas.drawImage(image, Offset.zero, Paint());

    final picture = recorder.endRecording();
    final img = await picture.toImage(image.width, image.height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    final fixedImageFile = File(imageFile.path);
    await fixedImageFile.writeAsBytes(byteData!.buffer.asUint8List());

    return fixedImageFile;
  }

  /// Utility function to compute perceptual hash (pHash) of an image
  String computeImageHash(File imageFile) {
    final image = img.decodeImage(imageFile.readAsBytesSync());
    if (image == null) {
      throw Exception("Failed to decode image.");
    }

    // Resize to 8x8 and convert to grayscale
    final resized = img.copyResize(image, width: 8, height: 8);
    final grayscale = img.grayscale(resized);

    // Compute average pixel value
    final avgPixelValue = grayscale.getBytes().map((pixel) => pixel).reduce((a, b) => a + b) ~/ grayscale.getBytes().length;

    // Generate hash based on whether pixel values are above or below the average
    final hash = grayscale.getBytes().map((pixel) => pixel > avgPixelValue ? '1' : '0').join();
    return hash;
  }

  /// Function to check for duplicate wallpapers
  Future<bool> isDuplicateWallpaper(File newImage) async {
    final newImageHash = computeImageHash(newImage);

    // Fetch existing hashes from Firestore
    final firestoreService = FirestoreService();
    final existingWallpapers =
        await firestoreService.getAllImageDetailsFromFirestore();

    for (var wallpaper in existingWallpapers) {
      if (wallpaper['hash'] == newImageHash) {
        return true; // Duplicate found
      }
    }
    return false; // No duplicates
  }

  Future<void> _pickImage() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    PermissionStatus status;

    // Check Android version
    if (androidInfo.version.sdkInt >= 33) {
      // Request READ_MEDIA_IMAGES for Android 13+
      status = await Permission.photos.request();
    } else {
      // Request READ_EXTERNAL_STORAGE for Android 12 and below
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      setState(() {
        _isLoading =
            false; // Hide loading indicator immediately after picker opens
      });

      if (pickedFile != null) {
        File selectedFile = File(pickedFile.path);

        // Fix the orientation of the image
        selectedFile = await _fixImageOrientation(selectedFile);

        setState(() {
          _selectedImage = selectedFile;
        });
      }
    } else if (status.isDenied) {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage permission is required to pick an image.'),
        ),
      );
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable storage permission from settings.'),
        ),
      );
      await openAppSettings(); // Opens app settings for the user to enable permissions
    } else {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage != null) {
      setState(() {
        _isUploading = true; // Show loading indicator
      });

      try {
        debugPrint("Starting image upload process...");

        // Check for duplicates
        final isDuplicate = await isDuplicateWallpaper(_selectedImage!);
        if (isDuplicate) {
          debugPrint("Duplicate wallpaper detected.");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Duplicate wallpaper detected!')),
          );
          setState(() {
            _isUploading = false; // Hide loading indicator
          });
          return;
        }

        // Upload the file to Firebase Storage
        debugPrint("Uploading image to Firebase Storage...");
        final result = await uploadFileToFirebase(_selectedImage!);

        if (result == null) {
          throw Exception('Failed to upload images');
        }
        debugPrint("Image uploaded successfully. Firebase result: $result");

        // Extract URLs, size, and resolution
        final originalUrl = result['originalUrl'];
        final thumbnailUrl = result['thumbnailUrl'];
        final previewUrl = result['previewUrl'];
        final originalSize = result['originalSize'];
        final originalResolution = result['originalResolution'];
        debugPrint("Extracted image details: originalUrl=$originalUrl, thumbnailUrl=$thumbnailUrl, previewUrl=$previewUrl");

        // Generate a unique ID for the document
        final id = const Uuid().v4();
        debugPrint("Generated unique ID for wallpaper: $id");

        // Compute perceptual hash for the uploaded image
        debugPrint("Computing perceptual hash...");
        final imageHash = computeImageHash(_selectedImage!);
        debugPrint("Perceptual hash computed: $imageHash");

        // Create a Wallpaper object
        debugPrint("Creating Wallpaper object...");
        final wallpaper = Wallpaper(
          id: id,
          name: _wallpaperNameController.text.isNotEmpty
              ? _wallpaperNameController.text
              : 'Wallpaper $id',
          imageUrl: originalUrl,
          thumbnailUrl: thumbnailUrl,
          previewUrl: previewUrl,
          downloads: 0,
          likes: 0,
          size: originalSize,
          resolution: originalResolution,
          aspectRatio: 1.78, // Replace with dynamic aspect ratio if needed
          orientation: 'landscape', // Replace with dynamic orientation if needed
          category: 'Urban', // Replace with dynamic category if needed
          tags: ['example', 'tag'], // Replace with dynamic tags if needed
          colors: ['#FFFFFF', '#000000'], // Replace with extracted colors if needed
          author: 'Author $id',
          authorImage: '/assets/icons/author1.png', // Replace with actual author image
          uploadedBy: 'system', // Replace with dynamic uploader if needed
          description: 'A mesmerizing view of the night sky.', // Replace with dynamic description
          isPremium: false,
          isAIgenerated: false,
          status: 'approved',
          createdAt: DateTime.now().toIso8601String(),
          license: 'free-commercial',
          hash: imageHash, // Add the computed hash
        );
        debugPrint("Wallpaper object created successfully.");

        // Add wallpaper to Firestore
        debugPrint("Adding wallpaper details to Firestore...");
        final firestoreService = FirestoreService();
        await firestoreService.addImageDetailsToFirestore(wallpaper);
        debugPrint("Wallpaper details added to Firestore successfully.");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!')),
        );

        setState(() {
          _selectedImage = null; // Reset the selected image after upload
          _wallpaperNameController.clear(); // Clear the wallpaper name field
        });
      } catch (e, stack) {
        debugPrint("Error during image upload: $e");
        debugPrint("Stack trace: $stack");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      } finally {
        setState(() {
          _isUploading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var preferencesBox = Hive.box('preferences');
    var userData = preferencesBox.get('userData', defaultValue: {});
    final userEmail = userData['email'] ?? '';

    // Restrict access to the page
    if (userEmail != "ishu.111636@gmail.com") {
      return Scaffold(
        body: Center(
          child: Text(
            'Access Denied',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Unfocus when tapping outside
        },
        child: KeyboardVisibilityBuilder(
          builder: (context, isKeyboardVisible) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap:
                        _isLoading
                            ? null
                            : _pickImage, // Disable click if loading
                    child: Stack(
                      children: [
                        Container(
                          height: 300,
                          width: 300,
                          
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 48, 51, 65)
                                .withValues(alpha:0.3), // Background color with opacity
                            
                            borderRadius: BorderRadius.circular(24),
                           
                            image:
                                _selectedImage != null
                                    ? DecorationImage(
                                      image: FileImage(_selectedImage!),
                                      fit: BoxFit.cover,
                                    )
                                    : null,
                          ),
                          child:
                              _selectedImage == null
                                  ? const Center(
                                    child: Text(
                                      'Click to Select Image',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                  : null,
                        ),
                        if (_isLoading)
                          Container(
                            height: 300,
                            width: 300,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha:
                                0.5,
                              ), // Add blur effect
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) {
                        FocusScope.of(
                          context,
                        ).unfocus(); // Remove focus when clicking outside
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        enabled:
                            _selectedImage !=
                            null, // Disable if no image selected
                        controller: _wallpaperNameController,
                        decoration: InputDecoration(
                          hintText: 'Give your wallpaper a name',
                          alignLabelWithHint: true, // Align hint to center
                          floatingLabelBehavior:
                              FloatingLabelBehavior
                                  .never, // Disable floating behavior
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ), // Center hint vertically
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Colors.black12, // Border with opacity 0.2
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color:
                                  Colors.blueAccent, // Blue border when focused
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your photos on BloomSplash.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 212,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.check_circle,
                              color: Colors.blue,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'High quality photographs',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: const [
                            Icon(
                              Icons.check_circle,
                              color: Colors.blue,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Original design and artworks',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: const [
                            Icon(
                              Icons.check_circle,
                              color: Colors.blue,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No copyright or explicit content',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Checkbox(
                          activeColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          side: const BorderSide(color: Colors.grey, width: 1),
                          checkColor: Colors.grey[900],
                          value: _termsAccepted,
                          onChanged: (value) {
                            setState(() {
                              _termsAccepted = value ?? false;
                            });
                          },

                          materialTapTargetSize:
                              MaterialTapTargetSize
                                  .padded, // Makes the tap area larger
                        ),
                        const Expanded(
                          child: Text(
                            'I agree to the Terms of Use and understand this does not guarantee approval for the community.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed:
                            _isUploading || !_termsAccepted
                                ? null
                                : _uploadImage, // Disable if uploading or terms not accepted
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child:
                            _isUploading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'Upload',
                                  style: TextStyle(fontSize: 16),
                                ),
                      ),
                      OutlinedButton(
                        onPressed: _pickImage,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blueAccent),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Select',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedbackForm extends StatefulWidget {
  final VoidCallback? onSubmitted;
  const FeedbackForm({super.key, this.onSubmitted});

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'Suggestion';
  String _message = '';
  late final TextEditingController _messageController;
  File? _screenshotFile;
  bool _isSubmitting = false;
  String? _error;

  // For auto-save
  static const _autosaveKey = 'feedback_form_autosave';

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _restoreFormState();
  }

  @override
  void dispose() {
    // Always save the latest text from the controller
    _message = _messageController.text;
    _saveFormState();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _saveFormState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_autosaveKey, [
      _type,
      _messageController.text,
      _screenshotFile?.path ?? '',
    ]);
  }

  Future<void> _restoreFormState() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_autosaveKey);
    if (data != null && data.length == 3) {
      setState(() {
        _type = data[0];
        _message = data[1];
        _messageController.text = data[1];
        if (data[2].isNotEmpty) {
          _screenshotFile = File(data[2]);
        }
      });
    }
  }

  Future<void> _clearAutosave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_autosaveKey);
    // Also clear controller
    _messageController.clear();
  }

  final List<String> _types = ['Suggestion', 'Issue', 'Bug', 'Other'];

  Future<Map<String, dynamic>> _getDeviceAppInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    Map<String, dynamic> deviceData = {};
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceData = {
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'brand': androidInfo.brand,
          'osVersion': androidInfo.version.release,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceData = {
          'model': iosInfo.utsname.machine,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
        };
      }
    } catch (_) {}
    return {
      'device': deviceData,
      'app': {
        'appName': packageInfo.appName,
        'packageName': packageInfo.packageName,
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
      },
    };
  }

  Future<String?> _uploadScreenshot(File file) async {
    try {
      final fileName = 'feedbacks/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _screenshotFile = File(picked.path);
      });
      _saveFormState();
    }
  }

  void _removeScreenshot() {
    setState(() {
      _screenshotFile = null;
    });
    _saveFormState();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    _message = _messageController.text;
    _formKey.currentState!.save();
    await _saveFormState();
    try {
      final info = await _getDeviceAppInfo();
      String? screenshotUrl;
      if (_screenshotFile != null) {
        screenshotUrl = await _uploadScreenshot(_screenshotFile!);
      }
      await FirebaseFirestore.instance.collection('feedback').add({
        'type': _type,
        'message': _message,
        'createdAt': FieldValue.serverTimestamp(),
        'deviceInfo': info['device'],
        'appInfo': info['app'],
        'screenshotUrl': screenshotUrl,
      });
      // Clear autosave and local state before closing dialog
      await _clearAutosave();
      if (mounted) {
        setState(() {
          _type = 'Suggestion';
          _message = '';
          _screenshotFile = null;
          _messageController.clear();
        });
        // Navigator.of(context).pop();
        // Show snackbar on parent after dialog closes
        final msg = (_type == 'Suggestion' || _type == 'Other')
            ? 'Thank you for your feedback! We appreciate your suggestion.'
            : 'Thank you! We will look into this issue as soon as possible.';
        // Use addPostFrameCallback to ensure snackbar is shown after pop
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      }
      widget.onSubmitted?.call();
    } catch (e) {
      setState(() {
        _error = 'Failed to submit feedback. Please try again.';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900, minWidth: 800, minHeight: 400),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.18),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            onChanged: _saveFormState,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.feedback_outlined, color: theme.colorScheme.primary, size: 30),
                    const SizedBox(width: 12),
                    Text('Send Feedback', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 22),
                DropdownButtonFormField<String>(
                  value: _type,
                  items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) {
                    setState(() => _type = v ?? 'Suggestion');
                    _saveFormState();
                  },
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _messageController,
                  minLines: 4,
                  maxLines: 8,
                  style: theme.textTheme.bodyMedium,
                  onChanged: (v) {
                    _message = v;
                    _saveFormState();
                  },
                  decoration: InputDecoration(
                    labelText: 'Describe your feedback',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your feedback';
                    }
                    if (v.trim().length < 15) {
                      return 'Please provide at least 15 characters for better context.';
                    }
                    return null;
                  },
                  onSaved: (v) => _message = v ?? '',
                ),
                const SizedBox(height: 18),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: _pickScreenshot,
                      icon: const Icon(Icons.image_outlined, size: 20),
                      label: const Text('Attach Screenshot'),
                    ),
                    if (_screenshotFile != null)
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(
                              _screenshotFile!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: _removeScreenshot,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(Icons.close, size: 28, color: Colors.redAccent),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: theme.colorScheme.primary.withValues(alpha: 0.18),
                          width: 1.2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      elevation: 0,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

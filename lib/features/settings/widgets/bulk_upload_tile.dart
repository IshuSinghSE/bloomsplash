import 'package:flutter/material.dart';

class BulkUploadTile extends StatelessWidget {
  final VoidCallback onTap;
  const BulkUploadTile({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.cloud_upload),
      title: const Text('Bulk Upload Wallpapers'),
      subtitle: const Text('Preview and upload wallpapers from CSV'),
      onTap: onTap,
    );
  }
}

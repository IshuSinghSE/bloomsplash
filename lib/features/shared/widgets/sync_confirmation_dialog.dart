import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/providers/favorites_provider.dart';
import '../../../app/providers/auth_provider.dart';

class SyncConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirmSignOut;
  final VoidCallback? onGoToSettings;

  const SyncConfirmationDialog({
    super.key,
    required this.onConfirmSignOut,
    this.onGoToSettings,
  });

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.user?.uid;

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.sync_problem,
            color: Colors.orange[400],
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Unsaved Changes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You have unsaved favorite changes that haven\'t been synced to the cloud yet.',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[900]?.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange[400]!.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.orange[400],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'If you sign out now, these changes will be lost.',
                    style: TextStyle(
                      color: Colors.orange[100],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
        ),
        
        // Sync now button
        ElevatedButton.icon(
          onPressed: () async {
            if (uid != null) {
              try {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                
                await favoritesProvider.forceSyncNow(uid);
                
                // Close loading dialog
                Navigator.of(context).pop();
                // Close confirmation dialog
                Navigator.of(context).pop();
                
                // Proceed with sign out
                onConfirmSignOut();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[400]),
                        const SizedBox(width: 8),
                        const Text('Favorites synced successfully!'),
                      ],
                    ),
                    backgroundColor: Colors.green[800],
                  ),
                );
              } catch (e) {
                // Close loading dialog
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[400]),
                        const SizedBox(width: 8),
                        const Text('Sync failed. Please try again.'),
                      ],
                    ),
                    backgroundColor: Colors.red[800],
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.cloud_upload, size: 18),
          label: const Text(
            'Sync & Sign Out',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        
        // Sign out anyway button
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirmSignOut();
          },
          child: Text(
            'Sign Out Anyway',
            style: TextStyle(
              color: Colors.red[400],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Show the sync confirmation dialog
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onConfirmSignOut,
    VoidCallback? onGoToSettings,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SyncConfirmationDialog(
          onConfirmSignOut: onConfirmSignOut,
          onGoToSettings: onGoToSettings,
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/providers/auth_provider.dart';
import '../../dashboard/screens/my_uploads_page.dart';
import '../../../app/providers/favorites_provider.dart';
import '../widgets/settings_tile.dart'; // Import the new widget

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  int _cacheSize = 0; // Cache size in bytes
  bool _isSyncingFavorites = false;
  bool _isLoggingOut = false;
  bool _isClearingCache = false;
  
  // Helper getter to check if any operation is in progress
  bool get _isProcessing => _isSyncingFavorites || _isLoggingOut || _isClearingCache;
  
  late final AnimationController _syncController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void initState() {
    super.initState();
    _updateCacheSize(); // Calculate cache size on initialization
  }

  @override
  void dispose() {
    _syncController.dispose();
    super.dispose();
  }

  Future<void> _updateCacheSize() async {
    try {
      final cacheDirPath =
          await getTemporaryDirectory(); // Get the temporary directory path
      final cacheDir = Directory(
        cacheDirPath.path,
      ); // Create a Directory object
      if (await cacheDir.exists()) {
        final size = cacheDir
            .listSync(recursive: true)
            .whereType<File>()
            .fold<int>(0, (sum, file) => sum + file.lengthSync());
        setState(() {
          _cacheSize = size; // Update the cache size
        });
      } else {
        setState(() {
          _cacheSize = 0; // Set cache size to 0 if directory doesn't exist
        });
      }
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      setState(() {
        _cacheSize = 0; // Fallback to 0 on error
      });
    }
  }

  Future<void> _clearCache() async {
    if (_isProcessing) return;
    
    setState(() {
      _isClearingCache = true;
    });
    
    try {
      final cacheDir = Directory(
        (await getTemporaryDirectory()).path,
      ); // Get the cache directory
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await _updateCacheSize(); // Recalculate cache size after clearing
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image cache cleared successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No cache to clear!')));
        }
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to clear cache!')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClearingCache = false;
        });
      }
    }
  }
  
  Future<void> _logout() async {
    if (_isProcessing) return;
    
    setState(() {
      _isLoggingOut = true;
    });
    
    try {
      await Provider.of<AuthProvider>(
        context, 
        listen: false,
      ).signOut(context);
    } catch (e) {
      debugPrint('Error logging out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log out: $e')),
        );
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
    // Note: We don't set _isLoggingOut to false here because the page will be popped
  }

  @override
  Widget build(BuildContext context) {
    var preferencesBox = Hive.box('preferences');
    var userData = preferencesBox.get('userData', defaultValue: {});

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text(
              'Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: const Icon(
                    Icons.login_outlined,
                    color: Colors.deepOrange,
                    semanticLabel: "Log out",
                  ),
                  onPressed: _isProcessing ? null : _logout,
                ),
              ),
            ],
          ),
          body: AbsorbPointer(
            absorbing: _isProcessing,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: <Widget>[
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color.fromARGB(255, 56, 91, 114),
                      ),
                    ),
                    if (userData['photoUrl'] != null && userData['photoUrl']!.isNotEmpty)
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: CachedNetworkImageProvider(
                          userData['photoUrl']!,
                          cacheKey: userData['uid'] ?? 'user_avatar',
                        ),
                      )
                    else
                      const CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('assets/avatar/Itsycal.webp'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    userData['displayName'] ?? 'Guest User',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: Text(
                    userData['email'] ?? 'No email available',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
                if (userData['email'] == "ishu.111636@gmail.com") ...[
                  const SizedBox(height: 24),
                  SettingsTile(
                    icon: Icons.dashboard,
                    title: 'Admin Dashboard',
                    type: SettingsTileType.action,
                    disabled: _isProcessing,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyUploadsPage(),
                        ),
                      );
                    },
                  ),
                ],
                
                ListTile(
                  leading: AnimatedBuilder(
                    animation: _syncController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _syncController.value * 6.28319, // 2*pi radians
                        child: child,
                      );
                    },
                    child: const Icon(Icons.sync),
                  ),
                  title: const Text('Sync Favorites'),
                  subtitle: const Text(
                    'Sync your favourites across all your devices',
                  ),
                  onTap: _isProcessing
                      ? null
                      : () async {
                          setState(() {
                            _isSyncingFavorites = true;
                          });
                          _syncController.repeat();
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          final favoritesProvider = Provider.of<FavoritesProvider>(
                            context,
                            listen: false,
                          );
                          final uid = authProvider.user?.uid;
                          if (uid != null) {
                            await favoritesProvider.saveFavoritesToFirestore(uid);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Favorites synced to cloud!'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'You must be logged in to sync favorites.',
                                ),
                              ),
                            );
                          }
                          _syncController.stop();
                          setState(() {
                            _isSyncingFavorites = false;
                          });
                        },
                ),
                
                // Replace with reusable widget for Clear Cache
                SettingsTile(
                  icon: Icons.storage,
                  title: 'Clear Cache',
                  type: SettingsTileType.action,
                  disabled: _isProcessing,
                  customSubtitle: Text(
                    _cacheSize > 1024 * 1024
                        ? 'Current size: ${(_cacheSize / (1024 * 1024)).toStringAsFixed(2)} MB'
                        : 'Current size: ${(_cacheSize / 1024).toStringAsFixed(2)} KB',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _isProcessing ? null : _clearCache,
                  ),
                  onTap: _clearCache,
                ),
                
                const Divider(),
                
                // Replace with reusable widget for Help & Support
                SettingsTile(
                  icon: Icons.headset_mic_rounded,
                  title: 'Help & Support',
                  subtitle: 'Got a question? We have answers!',
                  type: SettingsTileType.dialog,
                  disabled: _isProcessing,
                  dialogTitle: 'Help & Support',
                  dialogContent: const SelectableText(
                    'For any questions or support, email us at:\n\n'
                    'support@bloomsplash.app',
                  ),
                ),
                
                // Replace with reusable widget for Terms & Conditions
                SettingsTile(
                  icon: Icons.article,
                  title: 'Terms & Conditions',
                  subtitle: 'Read our terms and conditions.',
                  type: SettingsTileType.dialog,
                  disabled: _isProcessing,
                  dialogTitle: 'Terms & Conditions',
                  dialogContent: const SingleChildScrollView(
                    child: Text(
                      'Here are the Terms & Conditions of the app. Please visit our website for the full document.',
                    ),
                  ),
                ),
                
                // Replace with reusable widget for Privacy Policy
                SettingsTile(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy.',
                  type: SettingsTileType.dialog,
                  disabled: _isProcessing,
                  dialogTitle: 'Privacy Policy',
                  dialogContent: const SingleChildScrollView(
                    child: Text(
                      'Here is the Privacy Policy of the app. Please visit our website for the full document.',
                    ),
                  ),
                ),
                
                // Replace with reusable widget for About
                SettingsTile(
                  icon: Icons.copyright,
                  title: 'About',
                  subtitle: 'License & Credits',
                  type: SettingsTileType.dialog,
                  disabled: _isProcessing,
                  dialogTitle: 'License & Credits',
                  dialogContent: const SingleChildScrollView(
                    child: Text(
                      'This app is developed by BloomSplash Team.\n\n'
                      'Credits:\n'
                      '- Flutter & Dart\n'
                      '- Open source packages\n\n'
                      'All rights reserved.\n'
                      'See our website for full license details.',
                    ),
                  ),
                ),
                
                // Replace with reusable widget for App Version
                SettingsTile(
                  icon: Icons.info_outline,
                  title: 'App Version',
                  subtitle: '1.0.0',
                  type: SettingsTileType.action,
                  disabled: true,
                ),
              ],
            ),
          ),
        ),
        
        // Loading overlay for logout and clear cache
        if (_isLoggingOut || _isClearingCache)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Card(
                  elevation: 8.0,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16.0),
                        Text(
                          _isLoggingOut ? 'Logging out...' : 'Clearing cache...',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

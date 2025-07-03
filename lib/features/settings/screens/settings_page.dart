import 'package:bloomsplash/features/about_page.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../app/providers/auth_provider.dart';
import '../../dashboard/screens/my_uploads_page.dart';
import '../../../app/providers/favorites_provider.dart';
import '../../../app/services/cache_service.dart'; // Import the new service
import '../widgets/settings_tile.dart'; // Import the new widget
import '../widgets/feedback_form.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  // App version for dynamic display
  String? _appVersion;
  int _cacheSize = 0; // Cache size in bytes
  bool _isSyncingFavorites = false;
  bool _isLoggingOut = false;
  bool _isClearingCache = false;

  // Helper getter to check if any operation is in progress
  bool get _isProcessing =>
      _isSyncingFavorites || _isLoggingOut || _isClearingCache;

  late final AnimationController _syncController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void initState() {
    super.initState();
    _updateCacheSize(); // Calculate cache size on initialization
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = 'v${info.version}';
      });
    } catch (e) {
      debugPrint('Error loading app version: $e');
      setState(() {
        _appVersion = '';
      });
    }
  }

  @override
  void dispose() {
    _syncController.dispose();
    super.dispose();
  }

  Future<void> _updateCacheSize() async {
    final size = await CacheService.getCacheSize();
    if (mounted) {
      setState(() {
        _cacheSize = size;
      });
    }
  }

  Future<void> _clearCache() async {
    if (_isProcessing) return;

    setState(() {
      _isClearingCache = true;
    });

    final success = await CacheService.clearCache();

    if (mounted) {
      if (success) {
        await _updateCacheSize(); // Recalculate cache size after clearing
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image cache cleared successfully!')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to clear cache!')));
      }
      setState(() {
        _isClearingCache = false;
      });
    }
  }

  Future<void> _logout() async {
    if (_isProcessing) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false).signOut(context);
    } catch (e) {
      debugPrint('Error logging out: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to log out: $e')));
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            actions: [
              if (_appVersion != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: Text(
                      _appVersion!,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
          body: AbsorbPointer(
            absorbing: _isProcessing,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
              children: <Widget>[
                // Profile Card
                Center(
                  child: Container(
                    width: 370,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.white,
                          child:
                              userData['photoUrl'] != null &&
                                      userData['photoUrl']!.isNotEmpty
                                  ? CircleAvatar(
                                    radius: 46,
                                    backgroundImage: CachedNetworkImageProvider(
                                      userData['photoUrl']!,
                                      cacheKey:
                                          userData['uid'] ?? 'user_avatar',
                                    ),
                                  )
                                  : const CircleAvatar(
                                    radius: 46,
                                    backgroundImage: AssetImage(
                                      'assets/avatar/Itsycal.webp',
                                    ),
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userData['displayName'] ?? 'Guest User',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userData['email'] ?? 'No email available',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 180,
                          child: OutlinedButton.icon(
                            icon: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return const LinearGradient(
                                  colors: [
                                    Color.fromARGB(255, 253, 56, 95),
                                    Color(0xFFB22222),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              child: const Icon(
                                Icons.logout,
                                color: Colors.white,
                              ),
                            ),
                            label: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return const LinearGradient(
                                  colors: [
                                    Color.fromARGB(255, 211, 58, 88),
                                    Color.fromARGB(255, 255, 107, 107),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              child: const Text(
                                'Sign Out',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color.fromARGB(255, 209, 60, 90),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                            ).copyWith(
                              overlayColor: MaterialStateProperty.all(
                                const Color.fromARGB(
                                  255,
                                  253,
                                  10,
                                  59,
                                ).withOpacity(0.08),
                              ),
                            ),
                            onPressed: _isProcessing ? null : _logout,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (userData['email'] == "ishu.111636@gmail.com") ...[
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

                SettingsTile(
                  icon: Icons.sync,
                  title: 'Sync Favorites',
                  subtitle: 'Sync your favorites across all devices',
                  type: SettingsTileType.action,
                  disabled: _isProcessing,
                  onTap:
                      _isProcessing
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
                            final favoritesProvider =
                                Provider.of<FavoritesProvider>(
                                  context,
                                  listen: false,
                                );
                            final uid = authProvider.user?.uid;
                            if (uid != null) {
                              await favoritesProvider.saveFavoritesToFirestore(
                                uid,
                              );
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

                  onTap: _clearCache,
                ),

                const Divider(),

                // Grouped legal and info section

                // New tiles for rating and feedback
                SettingsTile(
                  icon: Icons.star_border,
                  title: 'Rate & Review',
                  subtitle: 'Let others know what you think',
                  type: SettingsTileType.action,
                  disabled: _isProcessing,
                  onTap: () {
                    // TODO: Implement rating functionality
                  },
                ),
                SettingsTile(
                  icon: Icons.email_outlined,
                  title: 'Help & Feedback',
                  subtitle: 'Get help or send us feedback',
                  type: SettingsTileType.action,
                  disabled: _isProcessing,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => FeedbackForm(
                        onSubmitted: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                ),
                SettingsTile(
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'Learn more about the app',
                  type: SettingsTileType.action,
                  disabled: _isProcessing,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutPage(),
                      ),
                    );
                  },
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
                          _isLoggingOut
                              ? 'Logging out...'
                              : 'Clearing cache...',
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

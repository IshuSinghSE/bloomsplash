import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../../../core/constant/config.dart';
import '../../shared/widgets/custom_bottom_nav_bar.dart';
import '../../collections/screens/collections_page.dart' deferred as collections_page;
import '../../explore/screens/explore_page.dart' deferred as explore_page;
import '../../favorites/screens/favorites_page.dart' deferred as favorites_page;
import '../../settings/screens/settings_page.dart' deferred as settings_page;
import '../../upload/screens/upload_page.dart' deferred as upload_page;

class HomePage extends StatefulWidget {
  final Box preferencesBox;
  final int? initialSelectedIndex;
  const HomePage({
    super.key,
    required this.preferencesBox,
    this.initialSelectedIndex,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class DeferredPageLoader extends StatefulWidget {
  final Future<void> Function() loadLibrary;
  final Widget Function() builder;
  const DeferredPageLoader({super.key, required this.loadLibrary, required this.builder});

  @override
  State<DeferredPageLoader> createState() => _DeferredPageLoaderState();
}

class _DeferredPageLoaderState extends State<DeferredPageLoader> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    widget.loadLibrary().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loaded) {
      return widget.builder();
    }
    return const Center(child: CircularProgressIndicator());
  }
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;
  late final List<Widget> pages;
  late final List<String> tabTitles;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex ?? 0;
    var userData = widget.preferencesBox.get('userData', defaultValue: {});
    final isAdmin = userData['isAdmin'] ?? false;
    pages = [
      DeferredPageLoader(
        loadLibrary: explore_page.loadLibrary,
        builder: () => explore_page.ExplorePage(),
      ),
      DeferredPageLoader(
        loadLibrary: collections_page.loadLibrary,
        builder: () => collections_page.CollectionsPage(),
      ),
      DeferredPageLoader(
        loadLibrary: favorites_page.loadLibrary,
        builder: () => favorites_page.FavoritesPage(),
      ),
      if (isAdmin)
        DeferredPageLoader(
          loadLibrary: upload_page.loadLibrary,
          builder: () => upload_page.UploadPage(),
        ),
    ];
// Widget to handle deferred loading of a page

// Widget to handle deferred loading of a page
    tabTitles = [
      "BloomSplash",
      "Collections",
      "Favorites",
      if (isAdmin) "Upload",
    ];
  }

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            tabTitles[_selectedIndex],
            style: const TextStyle(
              fontFamily: 'Raleway',
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: CircleAvatar(
                backgroundImage:
                    widget.preferencesBox.get('userData')?['photoUrl'] != null
                        ? NetworkImage(
                          widget.preferencesBox.get('userData')['photoUrl'],
                        )
                        : AssetImage(AppConfig.avatarIconPath) as ImageProvider,
              ),
              onPressed: () async {
                await settings_page.loadLibrary();
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => settings_page.SettingsPage()),
                );
              },
            ),
          ),
        ],
      ),
      
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          if (index < pages.length) {
            onItemTapped(index);
          }
        },
      ),
    );
  }
}
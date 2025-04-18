import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/data.dart'; // Import the dummy data
import 'collection_wallpapers_page.dart'; // Import the collection wallpapers page
import 'category_wallpapers_page.dart';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  String selectedCategory = "All"; // Track the selected chip

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      // appBar: AppBar(
      //   title: const Text('Collections'),
      // ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggleable Chips
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 20.0,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildChip("All"),
                    _buildChip("Nature"),
                    _buildChip("Abstract"),
                    _buildChip("Minimalist"),
                    _buildChip("Sci-Fi"),
                    _buildChip("Space"),
                  ],
                ),
              ),
            ),
            // Collections Sections
            ...collections.entries.map((entry) {
              final sectionTitle = entry.key;
              final sectionItems = entry.value;
              return _buildCollectionSection(sectionTitle, sectionItems);
            }),
            // Curated Categories Section
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                'Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: SizedBox(
                height: 140, // Height of the carousel
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Padding(
                      padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to the category wallpapers page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              // Navigate to the category wallpapers page bottom row
                              builder:
                                  (context) => CategoryWallpapersPage(
                                    category: category["title"]!,
                                    wallpapers:
                                        categoryWallpapers[category["title"]!] ??
                                        [],
                                  ),
                            ),
                          );
                        },
                        child: Container(
                          width: 140, // Width of each card
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: AssetImage(category["image"]!),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Gradient overlay for text readability
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withOpacity(0.6),
                                        Colors.black.withOpacity(0.1),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                ),
                              ),
                              // Category title and icon
                              Positioned(
                                bottom: 8,
                                left: 8,
                                right: 8,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        category["title"]!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Add bottom space
            const SizedBox(height: 80), // Adjust height as needed
          ],
        ),
      ),
    );
  }

  // Build a single chip
  Widget _buildChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        backgroundColor: const Color.fromARGB(255, 56, 91, 114).withOpacity(0.1),
        selectedColor: const Color.fromARGB(255, 56, 91, 114).withOpacity(0.7),
        label: Text(label),
        selected: selectedCategory == label,
        onSelected: (isSelected) {
          setState(() {
            selectedCategory = label;
          });
        },
      ),
    );
  }

  // Build a collection section { featured, curated, popular }
  // with a title and a list of wallpapers
  Widget _buildCollectionSection(
    String title,
    List<Map<String, dynamic>> wallpapers,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Column(
            children:
                wallpapers.take(3).map((wallpaper) {
                  final image =
                      wallpaper["image"] ?? "assets/sample/1744480267990.png";
                  final title = wallpaper["title"] ?? "Untitled";
                  final author = wallpaper["author"] ?? "Unknown";

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Background image
                          // if (image.isNotEmpty)
                          // Image.asset(
                          //   image,
                          //   width: double.infinity,
                          //   height: 100,
                          //   fit: BoxFit.cover,
                          // ),
                          // Blur overlay
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                color: const Color.fromARGB(
                                  255,
                                  56,
                                  91,
                                  114,
                                ).withOpacity(0.15),
                              ),
                            ),
                          ),
                          // Content
                          ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                image,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              "By $author",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            onTap: () {
                              // Navigate to the collection wallpapers page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => CollectionWallpapersPage(
                                        title: title ?? "Untitled",
                                        author: author ?? "Unknown",
                                        wallpapers:
                                            wallpaper["wallpapers"] ?? [],
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () {
                // Navigate to the collection wallpapers page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => CollectionWallpapersPage(
                          title: title,
                          author: wallpapers[0]["author"],
                          wallpapers: wallpapers,
                        ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                
                // backgroundColor: const Color.fromARGB(20, 56, 91, 114),
                side: const BorderSide(color:Color.fromARGB(200, 56, 91, 114), width: 1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                
                'Show All',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

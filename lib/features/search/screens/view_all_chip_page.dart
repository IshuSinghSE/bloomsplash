import 'package:flutter/material.dart';
import './search_chip_widgets.dart';
import 'package:bloomsplash/app/services/firebase/search_db.dart';
import './search_detail_page.dart';

class ViewAllChipPage extends StatelessWidget {
  final String type; // "Color", "Category", or "Tags"
  final List<dynamic> items; // List of colors, categories, or tags

  const ViewAllChipPage({
    super.key,
    required this.type,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 4, 5, 14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('$type', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
            childAspectRatio: 1,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            String label = item is Map ? item['label'] : item.toString();
            Widget chip;
            switch (type) {
              case 'Color':
                chip = ColorChip(label: label, color: item['color']);
                break;
              case 'Category':
                chip = CategoryChip(label: label, icon: item['icon'], color: item['color']);
                break;
              case 'Tags':
                chip = TagChip(label: label);
                break;
              default:
                chip = const SizedBox.shrink();
            }
            return GestureDetector(
              onTap: () async {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );
                List<Map<String, dynamic>> results = [];
                if (type == 'Color') {
                  results = await SearchDb.searchByColor(label.toLowerCase());
                } else if (type == 'Category') {
                  results = await SearchDb.searchByCategory(label.toLowerCase());
                } else if (type == 'Tags') {
                  results = await SearchDb.searchByTag(label.toLowerCase());
                }
                Navigator.of(context).pop(); // Remove loading
                // Navigate to SearchDetailPage and show the search UI with the query
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchDetailPage(
                      wallpapers: results,
                      scrollController: ScrollController(),
                      isLoading: false,
                      hasReachedEnd: true,
                      onRefresh: () async {
                        if (type == 'Color') {
                          await SearchDb.searchByColor(label.toLowerCase());
                        } else if (type == 'Category') {
                          await SearchDb.searchByCategory(label.toLowerCase());
                        } else if (type == 'Tags') {
                          await SearchDb.searchByTag(label.toLowerCase());
                        }
                      },
                      result: results.isNotEmpty ? results.first : {},
                      initialQuery: label,
                    ),
                  ),
                );
              },
              child: chip,
            );
          },
        ),
      ),
    );
  }
}
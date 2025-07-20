import 'package:flutter/material.dart';
import 'package:bloomsplash/features/search/screens/search_chip_widgets.dart';
import 'package:bloomsplash/features/search/screens/view_all_chip_page.dart';
import 'package:bloomsplash/app/constants/category_list.dart';
import 'package:bloomsplash/app/constants/colors_list.dart';
import 'package:bloomsplash/app/constants/tags_list.dart';

class SearchDefaultPage extends StatelessWidget {
  final void Function(String label, String type)? onChipTap;
  const SearchDefaultPage({super.key, this.onChipTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Chips
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                const Text(
                  'Browse by ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFC700),
                  ),
                ),
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewAllChipPage(
                          type: 'Category',
                          items: kCategoryList,
                        ),
                      ),
                    );
                  },
                  child: const Text('View all'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (var chip in kCategoryList)
                  GestureDetector(
                    onTap: () async {
                      final label = chip['label'] as String;
                      if (onChipTap != null) {
                        onChipTap!(label, 'Category');
                      }
                    },
                    child: CategoryChip(
                      label: chip['label'] as String,
                      icon: chip['icon'] as IconData,
                      color: chip['color'] as Color,
                    ),
                  ),
              ],
            ),
          ),
          // Color Chips
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Row(
              children: [
                const Text(
                  'Browse by ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF00B8D9),
                  ),
                ),
                const Text(
                  'Color',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewAllChipPage(
                          type: 'Color',
                          items: kColorList,
                        ),
                      ),
                    );
                  },
                  child: const Text('View all'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (var chip in kColorList)
                  GestureDetector(
                    onTap: () async {
                      final label = chip['label'] as String;
                      if (onChipTap != null) {
                        onChipTap!(label, 'Color');
                      }
                    },
                    child: ColorChip(
                      label: chip['label'] as String,
                      color: chip['color'] as Color,
                    ),
                  ),
              ],
            ),
          ),
          // Tag Chips
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Row(
              children: [
                const Text(
                  'Browse by ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFC700),
                  ),
                ),
                const Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewAllChipPage(
                          type: 'Tags',
                          items: kTagList.map((e) => {'label': e}).toList(),
                        ),
                      ),
                    );
                  },
                  child: const Text('View all'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (var label in kTagList)
                  GestureDetector(
                    onTap: () async {
                      if (onChipTap != null) {
                        onChipTap!(label, 'Tags');
                      }
                    },
                    child: TagChip(label: label),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

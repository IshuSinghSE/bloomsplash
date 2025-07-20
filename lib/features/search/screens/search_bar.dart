import 'package:flutter/material.dart';

class SearchBar extends StatefulWidget {
  /// Call this to programmatically set the search text
  static void setSearchText(BuildContext context, String text) {
    final state = context.findAncestorStateOfType<_SearchBarState>();
    state?._setSearchText(text);
  }
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final TextEditingController? controller;
  const SearchBar({super.key, this.onChanged, this.onSubmitted, this.autofocus = false, this.controller});

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  void _setSearchText(String text) {
    _searchController.text = text;
    _searchController.selection = TextSelection.fromPosition(TextPosition(offset: text.length));
    if (widget.onChanged != null) widget.onChanged!(text);
  }
  TextEditingController get _searchController => widget.controller ?? _internalController;
  final TextEditingController _internalController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            autofocus: widget.autofocus,
            decoration: InputDecoration(
              hintText: 'Search wallpapers',
              hintStyle: const TextStyle(color: Colors.white70),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: const Icon(Icons.search, color: Colors.white),
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: ValueListenableBuilder(
                  valueListenable: _searchController,
                  builder: (context, TextEditingValue value, _) {
                    if (value.text.isEmpty) return SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        _searchController.clear();
                        if (widget.onChanged != null) widget.onChanged!("");
                        // Instantly close keyboard using native unfocus
                        _focusNode.unfocus();
                      },
                    );
                  },
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 24.0,
                horizontal: 4.0,
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

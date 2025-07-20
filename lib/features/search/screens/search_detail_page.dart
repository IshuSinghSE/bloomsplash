import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../explore/widgets/wallpaper_card.dart';
import '../../../core/constant/config.dart';
import '../../shared/widgets/fade_placeholder_image.dart';
import 'search_bar.dart' as custom;
import 'package:bloomsplash/app/services/firebase/search_db.dart';
import 'package:bloomsplash/app/providers/search_provider.dart';


class SearchDetailPage extends StatefulWidget {
  final List<Map<String, dynamic>> wallpapers;
  final ScrollController? scrollController;
  final bool isLoading;
  final bool hasReachedEnd;
  final Future<void> Function()? onRefresh;
  final String? initialQuery;
  final Map<String, dynamic> result;
  final TextEditingController? controller;

  const SearchDetailPage({
    Key? key,
    required this.wallpapers,
    this.scrollController,
    this.isLoading = false,
    this.hasReachedEnd = false,
    this.onRefresh,
    this.initialQuery,
    required this.result,
    this.controller,
  }) : super(key: key);

  @override
  State<SearchDetailPage> createState() => _SearchDetailPageState();
}

class _SearchDetailPageState extends State<SearchDetailPage> {
  late List<Map<String, dynamic>> wallpapers;
  late bool isLoading;
  late bool hasReachedEnd;
  late String? query;
  ScrollController? scrollController;

  @override
  void initState() {
    super.initState();
    wallpapers = widget.wallpapers;
    isLoading = widget.isLoading;
    hasReachedEnd = widget.hasReachedEnd;
    query = widget.initialQuery;
    scrollController = widget.scrollController ?? ScrollController();
    if (widget.controller != null && query != null) {
      widget.controller!.text = query!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, popResult) {
        if (!didPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 0.0),
                child: custom.SearchBar(
                  controller: widget.controller ?? TextEditingController(text: query ?? ''),
                  autofocus: false,
                  onChanged: null,
                  onSubmitted: (val) async {
                    final trimmed = val.trim();
                    if (trimmed.isNotEmpty) {
                      setState(() {
                        isLoading = true;
                        query = trimmed;
                      });
                      if (widget.controller != null) {
                        widget.controller!.text = trimmed;
                      }
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator()),
                      );
                      final searchProvider = SearchProvider();
                      List<Map<String, dynamic>> results = await searchProvider.search(
                        trimmed,
                        (q) async {
                          List<Map<String, dynamic>> r = await SearchDb.searchByColor(q.toLowerCase());
                          if (r.isEmpty) r = await SearchDb.searchByCategory(q.toLowerCase());
                          if (r.isEmpty) r = await SearchDb.searchByTag(q.toLowerCase());
                          if (r.isEmpty) r = await SearchDb.searchAllFields(q, limit: 20);
                          return r;
                        },
                      );
                      Navigator.of(context).pop(); // Remove loading
                      setState(() {
                        wallpapers = results;
                        isLoading = false;
                        hasReachedEnd = true;
                      });
                    }
                  },
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: widget.onRefresh ?? () async {},
                  child: isLoading
                      ? CustomScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.all(8.0),
                              sliver: SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 0.75,
                                    ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    return WallpaperCard(
                                      wallpaper: {
                                        'title': 'Loading...',
                                        'author': '....',
                                        'isFavorite': false,
                                        'thumbnail': AppConfig.shimmerImagePath,
                                        'url': '',
                                        'status': 'approved',
                                      },
                                      onFavoritePressed: () {},
                                      imageBuilder:
                                          (context) => FadePlaceholderImage(
                                            path: AppConfig.shimmerImagePath,
                                          ),
                                    );
                                  },
                                  childCount: 8,
                                  addAutomaticKeepAlives: false,
                                  addRepaintBoundaries: true,
                                  addSemanticIndexes: false,
                                ),
                              ),
                            ),
                          ],
                        )
                      : wallpapers.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: MediaQuery.sizeOf(context).height * 0.7,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.image_not_supported_rounded,
                                        size: 70,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No wallpapers found',
                                        style: Theme.of(context).textTheme.titleLarge
                                            ?.copyWith(color: Colors.grey[700]),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Try another search',
                                        style: Theme.of(context).textTheme.bodyMedium
                                            ?.copyWith(color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : CustomScrollView(
                              controller: scrollController,
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              slivers: [
                                SliverPadding(
                                  padding: const EdgeInsets.all(8.0),
                                  sliver: SliverGrid(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                          childAspectRatio: 0.75,
                                        ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final wallpaper = wallpapers[index];
                                        return WallpaperCard(
                                          wallpaper: wallpaper,
                                          onFavoritePressed:
                                              () {}, // You can add favorite logic here
                                          imageBuilder: (context) {
                                            final String? thumbnailUrl =
                                                wallpaper['thumbnail'];
                                            if (thumbnailUrl != null &&
                                                thumbnailUrl.startsWith('http')) {
                                              return CachedNetworkImage(
                                                imageUrl: thumbnailUrl,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                                useOldImageOnUrlChange: false,
                                                placeholder:
                                                    (context, url) => FadePlaceholderImage(
                                                      path: AppConfig.shimmerImagePath,
                                                    ),
                                                errorWidget:
                                                    (context, url, error) => const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        size: 50,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                              );
                                            } else {
                                              return const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            }
                                          },
                                        );
                                      },
                                      childCount: wallpapers.length,
                                      addAutomaticKeepAlives: false,
                                      addRepaintBoundaries: true,
                                      addSemanticIndexes: false,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/providers/favorites_provider.dart';
import '../widgets/details_container.dart';
import '../../../core/constant/config.dart';

class WallpaperDetailsPage extends StatefulWidget {
  final Map<String, dynamic> wallpaper;

  const WallpaperDetailsPage({super.key, required this.wallpaper});

  @override
  State<WallpaperDetailsPage> createState() => _WallpaperDetailsPageState();
}

class _WallpaperDetailsPageState extends State<WallpaperDetailsPage> {
  bool _showDetails = true;
  bool _showButtons = true;
  bool _showMetadata = false;

  @override
  void initState() {
    super.initState();
  }

  void _toggleMetadata() {
    setState(() {
      _showMetadata = !_showMetadata;
    });
  }

  void _closeMetadata() {
    if (_showMetadata) {
      setState(() {
        _showMetadata = false;
      });
    }
  }

  void _toggleDetailsAndButtons() {
    setState(() {
      _showDetails = !_showDetails;
      _showButtons = _showDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final String? thumbnailUrl = widget.wallpaper['thumbnail'];
    final String heroTag = widget.wallpaper['id'] ?? thumbnailUrl ?? '';
    final isFavorite = favoritesProvider.isFavorite(widget.wallpaper);

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            if (_showMetadata) {
              _closeMetadata();
            } else if (_showButtons && _showDetails) {
              _showButtons = false;
              _showDetails = false;
            } else {
              _showButtons = true;
              _showDetails = true;
            }
          });
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Hero(
                tag: heroTag,
                transitionOnUserGestures: true,
                createRectTween: (begin, end) => MaterialRectArcTween(begin: begin, end: end),
                child: Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    child: thumbnailUrl != null && thumbnailUrl.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: thumbnailUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (context, url) => Image.asset(
                              AppConfig.shimmerImagePath,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          ),
                  ),
                ),
              ),
            ),
            if (_showButtons)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 16,
                child: AnimatedOpacity(
                  opacity: _showButtons ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Tooltip(
                        message: "Back",
                        child: Container(
                          color: Colors.black.withAlpha(64),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_showButtons)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                right: 16,
                child: AnimatedOpacity(
                  opacity: _showButtons ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Tooltip(
                        message: "Preview",
                        child: Container(
                          color: Colors.black.withAlpha(64),
                          child: IconButton(
                            icon: Icon(_showDetails ? Icons.visibility_off : Icons.visibility, color: Colors.white),
                            onPressed: _toggleDetailsAndButtons,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Hero(
                tag: 'details_${widget.wallpaper['id']}',
                flightShuttleBuilder: (flightContext, animation, direction, fromContext, toContext) {
                  return FadeTransition(
                    opacity: animation,
                    child: Material(
                      color: Colors.transparent,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: DetailsContainer(
                          wallpaper: widget.wallpaper,
                          showMetadata: _showMetadata,
                          toggleMetadata: _toggleMetadata,
                          isFavorite: isFavorite,
                          toggleFavorite: () {
                            favoritesProvider.toggleFavorite(widget.wallpaper);
                          },
                          slideAnimation: const AlwaysStoppedAnimation(Offset.zero),
                        ),
                      ),
                    ),
                  );
                },
                createRectTween: (begin, end) {
                  return RectTween(
                    begin: begin,
                    end: end,
                  );
                },
                child: GestureDetector(
                  onTap: () {},
                  child: AnimatedOpacity(
                    opacity: _showDetails ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOutCubic,
                    child: DetailsContainer(
                      wallpaper: widget.wallpaper,
                      showMetadata: _showMetadata,
                      toggleMetadata: _toggleMetadata,
                      isFavorite: isFavorite,
                      toggleFavorite: () {
                        favoritesProvider.toggleFavorite(widget.wallpaper);
                      },
                      slideAnimation: const AlwaysStoppedAnimation(Offset.zero),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
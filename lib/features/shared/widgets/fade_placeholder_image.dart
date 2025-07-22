import 'package:flutter/material.dart';

class FadePlaceholderImage extends StatefulWidget {
  final String path;
  const FadePlaceholderImage({required this.path, Key? key}) : super(key: key);

  @override
  State<FadePlaceholderImage> createState() => _FadePlaceholderImageState();
}

class _FadePlaceholderImageState extends State<FadePlaceholderImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Image.asset(
        widget.path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}

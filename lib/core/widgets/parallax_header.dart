import 'dart:ui';
import 'package:flutter/material.dart';

class ParallaxHeader extends StatelessWidget {
  final Widget background;
  final Widget content;
  final double expandedHeight;
  final double collapsedHeight;

  const ParallaxHeader({
    super.key,
    required this.background,
    required this.content,
    this.expandedHeight = 300,
    this.collapsedHeight = kToolbarHeight + 40,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _ParallaxHeaderDelegate(
        background: background,
        content: content,
        expandedHeight: expandedHeight,
        collapsedHeight: collapsedHeight,
        topPadding: MediaQuery.of(context).padding.top,
      ),
    );
  }
}

class _ParallaxHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget background;
  final Widget content;
  final double expandedHeight;
  final double collapsedHeight;
  final double topPadding;

  _ParallaxHeaderDelegate({
    required this.background,
    required this.content,
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.topPadding,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = shrinkOffset / maxExtent;
    
    // Parallax effect for background
    // We move the background down by half the shrink offset to make it look like it's moving slower
    // Actually, to make it parallax, we can translate it.
    // Simple parallax: Alignment changes or Transform.translate.
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background with Parallax
        Positioned(
          top: -shrinkOffset * 0.5, // Move slower than scroll
          left: 0,
          right: 0,
          bottom: 0,
          child: Opacity(
            opacity: (1 - progress).clamp(0.0, 1.0), // Fade out as we scroll up? Or keep it? 
            // Let's keep it visible but maybe blur it?
            child: background,
          ),
        ),

        // Gradient overlay for text readability when collapsed
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: progress.clamp(0.0, 0.8)),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Content
        Positioned.fill(
          top: topPadding, // Respect status bar
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: content,
            ),
          ),
        ),
        
        // Blurred Glass effect when collapsed (optional, acts as AppBar)
        if (progress > 0.8)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: collapsedHeight + topPadding,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight + topPadding;

  @override
  bool shouldRebuild(covariant _ParallaxHeaderDelegate oldDelegate) {
    return expandedHeight != oldDelegate.expandedHeight ||
        collapsedHeight != oldDelegate.collapsedHeight ||
        background != oldDelegate.background ||
        content != oldDelegate.content;
  }
}

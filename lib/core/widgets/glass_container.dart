import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:customer_nzubia_global/core/theme/custom_theme_extension.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>();
    final design = theme.extension<AppDesignExtension>();

    // Default border radius from design extension if not provided
    final effectiveBorderRadius = borderRadius ?? 
        BorderRadius.circular(design?.cardBorderRadius ?? 16.0);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: (colors?.surfaceSlate ?? theme.colorScheme.surface).withValues(alpha: opacity),
              borderRadius: effectiveBorderRadius,
              border: border ?? Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                width: 1.0,
              ),
              // gradient: colors?.glassGradient, // Removed for minimalistic look
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

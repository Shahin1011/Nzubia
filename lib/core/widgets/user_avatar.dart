import 'package:flutter/material.dart';
import 'package:customer_nzubia_global/core/theme/custom_theme_extension.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name; // For initials fallback
  final double radius;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>();
    final primaryColor = colors?.neonCyan ?? theme.primaryColor;

    final initials = _getInitials(name);
    
    Widget avatarContent;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatarContent = ClipOval(
        child: Image.network(
          imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallback(primaryColor);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildFallback(primaryColor, isLoading: true);
          },
        ),
      );
    } else {
      avatarContent = _buildFallback(primaryColor);
    }

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.transparent, // Handled by content or fallback
        child: avatarContent,
      ),
    );
  }

  Widget _buildFallback(Color primaryColor, {bool isLoading = false}) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 1),
      ),
      alignment: Alignment.center,
      child: isLoading
          ? SizedBox(
              width: radius,
              height: radius,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            )
          : Text(
              _getInitials(name),
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

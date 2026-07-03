import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/core/theme/custom_theme_extension.dart';

class TrackingSearchBar extends StatefulWidget {
  const TrackingSearchBar({super.key});

  @override
  State<TrackingSearchBar> createState() => _TrackingSearchBarState();
}

class _TrackingSearchBarState extends State<TrackingSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final trackingNumber = _controller.text.trim();
    if (trackingNumber.isNotEmpty) {
      context.push('/track/$trackingNumber');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _controller,
        style: TextStyle(color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Track by code (e.g., NZ-260104-2193)',
          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          prefixIcon: Icon(Icons.search, color: theme.colorScheme.secondary),
          suffixIcon: IconButton(
            icon: Icon(Icons.arrow_forward, color: theme.colorScheme.secondary),
            onPressed: _handleSearch,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onSubmitted: (_) => _handleSearch(),
      ),
    );
  }
}

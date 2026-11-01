import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';

/// A wrapper around [AdvancedSwitch] providing standard Flutter Switch API
/// (`value` + `onChanged`), consistent theme styling, and brand colors.
class AppAdvancedSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final Color? activeColor;
  final Color? inactiveColor;
  final double width;
  final double height;
  final Widget? activeChild;
  final Widget? inactiveChild;
  final Widget? thumb;
  final BorderRadius? borderRadius;

  const AppAdvancedSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.activeColor,
    this.inactiveColor,
    this.width = 52.0,
    this.height = 30.0,
    this.activeChild,
    this.inactiveChild,
    this.thumb,
    this.borderRadius,
  });

  @override
  State<AppAdvancedSwitch> createState() => _AppAdvancedSwitchState();
}

class _AppAdvancedSwitchState extends State<AppAdvancedSwitch> {
  late final ValueNotifier<bool> _controller;

  @override
  void initState() {
    super.initState();
    _controller = ValueNotifier<bool>(widget.value);
    _controller.addListener(_handleValueChanged);
  }

  @override
  void didUpdateWidget(covariant AppAdvancedSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.value != widget.value) {
      _controller.value = widget.value;
    }
  }

  void _handleValueChanged() {
    if (widget.onChanged != null && _controller.value != widget.value) {
      widget.onChanged!(_controller.value);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleValueChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveActiveColor = widget.activeColor ?? AppTheme.primaryColor;
    final effectiveInactiveColor = widget.inactiveColor ??
        (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0));

    return AdvancedSwitch(
      controller: _controller,
      enabled: widget.enabled && widget.onChanged != null,
      activeColor: effectiveActiveColor,
      inactiveColor: effectiveInactiveColor,
      width: widget.width,
      height: widget.height,
      activeChild: widget.activeChild,
      inactiveChild: widget.inactiveChild,
      thumb: widget.thumb,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
        border: Border.all(
          color: isDark
              ? const Color(0xFF64748B).withValues(alpha: 0.6)
              : const Color(0xFFCBD5E1),
          width: 1.0,
        ),
      ),
    );
  }
}

/// A drop-in replacement for [SwitchListTile] using [AppAdvancedSwitch].
class AppAdvancedSwitchListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? secondary;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final EdgeInsetsGeometry? contentPadding;
  final Color? activeColor;
  final Color? inactiveColor;
  final double width;
  final double height;
  final bool enabled;

  const AppAdvancedSwitchListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.secondary,
    required this.value,
    required this.onChanged,
    this.contentPadding,
    this.activeColor,
    this.inactiveColor,
    this.width = 52.0,
    this.height = 30.0,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled && onChanged != null,
      contentPadding: contentPadding,
      leading: secondary,
      title: title,
      subtitle: subtitle,
      trailing: AppAdvancedSwitch(
        value: value,
        onChanged: onChanged,
        enabled: enabled,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        width: width,
        height: height,
      ),
      onTap: (enabled && onChanged != null) ? () => onChanged!(!value) : null,
    );
  }
}

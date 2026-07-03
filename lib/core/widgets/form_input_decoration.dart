import 'package:flutter/material.dart';

/// Helper class for consistent form input decorations across the app
/// Fixes label overlap and provides proper spacing
class FormInputDecoration {
  /// Creates an InputDecoration with proper label spacing and no overlap
  static InputDecoration create({
    required String label,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      errorText: errorText,
      enabled: enabled,
      
      // Fix label overlap by adding background color
      filled: true,
      fillColor: enabled ? Colors.transparent : Colors.grey.withValues(alpha: 0.1),
      
      // Proper spacing for floating label
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      
      // Label style with background to prevent overlap
      labelStyle: const TextStyle(
        fontSize: 14,
        height: 1.0, // Compact label height
      ),
      
      floatingLabelStyle: const TextStyle(
        fontSize: 14,
        height: 1.0,
        backgroundColor: Colors.transparent, // No background when floating
      ),
      
      // Border configuration
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(width: 1),
      ),
      
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF22878D), width: 2),
      ),
      
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      
      // Floating behavior - label moves up with gap
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }
  
  /// Alternative style with filled background
  static InputDecoration createFilled({
    required String label,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
    Color? fillColor,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      errorText: errorText,
      
      // Filled style
      filled: true,
      fillColor: fillColor ?? Colors.grey.shade100,
      
      // Extra padding for filled style
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      
      // Label styles
      labelStyle: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade700,
      ),
      
      floatingLabelStyle: const TextStyle(
        fontSize: 14,
        color: Color(0xFF22878D),
      ),
      
      // Rounded borders
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF22878D), width: 2),
      ),
      
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }
}

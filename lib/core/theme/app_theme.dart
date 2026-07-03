import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_nzubia_global/core/theme/custom_theme_extension.dart';

class AppTheme {
  // --- Core Palette (Deep Slate & Neon) ---
  static const Color _deepSlate = Color(0xFF0F172A); // Main Background
  static const Color _surfaceSlate = Color(0xFF1E293B); // Cards / Surface
  static const Color _lightSlate = Color(0xFF334155); // Borders / Dividers

  static const Color _neonCyan = Color(0xFF22878D); // Primary Action
  static const Color _neonPurple = Color(0xFFAC663E); // Secondary / Accent
  static const Color _neonLime = Color(0xFFA3E635); // Success / Highlight
  static const Color _errorRed = Color(0xFFEF4444); // Error

  // --- Brand Palette (Light Mode) ---
  static const Color _brandGreen = Color(0xFF22878D); // Primary
  static const Color _brandBrown = Color(0xFFAC663E); // Secondary/Accent
  static const Color _brandLightGray = Color(0xFFCCCCCC); // Surface/Borders
  static const Color _brandGray = Color(0xFF666666); // Text/Subtitles
  static const Color _brandWhite = Color(0xFFF9F9F9); // Main Background Light

  static const Color primaryColor = _neonCyan;
  static const Color secondaryColor = _neonPurple;
  static const Color darkGray = Color(0xFF4B5563); // Cool Gray 600
  static const Color errorColor = _errorRed; // Used by p2p screens

  // --- Gradients ---
  static const LinearGradient _primaryGradient = LinearGradient(
    colors: [_neonCyan, _neonCyan], // Solid color for minimalist look
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient _glassGradient = LinearGradient(
    colors: [
      Color(0x1FFFFFFF), // White with 12% opacity
      Color(0x05FFFFFF), // White with 2% opacity
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
    static const LinearGradient _lightGradient = LinearGradient(
    colors: [_brandGreen, _brandGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient _lightGlassGradient = LinearGradient(
    colors: [
      Color(0x1F000000), // Black with 12% opacity
      Color(0x05000000), // Black with 2% opacity
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.outfitTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _brandWhite, // Light background
      primaryColor: _brandGreen,

      colorScheme: const ColorScheme.light(
        primary: _brandGreen,
        onPrimary: Colors.white,
        secondary: _brandBrown,
        onSecondary: Colors.white,
        surface: Colors.white, // Card surface
        onSurface: _brandGray,
        error: _errorRed,
        onError: Colors.white,
        outline: _brandLightGray,
      ),

      // --- Extensions ---
      extensions: <ThemeExtension<dynamic>>[
        const AppColorsExtension(
          success: Color(0xFF10B981), // Standard Green for success in light mode
          warning: Color(0xFFF59E0B),
          info: _brandGreen,
          deepSlate: _brandWhite, // Reused as background
          surfaceSlate: Colors.white, // Reused as surface
          neonCyan: _brandGreen, // Primary action
          neonPurple: _brandBrown, // Accent
          neonLime: Color(0xFF10B981),
          glassGradient: _lightGlassGradient,
          primaryGradient: _lightGradient,
        ),
        const AppDesignExtension(
          cardBorderRadius: 16.0,
          buttonBorderRadius: 12.0,
          glowShadow: BoxShadow(
            color: Color(0x1A22878D), // Subtle Green Shadow
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ),
      ],

      // --- Typography ---
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: Colors.black87,
          letterSpacing: -1.0,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          letterSpacing: -0.5,
        ),
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
           fontWeight: FontWeight.w600,
           color: Colors.black87,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
           fontWeight: FontWeight.w500,
           color: Colors.black87,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
           fontWeight: FontWeight.w500,
           color: Colors.black87,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: Colors.black87,
          fontSize: 16,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: _brandGray,
          fontSize: 14,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: _brandGray,
          fontSize: 12,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          color: Colors.white, // Button text usually white on primary
          fontWeight: FontWeight.w600,
        ),
      ),

      // --- Component Themes ---
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        actionsIconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Outfit',
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _brandGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: _brandGreen.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Outfit',
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _brandGreen,
          textStyle: const TextStyle(
             fontWeight: FontWeight.w600,
             fontFamily: 'Outfit',
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _brandGreen,
          side: const BorderSide(color: _brandGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Outfit',
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        
        // Fix label overlap - add proper spacing
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        
        // Label styles with proper spacing
        labelStyle: const TextStyle(
          color: _brandGray,
          fontSize: 14,
        ),
        
        floatingLabelStyle: const TextStyle(
          color: _brandGreen,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        
        hintStyle: TextStyle(color: _brandGray.withValues(alpha: 0.5)),
        
        // Floating behavior - auto moves label up with proper gap
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        
        // Icon colors
        prefixIconColor: _brandGray,
        suffixIconColor: _brandGray,
        
        // Borders with proper spacing
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _brandLightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _brandLightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _brandGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _errorRed, width: 2),
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _brandLightGray, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      iconTheme: const IconThemeData(
        color: _brandGray,
      ),

      dividerTheme: const DividerThemeData(
        color: _brandLightGray,
        thickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF334155),
        contentTextStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
        actionTextColor: _brandGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      popupMenuTheme: const PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        textStyle: TextStyle(color: Colors.black87),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _brandGreen,
        unselectedItemColor: _brandGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData get darkTheme {
    // We are essentially building a "Dark Mode" aesthetic as the default "Light Theme"
    // because the design requirement specifies "Deep Slate" which is dark.
    // If a true light mode is needed later, we can add get darkTheme.

    final baseTextTheme = GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _deepSlate,
      primaryColor: _neonCyan,

      colorScheme: const ColorScheme.dark(
        primary: _neonCyan,
        onPrimary: Colors.black, // Text on neon should be dark for contrast
        secondary: _neonPurple,
        onSecondary: Colors.white,
        surface: _surfaceSlate,
        onSurface: Colors.white,
        error: _errorRed,
        onError: Colors.white,
        outline: _lightSlate,
      ),

      // --- Extensions ---
      extensions: <ThemeExtension<dynamic>>[
        const AppColorsExtension(
          success: _neonLime,
          warning: Color(0xFFF59E0B),
          info: _neonCyan,
          deepSlate: _deepSlate,
          surfaceSlate: _surfaceSlate,
          neonCyan: _neonCyan,
          neonPurple: _neonPurple,
          neonLime: _neonLime,
          glassGradient: _glassGradient,
          primaryGradient: _primaryGradient,
        ),
        const AppDesignExtension(
          cardBorderRadius: 16.0,
          buttonBorderRadius: 12.0,
          glowShadow: BoxShadow(
            color: Color(0x6606B6D4), // Neon Cyan glow
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ),
      ],

      // --- Typography ---
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -1.0,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: Colors.white70,
          fontSize: 16,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: Colors.white60,
          fontSize: 14,
        ),
      ),

      // --- Component Themes ---
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Glassmorphism handled by widgets
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Outfit', // Ensure font matches
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _neonCyan,
          foregroundColor: Colors.black, // Contrast on neon
          elevation: 0,
          shadowColor: _neonCyan.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Outfit',
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _neonCyan,
          side: const BorderSide(color: _neonCyan, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Outfit',
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceSlate.withValues(alpha: 0.5),
        
        // Fix label overlap - add proper spacing
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        
        // Label styles
        labelStyle: const TextStyle(
          color: Colors.white54,
          fontSize: 14,
        ),
        
        floatingLabelStyle: const TextStyle(
          color: _neonCyan,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        
        hintStyle: const TextStyle(color: Colors.white30),
        
        // Floating behavior
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        
        // Icon colors
        prefixIconColor: Colors.white54,
        suffixIconColor: Colors.white54,
        
        // Borders
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightSlate),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightSlate),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _neonCyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _errorRed, width: 2),
        ),
      ),

      cardTheme: CardThemeData(
        color: _surfaceSlate,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _lightSlate, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      iconTheme: const IconThemeData(
        color: Colors.white,
      ),

      dividerTheme: const DividerThemeData(
        color: _lightSlate,
        thickness: 1,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _surfaceSlate,
        selectedItemColor: _neonCyan,
        unselectedItemColor: Colors.white60,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: _surfaceSlate,
        contentTextStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
        actionTextColor: _neonCyan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

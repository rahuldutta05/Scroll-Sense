import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF6366F1);       // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color accent = Color(0xFFFF6B6B);        // Coral
  static const Color success = Color(0xFF10B981);       // Emerald
  static const Color warning = Color(0xFFF59E0B);       // Amber
  static const Color danger = Color(0xFFEF4444);        // Red

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF6366F1),
    Color(0xFFFF6B6B),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: accent,
        surface: const Color(0xFFF8F9FF),
        background: const Color(0xFFF0F1FF),
      ),
      scaffoldBackgroundColor: const Color(0xFFF0F1FF),
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge: GoogleFonts.dmSans(
          fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF1A1B3E),
        ),
        displayMedium: GoogleFonts.dmSans(
          fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF1A1B3E),
        ),
        titleLarge: GoogleFonts.dmSans(
          fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1A1B3E),
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1B3E),
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16, fontWeight: FontWeight.w400, color: const Color(0xFF3D3F6E),
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF3D3F6E),
        ),
        labelSmall: GoogleFonts.dmSans(
          fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF7B7FA6),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        shadowColor: Colors.black.withOpacity(0.08),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primaryLight,
        secondary: accent,
        surface: const Color(0xFF1E1F3A),
        background: const Color(0xFF13142B),
      ),
      scaffoldBackgroundColor: const Color(0xFF13142B),
      textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.dmSans(
          fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white,
        ),
        displayMedium: GoogleFonts.dmSans(
          fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white,
        ),
        titleLarge: GoogleFonts.dmSans(
          fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16, color: const Color(0xFFB8BAE0),
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14, color: const Color(0xFFB8BAE0),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1F3A),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

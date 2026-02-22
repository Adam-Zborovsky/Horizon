import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Obsidian & Gold Palette
  static const Color obsidian = Color(0xFF0C0C0C);
  static const Color goldAmber = Color(0xFFFFB800);
  static const Color softCrimson = Color(0xFFFF4B5C); // For negative price movements
  static const Color glassWhite = Color(0x14FFFFFF);
  static const Color cardGrey = Color(0xFF161618);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: obsidian,
      colorScheme: ColorScheme.fromSeed(
        seedColor: goldAmber,
        brightness: Brightness.dark,
        primary: goldAmber,
        secondary: goldAmber.withOpacity(0.8),
        surface: obsidian,
        surfaceContainerHigh: cardGrey,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.montserrat(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -1,
        ),
        displayMedium: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: Colors.white.withOpacity(0.9),
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
      cardTheme: CardThemeData(
        color: glassWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: obsidian,
        selectedItemColor: goldAmber,
        unselectedItemColor: Colors.white24,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}

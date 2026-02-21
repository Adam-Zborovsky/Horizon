import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color darkBg = Color(0xFF0A0A0B);
  static const Color cardBg = Color(0xFF141416);
  static const Color glassCardBg = Color(0x1AFFFFFF); // Low opacity for glass effect
  static const Color positiveGreen = Color(0xFF00C805);
  static const Color negativeRed = Color(0xFFFF3B30);
  static const Color neutralBlue = Color(0xFF007AFF);
  static const Color textMain = Colors.white;
  static const Color textDim = Color(0xFFA1A1AA);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: neutralBlue,
      colorScheme: const ColorScheme.dark(
        primary: neutralBlue,
        surface: cardBg,
        onSurface: textMain,
        error: negativeRed,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: textMain,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textMain,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textMain,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: textMain),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textDim),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: textDim),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static BoxDecoration glassCardDecoration(double sentiment) {
    final color = getSentimentColor(sentiment);
    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.1),
          blurRadius: 24,
          spreadRadius: 2,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static Color getSentimentColor(double sentiment) {
    if (sentiment > 0.3) return positiveGreen;
    if (sentiment < -0.3) return negativeRed;
    return neutralBlue;
  }
}

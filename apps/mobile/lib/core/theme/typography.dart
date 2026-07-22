import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme getTextTheme(bool isDark) {
    ThemeData base = isDark ? ThemeData.dark() : ThemeData.light();
    
    final jakartaTextTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

    return jakartaTextTheme.copyWith(
      displayLarge: jakartaTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 32),
      displayMedium: jakartaTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 28),
      displaySmall: jakartaTextTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 24),
      headlineLarge: jakartaTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 22),
      headlineMedium: jakartaTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 20),
      headlineSmall: jakartaTextTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
      titleLarge: jakartaTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
      titleMedium: jakartaTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
      titleSmall: jakartaTextTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
      bodyLarge: jakartaTextTheme.bodyLarge?.copyWith(fontSize: 16),
      bodyMedium: jakartaTextTheme.bodyMedium?.copyWith(fontSize: 14),
      bodySmall: jakartaTextTheme.bodySmall?.copyWith(fontSize: 12),
      labelLarge: jakartaTextTheme.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: jakartaTextTheme.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: jakartaTextTheme.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    );
  }
}

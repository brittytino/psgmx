import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme getTextTheme(bool isDark) {
    ThemeData base = isDark ? ThemeData.dark() : ThemeData.light();
    
    final interTextTheme = GoogleFonts.interTextTheme(base.textTheme);
    final soraTextTheme = GoogleFonts.soraTextTheme(base.textTheme);

    return interTextTheme.copyWith(
      displayLarge: soraTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 32),
      displayMedium: soraTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 28),
      displaySmall: soraTextTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 24),
      headlineLarge: soraTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 22),
      headlineMedium: soraTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 20),
      headlineSmall: soraTextTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
      titleLarge: soraTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
      titleMedium: soraTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
      titleSmall: soraTextTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
      bodyLarge: interTextTheme.bodyLarge?.copyWith(fontSize: 16),
      bodyMedium: interTextTheme.bodyMedium?.copyWith(fontSize: 14),
      bodySmall: interTextTheme.bodySmall?.copyWith(fontSize: 12),
      labelLarge: interTextTheme.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: interTextTheme.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: interTextTheme.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    );
  }
}

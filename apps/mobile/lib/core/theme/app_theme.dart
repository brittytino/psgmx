import 'package:flutter/material.dart';
import 'app_dimens.dart';
import 'typography.dart';

/// Custom theme extension for semantic colors
class SemanticColors extends ThemeExtension<SemanticColors> {
  final Color success;
  final Color successContainer;
  final Color onSuccess;
  final Color warning;
  final Color warningContainer;
  final Color onWarning;
  final Color info;
  final Color infoContainer;
  final Color onInfo;
  final Color gold;
  final Color silver;
  final Color bronze;

  const SemanticColors({
    required this.success,
    required this.successContainer,
    required this.onSuccess,
    required this.warning,
    required this.warningContainer,
    required this.onWarning,
    required this.info,
    required this.infoContainer,
    required this.onInfo,
    required this.gold,
    required this.silver,
    required this.bronze,
  });

  @override
  SemanticColors copyWith({
    Color? success,
    Color? successContainer,
    Color? onSuccess,
    Color? warning,
    Color? warningContainer,
    Color? onWarning,
    Color? info,
    Color? infoContainer,
    Color? onInfo,
    Color? gold,
    Color? silver,
    Color? bronze,
  }) {
    return SemanticColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfo: onInfo ?? this.onInfo,
      gold: gold ?? this.gold,
      silver: silver ?? this.silver,
      bronze: bronze ?? this.bronze,
    );
  }

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      silver: Color.lerp(silver, other.silver, t)!,
      bronze: Color.lerp(bronze, other.bronze, t)!,
    );
  }

  static const light = SemanticColors(
    success: Color(0xFF059669),
    successContainer: Color(0xFFD1FAE5),
    onSuccess: Color(0xFF065F46),
    warning: Color(0xFFF59E0B),
    warningContainer: Color(0xFFFEF3C7),
    onWarning: Color(0xFF92400E),
    info: Color(0xFF3B82F6),
    infoContainer: Color(0xFFDEEBFF),
    onInfo: Color(0xFF1E40AF),
    gold: Color(0xFFFFD700),
    silver: Color(0xFFC0C0C0),
    bronze: Color(0xFFCD7F32),
  );

  static const dark = SemanticColors(
    success: Color(0xFF10B981),
    successContainer: Color(0xFF064E3B),
    onSuccess: Color(0xFFD1FAE5),
    warning: Color(0xFFFBBF24),
    warningContainer: Color(0xFF78350F),
    onWarning: Color(0xFFFEF3C7),
    info: Color(0xFF60A5FA),
    infoContainer: Color(0xFF1E3A8A),
    onInfo: Color(0xFFDEEBFF),
    gold: Color(0xFFFFD700),
    silver: Color(0xFFC0C0C0),
    bronze: Color(0xFFCD7F32),
  );
}

class AppTheme {
  // --- Daybreak Light Theme Colors ---
  static const Color _lightBg = Color(0xFFFBF6EE); // Paper Cream
  static const Color _lightSurface = Color(0xFFFFFFFF); 
  static const Color _lightBorder = Color(0xFFEFE9E0); // Subtle darker cream for borders
  
  static const Color _lightTextPrimary = Color(0xFF221F1A); // Ink primary

  static const Color _lightTextMuted = Color(0xFF9E9A92); // Muted ink

  // --- Daybreak Dark Theme Colors (Derived) ---
  static const Color _darkBg = Color(0xFF0C0C0E); 
  static const Color _darkSurface = Color(0xFF17171B); 
  static const Color _darkBorder = Color(0x1AFFFFFF); // Low opacity white
  
  static const Color _darkTextPrimary = Color(0xFFF5F4F2);

  static const Color _darkTextMuted = Color(0xFF6B7078);

  // --- Brand / Illustration Colors ---
  static const Color accentCoral = Color(0xFFFF6B4A);
  static const Color illusTerracotta = Color(0xFFE4572E);
  static const Color illusSage = Color(0xFF8FB996);
  static const Color illusGold = Color(0xFFE8B84B);

  // --- Methods ---

  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: accentCoral,
      onPrimary: Colors.white,
      secondary: accentCoral,
      onSecondary: _lightBg,
      surface: _lightSurface,
      onSurface: _lightTextPrimary,
      surfaceContainerHighest: _lightBg,
      error: Color(0xFFEF4743),
      onError: Colors.white,
      outline: _lightBorder,
    );

    return _buildTheme(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBg: _lightBg,
      surfaceColor: _lightSurface,
      borderColor: _lightBorder,
      textPrimary: _lightTextPrimary,
      textMuted: _lightTextMuted,
      semanticColors: SemanticColors.light,
    );
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: accentCoral,
      onPrimary: Colors.white,
      secondary: accentCoral,
      onSecondary: _darkBg,
      surface: _darkSurface,
      onSurface: _darkTextPrimary,
      surfaceContainerHighest: _darkSurface,
      error: Color(0xFFEF4743),
      onError: Colors.white,
      outline: _darkBorder,
    );

    return _buildTheme(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBg: _darkBg,
      surfaceColor: _darkSurface,
      borderColor: _darkBorder,
      textPrimary: _darkTextPrimary,
      textMuted: _darkTextMuted,
      semanticColors: SemanticColors.dark,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textMuted,
    required SemanticColors semanticColors,
  }) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      extensions: <ThemeExtension<dynamic>>[semanticColors],
      
      // Typography
      textTheme: AppTypography.getTextTheme(isDark),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF221F1A)),
      ),
      
      // Card Theme (flat cards, soft shadow on light, 1px border on both)
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: isDark ? 0 : 2, 
        shadowColor: isDark ? Colors.transparent : const Color(0xFFE8B84B).withValues(alpha: 0.05), // Soft warm shadow on light
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scaffoldBg,
        hintStyle: TextStyle(color: textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: accentCoral, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
      ),
      
      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentCoral,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: borderColor, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
        ),
      ),
      
      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: accentCoral,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : const Color(0xFF221F1A),
      ),
    );
  }
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Logical
  static const double cardPadding = md;
  static const double screenPadding = md;
  static const double elementSpacing = sm;

  // Responsive breakpoints (merged from the now-removed layout_tokens.dart)
  static const double tabletBreakpoint = 600.0;
  static const double desktopBreakpoint = 900.0;
  static const double maxContentWidth = 800.0;
}

class AppRadius {
  static const double sm = 4.0;
  static const double md = 12.0;
  // The de facto standard most existing "white card with border" list items
  // already converged on (today/community/interview_patterns/progress/etc.)
  // — the canonical radius for that pattern going forward via PremiumCard's
  // `radius` param, distinct from `md` which stays for smaller nested chips.
  static const double card = 18.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double pill = 100.0;
}

class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

import 'package:flutter/material.dart';

class AppSpacing {
  // Padding & Margin
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Max Content Widths
  static const double maxContentWidth = 800.0;
  static const double tabletBreakpoint = 600.0;
  static const double desktopBreakpoint = 900.0;
}

class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 28.0; // M3 Standard
}

class AppMotion {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration long = Duration(milliseconds: 600);
  
  static const Curve defaultCurve = Curves.easeInOutCubic;
}

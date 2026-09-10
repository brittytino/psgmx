import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  static const int destinationCount = 5;

  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    // Deep links and restored state may contain an index from an older app
    // version. Clamp it here so every navigation surface always receives a
    // valid selectedIndex and cannot trip a framework assertion.
    final normalizedIndex = index.clamp(0, destinationCount - 1).toInt();
    if (_currentIndex != normalizedIndex) {
      _currentIndex = normalizedIndex;
      notifyListeners();
    }
  }
}

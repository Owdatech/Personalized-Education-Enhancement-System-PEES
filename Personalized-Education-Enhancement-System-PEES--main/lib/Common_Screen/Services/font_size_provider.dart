import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSizeProvider with ChangeNotifier {
  double _fontSize = 16.0; // Default font size

  double get fontSize => _fontSize;

  Future<void> setFontSize(double newSize) async {
    _fontSize = newSize;
    notifyListeners();

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('fontSize', newSize);
  }

  Future<void> loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    notifyListeners();
  }
}

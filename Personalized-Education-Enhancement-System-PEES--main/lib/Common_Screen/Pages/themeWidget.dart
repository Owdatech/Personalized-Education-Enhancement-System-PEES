import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
   bool _isHighContrast = false;
  bool get isHighContrast => _isHighContrast;

  ThemeManager() {
    _loadTheme();
  }

  void toggleContrastMode() async {
    _isHighContrast = !_isHighContrast;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_contrast', _isHighContrast);
    notifyListeners();
  }

  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isHighContrast = prefs.getBool('high_contrast') ?? false;
    notifyListeners();
  }
}

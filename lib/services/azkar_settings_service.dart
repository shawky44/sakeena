// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AzkarSettingsService {
  static const String _fontSizeKey = 'azkar_font_size';
  static const String _cardColorKey = 'azkar_card_color';

  static const double defaultFontSize = 24.0;
  static const Color defaultCardColor = Color.fromARGB(240, 230, 237, 205);

  Future<void> saveFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, fontSize);
  }

  Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? defaultFontSize;
  }

  Future<void> saveCardColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cardColorKey, color.value);
  }

  Future<Color> getCardColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_cardColorKey);
    if (colorValue != null) {
      return Color(colorValue);
    }
    return defaultCardColor;
  }

  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fontSizeKey);
    await prefs.remove(_cardColorKey);
  }
}
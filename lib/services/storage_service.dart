// lib/services/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _favoritesKey = 'seerah_favorites';
  static const String _completedKey = 'seerah_completed';

  // حفظ المفضلة
  static Future<void> saveFavorites(Set<int> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _favoritesKey,
      favorites.map((id) => id.toString()).toList(),
    );
  }

  // جلب المفضلة
  static Future<Set<int>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesList = prefs.getStringList(_favoritesKey) ?? [];
    return favoritesList.map((id) => int.parse(id)).toSet();
  }

  // حفظ القصص المكتملة
  static Future<void> saveCompleted(Set<int> completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _completedKey,
      completed.map((id) => id.toString()).toList(),
    );
  }

  // جلب القصص المكتملة
  static Future<Set<int>> getCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final completedList = prefs.getStringList(_completedKey) ?? [];
    return completedList.map((id) => int.parse(id)).toSet();
  }

  // مسح كل البيانات (للتجربة)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoritesKey);
    await prefs.remove(_completedKey);
  }
}
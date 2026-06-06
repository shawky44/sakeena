// lib/services/azkar_storage_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/zikr_model.dart';

class AzkarStorageService {
  static const String _morningKey = 'azkar_progress_morning';
  static const String _eveningKey = 'azkar_progress_evening';
  static const String _sleepKey   = 'azkar_progress_sleep';

  static String _keyFor(String type) {
    switch (type) {
      case 'morning': return _morningKey;
      case 'evening': return _eveningKey;
      case 'sleep':   return _sleepKey;
      default:        return 'azkar_progress_$type';
    }
  }

  // ── حفظ كل الأذكار لنوع معين ─────────────────────────────────────────────
  static Future<void> saveProgress(
      String type, List<Zikr> azkarList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // نحفظ map من id → {currentCount, isCompleted}
      final Map<String, Map<String, dynamic>> progressMap = {};
      for (final z in azkarList) {
        progressMap[z.id] = {
          'currentCount': z.currentCount,
          'isCompleted': z.isCompleted,
        };
      }
      await prefs.setString(_keyFor(type), jsonEncode(progressMap));
      debugPrint('✅ Saved azkar progress for $type');
    } catch (e) {
      debugPrint('❌ Error saving azkar progress: $e');
    }
  }

  // ── تحميل وتطبيق الـ progress على list موجودة ────────────────────────────
  static Future<void> loadAndApplyProgress(
      String type, List<Zikr> azkarList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_keyFor(type));
      if (raw == null) return;

      final Map<String, dynamic> progressMap = jsonDecode(raw);

      // نتحقق من الـ date — لو يوم جديد نمسح
      final String? savedDateStr = prefs.getString('${_keyFor(type)}_date');
      if (savedDateStr != null) {
        final savedDate = DateTime.parse(savedDateStr);
        final now = DateTime.now();
        final isNewDay = now.year != savedDate.year ||
            now.month != savedDate.month ||
            now.day != savedDate.day;
        if (isNewDay) {
          await clearProgress(type);
          debugPrint('🔄 New day — cleared azkar progress for $type');
          return;
        }
      }

      // نطبق الـ progress على كل ذكر
      for (final z in azkarList) {
        if (progressMap.containsKey(z.id)) {
          final data = progressMap[z.id] as Map<String, dynamic>;
          z.currentCount = data['currentCount'] ?? 0;
          z.isCompleted  = data['isCompleted'] ?? false;
        }
      }
      debugPrint('✅ Loaded azkar progress for $type');
    } catch (e) {
      debugPrint('❌ Error loading azkar progress: $e');
    }
  }

  // ── مسح progress نوع معين ──────────────────────────────────────────────────
  static Future<void> clearProgress(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(type));
    await prefs.remove('${_keyFor(type)}_date');
  }

  // ── تسجيل تاريخ اليوم عند أول حفظ ────────────────────────────────────────
  static Future<void> stampToday(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_keyFor(type)}_date';
    if (prefs.getString(key) == null) {
      await prefs.setString(key, DateTime.now().toIso8601String());
    }
  }

  // ── مسح كل شيء (للـ midnight reset) ──────────────────────────────────────
  static Future<void> clearAll() async {
    await clearProgress('morning');
    await clearProgress('evening');
    await clearProgress('sleep');
    debugPrint('🗑️ All azkar progress cleared');
  }

  // ── جلب عدد المكتملين لنوع معين بدون تحميل الـ list ─────────────────────
  static Future<Map<String, int>> getProgressSummary(
      String type, int totalCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_keyFor(type));
      if (raw == null) return {'completed': 0, 'total': totalCount};

      final Map<String, dynamic> progressMap = jsonDecode(raw);
      int completed = 0;
      for (final entry in progressMap.values) {
        if ((entry as Map<String, dynamic>)['isCompleted'] == true) {
          completed++;
        }
      }
      return {'completed': completed, 'total': totalCount};
    } catch (e) {
      return {'completed': 0, 'total': totalCount};
    }
  }
}
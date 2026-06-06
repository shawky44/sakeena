// lib/services/journey_service.dart (إضافة في النهاية)

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journey_model.dart';
import '../models/zikr_model.dart';

class JourneyService {
  static const String _storageKey = 'journey_data';
  Timer? _midnightTimer;

  Future<JourneyData> loadJourneyData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(jsonString);
        final data = JourneyData.fromJson(json);

        if (data.needsDailyReset()) {
          debugPrint('🔄 Daily reset needed');
          data.resetForNewDay();
          await saveJourneyData(data);
        }

        return data;
      } catch (e) {
        debugPrint('Error loading journey data: $e');
        return JourneyData();
      }
    }

    return JourneyData();
  }

  Future<void> saveJourneyData(JourneyData data) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(data.toJson());
    await prefs.setString(_storageKey, jsonString);
    debugPrint('✅ Journey data saved');
  }

  Future<void> togglePrayer(JourneyData data, String prayerName) async {
    final currentValue = data.prayersCompleted[prayerName] ?? false;
    data.prayersCompleted[prayerName] = !currentValue;

    if (!currentValue) {
      data.totalPrayersCompleted++;
    } else {
      data.totalPrayersCompleted--;
    }

    await saveJourneyData(data);
  }

  // ✅ NEW: Update from Zikr list directly
  Future<void> syncAzkarProgressFromList(
    JourneyData data,
    String azkarType,
    List<Zikr> azkarList,
  ) async {
    final completed = azkarList.where((z) => z.isCompleted).length;
    final total = azkarList.length;

    await updateAzkarProgress(data, azkarType, completed, total);
  }

  Future<void> updateAzkarProgress(
    JourneyData data,
    String azkarType,
    int completed,
    int total,
  ) async {
    if (data.azkarProgress.containsKey(azkarType)) {
      final wasCompleted = data.azkarProgress[azkarType]!.isCompleted;
      
      data.azkarProgress[azkarType]!.completed = completed;
      data.azkarProgress[azkarType]!.total = total;

      final isNowCompleted = data.azkarProgress[azkarType]!.isCompleted;

      if (!wasCompleted && isNowCompleted) {
        data.totalAzkarCompleted++;
      } else if (wasCompleted && !isNowCompleted) {
        data.totalAzkarCompleted--;
      }

      await saveJourneyData(data);
    }
  }

  void scheduleMidnightReset(Function() onReset) {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    final durationUntilMidnight = nextMidnight.difference(now);

    debugPrint('⏰ Scheduling midnight reset at: $nextMidnight');

    _midnightTimer = Timer(durationUntilMidnight, () {
      debugPrint('🌙 Midnight reset triggered');
      onReset();
      scheduleMidnightReset(onReset);
    });
  }

  void dispose() {
    _midnightTimer?.cancel();
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    debugPrint('🗑️ Journey data cleared');
  }
}
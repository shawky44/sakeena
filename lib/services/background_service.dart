import 'package:flutter/material.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'prayer_notification_service.dart';

@pragma('vm:entry-point')
void dailyPrayerRefreshCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🔄 Daily prayer refresh triggered at ${DateTime.now()}');
  
  final service = PrayerBackgroundService();
  await service.scheduleDailyPrayers();
}

class PrayerBackgroundService {
  static const int _dailyRefreshId = 9999;

  Future<void> scheduleDailyPrayers() async {
    try {
      debugPrint('📅 Starting daily prayer scheduling...');
      
      // الحصول على الموقع
      final prefs = await SharedPreferences.getInstance();
      final cachedLat = prefs.getDouble('cached_lat');
      final cachedLon = prefs.getDouble('cached_lon');
      final cachedCountry = prefs.getString('cached_country');

      if (cachedLat == null || cachedLon == null) {
        debugPrint('⚠️ No cached location found');
        return;
      }

      // حساب أوقات الصلاة
      final prayerTimes = await _calculatePrayerTimes(
        cachedLat,
        cachedLon,
        cachedCountry,
      );

      // جدولة الإشعارات
      final notificationService = PrayerNotificationService();
      await notificationService.ensureInitialized();
      await notificationService.schedulePrayerNotifications(prayerTimes);

      debugPrint('✅ Daily prayers scheduled successfully');
    } catch (e) {
      debugPrint('❌ Error scheduling daily prayers: $e');
    }
  }

  Future<Map<String, DateTime>> _calculatePrayerTimes(
    double lat,
    double lon,
    String? country,
  ) async {
    final coordinates = Coordinates(lat, lon);
    final now = DateTime.now();
    final localDate = DateTime(now.year, now.month, now.day);

    final params = _getCalculationMethod(lat, lon, country);

    final prayerTimes = PrayerTimes(
      coordinates: coordinates,
      date: localDate,
      calculationParameters: params,
    );

    return {
      'Fajr': prayerTimes.fajr!.toLocal(),
      'Dhuhr': prayerTimes.dhuhr!.toLocal(),
      'Asr': prayerTimes.asr!.toLocal(),
      'Maghrib': prayerTimes.maghrib!.toLocal(),
      'Isha': prayerTimes.isha!.toLocal(),
    };
  }

  CalculationParameters _getCalculationMethod(double lat, double lon, String? country) {
    final countryLower = country?.toLowerCase() ?? '';
    CalculationParameters params;

    if (countryLower.contains('egypt') || countryLower.contains('مصر')) {
      params = CalculationMethod.egyptian();
    } else if (countryLower.contains('saudi') || countryLower.contains('السعودية')) {
      params = CalculationMethod.ummAlQura();
    } else {
      params = CalculationMethod.muslimWorldLeague();
    }

    params.madhab = Madhab.shafi;
    return params;
  }

  Future<void> scheduleNextDayRefresh() async {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 5, 0);

    await AndroidAlarmManager.oneShotAt(
      nextMidnight,
      _dailyRefreshId,
      dailyPrayerRefreshCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );

    debugPrint('⏰ Next refresh scheduled for: $nextMidnight');
  }
}
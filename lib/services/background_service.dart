import 'dart:ui';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prayer_notification_service.dart';
import 'prayer_calculation_service.dart';
import 'prayer_location_service.dart';

@pragma('vm:entry-point')
void dailyPrayerRefreshCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final service = PrayerBackgroundService();
  await service.scheduleDailyPrayers();
  await service.scheduleNextDayRefresh();
}

class PrayerBackgroundService {
  static const int _dailyRefreshId = 9999;

  Future<void> scheduleDailyPrayers() async {
    try {
      await PrayerLocationService().refreshCachedLocation(
        fromBackground: true,
      );
      final prefs = await SharedPreferences.getInstance();
      final cachedLat = prefs.getDouble('cached_lat');
      final cachedLon = prefs.getDouble('cached_lon');
      final cachedCountry = prefs.getString('cached_country');

      if (cachedLat == null || cachedLon == null) {
        debugPrint('No cached location found for prayer scheduling');
        return;
      }

      final prayerTimes = _calculatePrayerTimesForDays(
        cachedLat,
        cachedLon,
        cachedCountry,
        days: 7,
      );

      final notificationService = PrayerNotificationService();
      await notificationService.ensureInitialized();
      await notificationService.schedulePrayerNotifications(prayerTimes);

      debugPrint('Daily prayers scheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling daily prayers: $e');
    }
  }

  Map<String, DateTime> _calculatePrayerTimesForDays(
    double lat,
    double lon,
    String? country, {
    int days = 3,
  }) {
    final coordinates = Coordinates(lat, lon);
    final now = DateTime.now();
    final params = PrayerCalculationService.parametersFor(
      latitude: lat,
      longitude: lon,
      country: country,
    );
    final result = <String, DateTime>{};

    for (var dayOffset = 0; dayOffset < days; dayOffset++) {
      final date = DateTime(now.year, now.month, now.day + dayOffset);
      final prayerTimes = PrayerTimes(
        coordinates: coordinates,
        date: date,
        calculationParameters: params,
      );

      if (prayerTimes.fajr != null) {
        result['Fajr_$dayOffset'] = prayerTimes.fajr!.toLocal();
      }
      if (prayerTimes.sunrise != null) {
        result['Sunrise_$dayOffset'] = prayerTimes.sunrise!.toLocal();
      }
      if (prayerTimes.dhuhr != null) {
        result['Dhuhr_$dayOffset'] = prayerTimes.dhuhr!.toLocal();
      }
      if (prayerTimes.asr != null) {
        result['Asr_$dayOffset'] = prayerTimes.asr!.toLocal();
      }
      if (prayerTimes.maghrib != null) {
        result['Maghrib_$dayOffset'] = prayerTimes.maghrib!.toLocal();
      }
      if (prayerTimes.isha != null) {
        result['Isha_$dayOffset'] = prayerTimes.isha!.toLocal();
      }
    }

    return result;
  }

  Future<void> scheduleNextDayRefresh() async {
    final now = DateTime.now();
    final nextRefresh = DateTime(now.year, now.month, now.day + 1, 0, 5);

    await AndroidAlarmManager.oneShotAt(
      nextRefresh,
      _dailyRefreshId,
      dailyPrayerRefreshCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );

    debugPrint('Next prayer refresh scheduled for: $nextRefresh');
  }
}

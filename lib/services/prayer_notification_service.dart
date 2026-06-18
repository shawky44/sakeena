import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<String> prayerNames = [
  'الفجر',
  'الظهر',
  'العصر',
  'المغرب',
  'العشاء'
];
const List<String> prayerNamesEng = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

enum ReliabilityRequirement {
  notifications,
  exactAlarm,
  backgroundLocation,
  batteryOptimization,
}

class PrayerNotificationService {
  PrayerNotificationService._internal();
  static final PrayerNotificationService _instance =
      PrayerNotificationService._internal();
  factory PrayerNotificationService() => _instance;

  static const MethodChannel _nativeChannel =
      MethodChannel('com.example.azkar_app/battery');

  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String adhanEnabledKey = 'adhan_enabled';
  static const String shortAdhanKey = 'adhan_short_mode';
  static const String _prayerEnabledPrefix = 'adhan_prayer_enabled_';
  static const String _playAdhanAction = 'com.example.azkar_app.PLAY_ADHAN';
  static const String _prayerReminderAction =
      'com.example.azkar_app.PRAYER_REMINDER';
  static const String _activityReminderAction =
      'com.example.azkar_app.ACTIVITY_REMINDER';
  static const int _reminderMinutesBefore = 15;

  static const Map<String, List<String>> _activityTitles = {
    'morning_azkar': [
      'وقت أذكار الصباح',
      'صباحك يبدأ بذكر الله',
      'لا تنس أذكار الصباح',
    ],
    'duha': [
      'حان وقت صلاة الضحى',
      'ركعتا الضحى تناديانك',
      'موعد جميل مع صلاة الضحى',
    ],
    'evening_azkar': [
      'وقت أذكار المساء',
      'مساؤك أجمل بذكر الله',
      'لا تنس أذكار المساء',
    ],
    'night_prayer': [
      'حان وقت قيام الليل',
      'ركعتان في هدوء الليل',
      'موعدك مع قيام الليل',
    ],
  };

  static const Map<String, List<String>> _activityBodies = {
    'morning_azkar': [
      'ابدأ يومك بذكر الله، وافتح أذكار الصباح الآن.',
      'دقائق من الذكر تمنح صباحك سكينة وطمأنينة.',
      'حصّن يومك بالأذكار، واقرأ أذكار الصباح.',
    ],
    'duha': [
      'ابدأها بركعتين خفيفتين، وصلِّ الضحى.',
      'خذ استراحة قصيرة من يومك واجعلها ركعتين لله.',
      'باب خير في أول النهار، فلا تفوّت صلاة الضحى.',
    ],
    'evening_azkar': [
      'اختم نهارك بذكر الله، وافتح أذكار المساء الآن.',
      'دقائق هادئة للأذكار تمنح مساءك سكينة.',
      'حصّن مساءك بالأذكار، ولا تؤجلها.',
    ],
    'night_prayer': [
      'اهدأ من ضجيج اليوم، وقم لله ولو بركعتين.',
      'في هدوء الليل لحظات لا تُعوّض، فقم وصلِّ.',
      'اجعل لك نصيبًا من الليل، ولو بركعتين خفيفتين.',
      'اقترب من الله في سكون الليل، وحان وقت القيام.',
    ],
  };

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> ensureInitialized() async {
    if (_isInitialized) return;

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _notifications.initialize(initSettings);
    await _createFallbackChannels();
    _isInitialized = true;
  }

  Future<void> _createFallbackChannels() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'prayer_reminder',
        'تذكير الصلاة',
        description: 'تذكير قبل الصلاة',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return true;

    var notification = await Permission.notification.status;
    if (!notification.isGranted) {
      notification = await Permission.notification.request();
    }
    if (!notification.isGranted) return false;

    return canScheduleExactAlarms();
  }

  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _nativeChannel
              .invokeMethod<bool>('canScheduleExactAlarms') ??
          false;
    } catch (e) {
      debugPrint('Error checking exact alarm permission: $e');
      return false;
    }
  }

  Future<void> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return;
    await _nativeChannel.invokeMethod('openExactAlarmSettings');
  }

  Future<void> openAdhanNotificationSettings() async {
    if (!Platform.isAndroid) return;
    await _nativeChannel.invokeMethod('openAdhanNotificationSettings');
  }

  Future<void> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return;
    await _nativeChannel.invokeMethod('requestBatteryOptimization');
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _nativeChannel
              .invokeMethod<bool>('isIgnoringBatteryOptimizations') ??
          false;
    } catch (e) {
      debugPrint('Error checking battery optimization state: $e');
      return false;
    }
  }

  Future<ReliabilityRequirement?> getMissingReliabilityRequirement() async {
    if (!Platform.isAndroid) return null;
    final notification = await Permission.notification.status;
    if (!notification.isGranted) {
      return ReliabilityRequirement.notifications;
    }
    if (!await canScheduleExactAlarms()) {
      return ReliabilityRequirement.exactAlarm;
    }
    final backgroundLocation = await Permission.locationAlways.status;
    if (!backgroundLocation.isGranted) {
      return ReliabilityRequirement.backgroundLocation;
    }
    if (!await isIgnoringBatteryOptimizations()) {
      return ReliabilityRequirement.batteryOptimization;
    }
    return null;
  }

  Future<void> resolveReliabilityRequirement(
    ReliabilityRequirement requirement,
  ) async {
    if (!Platform.isAndroid) return;

    switch (requirement) {
      case ReliabilityRequirement.notifications:
        final status = await Permission.notification.status;
        if (status.isPermanentlyDenied || status.isRestricted) {
          await openAppSettings();
        } else if (!status.isGranted) {
          await Permission.notification.request();
        }
        return;
      case ReliabilityRequirement.exactAlarm:
        if (!await canScheduleExactAlarms()) {
          await openExactAlarmSettings();
        }
        return;
      case ReliabilityRequirement.backgroundLocation:
        final foregroundLocation = await Permission.location.status;
        if (!foregroundLocation.isGranted) {
          await Permission.location.request();
          return;
        }
        final backgroundLocation = await Permission.locationAlways.status;
        if (!backgroundLocation.isGranted) {
          await Permission.locationAlways.request();
        }
        return;
      case ReliabilityRequirement.batteryOptimization:
        if (!await isIgnoringBatteryOptimizations()) {
          await requestBatteryOptimizationExemption();
        }
        return;
    }
  }

  Future<void> stopAdhan() async {
    if (!Platform.isAndroid) return;
    await _nativeChannel.invokeMethod('stopAdhan');
  }

  Future<bool> isAdhanEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(adhanEnabledKey) ?? true;
  }

  Future<void> setAdhanEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(adhanEnabledKey, enabled);
    if (!enabled) await stopAdhan();
  }

  Future<bool> isShortAdhanEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(shortAdhanKey) ?? false;
  }

  Future<void> setShortAdhanEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(shortAdhanKey, enabled);
  }

  Future<bool> isPrayerEnabled(String prayerKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prayerEnabledPrefix$prayerKey') ?? true;
  }

  Future<void> setPrayerEnabled(String prayerKey, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prayerEnabledPrefix$prayerKey', enabled);
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    bool withAdhan = true,
    int id = 999,
  }) async {
    await ensureInitialized();
    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_reminder',
          'تذكير الصلاة',
          channelDescription: 'تذكير قبل الصلاة',
          importance: Importance.max,
          priority: Priority.max,
          playSound: !withAdhan,
          enableVibration: true,
          autoCancel: true,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
    );
  }

  Future<bool> schedulePrayerNotifications(
    Map<String, DateTime> prayerTimes,
  ) async {
    await ensureInitialized();

    final prefs = await SharedPreferences.getInstance();
    final adhanEnabled = prefs.getBool(adhanEnabledKey) ?? true;
    var notificationAllowed = await Permission.notification.status;
    if (!notificationAllowed.isGranted) {
      notificationAllowed = await Permission.notification.request();
    }
    if (!notificationAllowed.isGranted) {
      debugPrint('Prayer reminder notifications are disabled by the user');
    }

    final canSchedule = await canScheduleExactAlarms();
    if (!canSchedule) return false;

    final playShort = prefs.getBool(shortAdhanKey) ?? false;
    final now = DateTime.now();
    final alarms = <Map<String, Object>>[];

    _addActivityReminders(alarms, prayerTimes, now);

    for (final entry in prayerTimes.entries) {
      final prayerKey = _normalizePrayerKey(entry.key);
      if (prayerKey == null) continue;

      final prayerEnabled =
          prefs.getBool('$_prayerEnabledPrefix$prayerKey') ?? true;
      if (!entry.value.isAfter(now)) continue;

      final prayerIndex = prayerNamesEng.indexOf(prayerKey);
      final dayCode =
          entry.value.year * 10000 + entry.value.month * 100 + entry.value.day;
      final id = dayCode * 10 + prayerIndex;
      final reminderTime =
          entry.value.subtract(const Duration(minutes: _reminderMinutesBefore));

      if (reminderTime.isAfter(now)) {
        alarms.add({
          'id': id + 50000,
          'action': _prayerReminderAction,
          'prayerKey': prayerKey,
          'prayerName': prayerNames[prayerIndex],
          'timeMillis': reminderTime.millisecondsSinceEpoch,
          'playShort': false,
          'minutesBefore': _reminderMinutesBefore,
        });
      }

      if (!adhanEnabled || !prayerEnabled) continue;

      alarms.add({
        'id': id,
        'action': _playAdhanAction,
        'prayerKey': prayerKey,
        'prayerName': prayerNames[prayerIndex],
        'timeMillis': entry.value.millisecondsSinceEpoch,
        'playShort': playShort,
        'minutesBefore': 0,
      });
    }

    final scheduled = await _nativeChannel.invokeMethod<bool>(
          'schedulePrayerAlarms',
          {'alarms': alarms},
        ) ??
        false;

    await prefs.setBool(_notificationsEnabledKey, scheduled);
    debugPrint('Prayer alarms scheduled: $scheduled (${alarms.length})');
    return scheduled;
  }

  void _addActivityReminders(
    List<Map<String, Object>> alarms,
    Map<String, DateTime> prayerTimes,
    DateTime now,
  ) {
    final days = <int, Map<String, DateTime>>{};
    for (final entry in prayerTimes.entries) {
      final prayerKey = entry.key.split('_').first;
      if (!const {'Fajr', 'Sunrise', 'Asr', 'Isha'}.contains(prayerKey)) {
        continue;
      }
      final time = entry.value;
      final dayCode = time.year * 10000 + time.month * 100 + time.day;
      days.putIfAbsent(dayCode, () => {})[prayerKey] = time;
    }

    for (final dayEntry in days.entries) {
      final times = dayEntry.value;
      final fajr = times['Fajr'];
      final sunrise = times['Sunrise'];
      final asr = times['Asr'];
      final isha = times['Isha'];

      if (fajr != null) {
        _addActivityAlarm(
          alarms,
          dayEntry.key,
          0,
          'morning_azkar',
          fajr.add(const Duration(minutes: 30)),
          now,
        );
      }
      if (sunrise != null) {
        _addActivityAlarm(
          alarms,
          dayEntry.key,
          1,
          'duha',
          sunrise.add(const Duration(minutes: 20)),
          now,
        );
      }
      if (asr != null) {
        _addActivityAlarm(
          alarms,
          dayEntry.key,
          2,
          'evening_azkar',
          asr.add(const Duration(minutes: 30)),
          now,
        );
      }
      if (isha != null) {
        _addActivityAlarm(
          alarms,
          dayEntry.key,
          3,
          'night_prayer',
          isha.add(const Duration(hours: 2)),
          now,
        );
        _addActivityAlarm(
          alarms,
          dayEntry.key,
          4,
          'night_prayer',
          DateTime(isha.year, isha.month, isha.day + 1, 2),
          now,
        );
      }
    }
  }

  void _addActivityAlarm(
    List<Map<String, Object>> alarms,
    int dayCode,
    int typeIndex,
    String type,
    DateTime time,
    DateTime now,
  ) {
    if (!time.isAfter(now)) return;

    final titles = _activityTitles[type]!;
    final bodies = _activityBodies[type]!;
    final variation = (dayCode + typeIndex) % titles.length;
    final bodyVariation = (dayCode * 3 + typeIndex) % bodies.length;

    alarms.add({
      'id': dayCode * 10 + 100000 + typeIndex,
      'action': _activityReminderAction,
      'prayerKey': type,
      'prayerName': '',
      'timeMillis': time.millisecondsSinceEpoch,
      'playShort': false,
      'minutesBefore': 0,
      'title': titles[variation],
      'body': bodies[bodyVariation],
    });
  }

  Future<void> cancelAll() async {
    try {
      await _nativeChannel.invokeMethod('cancelPrayerAlarms');
    } catch (e) {
      debugPrint('Error cancelling native prayer alarms: $e');
    }
    await _notifications.cancelAll();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, false);
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? false;
  }

  String? _normalizePrayerKey(String key) {
    final lower = key.toLowerCase();
    if (lower.contains('fajr') || key.contains('فجر')) return 'Fajr';
    if (lower.contains('dhuhr') ||
        lower.contains('zuhr') ||
        key.contains('ظهر')) {
      return 'Dhuhr';
    }
    if (lower.contains('asr') || key.contains('عصر')) return 'Asr';
    if (lower.contains('maghrib') || key.contains('مغرب')) return 'Maghrib';
    if (lower.contains('isha') || key.contains('عشاء')) return 'Isha';
    return null;
  }
}

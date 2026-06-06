import 'dart:io';
import 'package:azkar_app/services/background_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

// ✅ تعريف أسماء الصلوات بالترتيب
const List<String> prayerNames = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
const List<String> prayerNamesEng = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

// دالة التذكير قبل الصلاة
@pragma('vm:entry-point')
void reminderAlarmCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  final service = PrayerNotificationService();
  await service.ensureInitialized();
  
  // ✅ استخراج رقم الصلاة من الـ ID
  final prayerIndex = (id - 1000) % 5;
  final prayerName = prayerNames[prayerIndex];
  
  await service.showImmediateNotification(
    title: '⏰ تذكير صلاة',
    body: 'صلاة $prayerName بعد 15 دقيقة، استعد للصلاة',
    withAdhan: false,
    id: id,
  );
  debugPrint('✅ Reminder shown for: $prayerName (ID: $id)');
}

// دالة الأذان الفعلي
@pragma('vm:entry-point')
void adhanAlarmCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  final service = PrayerNotificationService();
  await service.ensureInitialized();
  
  // ✅ استخراج رقم الصلاة من الـ ID
  final prayerIndex = id % 5;
  final prayerName = prayerNames[prayerIndex];
  
  await service.showImmediateNotification(
    title: '🕌 موعد الأذان',
    body: 'حان الآن وقت صلاة $prayerName',
    withAdhan: true,
    id: id,
  );
  debugPrint('✅ Adhan shown for: $prayerName (ID: $id)');
}

class PrayerNotificationService {
  PrayerNotificationService._internal();
  static final PrayerNotificationService _instance = PrayerNotificationService._internal();
  factory PrayerNotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String _adhanChannelId = 'prayer_adhan';
  static const String _reminderChannelId = 'prayer_reminder';
  static const String _notificationsEnabledKey = 'notifications_enabled';

  Future<void> ensureInitialized() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Cairo'));

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _notifications.initialize(initSettings);
    await _createChannels();
    _isInitialized = true;
  }

  Future<void> _createChannels() async {
    final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    // قناة الأذان
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _adhanChannelId,
        'أذان الصلاة',
        description: 'إشعارات الأذان عند دخول وقت الصلاة',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('adhan'),
        playSound: true,
        enableVibration: true,
      ),
    );

    // قناة التذكير
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _reminderChannelId,
        'تذكير الصلاة',
        description: 'تذكير قبل الصلاة بـ15 دقيقة',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final notification = await Permission.notification.request();
      if (!notification.isGranted) return false;

      final exactAlarm = await Permission.scheduleExactAlarm.request();
      if (!exactAlarm.isGranted) return false;

      final battery = await Permission.ignoreBatteryOptimizations.request();
      if (!battery.isGranted) {
        debugPrint('⚠️ Battery optimization not granted, but continuing...');
      }

      return true;
    }
    return true;
  }

  Future<bool> ensureExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final status = await Permission.scheduleExactAlarm.status;
      if (!status.isGranted) {
        final result = await Permission.scheduleExactAlarm.request();
        return result.isGranted;
      }
      return true;
    } catch (e) {
      debugPrint('❌ Error requesting exact alarm permission: $e');
      return false;
    }
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    bool withAdhan = true,
    int id = 999,
  }) async {
    try {
      await _notifications.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            withAdhan ? _adhanChannelId : _reminderChannelId,
            withAdhan ? 'أذان الصلاة' : 'تذكير الصلاة',
            channelDescription: withAdhan 
                ? 'إشعارات الأذان عند دخول وقت الصلاة'
                : 'تذكير قبل الصلاة بـ15 دقيقة',
            importance: Importance.max,
            priority: Priority.max,
            sound: withAdhan ? const RawResourceAndroidNotificationSound('adhan') : null,
            playSound: true,
            fullScreenIntent: true,
            enableVibration: true,
            autoCancel: true,
            styleInformation: BigTextStyleInformation(body),
          ),
        ),
      );
      debugPrint('✅ Notification shown: $title');
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
    }
  }

Future<void> schedulePrayerNotifications(Map<String, DateTime> prayerTimes) async {
  await ensureInitialized();

  final permitted = await requestPermissions();
  final canSchedule = await ensureExactAlarmPermission();
  
  if (!permitted || !canSchedule) {
    debugPrint('❌ Cannot schedule: permissions missing');
    return;
  }

  // إلغاء جميع الإشعارات السابقة
  await _cancelAllAlarms();
  await _notifications.cancelAll();

  final now = DateTime.now();
  
  // ✅ قائمة أسماء الصلوات بالإنجليزية
  final prayerKeys = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  
  // ✅ المرور على كل صلاة
  for (int i = 0; i < prayerKeys.length; i++) {
    final prayerKey = prayerKeys[i];
    final prayerTime = prayerTimes[prayerKey];
    
    // ✅ التأكد من وجود الوقت
    if (prayerTime == null) {
      debugPrint('⚠️ Prayer time not found for: $prayerKey');
      continue;
    }
    
    if (prayerTime.isAfter(now)) {
      final reminderTime = prayerTime.subtract(const Duration(minutes: 15));
      
      // استخدام index ثابت حسب اسم الصلاة
      final adhanId = i;
      final reminderId = 1000 + i;

      // تذكير قبل الأذان بـ15 دقيقة
      if (reminderTime.isAfter(now)) {
        await AndroidAlarmManager.oneShotAt(
          reminderTime,
          reminderId,
          reminderAlarmCallback,
          exact: true,
          wakeup: true,
          allowWhileIdle: true,
          rescheduleOnReboot: true,
        );
        debugPrint('⏰ Scheduled reminder for ${prayerNames[i]} at $reminderTime (ID: $reminderId)');
      }

      // الأذان في الوقت الفعلي
      await AndroidAlarmManager.oneShotAt(
        prayerTime,
        adhanId,
        adhanAlarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
      debugPrint('🕌 Scheduled adhan for ${prayerNames[i]} at $prayerTime (ID: $adhanId)');
    } else {
      debugPrint('⏩ Skipping $prayerKey - time already passed');
    }
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_notificationsEnabledKey, true);
  
  debugPrint('✅ All prayer notifications scheduled successfully');
}

  Future<void> rescheduleAllNotifications() async {
    debugPrint('🔄 Rescheduling all notifications...');
    
    final backgroundService = PrayerBackgroundService();
    await backgroundService.scheduleDailyPrayers();
  }

  Future<void> _cancelAllAlarms() async {
    for (int i = 0; i < 10; i++) {
      await AndroidAlarmManager.cancel(i);
      await AndroidAlarmManager.cancel(i + 1000);
    }
  }

  Future<void> cancelAll() async {
    await _cancelAllAlarms();
    await _notifications.cancelAll();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, false);
    
    debugPrint('🗑️ All notifications cancelled');
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? false;
  }
}
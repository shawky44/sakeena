// lib/services/prayer_notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PrayerNotificationService {
  static final PrayerNotificationService _instance =
      PrayerNotificationService._internal();
  factory PrayerNotificationService() => _instance;
  PrayerNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const Map<String, String> prayerReminderMessages = {
    'الفجر': 'حان موعد صلاة الفجر بعد 15 دقيقة. استعد للصلاة',
    'الظهر': 'حان موعد صلاة الظهر بعد 15 دقيقة. استعد للصلاة',
    'العصر': 'حان موعد صلاة العصر بعد 15 دقيقة. استعد للصلاة',
    'المغرب': 'حان موعد صلاة المغرب بعد 15 دقيقة. استعد للصلاة',
    'العشاء': 'حان موعد صلاة العشاء بعد 15 دقيقة. استعد للصلاة',
  };

  static const Map<String, String> prayerAdhanMessages = {
    'الفجر': 'حان الآن موعد صلاة الفجر 🕌',
    'الظهر': 'حان الآن موعد صلاة الظهر 🕌',
    'العصر': 'حان الآن موعد صلاة العصر 🕌',
    'المغرب': 'حان الآن موعد صلاة المغرب 🕌',
    'العشاء': 'حان الآن موعد صلاة العشاء 🕌',
  };

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Africa/Cairo'));

      // Create notification channels for Android
      await _createNotificationChannels();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = initialized ?? false;
      debugPrint('✅ Notification Service Initialized: $_isInitialized');
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
      _isInitialized = false;
    }
  }

  // Create notification channels for Android 8.0+
  Future<void> _createNotificationChannels() async {
    // Channel for reminders (15 min before)
    const reminderChannel = AndroidNotificationChannel(
      'prayer_reminders',
      'تذكير الصلاة',
      description: 'تذكير بمواقيت الصلاة قبل 15 دقيقة',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Channel for adhan (at prayer time)
    const adhanChannel = AndroidNotificationChannel(
      'prayer_adhan',
      'أذان الصلاة',
      description: 'صوت الأذان عند دخول وقت الصلاة',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan'),
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(reminderChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(adhanChannel);

    debugPrint('✅ Notification channels created');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<bool> requestPermissions() async {
    try {
      // For Android 13+ (API 33+), request notification permission
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        if (!status.isGranted) {
          debugPrint('❌ Notification permission denied');
          return false;
        }
      }

      // Request exact alarm permission for Android 12+ (API 31+)
      if (await Permission.scheduleExactAlarm.isDenied) {
        final status = await Permission.scheduleExactAlarm.request();
        if (!status.isGranted) {
          debugPrint(
            '⚠️ Exact alarm permission denied - notifications may not be exact',
          );
        }
      }

      // Request iOS permissions
      final iosImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      debugPrint('✅ Permissions requested');
      return true;
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      return false;
    }
  }

  Future<void> schedulePrayerNotifications(
    Map<String, DateTime> prayerTimes,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      debugPrint('❌ Cannot schedule notifications without permission');
      return;
    }

    await cancelAllNotifications();

    int notificationId = 0;
    final now = DateTime.now();

    for (var entry in prayerTimes.entries) {
      final prayerName = entry.key;
      final prayerTime = entry.value;

      // Schedule REMINDER (15 minutes before)
      final reminderTime = prayerTime.subtract(const Duration(minutes: 15));
      if (reminderTime.isAfter(now)) {
        try {
          await _scheduleReminderNotification(
            id: notificationId++,
            title: '⏰ تذكير صلاة $prayerName',
            body:
                prayerReminderMessages[prayerName] ??
                'حان موعد الصلاة بعد 15 دقيقة',
            scheduledTime: reminderTime,
            payload: '${prayerName}_reminder',
          );
          debugPrint('✅ Scheduled REMINDER for $prayerName at $reminderTime');
        } catch (e) {
          debugPrint('❌ Error scheduling reminder for $prayerName: $e');
        }
      }

      // Schedule ADHAN (at prayer time)
      if (prayerTime.isAfter(now)) {
        try {
          await _scheduleAdhanNotification(
            id: notificationId++,
            title: '🕌 صلاة $prayerName',
            body: prayerAdhanMessages[prayerName] ?? 'حان الآن موعد الصلاة',
            scheduledTime: prayerTime,
            payload: '${prayerName}_adhan',
          );
          debugPrint('✅ Scheduled ADHAN for $prayerName at $prayerTime');
        } catch (e) {
          debugPrint('❌ Error scheduling adhan for $prayerName: $e');
        }
      }
    }

    final pending = await getPendingNotifications();
    debugPrint('📋 Total pending notifications: ${pending.length}');
    for (var notif in pending) {
      debugPrint(
        '  - ID: ${notif.id}, Title: ${notif.title}, Body: ${notif.body}',
      );
    }
  }

  Future<void> _scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'prayer_reminders',
      'تذكير الصلاة',
      channelDescription: 'تذكير بمواقيت الصلاة قبل 15 دقيقة',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> _scheduleAdhanNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'prayer_adhan',
      'أذان الصلاة',
      channelDescription: 'صوت الأذان عند دخول وقت الصلاة',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan'),
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      autoCancel: false,
      ongoing: false,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'adhan.mp3',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('🗑️ All notifications cancelled');
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    debugPrint('🗑️ Notification $id cancelled');
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Test notification - use this to verify notifications work
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    bool withAdhan = true,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final androidDetails = AndroidNotificationDetails(
      withAdhan ? 'prayer_adhan' : 'prayer_reminders',
      withAdhan ? 'أذان الصلاة' : 'تذكير الصلاة',
      channelDescription: 'إشعارات مواقيت الصلاة',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: withAdhan
          ? const RawResourceAndroidNotificationSound('adhan')
          : null,
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: withAdhan ? 'adhan.mp3' : null,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(999, title, body, notificationDetails);

    debugPrint('✅ Immediate notification sent: $title');
  }
}

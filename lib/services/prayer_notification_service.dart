import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class PrayerNotificationService {
  PrayerNotificationService._internal();
  static final PrayerNotificationService _instance = PrayerNotificationService._internal();
  factory PrayerNotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool _channelsCreated = false;

  static const String _adhanChannelId = 'prayer_adhan';
  static const String _reminderChannelId = 'prayer_reminders';

  static const Map<String, String> prayerReminderMessages = {
    'الفجر': ' صلاة الفجر بعد 15 دقيقة. استعد للصلاة',
    'الظهر': '  صلاة الظهر بعد 15 دقيقة. استعد للصلاة',
    'العصر': '  صلاة العصر بعد 15 دقيقة. استعد للصلاة',
    'المغرب': '  صلاة المغرب بعد 15 دقيقة. استعد للصلاة',
    'العشاء': '  صلاة العشاء بعد 15 دقيقة. استعد للصلاة',
  };

  static const Map<String, String> prayerAdhanMessages = {
    'الفجر': 'حان الآن موعد صلاة الفجر 🕌',
    'الظهر': 'حان الآن موعد صلاة الظهر 🕌',
    'العصر': 'حان الآن موعد صلاة العصر 🕌',
    'المغرب': 'حان الآن موعد صلاة المغرب 🕌',
    'العشاء': 'حان الآن موعد صلاة العشاء 🕌',
  };

  Future<void> ensureInitialized() async {
    if (_isInitialized && _channelsCreated) return;

    await _requestBasicNotificationPermission();
    await _initializePluginAndTz();
    await _createNotificationChannels();
  }

  Future<bool> requestPermissions({bool requestExactAlarm = true}) async {
    final basic = await _requestBasicNotificationPermission();
    if (!basic) return false;

    if (requestExactAlarm && Platform.isAndroid) {
      await _requestExactAlarmPermissionIfNeeded();
    }
    return true;
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    bool withAdhan = true,
    int id = 999,
  }) async {
    await ensureInitialized();
    final details = _buildNotificationDetails(withAdhan: withAdhan);
    await _notifications.show(id, title, body, details);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> schedulePrayerNotifications(Map<String, DateTime> prayerTimes) async {
    await ensureInitialized();
    final permitted = await requestPermissions();
    if (!permitted) return;

    if (Platform.isAndroid) await _requestExactAlarmPermissionIfNeeded();
    await cancelAllNotifications();

    int notificationId = 0;
    final now = DateTime.now();

    for (final entry in prayerTimes.entries) {
      final prayerName = entry.key;
      final prayerTime = entry.value.toLocal();

      final reminderTime = prayerTime.subtract(const Duration(minutes: 15));
      if (reminderTime.isAfter(now)) {
        await _scheduleNotification(
          id: notificationId++,
          title: '⏰ تذكير صلاة $prayerName',
          body: prayerReminderMessages[prayerName] ?? '  الصلاة بعد 15 دقيقة',
          scheduledTime: reminderTime,
          withAdhan: false,
          payload: '${prayerName}_reminder',
        );
      }

      if (prayerTime.isAfter(now)) {
        await _scheduleNotification(
          id: notificationId++,
          title: '🕌 صلاة $prayerName',
          body: prayerAdhanMessages[prayerName] ?? 'حان الآن موعد الصلاة',
          scheduledTime: prayerTime,
          withAdhan: true,
          payload: '${prayerName}_adhan',
        );
      }
    }
  }

  Future<void> _initializePluginAndTz() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Cairo'));

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _notifications.initialize(initSettings, onDidReceiveNotificationResponse: _onNotificationTapped);
    _isInitialized = true;
  }

  Future<void> _createNotificationChannels() async {
    if (_channelsCreated) return;
    if (!Platform.isAndroid) {
      _channelsCreated = true;
      return;
    }

    final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _reminderChannelId,
        'تذكير الصلاة',
        description: 'تذكير بمواقيت الصلاة قبل 15 دقيقة',
        importance: Importance.high,
        playSound: true,
      ),
    );

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _adhanChannelId,
        'أذان الصلاة',
        description: 'صوت الأذان عند دخول وقت الصلاة',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('adhan'),
        playSound: true,
      ),
    );

    _channelsCreated = true;
  }

  void _onNotificationTapped(NotificationResponse response) {}

  NotificationDetails _buildNotificationDetails({required bool withAdhan}) {
    final androidDetails = AndroidNotificationDetails(
      withAdhan ? _adhanChannelId : _reminderChannelId,
      withAdhan ? 'أذان الصلاة' : 'تذكير الصلاة',
      channelDescription: 'Prayer notification system',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: withAdhan ? const RawResourceAndroidNotificationSound('adhan') : null,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      fullScreenIntent: withAdhan,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      sound: withAdhan ? 'adhan.mp3' : null,
      interruptionLevel: withAdhan ? InterruptionLevel.timeSensitive : InterruptionLevel.active,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required bool withAdhan,
    String? payload,
  }) async {
    final tzScheduled = tz.TZDateTime.from(scheduledTime.toLocal(), tz.local);
    final details = _buildNotificationDetails(withAdhan: withAdhan);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<bool> _requestBasicNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        if (status.isGranted) return true;
        final result = await Permission.notification.request();
        return result.isGranted;
      } else if (Platform.isIOS) {
        final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _requestExactAlarmPermissionIfNeeded() async {
    if (!Platform.isAndroid) return;
    final status = await Permission.scheduleExactAlarm.status;
    if (!status.isGranted) await Permission.scheduleExactAlarm.request();
  }
}

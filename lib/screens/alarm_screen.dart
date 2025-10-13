// import 'dart:async';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';

// class AlarmScreen extends StatefulWidget {
//   const AlarmScreen({super.key});

//   @override
//   State<AlarmScreen> createState() => _AlarmScreenState();
// }

// class _AlarmScreenState extends State<AlarmScreen> with WidgetsBindingObserver {
//   final List<AlarmItem> _alarms = [];
//   late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
//   Timer? _checkTimer;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initializeAlarmService();
//     _loadAlarms();
//   }

//   @override
//   void dispose() {
//     _checkTimer?.cancel();
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   // حفظ المنبهات
//   Future<void> _saveAlarms() async {
//     final prefs = await SharedPreferences.getInstance();
//     final alarmsJson = _alarms.map((alarm) => {
//       'id': alarm.id,
//       'hour': alarm.time.hour,
//       'minute': alarm.time.minute,
//       'isActive': alarm.isActive,
//     }).toList();
//     await prefs.setString('alarms', jsonEncode(alarmsJson));
//   }

//   // تحميل المنبهات
//   Future<void> _loadAlarms() async {
//     final prefs = await SharedPreferences.getInstance();
//     final alarmsString = prefs.getString('alarms');
    
//     if (alarmsString != null) {
//       final List<dynamic> alarmsJson = jsonDecode(alarmsString);
//       setState(() {
//         _alarms.clear();
//         for (var alarm in alarmsJson) {
//           _alarms.add(AlarmItem(
//             id: alarm['id'],
//             time: TimeOfDay(hour: alarm['hour'], minute: alarm['minute']),
//             isActive: alarm['isActive'],
//           ));
//         }
//       });
      
//       // إعادة جدولة المنبهات النشطة
//       for (var alarm in _alarms) {
//         if (alarm.isActive) {
//           await _scheduleBackupNotification(alarm);
//         }
//       }
//     }
//   }

//   // فحص دوري كل ثانية
//   void _startPeriodicCheck() {
//     _checkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       _checkAlarms();
//     });
//   }

//   void _checkAlarms() {
//     final now = DateTime.now();
    
//     for (var alarm in _alarms) {
//       if (!alarm.isActive) continue;
      
//       if (alarm.time.hour == now.hour && 
//           alarm.time.minute == now.minute &&
//           now.second == 0) {
//         _triggerAlarm(alarm);
//       }
//     }
//   }

//   Future<void> _triggerAlarm(AlarmItem alarm) async {
//     debugPrint('🔔 المنبه يرن الآن: ${alarm.time.format(context)}');
//     await _playAlarmWithRepeat(alarm.id);
    
//     if (mounted && WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
//       _showAlarmDialog(alarm);
//     }
//   }

//   Future<void> _playAlarmWithRepeat(int alarmId) async {
//     int repeatCount = 0;
//     const maxRepeats = 15;
    
//     await _showAlarmNotification(alarmId, repeatCount);
    
//     Timer.periodic(const Duration(seconds: 4), (timer) {
//       repeatCount++;
      
//       if (repeatCount >= maxRepeats) {
//         timer.cancel();
//         return;
//       }
      
//       _showAlarmNotification(alarmId, repeatCount);
//     });
//   }

//   Future<void> _showAlarmNotification(int alarmId, int count) async {
//     try {
//       await flutterLocalNotificationsPlugin.show(
//         alarmId + count,
//         '⏰ منبه - حان الوقت',
//         'المنبه يرن الآن! ${count > 0 ? "(تكرار $count)" : ""}',
//         NotificationDetails(
//           android: AndroidNotificationDetails(
//             'alarm_channel_full_screen',
//             'المنبهات',
//             channelDescription: 'قناة المنبهات الكاملة',
//             importance: Importance.max,
//             priority: Priority.high,
//             playSound: true,
//             enableVibration: true,
//             vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
//             sound: const RawResourceAndroidNotificationSound('alarm_sound'),
//             fullScreenIntent: true,
//             category: AndroidNotificationCategory.alarm,
//             visibility: NotificationVisibility.public,
//             ongoing: true,
//             autoCancel: false,
//             ticker: 'المنبه يرن',
//           ),
//         ),
//       );
//     } catch (e) {
//       debugPrint('❌ خطأ في إظهار الإشعار: $e');
//     }
//   }

//   void _showAlarmDialog(AlarmItem alarm) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => WillPopScope(
//         onWillPop: () async => false,
//         child: AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//           title: const Row(
//             children: [
//               Icon(Icons.alarm, color: Color(0xFF4F4F4F), size: 30),
//               SizedBox(width: 10),
//               Text('⏰ منبه'),
//             ],
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 alarm.time.format(context),
//                 style: const TextStyle(
//                   fontSize: 56,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF4F4F4F),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               const Text(
//                 'حان وقت المنبه!',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _snoozeAlarm(alarm);
//               },
//               child: const Text('غفوة (5 دقائق)', style: TextStyle(fontSize: 16)),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _stopAlarm(alarm);
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF4F4F4F),
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               ),
//               child: const Text('إيقاف', style: TextStyle(fontSize: 16)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _snoozeAlarm(AlarmItem alarm) {
//     final now = DateTime.now();
//     final snoozeTime = now.add(const Duration(minutes: 5));
    
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('تم تأجيل المنبه لـ ${TimeOfDay.fromDateTime(snoozeTime).format(context)}'),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _stopAlarm(AlarmItem alarm) async {
//     // إلغاء جميع الإشعارات الخاصة بهذا المنبه
//     for (int i = 0; i < 20; i++) {
//       await flutterLocalNotificationsPlugin.cancel(alarm.id + i);
//     }
//   }

//   Future<void> _initializeAlarmService() async {
//     await _requestPermissions();
//     await _initializeNotifications();
//     _startPeriodicCheck();
//   }

//   Future<void> _requestPermissions() async {
//     if (await Permission.notification.isDenied) {
//       final status = await Permission.notification.request();
//       debugPrint('صلاحية الإشعارات: $status');
//     }
    
//     if (await Permission.scheduleExactAlarm.isDenied) {
//       final status = await Permission.scheduleExactAlarm.request();
//       debugPrint('صلاحية المنبهات الدقيقة: $status');
//     }
//   }

//   Future<void> _initializeNotifications() async {
//     flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
//     tz.initializeTimeZones();
//     tz.setLocalLocation(tz.getLocation('Africa/Cairo'));

//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'alarm_channel_full_screen',
//       'المنبهات',
//       description: 'قناة الإشعارات الخاصة بالمنبهات',
//       importance: Importance.max,
//       playSound: true,
//       enableVibration: true,
//       sound: RawResourceAndroidNotificationSound('alarm_sound'),
//     );

//     await flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);

//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const InitializationSettings initializationSettings =
//         InitializationSettings(android: initializationSettingsAndroid);

//     await flutterLocalNotificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: (details) {
//         debugPrint('تم النقر على الإشعار');
//       },
//     );

//     debugPrint('✅ تم تهيئة الإشعارات بنجاح');
//   }

//   void _addAlarm() async {
//     final TimeOfDay? pickedTime = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Color(0xFF4F4F4F),
//               onPrimary: Colors.white,
//               surface: Colors.white,
//               onSurface: Colors.black87,
//             ),
//             textButtonTheme: TextButtonThemeData(
//               style: TextButton.styleFrom(
//                 foregroundColor: const Color(0xFF4F4F4F),
//               ),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (pickedTime != null && mounted) {
//       final newAlarm = AlarmItem(
//         id: DateTime.now().millisecondsSinceEpoch,
//         time: pickedTime,
//         isActive: true,
//       );

//       setState(() {
//         _alarms.add(newAlarm);
//         _alarms.sort((a, b) {
//           final aMinutes = a.time.hour * 60 + a.time.minute;
//           final bMinutes = b.time.hour * 60 + b.time.minute;
//           return aMinutes.compareTo(bMinutes);
//         });
//       });

//       await _scheduleBackupNotification(newAlarm);
//       await _saveAlarms();

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('✅ تم إضافة منبه لـ ${pickedTime.format(context)}'),
//             duration: const Duration(seconds: 2),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _scheduleBackupNotification(AlarmItem alarm) async {
//     final now = DateTime.now();
//     DateTime scheduledDate = DateTime(
//       now.year,
//       now.month,
//       now.day,
//       alarm.time.hour,
//       alarm.time.minute,
//       0,
//     );

//     if (scheduledDate.isBefore(now)) {
//       scheduledDate = scheduledDate.add(const Duration(days: 1));
//     }

//     final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

//     try {
//       await flutterLocalNotificationsPlugin.zonedSchedule(
//         alarm.id,
//         '⏰ منبه',
//         'حان وقت المنبه! ${alarm.time.format(context)}',
//         tzDateTime,
//         NotificationDetails(
//           android: AndroidNotificationDetails(
//             'alarm_channel_full_screen',
//             'المنبهات',
//             channelDescription: 'قناة المنبهات',
//             importance: Importance.max,
//             priority: Priority.high,
//             playSound: true,
//             enableVibration: true,
//             vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
//             sound: const RawResourceAndroidNotificationSound('alarm_sound'),
//             fullScreenIntent: true,
//             category: AndroidNotificationCategory.alarm,
//           ),
//         ),
//         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//         uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
//       );

//       debugPrint('✅ تم جدولة المنبه: ${alarm.time.hour}:${alarm.time.minute.toString().padLeft(2, '0')}');
//     } catch (e) {
//       debugPrint('❌ خطأ في جدولة الإشعار: $e');
//     }
//   }

//   // void _testAlarmNow() async {
//   //   debugPrint('🔔 اختبار المنبه الآن...');
//   //   await _playAlarmWithRepeat(99999);
    
//   //   if (mounted) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(
//   //         content: Text('🔊 تم تشغيل المنبه! يجب أن تسمع الصوت الآن'),
//   //         duration: Duration(seconds: 3),
//   //         backgroundColor: Colors.orange,
//   //       ),
//   //     );
//   //   }
//   // }

//   void _deleteAlarm(int index) async {
//     final alarm = _alarms[index];
    
//     await flutterLocalNotificationsPlugin.cancel(alarm.id);
    
//     if (mounted) {
//       setState(() {
//         _alarms.removeAt(index);
//       });
//       await _saveAlarms();
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('تم حذف المنبه'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//     }
//   }

//   void _toggleAlarm(int index) async {
//     final alarm = _alarms[index];

//     if (mounted) {
//       setState(() {
//         alarm.isActive = !alarm.isActive;
//       });
//       await _saveAlarms();
//     }

//     if (alarm.isActive) {
//       await _scheduleBackupNotification(alarm);
//     } else {
//       await flutterLocalNotificationsPlugin.cancel(alarm.id);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 218, 221, 209),
//       appBar: AppBar(
//         title: const Text('المنبه'),
//         backgroundColor: const Color.fromARGB(237, 91, 110, 102),
//         elevation: 0,
//         // actions: [
//           // IconButton(
//           //   icon: const Icon(Icons.volume_up),
//           //   onPressed: _testAlarmNow,
//           //   tooltip: 'اختبار الصوت',
//           // ),
//         // ],
//       ),
//       body: _alarms.isEmpty
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.alarm_off, size: 100, color: Colors.grey[400]),
//                   const SizedBox(height: 20),
//                   Text(
//                     'لا توجد منبهات',
//                     style: TextStyle(fontSize: 20, color: Colors.grey[600]),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'اضغط على زر + لإضافة منبه جديد',
//                     style: TextStyle(fontSize: 16, color: Colors.grey[500]),
//                   ),
//                   const SizedBox(height: 30),
//                   // ElevatedButton.icon(
//                   //   onPressed: _testAlarmNow,
//                   //   icon: const Icon(Icons.volume_up),
//                   //   label: const Text('🔊 اختبار الصوت الآن'),
//                   //   style: ElevatedButton.styleFrom(
//                   //     backgroundColor: const Color(0xFF4F4F4F),
//                   //     foregroundColor: Colors.white,
//                   //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                   //   ),
//                   // ),
//                 ],
//               ),
//             )
//           : ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: _alarms.length,
//               itemBuilder: (context, index) {
//                 final alarm = _alarms[index];
//                 return Card(
//                   margin: const EdgeInsets.only(bottom: 12),
//                   elevation: 2,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: ListTile(
//                     contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                     leading: Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: alarm.isActive
//                             ? const Color(0xFF4F4F4F).withOpacity(0.1)
//                             : Colors.grey.withOpacity(0.1),
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         Icons.alarm,
//                         color: alarm.isActive ? const Color(0xFF4F4F4F) : Colors.grey,
//                       ),
//                     ),
//                     title: Text(
//                       alarm.time.format(context),
//                       style: TextStyle(
//                         fontSize: 32,
//                         fontWeight: FontWeight.bold,
//                         color: alarm.isActive ? Colors.black87 : Colors.grey,
//                       ),
//                     ),
//                     subtitle: alarm.isActive
//                         ? Text(
//                             _getTimeRemaining(alarm),
//                             style: const TextStyle(fontSize: 12, color: Color(0xFF4F4F4F)),
//                           )
//                         : const Text('معطل', style: TextStyle(color: Colors.grey)),
//                     trailing: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Switch(
//                           value: alarm.isActive,
//                           onChanged: (value) => _toggleAlarm(index),
//                           activeColor: const Color(0xFF4F4F4F),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.delete),
//                           color: Colors.red,
//                           onPressed: () => _deleteAlarm(index),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _addAlarm,
//         backgroundColor: const Color.fromARGB(203, 79, 79, 79),
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//     );
//   }

//   String _getTimeRemaining(AlarmItem alarm) {
//     final now = DateTime.now();
//     DateTime alarmTime = DateTime(now.year, now.month, now.day, alarm.time.hour, alarm.time.minute);

//     if (alarmTime.isBefore(now)) {
//       alarmTime = alarmTime.add(const Duration(days: 1));
//     }

//     final difference = alarmTime.difference(now);
//     final hours = difference.inHours;
//     final minutes = difference.inMinutes % 60;

//     if (hours > 0) {
//       return 'بعد $hours ساعة و $minutes دقيقة';
//     } else {
//       return 'بعد $minutes دقيقة';
//     }
//   }
// }

// class AlarmItem {
//   final int id;
//   final TimeOfDay time;
//   bool isActive;

//   AlarmItem({
//     required this.id,
//     required this.time,
//     required this.isActive,
//   });
// }
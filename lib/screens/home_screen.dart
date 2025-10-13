// home_screen.dart
import 'dart:async';
import 'package:azkar_app/services/prayer_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:azkar_app/screens/azkar_screen.dart';
import 'package:azkar_app/screens/todo_screen.dart';
import 'package:azkar_app/screens/calendar_screen.dart';
import 'package:azkar_app/screens/more_screen.dart';
import 'package:azkar_app/widgets/main_content_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ==================== STATE VARIABLES ====================

  // Prayer times
  Map<String, String> allPrayerTimes = {
    'الفجر': '--:--',
    'الظهر': '--:--',
    'العصر': '--:--',
    'المغرب': '--:--',
    'العشاء': '--:--',
  };

  String nextPrayerName = '...';
  String displayPrayerTime = '--:--';
  String timeLeftText = '--:--';
  DateTime? nextPrayerTime;

  // Location
  String userLocation = '...';

  // Navigation
  int _currentIndex = 4;

  // Timers
  Timer? _clockTimer;
  Timer? _refreshPrayerTimer;

  // Prayer backgrounds
  static const Map<String, String> prayerBackgrounds = {
    'الفجر': 'assets/images/bg_fajr.png',
    'الشروق': 'assets/images/bg_sunrise.jpg',
    'الظهر': 'assets/images/bg_dhuhr.jpg',
    'العصر': 'assets/images/bg_asr.jpg',
    'المغرب': 'assets/images/bg_maghrib.jpg',
    'العشاء': 'assets/images/bg_isha.jpg',
  };
  // ==================== LIFECYCLE ====================

  @override
  void initState() {
    super.initState();
    _startClock();
    _initPrayerLogic();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _refreshPrayerTimer?.cancel();
    super.dispose();
  }

  // ==================== TIMER LOGIC ====================

  void _startClock() {
    _updateTimeLeft();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTimeLeft(),
    );
  }

  void _updateTimeLeft() {
    if (nextPrayerTime == null) return;

    final now = DateTime.now();
    final diff = nextPrayerTime!.difference(now);

    if (diff.isNegative) {
      timeLeftText = 'حان وقت الصلاة';
    } else {
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      final seconds = diff.inSeconds % 60;
      timeLeftText =
          '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    if (mounted) setState(() {});
  }

  // ==================== PRAYER LOGIC ====================

  Future<void> _initPrayerLogic() async {
    try {
      // Initialize notification service FIRST
      await PrayerNotificationService().initialize();
      await PrayerNotificationService().requestPermissions();

      final pos = await _determinePosition();
      _getLocationName(pos);
      await _calculateAndSetPrayer(pos.latitude, pos.longitude);

      // Schedule notifications after calculating prayer times
      await _scheduleNotificationsWithPosition(pos.latitude, pos.longitude);

      _refreshPrayerTimer = Timer.periodic(const Duration(minutes: 1), (
        _,
      ) async {
        await _calculateAndSetPrayer(pos.latitude, pos.longitude);
      });

      // Reschedule notifications daily at midnight
      _scheduleDailyNotificationRefresh(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('Prayer init error: $e');
      // Fallback to Cairo
      await _calculateAndSetPrayer(30.0444, 31.2357);
      await _scheduleNotificationsWithPosition(30.0444, 31.2357);
    }
  }

  Future<void> _calculateAndSetPrayer(double lat, double lon) async {
    final coordinates = Coordinates(lat, lon);
    final now = DateTime.now();
    // final dateUtc = now.toUtc();
    final localDate = DateTime(now.year, now.month, now.day);
    final params = CalculationMethod.egyptian();
    params.madhab = Madhab.shafi;

    final prayerTimes = PrayerTimes(
      coordinates: coordinates,
      date: localDate,
      calculationParameters: params,
    );

    // Get all prayer times in local time
    final fajrTime = prayerTimes.fajr?.toLocal();
    final sunriseTime = prayerTimes.sunrise?.toLocal();
    final dhuhrTime = prayerTimes.dhuhr?.toLocal();
    final asrTime = prayerTimes.asr?.toLocal();
    final maghribTime = prayerTimes.maghrib?.toLocal();
    final ishaTime = prayerTimes.isha?.toLocal();

    // Create a map of prayer names to their times
    final prayerMap = {
      'الفجر': fajrTime,
      'الشروق': sunriseTime,
      'الظهر': dhuhrTime,
      'العصر': asrTime,
      'المغرب': maghribTime,
      'العشاء': ishaTime,
    };

    // Find the next prayer manually
    String? foundNextPrayerName;
    DateTime? foundNextPrayerTime;

    for (var entry in prayerMap.entries) {
      if (entry.value != null && entry.value!.isAfter(now)) {
        foundNextPrayerName = entry.key;
        foundNextPrayerTime = entry.value;
        break;
      }
    }

    // If no prayer found today, get tomorrow's Fajr
    if (foundNextPrayerName == null || foundNextPrayerTime == null) {
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowUtc = tomorrow.toUtc();
      final tomorrowPrayers = PrayerTimes(
        coordinates: coordinates,
        date: tomorrowUtc,
        calculationParameters: params,
      );
      foundNextPrayerName = 'الفجر';
      foundNextPrayerTime = tomorrowPrayers.fajr?.toLocal();
    }

    // Format all prayer times
    final formattedPrayerTimes = {
      'الفجر': fajrTime != null
          ? DateFormat('hh:mm a').format(fajrTime)
          : '--:--',
      'الشروق': sunriseTime != null
          ? DateFormat('hh:mm a').format(sunriseTime)
          : '--:--',
      'الظهر': dhuhrTime != null
          ? DateFormat('hh:mm a').format(dhuhrTime)
          : '--:--',
      'العصر': asrTime != null
          ? DateFormat('hh:mm a').format(asrTime)
          : '--:--',
      'المغرب': maghribTime != null
          ? DateFormat('hh:mm a').format(maghribTime)
          : '--:--',
      'العشاء': ishaTime != null
          ? DateFormat('hh:mm a').format(ishaTime)
          : '--:--',
    };

    final formattedNextTime = foundNextPrayerTime != null
        ? DateFormat('hh:mm a').format(foundNextPrayerTime)
        : '--:--';

    if (mounted) {
      setState(() {
        nextPrayerName = foundNextPrayerName ?? 'الصلاة';
        displayPrayerTime = formattedNextTime;
        nextPrayerTime = foundNextPrayerTime;
        allPrayerTimes = formattedPrayerTimes;
      });
    }

    // Debug print to verify
    debugPrint('Next Prayer: $foundNextPrayerName at $formattedNextTime');
  }

  // ==================== LOCATION LOGIC ====================

  Future<void> _scheduleNotificationsWithPosition(
    double lat,
    double lon,
  ) async {
    final Map<String, DateTime> prayerTimesMap = {};

    final coordinates = Coordinates(lat, lon);
    final now = DateTime.now();
    // 👇 استخدم DateTime عادي بدل DateComponents
    final localDate = DateTime(now.year, now.month, now.day);

    final params = CalculationMethod.muslimWorldLeague();
    params.madhab = Madhab.shafi;

    final prayerTimes = PrayerTimes(
      coordinates: coordinates,
      date: localDate, // ✅ الباراميتر الصحيح في adhan_dart
      calculationParameters: params,
    );

    // Add all prayer times to map
    // Add all prayer times to map
    if (prayerTimes.fajr != null) {
      prayerTimesMap['الفجر'] = prayerTimes.fajr!;
    }
    if (prayerTimes.sunrise != null) {
      prayerTimesMap['الشروق'] = prayerTimes.sunrise!;
    }
    if (prayerTimes.dhuhr != null) {
      prayerTimesMap['الظهر'] = prayerTimes.dhuhr!;
    }
    if (prayerTimes.asr != null) {
      prayerTimesMap['العصر'] = prayerTimes.asr!;
    }
    if (prayerTimes.maghrib != null) {
      prayerTimesMap['المغرب'] = prayerTimes.maghrib!;
    }
    if (prayerTimes.isha != null) {
      prayerTimesMap['العشاء'] = prayerTimes.isha!;
    }

    debugPrint('📅 Scheduling notifications for:');
    prayerTimesMap.forEach((name, time) {
      debugPrint('  $name: ${DateFormat('hh:mm a').format(time)}');
    });

    await PrayerNotificationService().schedulePrayerNotifications(
      prayerTimesMap,
    );
  }
  // ==================== LOCATION LOGIC ====================

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    );
  }

  Future<void> _getLocationName(Position pos) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        if (mounted) {
          setState(() {
            userLocation =
                '${place.locality ?? place.subAdministrativeArea ?? 'موقعك'}'
                ' - ${place.country ?? ''}';
          });
        }
      }
    } catch (e) {
      debugPrint('Location name error: $e');
      if (mounted) {
        setState(() {
          userLocation = 'الموقع غير معروف';
        });
      }
    }
  }

  // ==================== UI BUILD ====================

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color.fromARGB(180, 217, 217, 217),
    extendBody: true,
    body: Container(
      decoration: const BoxDecoration(
        color: Colors.transparent, // ⬅️ جعل الخلفية شفافة
      ),
      child: SafeArea(
        bottom: false,
        child: _buildBody(),
      ),
    ),
    bottomNavigationBar: _buildBottomNavigationBar(),
  );
}

  Widget _buildBody() {
    final pages = [
      const MoreScreen(),
      const TodoScreen(),
      const CalendarScreen(),
      const AzkarScreen(),
      _buildHomeContent(),
    ];

    return IndexedStack(index: _currentIndex, children: pages);
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildPrayerHeader(),
          // Negative margin to create overlap (35% of 350px = 122.5px)
          Transform.translate(
            offset: const Offset(0, -30),
            child: MainContentSection(
              allPrayerTimes: allPrayerTimes,
              nextPrayerName: nextPrayerName,
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + 20, // ⬅️ أضف هذا
          ),
        ],
      ),
    );
  }

  // ==================== PRAYER HEADER ====================

  Widget _buildPrayerHeader() {
    final backgroundImage =
        prayerBackgrounds[nextPrayerName] ?? 'assets/images/bg_asr.jpg';

    return Container(
      width: double.infinity,
      height: 270,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(backgroundImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Text(
            'صلاة $nextPrayerName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            displayPrayerTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '- حتى: $timeLeftText',
            style: const TextStyle(
              color: Color.fromARGB(255, 241, 233, 233),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  // ==================== BOTTOM NAV ====================

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: .3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF6B8F7F),
          elevation: 0, // Changed from 1 to 0
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black54,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: [
            _buildNavItem('assets/images/more.png', 'المزيد'),
            _buildNavItem('assets/images/to-do.png', 'المهام'),
            _buildNavItem('assets/images/calendar.png', 'التقويم'),
            _buildNavItem('assets/images/azkar.png', 'الأذكار'),
            _buildNavItem('assets/images/home.png', 'الرئيسية'),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(String iconPath, String label) {
    return BottomNavigationBarItem(
      icon: Image.asset(
        iconPath,
        width: 25,
        height: 25,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error, size: 24);
        },
      ),
      label: label,
    );
  }

  void _scheduleDailyNotificationRefresh(double latitude, double longitude) {
    // Get current time
    final now = DateTime.now();

    // Calculate the next midnight (start of the next day)
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);

    // Duration until midnight
    final durationUntilMidnight = nextMidnight.difference(now);

    // Schedule a one-time timer
    Timer(durationUntilMidnight, () async {
      // Recalculate prayer times and reschedule notifications for the new day
      await _calculateAndSetPrayer(latitude, longitude);
      await _scheduleNotificationsWithPosition(latitude, longitude);

      // Schedule again for the following day (recursion)
      _scheduleDailyNotificationRefresh(latitude, longitude);
    });
  }
}

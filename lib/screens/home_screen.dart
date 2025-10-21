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

  String userLocation = '...';
  int _currentIndex = 4;

  Timer? _clockTimer;
  Timer? _refreshPrayerTimer;

  static const Map<String, String> prayerBackgrounds = {
    'الفجر': 'assets/images/bg_fajr.png',
    'الشروق': 'assets/images/bg_sunrise.jpg',
    'الظهر': 'assets/images/bg_dhuhr.jpg',
    'العصر': 'assets/images/bg_asr.jpg',
    'المغرب': 'assets/images/bg_maghrib.jpg',
    'العشاء': 'assets/images/bg_isha.jpg',
  };

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

  void _startClock() {
    _updateTimeLeft();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimeLeft());
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
      timeLeftText = '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    if (mounted) setState(() {});
  }

  Future<void> _initPrayerLogic() async {
    try {
      final pos = await _determinePosition();
      _getLocationName(pos);
      await _calculateAndSetPrayer(pos.latitude, pos.longitude);

      await _scheduleNotificationsWithPosition(pos.latitude, pos.longitude);

      _refreshPrayerTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
        await _calculateAndSetPrayer(pos.latitude, pos.longitude);
      });

      _scheduleDailyNotificationRefresh(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('Prayer init error: $e');
      await _calculateAndSetPrayer(30.0444, 31.2357);
      await _scheduleNotificationsWithPosition(30.0444, 31.2357);
    }
  }

  Future<void> _calculateAndSetPrayer(double lat, double lon) async {
    final coordinates = Coordinates(lat, lon);
    final now = DateTime.now();
    final localDate = DateTime(now.year, now.month, now.day);
    final params = CalculationMethod.egyptian();
    params.madhab = Madhab.shafi;

    final prayerTimes = PrayerTimes(coordinates: coordinates, date: localDate, calculationParameters: params);

    final fajrTime = prayerTimes.fajr?.toLocal();
    final sunriseTime = prayerTimes.sunrise?.toLocal();
    final dhuhrTime = prayerTimes.dhuhr?.toLocal();
    final asrTime = prayerTimes.asr?.toLocal();
    final maghribTime = prayerTimes.maghrib?.toLocal();
    final ishaTime = prayerTimes.isha?.toLocal();

    final prayerMap = {
      'الفجر': fajrTime,
      'الشروق': sunriseTime,
      'الظهر': dhuhrTime,
      'العصر': asrTime,
      'المغرب': maghribTime,
      'العشاء': ishaTime,
    };

    String? foundNextPrayerName;
    DateTime? foundNextPrayerTime;
    for (var entry in prayerMap.entries) {
      if (entry.value != null && entry.value!.isAfter(now)) {
        foundNextPrayerName = entry.key;
        foundNextPrayerTime = entry.value;
        break;
      }
    }

    if (foundNextPrayerName == null || foundNextPrayerTime == null) {
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final tomorrowPrayers = PrayerTimes(coordinates: coordinates, date: tomorrow, calculationParameters: params);
      foundNextPrayerName = 'الفجر';
      foundNextPrayerTime = tomorrowPrayers.fajr?.toLocal();
    }

    final formattedPrayerTimes = {
      'الفجر': fajrTime != null ? DateFormat('hh:mm a').format(fajrTime) : '--:--',
      'الشروق': sunriseTime != null ? DateFormat('hh:mm a').format(sunriseTime) : '--:--',
      'الظهر': dhuhrTime != null ? DateFormat('hh:mm a').format(dhuhrTime) : '--:--',
      'العصر': asrTime != null ? DateFormat('hh:mm a').format(asrTime) : '--:--',
      'المغرب': maghribTime != null ? DateFormat('hh:mm a').format(maghribTime) : '--:--',
      'العشاء': ishaTime != null ? DateFormat('hh:mm a').format(ishaTime) : '--:--',
    };

    final formattedNextTime = foundNextPrayerTime != null ? DateFormat('hh:mm a').format(foundNextPrayerTime) : '--:--';

    if (mounted) {
      setState(() {
        nextPrayerName = foundNextPrayerName ?? 'الصلاة';
        displayPrayerTime = formattedNextTime;
        nextPrayerTime = foundNextPrayerTime;
        allPrayerTimes = formattedPrayerTimes;
      });
    }

    debugPrint('Next Prayer: $foundNextPrayerName at $formattedNextTime');
  }

  Future<void> _scheduleNotificationsWithPosition(double lat, double lon) async {
    final Map<String, DateTime> prayerTimesMap = {};

    final coordinates = Coordinates(lat, lon);
    final now = DateTime.now();
    final localDate = DateTime(now.year, now.month, now.day);

    final params = CalculationMethod.muslimWorldLeague();
    params.madhab = Madhab.shafi;

    final prayerTimes = PrayerTimes(coordinates: coordinates, date: localDate, calculationParameters: params);

    // IMPORTANT: store times by local time not UTC
    if (prayerTimes.fajr != null) prayerTimesMap['الفجر'] = prayerTimes.fajr!.toLocal();
    if (prayerTimes.sunrise != null) prayerTimesMap['الشروق'] = prayerTimes.sunrise!.toLocal();
    if (prayerTimes.dhuhr != null) prayerTimesMap['الظهر'] = prayerTimes.dhuhr!.toLocal();
    if (prayerTimes.asr != null) prayerTimesMap['العصر'] = prayerTimes.asr!.toLocal();
    if (prayerTimes.maghrib != null) prayerTimesMap['المغرب'] = prayerTimes.maghrib!.toLocal();
    if (prayerTimes.isha != null) prayerTimesMap['العشاء'] = prayerTimes.isha!.toLocal();

    debugPrint('📅 Scheduling notifications for:');
    prayerTimesMap.forEach((name, time) {
      debugPrint('  $name: ${DateFormat('hh:mm a').format(time)} (local)');
    });

    await PrayerNotificationService().schedulePrayerNotifications(prayerTimesMap);
  }

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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 0),
    );
  }

  Future<void> _getLocationName(Position pos) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        if (mounted) {
          setState(() {
            userLocation = '${place.locality ?? place.subAdministrativeArea ?? 'موقعك'} - ${place.country ?? ''}';
          });
        }
      }
    } catch (e) {
      debugPrint('Location name error: $e');
      if (mounted) setState(() => userLocation = 'الموقع غير معروف');
    }
  }

  void _scheduleDailyNotificationRefresh(double latitude, double longitude) {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = nextMidnight.difference(now);

    Timer(durationUntilMidnight, () async {
      await _calculateAndSetPrayer(latitude, longitude);
      await _scheduleNotificationsWithPosition(latitude, longitude);
      _scheduleDailyNotificationRefresh(latitude, longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(180, 217, 217, 217),
      extendBody: true,
      body: SafeArea(bottom: false, child: _buildBody()),
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
          Transform.translate(
            offset: const Offset(0, -30),
            child: MainContentSection(allPrayerTimes: allPrayerTimes, nextPrayerName: nextPrayerName),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

  Widget _buildPrayerHeader() {
    final backgroundImage = prayerBackgrounds[nextPrayerName] ?? 'assets/images/bg_asr.jpg';
    return Container(
      width: double.infinity,
      height: 270,
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(backgroundImage), fit: BoxFit.cover),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'صلاة $nextPrayerName',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Text(
            displayPrayerTime,
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
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

  Widget _buildBottomNavigationBar() {
    return SafeArea(
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: .3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF6B8F7F),
            elevation: 0,
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
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
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(String iconPath, String label) {
    return BottomNavigationBarItem(
      icon: Image.asset(
        iconPath,
        width: 25,
        height: 25,
        errorBuilder: (_, __, ___) => const Icon(Icons.error, size: 24),
      ),
      label: label,
    );
  }
}

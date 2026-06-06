
import 'dart:async';
import 'dart:convert';
import 'package:azkar_app/screens/journey_screen.dart';
import 'package:azkar_app/services/prayer_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:azkar_app/screens/azkar_screen.dart';
import 'package:azkar_app/screens/calendar_screen.dart';
import 'package:azkar_app/screens/more_screen.dart';
import 'package:azkar_app/widgets/main_content_section.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:azkar_app/services/zikr_popup_notification.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _lastBackPressTime;
  Map<String, String> allPrayerTimes = {
    'الفجر': '--:--',
    'الظهر': '--:--',
    'العصر': '--:--',
    'المغرب': '--:--',
    'العشاء': '--:--',
  };

  String nextPrayerName = '...';
  String displayPrayerTime = '--:--';
  DateTime? nextPrayerTime;

  String userLocation = '...';
  int _currentIndex = 4;

  Timer? _refreshPrayerTimer;

  double? _cachedLat;
  double? _cachedLon;
  final bool _isLoading = false;
  String? _currentCountry;

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
    _loadCachedDataAndRefresh();
    _initZikrNotifications();
  }

  Future<void> _initZikrNotifications() async {
    final zikrService = ZikrPopupNotification();
    final isEnabled = await zikrService.isEnabled();
    if (!isEnabled) {
      await zikrService.start(intervalHours: 4);
      debugPrint('✅ Zikr notifications started');
    } else {
      debugPrint('✅ Zikr notifications already running');
    }
  }

  @override
  void dispose() {
    _refreshPrayerTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCachedDataAndRefresh() async {
    try {
      await _loadCachedPrayerData();
      _refreshPrayerDataInBackground();
    } catch (e) {
      debugPrint('Error loading cached data: $e');
      _initPrayerLogic();
    }
  }

  Future<void> _loadCachedPrayerData() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedPrayerTimesJson = prefs.getString('cached_prayer_times');
    final cachedNextPrayer      = prefs.getString('cached_next_prayer');
    final cachedNextPrayerTime  = prefs.getString('cached_next_prayer_time');
    final cachedLocation        = prefs.getString('cached_location');

    if (cachedPrayerTimesJson != null && cachedNextPrayer != null) {
      final Map<String, dynamic> decodedTimes = json.decode(cachedPrayerTimesJson);
      setState(() {
        allPrayerTimes     = Map<String, String>.from(decodedTimes);
        nextPrayerName     = cachedNextPrayer;
        displayPrayerTime  = prefs.getString('cached_next_prayer_display') ?? '--:--';
        userLocation       = cachedLocation ?? 'موقعك';
        if (cachedNextPrayerTime != null) {
          nextPrayerTime = DateTime.tryParse(cachedNextPrayerTime);
        }
      });
      debugPrint('✅ Loaded cached prayer data instantly!');
    }

    _cachedLat      = prefs.getDouble('cached_lat');
    _cachedLon      = prefs.getDouble('cached_lon');
    _currentCountry = prefs.getString('cached_country');
  }

  Future<void> _refreshPrayerDataInBackground() async {
    try {
      final prefs     = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString('last_prayer_update');
      final today      = DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (lastUpdate == today && _cachedLat != null && _cachedLon != null) {
        await _calculateAndSetPrayer(_cachedLat!, _cachedLon!, _currentCountry);
        debugPrint('✅ Prayer times are up to date, recalculated next prayer only');
        return;
      }

      final pos     = await _determinePosition();
      final country = await _getLocationName(pos);
      _currentCountry = country;

      await _saveCachedLocation(pos.latitude, pos.longitude, country);
      _cachedLat = pos.latitude;
      _cachedLon = pos.longitude;

      await _calculateAndSetPrayer(pos.latitude, pos.longitude, country);
      await _scheduleNotificationsWithPosition(pos.latitude, pos.longitude, country);
      await prefs.setString('last_prayer_update', today);

      _refreshPrayerTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
        if (_cachedLat != null && _cachedLon != null) {
          await _calculateAndSetPrayer(_cachedLat!, _cachedLon!, _currentCountry);
        }
      });

      _scheduleDailyNotificationRefresh(pos.latitude, pos.longitude, country);
      debugPrint('✅ Prayer data refreshed in background');

    } catch (e) {
      debugPrint('Background refresh error: $e');
      if (_cachedLat == null || _cachedLon == null) {
        await _calculateAndSetPrayer(30.0444, 31.2357, 'Egypt');
        await _scheduleNotificationsWithPosition(30.0444, 31.2357, 'Egypt');
      }
    }
  }

  Future<void> _initPrayerLogic() async {
    try {
      final pos     = await _determinePosition();
      final country = await _getLocationName(pos);
      _currentCountry = country;

      await _saveCachedLocation(pos.latitude, pos.longitude, country);
      _cachedLat = pos.latitude;
      _cachedLon = pos.longitude;

      await _calculateAndSetPrayer(pos.latitude, pos.longitude, country);
      await _scheduleNotificationsWithPosition(pos.latitude, pos.longitude, country);

      _refreshPrayerTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
        if (_cachedLat != null && _cachedLon != null) {
          await _calculateAndSetPrayer(_cachedLat!, _cachedLon!, _currentCountry);
        }
      });

      _scheduleDailyNotificationRefresh(pos.latitude, pos.longitude, country);

    } catch (e) {
      debugPrint('Prayer init error: $e');
      await _calculateAndSetPrayer(30.0444, 31.2357, 'Egypt');
      await _scheduleNotificationsWithPosition(30.0444, 31.2357, 'Egypt');
    }
  }

  Future<void> _saveCachedLocation(double lat, double lon, String? country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('cached_lat', lat);
    await prefs.setDouble('cached_lon', lon);
    if (country != null) await prefs.setString('cached_country', country);
  }

  Future<void> _savePrayerTimesToCache(
    Map<String, String> prayerTimes,
    String nextPrayer,
    String nextPrayerDisplay,
    DateTime? nextPrayerDateTime,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_prayer_times', json.encode(prayerTimes));
    await prefs.setString('cached_next_prayer', nextPrayer);
    await prefs.setString('cached_next_prayer_display', nextPrayerDisplay);
    if (nextPrayerDateTime != null) {
      await prefs.setString('cached_next_prayer_time', nextPrayerDateTime.toIso8601String());
    }
  }

  CalculationParameters _getCalculationMethod(double lat, double lon, String? country) {
    final countryLower = country?.toLowerCase() ?? '';
    CalculationParameters params;

    if (countryLower.contains('egypt') || countryLower.contains('مصر') ||
        countryLower.contains('sudan') || countryLower.contains('السودان') ||
        countryLower.contains('libya') || countryLower.contains('ليبيا')) {
      params = CalculationMethod.egyptian();
    } else if (countryLower.contains('united states') || countryLower.contains('canada') ||
               countryLower.contains('أمريكا') || countryLower.contains('كندا') ||
               (lat > 25 && lat < 50 && lon > -130 && lon < -60)) {
      params = CalculationMethod.northAmerica();
    } else if (countryLower.contains('saudi') || countryLower.contains('السعودية') ||
               countryLower.contains('kuwait') || countryLower.contains('الكويت') ||
               countryLower.contains('qatar') || countryLower.contains('قطر') ||
               countryLower.contains('bahrain') || countryLower.contains('البحرين') ||
               countryLower.contains('emirates') || countryLower.contains('الإمارات') ||
               countryLower.contains('oman') || countryLower.contains('عمان')) {
      params = CalculationMethod.ummAlQura();
    } else if (countryLower.contains('turkey') || countryLower.contains('تركيا') ||
               countryLower.contains('türkiye')) {
      params = CalculationMethod.turkiye();
    } else if (countryLower.contains('iran') || countryLower.contains('إيران') ||
               countryLower.contains('iraq') || countryLower.contains('العراق')) {
      params = CalculationMethod.tehran();
    } else if (countryLower.contains('pakistan') || countryLower.contains('باكستان') ||
               countryLower.contains('india') || countryLower.contains('الهند') ||
               countryLower.contains('bangladesh') || countryLower.contains('بنغلاديش')) {
      params = CalculationMethod.karachi();
    } else if (countryLower.contains('malaysia') || countryLower.contains('ماليزيا') ||
               countryLower.contains('singapore') || countryLower.contains('سنغافورة') ||
               countryLower.contains('indonesia') || countryLower.contains('إندونيسيا') ||
               countryLower.contains('brunei') || countryLower.contains('بروناي')) {
      params = CalculationMethod.singapore();
    } else if (countryLower.contains('morocco') || countryLower.contains('المغرب') ||
               countryLower.contains('tunisia') || countryLower.contains('تونس') ||
               countryLower.contains('algeria') || countryLower.contains('الجزائر') ||
               countryLower.contains('mauritania') || countryLower.contains('موريتانيا')) {
      params = CalculationMethod.moonsightingCommittee();
    } else if (countryLower.contains('syria') || countryLower.contains('سوريا') ||
               countryLower.contains('jordan') || countryLower.contains('الأردن') ||
               countryLower.contains('palestine') || countryLower.contains('فلسطين') ||
               countryLower.contains('lebanon') || countryLower.contains('لبنان')) {
      params = CalculationMethod.muslimWorldLeague();
    } else if (lat > 40 && lat < 70 && lon > -10 && lon < 40) {
      params = CalculationMethod.muslimWorldLeague();
    } else {
      params = CalculationMethod.muslimWorldLeague();
    }

    if (countryLower.contains('egypt') || countryLower.contains('saudi') ||
        countryLower.contains('kuwait') || countryLower.contains('emirates') ||
        countryLower.contains('malaysia') || countryLower.contains('indonesia') ||
        countryLower.contains('مصر') || countryLower.contains('السعودية') ||
        countryLower.contains('الكويت') || countryLower.contains('الإمارات') ||
        countryLower.contains('ماليزيا') || countryLower.contains('إندونيسيا')) {
      params.madhab = Madhab.shafi;
    } else {
      params.madhab = Madhab.hanafi;
    }

    if (lat.abs() > 48) params.highLatitudeRule = HighLatitudeRule.middleOfTheNight;

    return params;
  }

  Future<void> _calculateAndSetPrayer(double lat, double lon, String? country) async {
    final coordinates = Coordinates(lat, lon);
    final now       = DateTime.now();
    final localDate = DateTime(now.year, now.month, now.day);
    final params    = _getCalculationMethod(lat, lon, country);

    final prayerTimes = PrayerTimes(
      coordinates: coordinates, date: localDate, calculationParameters: params);

    final fajrTime    = prayerTimes.fajr?.toLocal();
    final sunriseTime = prayerTimes.sunrise?.toLocal();
    final dhuhrTime   = prayerTimes.dhuhr?.toLocal();
    final asrTime     = prayerTimes.asr?.toLocal();
    final maghribTime = prayerTimes.maghrib?.toLocal();
    final ishaTime    = prayerTimes.isha?.toLocal();

    final prayerMap = {
      'الفجر': fajrTime, 'الشروق': sunriseTime, 'الظهر': dhuhrTime,
      'العصر': asrTime,  'المغرب': maghribTime,  'العشاء': ishaTime,
    };

    String?   foundNextPrayerName;
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
      final tomorrowPrayers = PrayerTimes(
        coordinates: coordinates, date: tomorrow, calculationParameters: params);
      foundNextPrayerName = 'الفجر';
      foundNextPrayerTime = tomorrowPrayers.fajr?.toLocal();
    }

    final formattedPrayerTimes = {
      'الفجر':  fajrTime    != null ? DateFormat('h:mm a', 'en_US').format(fajrTime)    : '--:--',
      'الظهر':  dhuhrTime   != null ? DateFormat('h:mm a', 'en_US').format(dhuhrTime)   : '--:--',
      'العصر':  asrTime     != null ? DateFormat('h:mm a', 'en_US').format(asrTime)     : '--:--',
      'المغرب': maghribTime != null ? DateFormat('h:mm a', 'en_US').format(maghribTime) : '--:--',
      'العشاء': ishaTime    != null ? DateFormat('h:mm a', 'en_US').format(ishaTime)    : '--:--',
    };

    final formattedNextTime = foundNextPrayerTime != null
        ? DateFormat('h:mm a', 'en_US').format(foundNextPrayerTime) : '--:--';

    final prefsForJourney = await SharedPreferences.getInstance();
    final prayerTimeKeys  = {
      'الفجر': fajrTime, 'الظهر': dhuhrTime, 'العصر': asrTime,
      'المغرب': maghribTime, 'العشاء': ishaTime,
    };
    final keyMap = {
      'الفجر': 'cached_fajr_time', 'الظهر': 'cached_dhuhr_time',
      'العصر': 'cached_asr_time',  'المغرب': 'cached_maghrib_time', 'العشاء': 'cached_isha_time',
    };
    for (final entry in prayerTimeKeys.entries) {
      if (entry.value != null) {
        await prefsForJourney.setString(keyMap[entry.key]!, entry.value!.toIso8601String());
      }
    }

    await _savePrayerTimesToCache(
      formattedPrayerTimes,
      foundNextPrayerName ?? 'الصلاة',
      formattedNextTime,
      foundNextPrayerTime,
    );

    if (mounted) {
      setState(() {
        nextPrayerName    = foundNextPrayerName ?? 'الصلاة';
        displayPrayerTime = formattedNextTime;
        nextPrayerTime    = foundNextPrayerTime;
        allPrayerTimes    = formattedPrayerTimes;
      });
    }

    debugPrint('✅ Next Prayer: $foundNextPrayerName at $formattedNextTime');
  }

  Future<void> _scheduleNotificationsWithPosition(double lat, double lon, String? country) async {
    final Map<String, DateTime> prayerTimesMap = {};
    final coordinates = Coordinates(lat, lon);
    final now         = DateTime.now();
    final localDate   = DateTime(now.year, now.month, now.day);
    final params      = _getCalculationMethod(lat, lon, country);

    final prayerTimes = PrayerTimes(
      coordinates: coordinates, date: localDate, calculationParameters: params);

    if (prayerTimes.fajr    != null) prayerTimesMap['الفجر']   = prayerTimes.fajr!.toLocal();
    if (prayerTimes.sunrise != null) prayerTimesMap['الشروق']  = prayerTimes.sunrise!.toLocal();
    if (prayerTimes.dhuhr   != null) prayerTimesMap['الظهر']   = prayerTimes.dhuhr!.toLocal();
    if (prayerTimes.asr     != null) prayerTimesMap['العصر']   = prayerTimes.asr!.toLocal();
    if (prayerTimes.maghrib != null) prayerTimesMap['المغرب']  = prayerTimes.maghrib!.toLocal();
    if (prayerTimes.isha    != null) prayerTimesMap['العشاء']  = prayerTimes.isha!.toLocal();

    await PrayerNotificationService().schedulePrayerNotifications(prayerTimesMap);
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw Exception('Location permissions are denied');
    }
    if (permission == LocationPermission.deniedForever) throw Exception('Location permissions are permanently denied');

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 0));
  }

  Future<String?> _getLocationName(Position pos) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final place   = placemarks.first;
        final country = place.country ?? '';
        if (mounted) {
          setState(() {
            userLocation = '${place.locality ?? place.subAdministrativeArea ?? 'موقعك'} - $country';
          });
          SharedPreferences.getInstance().then((prefs) {
            prefs.setString('cached_location', userLocation);
          });
        }
        return country;
      }
    } catch (e) {
      debugPrint('Location name error: $e');
      if (mounted) setState(() => userLocation = 'الموقع غير معروف');
    }
    return null;
  }

  void _scheduleDailyNotificationRefresh(double latitude, double longitude, String? country) {
    final now             = DateTime.now();
    final nextMidnight    = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = nextMidnight.difference(now);
    Timer(durationUntilMidnight, () async {
      await _calculateAndSetPrayer(latitude, longitude, country);
      await _scheduleNotificationsWithPosition(latitude, longitude, country);
      _scheduleDailyNotificationRefresh(latitude, longitude, country);
    });
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 4) {
          setState(() => _currentIndex = 4);
          return false;
        }
        final now = DateTime.now();
        if (_lastBackPressTime != null &&
            now.difference(_lastBackPressTime!) < const Duration(seconds: 2)) {
          return true;
        }
        _lastBackPressTime = now;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('اضغط مرة أخرى للخروج'),
          duration: Duration(seconds: 2),
          backgroundColor: Color.fromARGB(186, 107, 143, 127),
        ));
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(180, 217, 217, 217),
        extendBody: true,
        body: SafeArea(bottom: false, child: _buildBody()),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildBody() {
    final pages = [
      const MoreScreen(),
      const JourneyScreen(),
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
            child: MainContentSection(
              allPrayerTimes: allPrayerTimes,
              nextPrayerName: nextPrayerName,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

  Widget _buildPrayerHeader() {
    final backgroundImage = prayerBackgrounds[nextPrayerName] ?? 'assets/images/bg_asr.jpg';

    if (_isLoading && nextPrayerName == '...') {
      return Container(
        width: double.infinity, height: 270,
        decoration: BoxDecoration(image: DecorationImage(image: AssetImage(backgroundImage), fit: BoxFit.cover)),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Container(
      width: double.infinity, height: 270,
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(backgroundImage), fit: BoxFit.cover)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('صلاة $nextPrayerName',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Text(displayPrayerTime,
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _CountdownText(nextPrayerTime: nextPrayerTime),
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
          boxShadow: [BoxShadow(
            color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: .3),
            blurRadius: 10, offset: const Offset(0, -2))],
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
      icon: Image.asset(iconPath, width: 25, height: 25,
        errorBuilder: (_, __, ___) => const Icon(Icons.error, size: 24)),
      label: label,
    );
  }
}

class _CountdownText extends StatefulWidget {
  final DateTime? nextPrayerTime;
  const _CountdownText({required this.nextPrayerTime});

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText> {
  Timer? _timer;
  String _text = '--:--';

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  @override
  void didUpdateWidget(_CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nextPrayerTime != widget.nextPrayerTime) _update();
  }

  void _update() {
    if (widget.nextPrayerTime == null) {
      if (mounted) setState(() => _text = '--:--');
      return;
    }
    final diff = widget.nextPrayerTime!.difference(DateTime.now());
    final text = diff.isNegative
        ? 'حان وقت الصلاة'
        : '${diff.inHours.toString().padLeft(2, '0')}:'
          '${(diff.inMinutes % 60).toString().padLeft(2, '0')}:'
          '${(diff.inSeconds % 60).toString().padLeft(2, '0')}';
    if (mounted) setState(() => _text = text);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '- حتى: $_text',
      style: const TextStyle(
        color: Color.fromARGB(255, 241, 233, 233),
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
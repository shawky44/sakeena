
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  double? _currentHeading;
  double? _qiblaDirection;
  bool _hasPermission = false;
  bool _isLoading = true;
  String _errorMessage = '';
  Position? _currentPosition;
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _compassAvailable = true;
  
  // للدقة والمعايرة
  final List<double> _headingHistory = [];
  static const int _historySize = 5; // عدد القراءات للمتوسط
  double _compassAccuracy = 0.0;
  bool _needsCalibration = false;
  int _stableReadings = 0;
  double? _lastStableHeading;
  
  // لاكتشاف التداخل المغناطيسي
  bool _magneticInterference = false;
  DateTime? _lastInterferenceCheck;

  @override
  void initState() {
    super.initState();
    _initQiblaFinder();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initQiblaFinder() async {
    await _checkPermissions();
    if (_hasPermission) {
      await _getCurrentLocation();
      await _listenToCompass();
    }
  }

  Future<void> _checkPermissions() async {
    var locationStatus = await Permission.location.status;
    if (locationStatus.isDenied) {
      locationStatus = await Permission.location.request();
    }

    var sensorsStatus = await Permission.sensors.status;
    if (sensorsStatus.isDenied) {
      sensorsStatus = await Permission.sensors.request();
    }

    setState(() {
      _hasPermission = locationStatus.isGranted;
      if (!_hasPermission) {
        _errorMessage = 'يرجى السماح بالوصول للموقع والبوصلة';
        _isLoading = false;
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'يرجى تفعيل خدمة الموقع';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best, // أعلى دقة
          distanceFilter: 0,
        ),
      );

      setState(() {
        _currentPosition = position;
        _qiblaDirection = _calculateQiblaDirection(
          position.latitude,
          position.longitude,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في الحصول على الموقع: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  double _calculateQiblaDirection(double latitude, double longitude) {
    const double kaabaLat = 21.4225;
    const double kaabaLng = 39.8262;

    double lat1 = latitude * math.pi / 180;
    double lng1 = longitude * math.pi / 180;
    double lat2 = kaabaLat * math.pi / 180;
    double lng2 = kaabaLng * math.pi / 180;

    double dLng = lng2 - lng1;
    double y = math.sin(dLng) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    double bearing = math.atan2(y, x);

    bearing = bearing * 180 / math.pi;
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  Future<void> _listenToCompass() async {
    final compassEvents = FlutterCompass.events;
    
    if (compassEvents == null) {
      setState(() {
        _compassAvailable = false;
        _errorMessage = 'البوصلة غير متاحة على هذا الجهاز';
        _isLoading = false;
      });
      return;
    }

    _compassSubscription = compassEvents.listen(
      (CompassEvent event) {
        if (mounted && event.heading != null) {
          _processCompassReading(event);
        }
      },
      onError: (error) {
        debugPrint('❌ Compass error: $error');
        if (mounted) {
          setState(() {
            _errorMessage = 'خطأ في قراءة البوصلة: $error';
          });
        }
      },
    );
  }

  void _processCompassReading(CompassEvent event) {
    final heading = event.heading!;
    final accuracy = event.accuracy ?? 0.0;

    // إضافة القراءة للتاريخ
    _headingHistory.add(heading);
    if (_headingHistory.length > _historySize) {
      _headingHistory.removeAt(0);
    }

    // حساب المتوسط المتحرك (Moving Average) لتقليل الضوضاء
    double smoothedHeading = _calculateSmoothedHeading();

    // اكتشاف التداخل المغناطيسي
    _detectMagneticInterference(heading);

    // تحديد حاجة المعايرة
    _checkCalibrationStatus(accuracy);

    // تحديث القراءة المستقرة
    _updateStableReading(smoothedHeading);

    if (mounted) {
      setState(() {
        _currentHeading = smoothedHeading;
        _compassAccuracy = accuracy;
      });
    }
  }

  double _calculateSmoothedHeading() {
    if (_headingHistory.isEmpty) return 0;
    if (_headingHistory.length == 1) return _headingHistory[0];

    // معالجة حالة 0°/360° (الشمال)
    // نحول الزوايا للتعامل مع الانتقال من 359° إلى 0°
    List<double> adjustedHeadings = [];
    double reference = _headingHistory[0];

    for (var heading in _headingHistory) {
      double diff = heading - reference;
      if (diff > 180) {
        adjustedHeadings.add(heading - 360);
      } else if (diff < -180) {
        adjustedHeadings.add(heading + 360);
      } else {
        adjustedHeadings.add(heading);
      }
    }

    // حساب المتوسط
    double sum = adjustedHeadings.reduce((a, b) => a + b);
    double average = sum / adjustedHeadings.length;

    // إرجاع القيمة للنطاق 0-360
    return (average + 360) % 360;
  }

  void _detectMagneticInterference(double heading) {
    if (_headingHistory.length < 3) return;

    // حساب التغير السريع في القراءات
    double maxChange = 0;
    for (int i = 1; i < _headingHistory.length; i++) {
      double change = (_headingHistory[i] - _headingHistory[i - 1]).abs();
      if (change > 180) change = 360 - change;
      if (change > maxChange) maxChange = change;
    }

    // إذا كان التغير أكبر من 30 درجة بين القراءات = تداخل محتمل
    bool hasInterference = maxChange > 30;

    // تحديث حالة التداخل كل 3 ثواني
    final now = DateTime.now();
    if (_lastInterferenceCheck == null ||
        now.difference(_lastInterferenceCheck!).inSeconds >= 3) {
      if (mounted && _magneticInterference != hasInterference) {
        setState(() {
          _magneticInterference = hasInterference;
        });
      }
      _lastInterferenceCheck = now;
    }
  }

  void _checkCalibrationStatus(double accuracy) {
    // دقة منخفضة = يحتاج معايرة
    // accuracy: -1 (unknown), 0 (unreliable), 1 (low), 2 (medium), 3 (high)
    bool needsCal = accuracy < 2;

    if (mounted && _needsCalibration != needsCal) {
      setState(() {
        _needsCalibration = needsCal;
      });
    }
  }

  void _updateStableReading(double heading) {
    if (_lastStableHeading == null) {
      _lastStableHeading = heading;
      _stableReadings = 1;
      return;
    }

    // حساب الفرق
    double diff = (heading - _lastStableHeading!).abs();
    if (diff > 180) diff = 360 - diff;

    // إذا كان الفرق أقل من 2 درجة = قراءة مستقرة
    if (diff < 2) {
      _stableReadings++;
    } else {
      _stableReadings = 0;
      _lastStableHeading = heading;
    }
  }

  double get _qiblaAngle {
    if (_currentHeading == null || _qiblaDirection == null) return 0;
    double angle = _qiblaDirection! - _currentHeading!;
    return angle * math.pi / 180;
  }

  bool get _isPointingToQibla {
    if (_currentHeading == null || _qiblaDirection == null) return false;
    if (_stableReadings < 3) return false; // يتطلب 3 قراءات مستقرة
    
    double diff = (_qiblaDirection! - _currentHeading!).abs();
    diff = diff > 180 ? 360 - diff : diff;
    return diff < 5; // ضيقنا النطاق لـ 5 درجات للدقة
  }

  Color get _compassAccuracyColor {
    if (_compassAccuracy >= 3) return Colors.green;
    if (_compassAccuracy >= 2) return Colors.orange;
    return Colors.red;
  }

  String get _compassAccuracyText {
    if (_compassAccuracy >= 3) return 'دقة عالية';
    if (_compassAccuracy >= 2) return 'دقة متوسطة';
    if (_compassAccuracy >= 1) return 'دقة منخفضة';
    return 'دقة غير معروفة';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF476B5E),
      appBar: AppBar(
        title: const Text(
          'اتجاه القبلة',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF476B5E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = '';
                _headingHistory.clear();
                _stableReadings = 0;
              });
              _initQiblaFinder();
            },
            tooltip: 'إعادة التحميل',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _errorMessage.isNotEmpty
                ? _buildErrorWidget()
                : _buildQiblaCompass(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 64),
            const SizedBox(height: 20),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = '';
                });
                _initQiblaFinder();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF476B5E),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('إعادة المحاولة'),
            ),
            if (!_compassAvailable) ...[
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => openAppSettings(),
                child: const Text(
                  'فتح إعدادات التطبيق',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQiblaCompass() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              'اتجاه القبلة',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            
            // مؤشر الحالة الرئيسي
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _isPointingToQibla 
                    ? Colors.green.withValues(alpha: .3) 
                    : Colors.white.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isPointingToQibla ? Icons.check_circle : Icons.explore,
                    color: _isPointingToQibla ? Colors.greenAccent : Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isPointingToQibla ? 'أنت تتجه نحو القبلة ✓' : 'قم بتحريك هاتفك',
                    style: TextStyle(
                      fontSize: 16,
                      color: _isPointingToQibla ? Colors.greenAccent : Colors.white70,
                      fontWeight:
                          _isPointingToQibla ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // شريط دقة البوصلة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _compassAccuracyColor.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.speed,
                    color: _compassAccuracyColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _compassAccuracyText,
                    style: TextStyle(
                      color: _compassAccuracyColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // تحذير المعايرة
            if (_needsCalibration) ...[
              const SizedBox(height: 10),
              _buildCalibrationWarning(),
            ],

            // تحذير التداخل المغناطيسي
            if (_magneticInterference) ...[
              const SizedBox(height: 10),
              _buildInterferenceWarning(),
            ],

            const SizedBox(height: 30),

            // البوصلة
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .3),
                    spreadRadius: 5,
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // الدائرة الخارجية مع علامات الدرجات
                  CustomPaint(
                    size: const Size(300, 300),
                    painter: CompassPainter(
                      heading: _currentHeading ?? 0,
                    ),
                  ),

                  // السهم المشير للقبلة - بدون أنيميشن للدقة
                  Transform.rotate(
                    angle: _qiblaAngle,
                    child: Icon(
                      Icons.navigation,
                      size: 100,
                      color: _isPointingToQibla
                          ? Colors.green
                          : const Color(0xFF476B5E),
                    ),
                  ),

                  // نقطة المركز
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isPointingToQibla
                          ? Colors.green
                          : const Color(0xFF476B5E),
                    ),
                  ),

                  // مؤشر الاستقرار
                  if (_stableReadings >= 3)
                    Positioned(
                      top: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: .8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'مستقر',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // معلومات الموقع والاتجاه
            if (_currentPosition != null && _qiblaDirection != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoItem(
                          'اتجاه القبلة',
                          '${_qiblaDirection!.toStringAsFixed(1)}°',
                        ),
                        _buildInfoItem(
                          'اتجاه الهاتف',
                          '${(_currentHeading ?? 0).toStringAsFixed(1)}°',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoItem(
                          'الفرق',
                          '${_getAngleDifference().toStringAsFixed(1)}°',
                        ),
                        _buildInfoItem(
                          'القراءات المستقرة',
                          '$_stableReadings',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // إرشادات المعايرة
            _buildCalibrationInstructions(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationWarning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'البوصلة تحتاج معايرة!\nقم بتحريك الهاتف على شكل رقم 8',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterferenceWarning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: const Row(
        children: [
          Icon(Icons.sensors_off, color: Colors.red, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'تداخل مغناطيسي!\nابتعد عن الأجهزة الإلكترونية والمعادن',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationInstructions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white70, size: 20),
              SizedBox(width: 10),
              Text(
                'للحصول على أفضل دقة:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionItem('1️⃣', 'امسك الهاتف بشكل أفقي (موازي للأرض)'),
          _buildInstructionItem('2️⃣', 'ابتعد عن الأجهزة الإلكترونية والمعادن'),
          _buildInstructionItem('3️⃣', 'قم بمعايرة البوصلة: حرك الهاتف على شكل رقم 8'),
          _buildInstructionItem('4️⃣', 'انتظر حتى تظهر علامة "مستقر"'),
          _buildInstructionItem('5️⃣', 'تأكد من وجود إشارة GPS قوية'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  double _getAngleDifference() {
    if (_currentHeading == null || _qiblaDirection == null) return 0;
    double diff = (_qiblaDirection! - _currentHeading!).abs();
    return diff > 180 ? 360 - diff : diff;
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class CompassPainter extends CustomPainter {
  final double heading;

  CompassPainter({required this.heading});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // رسم الدائرة الخارجية
    final circlePaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 10, circlePaint);

    // رسم علامات الدرجات (كل 10 درجات)
    for (int i = 0; i < 360; i += 10) {
      final angle = (i - heading) * math.pi / 180;
      final startRadius = i % 30 == 0 ? radius - 30 : radius - 20;
      final endRadius = radius - 10;

      final start = Offset(
        center.dx + startRadius * math.sin(angle),
        center.dy - startRadius * math.cos(angle),
      );
      final end = Offset(
        center.dx + endRadius * math.sin(angle),
        center.dy - endRadius * math.cos(angle),
      );

      final paint = Paint()
        ..color = i % 90 == 0 ? Colors.red : Colors.grey.shade600
        ..strokeWidth = i % 30 == 0 ? 2 : 1;

      canvas.drawLine(start, end, paint);
    }

    // رسم حروف الاتجاهات
    final labels = ['N', 'E', 'S', 'W'];
    final labelsArabic = ['ش', 'ق', 'ج', 'غ'];
    final angles = [0, 90, 180, 270];

    for (int i = 0; i < 4; i++) {
      final angle = (angles[i] - heading) * math.pi / 180;
      final textRadius = radius - 45;
      final textPosition = Offset(
        center.dx + textRadius * math.sin(angle),
        center.dy - textRadius * math.cos(angle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${labels[i]}\n${labelsArabic[i]}',
          style: TextStyle(
            color: i == 0 ? Colors.red : const Color(0xFF476B5E),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          textPosition.dx - textPainter.width / 2,
          textPosition.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(CompassPainter oldDelegate) {
    return heading != oldDelegate.heading;
  }
}
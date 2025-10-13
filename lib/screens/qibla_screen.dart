import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

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

  @override
  void initState() {
    super.initState();
    _initQiblaFinder();
  }

  Future<void> _initQiblaFinder() async {
    await _checkPermissions();
    if (_hasPermission) {
      await _getCurrentLocation();
      _listenToCompass();
    }
  }

  Future<void> _checkPermissions() async {
    // Check location permission
    var locationStatus = await Permission.location.status;
    if (locationStatus.isDenied) {
      locationStatus = await Permission.location.request();
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
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
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
    // Kaaba coordinates
    const double kaabaLat = 21.4225;
    const double kaabaLng = 39.8262;

    // Convert to radians
    double lat1 = latitude * math.pi / 180;
    double lng1 = longitude * math.pi / 180;
    double lat2 = kaabaLat * math.pi / 180;
    double lng2 = kaabaLng * math.pi / 180;

    // Calculate bearing
    double dLng = lng2 - lng1;
    double y = math.sin(dLng) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    double bearing = math.atan2(y, x);

    // Convert to degrees
    bearing = bearing * 180 / math.pi;
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  void _listenToCompass() {
    FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted) {
        setState(() {
          _currentHeading = event.heading;
        });
      }
    });
  }

  double get _qiblaAngle {
    if (_currentHeading == null || _qiblaDirection == null) return 0;
    double angle = _qiblaDirection! - _currentHeading!;
    return angle * math.pi / 180;
  }

  bool get _isPointingToQibla {
    if (_currentHeading == null || _qiblaDirection == null) return false;
    double diff = (_qiblaDirection! - _currentHeading!).abs();
    diff = diff > 180 ? 360 - diff : diff;
    return diff < 10; // Within 10 degrees
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
          ],
        ),
      ),
    );
  }

  Widget _buildQiblaCompass() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'اتجاه القبلة',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isPointingToQibla ? '✓ أنت تتجه نحو القبلة' : 'قم بتحريك هاتفك',
            style: TextStyle(
              fontSize: 16,
              color: _isPointingToQibla ? Colors.greenAccent : Colors.white70,
              fontWeight:
                  _isPointingToQibla ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),

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

                // السهم المشير للقبلة
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
                ],
              ),
            ),

          const SizedBox(height: 20),

          // ملاحظة
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white70, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'امسك الهاتف بشكل أفقي للحصول على دقة أفضل',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

    // رسم علامات الدرجات
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
          text: labels[i],
          style: TextStyle(
            color: i == 0 ? Colors.red : const Color(0xFF476B5E),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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
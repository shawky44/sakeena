import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// رسائل تهنئة متنوعة
const List<String> _congratsMessages = [
  'بارك الله فيك، أتممت ذكرك كاملاً',
  'أحسنت! جعلها الله في ميزان حسناتك',
  'ما شاء الله! واظب على هذا الخير',
  'أحسنت وأجدت، حفظك الله ورعاك',
  'جزاك الله خيراً على هذا الجهد',
];

const List<String> _motivationalQuotes = [
  'وَالذَّاكِرِينَ اللَّهَ كَثِيرًا وَالذَّاكِرَاتِ أَعَدَّ اللَّهُ لَهُم مَّغْفِرَةً وَأَجْرًا عَظِيمًا',
  'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
  'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ',
  'مَن قَالَ: سُبحَانَ اللهِ وَبِحَمدِهِ، غُرِسَت لَهُ نَخلَةٌ في الجَنَّة',
  'الذِّكرُ يُنيرُ القَلبَ ويُطَهِّرُ الرُّوحَ',
];


Future<void> showCompletionDialog(
  BuildContext context, {
  required String azkarTitle,
}) {
  HapticFeedback.heavyImpact();
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'dismiss',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (_, __, ___) => _CompletionDialog(azkarTitle: azkarTitle),
    transitionBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return ScaleTransition(
        scale: Tween<double>(begin: 0.7, end: 1.0).animate(curved),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

class _CompletionDialog extends StatefulWidget {
  final String azkarTitle;
  const _CompletionDialog({required this.azkarTitle});

  @override
  State<_CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<_CompletionDialog>
    with TickerProviderStateMixin {
  late AnimationController _particlesController;
  late AnimationController _pulseController;
  late AnimationController _contentController;

  late Animation<double> _contentAnim;
  late Animation<double> _pulseAnim;

  final _random = math.Random();
  late String _congratsMsg;
  late String _quote;

  @override
  void initState() {
    super.initState();

    _congratsMsg = _congratsMessages[_random.nextInt(_congratsMessages.length)];
    _quote = _motivationalQuotes[_random.nextInt(_motivationalQuotes.length)];

    // Particles floating animation
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Pulse on the icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Content fade+slide
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _contentAnim = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _particlesController.dispose();
    _pulseController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4A6B68),
                  Color(0xFF3A5552),
                  Color(0xFF2E4543),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: .2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .5),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: const Color(0xFF5F7C7A).withValues(alpha: .3),
                  blurRadius: 60,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                  // ─── Floating Particles ───
                  ..._buildParticles(),

                  // ─── Top Decorative Arc ───
                  Positioned(
                    top: -60,
                    left: -60,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .04),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    right: -40,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .03),
                      ),
                    ),
                  ),

                  // ─── Main Content ───
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                    child: FadeTransition(
                      opacity: _contentAnim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(_contentAnim),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ─── Pulsing Icon ───
                            ScaleTransition(
                              scale: _pulseAnim,
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFE8D5A3),
                                      Color(0xFFD4A849),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFD4A849,
                                      ).withValues(alpha: .5),
                                      blurRadius: 25,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ─── Azkar Title Badge ───
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .3),
                                ),
                              ),
                              child: Text(
                                widget.azkarTitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ─── Congrats Message ───
                            Text(
                              _congratsMsg,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black38,
                                    offset: Offset(1, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ─── Divider ───
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.white.withValues(alpha: .4),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome,
                                    size: 16,
                                    color: Colors.white.withValues(alpha: .7),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: .4),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // ─── Motivational Quote ───
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .15),
                                ),
                              ),
                              child: Text(
                                _quote,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white.withValues(alpha: .9),
                                  height: 1.8,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // ─── Close Button ───
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF3A5552),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.done_all_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'جزاك الله خيراً',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildParticles() {
    const particles = [
      _ParticleData(top: 20, left: 20, size: 6, delay: 0.0),
      _ParticleData(top: 50, right: 15, size: 4, delay: 0.3),
      _ParticleData(top: 100, left: 40, size: 8, delay: 0.6),
      _ParticleData(bottom: 80, left: 25, size: 5, delay: 0.9),
      _ParticleData(bottom: 120, right: 30, size: 7, delay: 0.2),
      _ParticleData(top: 160, right: 50, size: 4, delay: 0.7),
    ];

    return particles.map((p) {
      return AnimatedBuilder(
        animation: _particlesController,
        builder: (_, __) {
          final t = (_particlesController.value + p.delay) % 1.0;
          final dy = math.sin(t * math.pi * 2) * 10;
          final opacity = (math.sin(t * math.pi * 2) * 0.5 + 0.5) * 0.4;

          return Positioned(
            top: p.top != null ? p.top! + dy : null,
            bottom: p.bottom != null ? p.bottom! - dy : null,
            left: p.left,
            right: p.right,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: p.size,
                height: p.size,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

class _ParticleData {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final double delay;

  const _ParticleData({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.delay,
  });
}
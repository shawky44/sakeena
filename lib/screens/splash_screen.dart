
import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFF5F7C7A),
              Color(0xFF3C5553),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // اللوجو أو الصورة
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 180,
                      height: 180,
                      padding: const EdgeInsets.all(20),
                      // decoration: BoxDecoration(
                      //   color: const Color(0xFF3C5553),
                      //   shape: BoxShape.circle,
                      //   boxShadow: [
                      //     BoxShadow(
                      //       color: Colors.black.withValues(alpha: .3),
                      //       blurRadius: 40,
                      //       spreadRadius: 5,
                      //     ),
                      //   ],
                      // ),
                      child: Image.asset(
                        'assets/images/logo.png', // ضع مسار الصورة هنا
                        errorBuilder: (context, error, stackTrace) {
                          // لو الصورة مش موجودة، اعرض أيقونة
                          return const Icon(
                            Icons.mosque_rounded,
                            size: 100,
                            color: Color(0xFF5F7C7A),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // النصوص
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          const Text(
                            'Sakeena',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                             'وَاذْكُر رَّبَّكَ كَثِيرًا',

                              style: TextStyle(
                                fontSize: 22,
                                color: Colors.white.withValues(alpha: .95),
                                fontWeight: FontWeight.w600,
                                height: 1.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Loading indicator
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 35,
                          height: 35,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: .7),
                            ),
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'جاري التحميل...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: .7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
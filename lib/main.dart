import 'package:azkar_app/screens/home_screen.dart';
import 'package:azkar_app/screens/splash_screen.dart'; // ⬅️ استيراد الـ Splash Screen
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تثبيت اتجاه الشاشة على Portrait فقط
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // تغيير لون الـ Status Bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF5F7C7A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const AzkArpp(),
    ),
  );
}

class AzkArpp extends StatelessWidget {
  const AzkArpp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ignore: deprecated_member_use
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      title: 'تطبيق الأذكار',
      theme: ThemeData(
        primaryColor: const Color(0xFF5F7C7A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5F7C7A),
        ),
        useMaterial3: true,
      ),
      
      // ⬅️ هنا الجزء المهم: نبدأ بالـ Splash Screen
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),        // الصفحة الأولى
        '/home': (context) => const HomeScreen(),      // الصفحة الرئيسية
      },
    );
  }
}
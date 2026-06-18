import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:azkar_app/screens/home_screen.dart';
import 'package:azkar_app/screens/splash_screen.dart';
import 'package:azkar_app/services/background_service.dart';
import 'package:azkar_app/services/prayer_notification_service.dart';
import 'package:azkar_app/services/zikr_popup_notification.dart';
import 'package:azkar_app/services/update_service.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ar', null);
  await initializeDateFormatting('en_US', null);

  await AndroidAlarmManager.initialize();

  await PrayerNotificationService().ensureInitialized();
  await ZikrPopupNotification().initialize();

  final backgroundService = PrayerBackgroundService();
  await backgroundService.scheduleNextDayRefresh();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
      enabled: false,
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
      title: 'Sakeena',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''),
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        primaryColor: const Color(0xFF5F7C7A),
        scaffoldBackgroundColor: const Color(0xFFF1E8D8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5F7C7A),
          surface: const Color(0xFFF1E8D8),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _NoPageTransitionsBuilder(),
            TargetPlatform.iOS: _NoPageTransitionsBuilder(),
            TargetPlatform.macOS: _NoPageTransitionsBuilder(),
            TargetPlatform.windows: _NoPageTransitionsBuilder(),
            TargetPlatform.linux: _NoPageTransitionsBuilder(),
            TargetPlatform.fuchsia: _NoPageTransitionsBuilder(),
          },
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashWrapper(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class _NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

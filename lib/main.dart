import 'package:azkar_app/screens/home_screen.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
void main() {
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const AzkArpp(), // Wrap your app
    ),
  );
}
 
// void main() {
//   runApp(const AzkArpp());
// }
class AzkArpp extends StatelessWidget {
  const AzkArpp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  // ignore: deprecated_member_use
  useInheritedMediaQuery: true,
  locale: DevicePreview.locale(context),
  builder: DevicePreview.appBuilder,
  debugShowCheckedModeBanner: false,
  title: 'Flutter Demo',
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 162, 66, 66),
    ),
  ),
  home: const HomeScreen(),

);
  
  }
}

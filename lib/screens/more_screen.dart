// import 'package:azkar_app/screens/alarm_screen.dart';
import 'package:azkar_app/screens/allah_names_screen.dart';
import 'package:azkar_app/screens/azkar_screen.dart';
import 'package:azkar_app/screens/calendar_screen.dart';
import 'package:azkar_app/screens/qibla_screen.dart';
import 'package:azkar_app/screens/tasbih_screen.dart';
import 'package:azkar_app/screens/todo_screen.dart';
import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xEB43635A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                ' المزيد',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 23, 58, 72),
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 20,
                  children: [
                    _buildMenuCard(
                      context,
                      icon: Icons.blur_circular,
                      title: 'المسبحة الإلكترونية',
                      color: const Color.fromARGB(255, 36, 59, 68),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TasbihScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.explore,
                      title: 'القبلة',
                      color: const Color(0xFF2E8B57),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QiblaScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.calendar_month,
                      title: 'التقويم',
                      color: const Color.fromARGB(255, 68, 173, 161),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CalendarScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.checklist,
                      title: 'المهام',
                      color: const Color.fromARGB(255, 80, 153, 94),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TodoScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.menu_book,
                      title: 'الأذكار',
                      color: const Color.fromARGB(255, 64, 105, 89),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AzkarScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuCardWithImage(
                      context,
                      imagePath: 'assets/images/allah_icon.png',
                      title: 'أسماء الله الحسنى',
                      color: const Color.fromARGB(255, 8, 9, 9),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllahNamesScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 210, 209, 209),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 95, 94, 94).withValues(alpha: .3),
              spreadRadius: 10,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCardWithImage(
    BuildContext context, {
    required String imagePath,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 210, 209, 209),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 95, 94, 94).withValues(alpha: .3),
              spreadRadius: 10,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                imagePath,
                width: 40,
                height: 40,
                color: color,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to icon if image fails to load
                  return Icon(Icons.auto_awesome, size: 40, color: color);
                },
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
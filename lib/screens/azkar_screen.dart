import 'package:azkar_app/data/custom_azkar.dart';
import 'package:azkar_app/data/evening_azkar.dart';
import 'package:azkar_app/data/prayer_azkar.dart';
import 'package:azkar_app/data/sleep_azkar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/zikr_model.dart';
import '../data/morning_azkar.dart';
import 'azkar_category_screen.dart';
import 'azkar_settings_screen.dart'; 
import '../widgets/custom_azkar_dialog.dart';

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  List<Zikr> _customAzkar = [];

  @override
  void initState() {
    super.initState();
    _loadCustomAzkar();
  }

  Future<void> _loadCustomAzkar() async {
    final prefs = await SharedPreferences.getInstance();
    final String? azkarJson = prefs.getString('custom_azkar');
    if (azkarJson != null) {
      final List<dynamic> decoded = json.decode(azkarJson);
      setState(() {
        _customAzkar = decoded.map((e) => Zikr.fromJson(e)).toList();

        _customAzkar.sort((a, b) => a.position.compareTo(b.position));
        
        bool needsSave = false;
        for (var zikr in _customAzkar) {
          if (zikr.needsDailyReset()) {
            zikr.checkAndResetIfNeeded();
            needsSave = true;
          }
        }
        
        if (needsSave) {
          _saveCustomAzkar();
        }
      });
    }
  }

  Future<void> _saveCustomAzkar() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(
      _customAzkar.map((e) => e.toJson()).toList(),
    );
    await prefs.setString('custom_azkar', encoded);
  }

  Future<void> _addCustomZikr() async {
    final result = await showDialog<Zikr>(
      context: context,
      builder: (context) => const CustomAzkarDialog(),
    );

    if (result != null) {
      setState(() {
        // إضافة position للذكر الجديد
        result.position = _customAzkar.length;
        result.lastResetDate = DateTime.now();
        _customAzkar.add(result);
      });
      await _saveCustomAzkar();
    }
  }

  void _deleteCustomZikr(int index) {
    setState(() {
      _customAzkar.removeAt(index);
      // إعادة ترتيب الـ positions
      for (int i = 0; i < _customAzkar.length; i++) {
        _customAzkar[i].position = i;
      }
    });
    _saveCustomAzkar();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _customAzkar.removeAt(oldIndex);
      _customAzkar.insert(newIndex, item);
      
      // تحديث الـ positions
      for (int i = 0; i < _customAzkar.length; i++) {
        _customAzkar[i].position = i;
      }
    });
    _saveCustomAzkar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(246, 205, 205, 205),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 70,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF5F7C7A),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'الأذكار',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Color(0xFF5F7C7A), Color(0xFF4A625F)],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildListDelegate([
                _buildAzkarGridCard(
                  title: 'أذكار المساء',
                  subtitle: 'Evening Azkar',
                  icon: Icons.nightlight_round,
                  color: const Color(0xFF8B5E3C),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AzkarCategoryScreen(
                          title: 'أذكار المساء',
                          azkarList: getEveningAzkar(),
                          themeColor: const Color(0xFF5F7C7A),
                        ),
                      ),
                    );
                  },
                ),
                
                _buildAzkarGridCard(
                  title: 'أذكار الصباح',
                  subtitle: 'Morning Azkar',
                  icon: Icons.wb_sunny_rounded,
                  color: const Color(0xFF3C5553),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AzkarCategoryScreen(
                          title: 'أذكار الصباح',
                          azkarList: getMorningAzkar(),
                          themeColor: const Color(0xFF4F6563),
                        ),
                      ),
                    );
                  },
                ),
                
                _buildAzkarGridCard(
                  title: 'أذكار الصلاة',
                  subtitle: 'Prayer Azkar',
                  icon: Icons.mosque_rounded,
                  color: const Color(0xFF26A69A),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AzkarCategoryScreen(
                          title: 'أذكار الصلاة',
                          azkarList: getPrayerAzkar(),
                          themeColor: const Color(0xFF5F7C7A),
                        ),
                      ),
                    );
                  },
                ),

                _buildAzkarGridCard(
                  title: 'أذكار النوم',
                  subtitle: 'Sleep Azkar',
                  icon: Icons.bedtime_rounded,
                  color: const Color(0xFF78909C),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AzkarCategoryScreen(
                          title: 'أذكار النوم',
                          azkarList: getSleepAzkar(),
                          themeColor: const Color(0xFF5F7C7A),
                        ),
                      ),
                    );
                  },
                ),

                _buildAzkarGridCard(
                  title: 'أذكار مختارة',
                  subtitle: 'Selected Azkar',
                  icon: Icons.star_rounded,
                  color: const Color.fromARGB(255, 239, 178, 80),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AzkarCategoryScreen(
                          title: 'أذكار مختارة',
                          azkarList: getOtherAzkar(),
                          themeColor: const Color(0xFF5F7C7A),
                        ),
                      ),
                    );
                  },
                ),

                // إعدادات الأذكار
                _buildAzkarGridCard(
                  title: 'إعدادات الأذكار',
                  subtitle: 'Settings',
                  icon: Icons.settings_rounded,
                  color: const Color(0xFF78909C),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AzkarSettingsScreen(),
                      ),
                    );
                  },
                ),
              ]),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5F7C7A), Color(0xFF4A625F)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.book_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'وردي الخاص',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _addCustomZikr,
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.white,
                            size: 32,
                          ),
                          tooltip: 'إضافة ذكر جديد',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _customAzkar.isEmpty
                          ? 'لم تقم بإضافة أي أذكار بعد'
                          : '${_customAzkar.length} ذكر في وردك',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .9),
                        fontSize: 14,
                      ),
                    ),
                    if (_customAzkar.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AzkarCategoryScreen(
                                title: 'وردي الخاص',
                                azkarList: _customAzkar,
                                themeColor: const Color(0xFF5F7C7A),
                                isCustomAzkar: true,
                                onDeleteZikr: _deleteCustomZikr,
                                onReorder: _onReorder,
                              ),
                            ),
                          ).then((_) => _saveCustomAzkar());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF5F7C7A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'فتح الورد',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAzkarGridCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5DC),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
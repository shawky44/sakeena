// lib/screens/azkar_screen.dart

import 'package:azkar_app/data/custom_azkar.dart';
import 'package:azkar_app/data/evening_azkar.dart';
import 'package:azkar_app/data/prayer_azkar.dart';
import 'package:azkar_app/data/sleep_azkar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../models/zikr_model.dart';
import '../data/morning_azkar.dart';
import 'azkar_category_screen.dart';
import 'azkar_settings_screen.dart';
import '../widgets/custom_azkar_dialog.dart';
import '../services/journey_service.dart';
import '../services/azkar_storage_service.dart';
import '../utils/instant_page_route.dart';

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});
  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen>
    with TickerProviderStateMixin {
  List<Zikr> _customAzkar = [];
  late AnimationController _headerController;
  late AnimationController _cardsController;
  late Animation<double> _headerAnimation;

  final JourneyService _journeyService = JourneyService();
  Map<String, bool> _doneMap = {
    'morning': false,
    'evening': false,
    'sleep': false
  };

  @override
  void initState() {
    super.initState();
    _loadCustomAzkar();
    _loadDoneState();
    _headerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _cardsController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _headerAnimation =
        CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic);
    _headerController.forward();
    _cardsController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  Future<void> _loadDoneState() async {
    final morningList = getMorningAzkar();
    final eveningList = getEveningAzkar();
    final sleepList = getSleepAzkar();
    await Future.wait([
      AzkarStorageService.loadAndApplyProgress('morning', morningList),
      AzkarStorageService.loadAndApplyProgress('evening', eveningList),
      AzkarStorageService.loadAndApplyProgress('sleep', sleepList),
    ]);
    if (mounted) {
      setState(() {
        _doneMap = {
          'morning':
              morningList.isNotEmpty && morningList.every((z) => z.isCompleted),
          'evening':
              eveningList.isNotEmpty && eveningList.every((z) => z.isCompleted),
          'sleep':
              sleepList.isNotEmpty && sleepList.every((z) => z.isCompleted),
        };
      });
    }
  }

  Future<void> _syncAfterReturn(String azkarType) async {
    List<Zikr> list;
    switch (azkarType) {
      case 'morning':
        list = getMorningAzkar();
        break;
      case 'evening':
        list = getEveningAzkar();
        break;
      case 'sleep':
        list = getSleepAzkar();
        break;
      default:
        return;
    }
    await AzkarStorageService.loadAndApplyProgress(azkarType, list);
    final completed = list.where((z) => z.isCompleted).length;
    final total = list.length;
    final isDone = total > 0 && completed == total;
    final journeyData = await _journeyService.loadJourneyData();
    await _journeyService.updateAzkarProgress(
        journeyData, azkarType, completed, total);
    if (mounted) setState(() => _doneMap[azkarType] = isDone);
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
        if (needsSave) _saveCustomAzkar();
      });
    }
  }

  Future<void> _saveCustomAzkar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_azkar',
        json.encode(_customAzkar.map((e) => e.toJson()).toList()));
  }

  Future<void> _addCustomZikr() async {
    final result = await showDialog<Zikr>(
        context: context, builder: (_) => const CustomAzkarDialog());
    if (result != null) {
      setState(() {
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
      for (int i = 0; i < _customAzkar.length; i++) {
        _customAzkar[i].position = i;
      }
    });
    _saveCustomAzkar();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _customAzkar.removeAt(oldIndex);
      _customAzkar.insert(newIndex, item);
      for (int i = 0; i < _customAzkar.length; i++) {
        _customAzkar[i].position = i;
      }
    });
    _saveCustomAzkar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 100, 138, 128),
                Color.fromARGB(223, 81, 107, 104),
                Color.fromARGB(244, 62, 90, 81)
              ]),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _headerAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, -0.3), end: Offset.zero)
                        .animate(_headerAnimation),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 25, 15, 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: .2),
                                Colors.white.withValues(alpha: .1)
                              ]),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: .3),
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: .2),
                                blurRadius: 20,
                                offset: const Offset(0, 10))
                          ],
                        ),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: .2),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: .3),
                                          width: 1.5)),
                                  child: const Icon(Icons.mosque_rounded,
                                      color: Colors.white, size: 24)),
                              const Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('الأذكار',
                                        style: TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                  color: Colors.black26,
                                                  offset: Offset(2, 2),
                                                  blurRadius: 4)
                                            ])),
                                    SizedBox(height: 2),
                                    Text('ذكر الله في كل وقت',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w500)),
                                  ]),
                            ]),
                      ),
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14),
                  delegate: SliverChildListDelegate([
                    _buildModernAzkarCard(
                        delay: 0,
                        title: 'أذكار الصباح',
                        subtitle: 'Morning Azkar',
                        icon: Icons.wb_sunny_rounded,
                        gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.fromARGB(211, 80, 105, 103),
                              Color.fromARGB(215, 68, 86, 85),
                              Color.fromARGB(210, 73, 98, 96)
                            ]),
                        iconColor: const Color(0xFF5F7C7A),
                        isDone: _doneMap['morning']!,
                        onTap: () async {
                          final list = getMorningAzkar();
                          await AzkarStorageService.loadAndApplyProgress(
                              'morning', list);
                          if (!context.mounted) return;
                          await Navigator.push(
                              context,
                              InstantPageRoute(
                                  builder: (_) => AzkarCategoryScreen(
                                      title: 'أذكار الصباح',
                                      azkarList: list,
                                      themeColor: const Color(0xFF4F6563),
                                      azkarType: 'morning')));
                          await _syncAfterReturn('morning');
                        }),
                    _buildModernAzkarCard(
                        delay: 100,
                        title: 'أذكار المساء',
                        subtitle: 'Evening Azkar',
                        icon: Icons.nightlight_round,
                        gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.fromARGB(255, 80, 105, 103),
                              Color.fromARGB(255, 71, 92, 90),
                              Color.fromARGB(216, 73, 99, 97)
                            ]),
                        iconColor: const Color(0xFF5D4E3A),
                        isDone: _doneMap['evening']!,
                        onTap: () async {
                          final list = getEveningAzkar();
                          await AzkarStorageService.loadAndApplyProgress(
                              'evening', list);
                          if (!context.mounted) return;
                          await Navigator.push(
                              context,
                              InstantPageRoute(
                                  builder: (_) => AzkarCategoryScreen(
                                      title: 'أذكار المساء',
                                      azkarList: list,
                                      themeColor: const Color(0xFF5F7C7A),
                                      azkarType: 'evening')));
                          await _syncAfterReturn('evening');
                        }),
                    _buildModernAzkarCard(
                        delay: 200,
                        title: 'أذكار الصلاة',
                        subtitle: 'Prayer Azkar',
                        icon: Icons.mosque_rounded,
                        gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.fromARGB(255, 120, 117, 109),
                              Color.fromARGB(255, 171, 160, 121)
                            ]),
                        iconColor: const Color(0xFF00695C),
                        isDone: false,
                        onTap: () => Navigator.push(
                            context,
                            InstantPageRoute(
                                builder: (_) => AzkarCategoryScreen(
                                    title: 'أذكار الصلاة',
                                    azkarList: getPrayerAzkar(),
                                    themeColor: const Color(0xFF5F7C7A))))),
                    _buildModernAzkarCard(
                        delay: 300,
                        title: 'أذكار النوم',
                        subtitle: 'Sleep Azkar',
                        icon: Icons.bedtime_rounded,
                        gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.fromARGB(206, 120, 144, 156),
                              Color.fromARGB(216, 96, 125, 139)
                            ]),
                        iconColor: const Color(0xFF455A64),
                        isDone: _doneMap['sleep']!,
                        onTap: () async {
                          final list = getSleepAzkar();
                          await AzkarStorageService.loadAndApplyProgress(
                              'sleep', list);
                          if (!context.mounted) return;
                          await Navigator.push(
                              context,
                              InstantPageRoute(
                                  builder: (_) => AzkarCategoryScreen(
                                      title: 'أذكار النوم',
                                      azkarList: list,
                                      themeColor: const Color(0xFF4A625F),
                                      azkarType: 'sleep')));
                          await _syncAfterReturn('sleep');
                        }),
                    _buildModernAzkarCard(
                        delay: 400,
                        title: 'أذكار مختارة',
                        subtitle: 'Selected Azkar',
                        icon: Icons.star_rounded,
                        gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.fromARGB(255, 80, 105, 103),
                              Color.fromARGB(255, 71, 92, 90),
                              Color.fromARGB(216, 73, 99, 97)
                            ]),
                        iconColor: const Color(0xFF5D4E3A),
                        isDone: false,
                        onTap: () => Navigator.push(
                            context,
                            InstantPageRoute(
                                builder: (_) => AzkarCategoryScreen(
                                    title: 'أذكار مختارة',
                                    azkarList: getOtherAzkar(),
                                    themeColor: const Color(0xFF5F7C7A))))),
                    _buildModernAzkarCard(
                        delay: 500,
                        title: 'إعدادات الأذكار',
                        subtitle: 'Settings',
                        icon: Icons.settings_rounded,
                        gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.fromARGB(255, 69, 79, 79),
                              Color.fromARGB(255, 39, 47, 47)
                            ]),
                        iconColor: const Color(0xFF37474F),
                        isDone: false,
                        onTap: () => Navigator.push(
                            context,
                            InstantPageRoute(
                                builder: (_) => const AzkarSettingsScreen()))),
                  ]),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Transform.scale(
                        scale: 0.8 + (value * 0.2),
                        child: Opacity(opacity: value, child: child)),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF5F7C7A), Color(0xFF4A625F)]),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: .2),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: .3),
                              blurRadius: 25,
                              offset: const Offset(0, 12)),
                          BoxShadow(
                              color: Colors.white.withValues(alpha: .05),
                              blurRadius: 10,
                              offset: const Offset(0, -5)),
                        ],
                      ),
                      child: Stack(children: [
                        Positioned(
                            top: -40,
                            right: -40,
                            child: Transform.rotate(
                                angle: math.pi / 6,
                                child: Icon(Icons.book_rounded,
                                    size: 150,
                                    color:
                                        Colors.white.withValues(alpha: .05)))),
                        Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(children: [
                                    Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                            gradient: LinearGradient(colors: [
                                              Colors.white
                                                  .withValues(alpha: .25),
                                              Colors.white
                                                  .withValues(alpha: .15)
                                            ]),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                                color: Colors.white
                                                    .withValues(alpha: .3),
                                                width: 1.5)),
                                        child: const Icon(Icons.book_rounded,
                                            color: Colors.white, size: 30)),
                                    const SizedBox(width: 14),
                                    const Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text('وردي الخاص',
                                              style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  shadows: [
                                                    Shadow(
                                                        color: Colors.black26,
                                                        offset: Offset(1, 1),
                                                        blurRadius: 3)
                                                  ])),
                                          SizedBox(height: 4),
                                          Text('أذكارك المفضلة',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.white70)),
                                        ])),
                                    Container(
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: .2),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4))
                                            ]),
                                        child: IconButton(
                                            onPressed: _addCustomZikr,
                                            icon: const Icon(Icons.add_circle,
                                                color: Color(0xFF5F7C7A),
                                                size: 32),
                                            tooltip: 'إضافة ذكر جديد')),
                                  ]),
                                  const SizedBox(height: 20),
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (_customAzkar.isEmpty) ...[
                                          Icon(Icons.bookmark_border,
                                              color: Colors.white
                                                  .withValues(alpha: .7),
                                              size: 24),
                                          const SizedBox(width: 10),
                                          Text('لم تقم بإضافة أي أذكار بعد',
                                              style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: .9),
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500)),
                                        ],
                                      ]),
                                  if (_customAzkar.isNotEmpty) ...[
                                    const SizedBox(height: 18),
                                    Container(
                                      decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                              colors: [
                                                Colors.white,
                                                Color(0xFFF5F5F5)
                                              ]),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: .2),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4))
                                          ]),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => Navigator.push(
                                              context,
                                              InstantPageRoute(
                                                  builder: (_) =>
                                                      AzkarCategoryScreen(
                                                        title: 'وردي الخاص',
                                                        azkarList: _customAzkar,
                                                        themeColor: const Color(
                                                            0xFF5F7C7A),
                                                        isCustomAzkar: true,
                                                        onDeleteZikr:
                                                            _deleteCustomZikr,
                                                        onReorder: _onReorder,
                                                      ))).then(
                                              (_) => _saveCustomAzkar()),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16, horizontal: 20),
                                            child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      decoration: BoxDecoration(
                                                          color: const Color(
                                                                  0xFF5F7C7A)
                                                              .withValues(
                                                                  alpha: .1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10)),
                                                      child: const Icon(
                                                          Icons
                                                              .arrow_back_ios_new,
                                                          color:
                                                              Color(0xFF5F7C7A),
                                                          size: 16)),
                                                  const SizedBox(width: 12),
                                                  const Text('فتح الورد',
                                                      style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color(
                                                              0xFF5F7C7A))),
                                                ]),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ])),
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernAzkarCard({
    required int delay,
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required Color iconColor,
    required bool isDone,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Opacity(opacity: value, child: child)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: isDone
                      ? Colors.greenAccent.withValues(alpha: .55)
                      : Colors.white.withValues(alpha: .2),
                  width: isDone ? 2 : 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: .25),
                    blurRadius: 15,
                    offset: const Offset(0, 8)),
                BoxShadow(
                    color: Colors.white.withValues(alpha: .05),
                    blurRadius: 8,
                    offset: const Offset(0, -4)),
              ],
            ),
            child: Stack(children: [
              Positioned(
                  top: -25,
                  right: -25,
                  child: Transform.rotate(
                      angle: math.pi / 6,
                      child: Icon(icon,
                          size: 100,
                          color: Colors.white.withValues(alpha: .08)))),

              if (isDone)
                Positioned(
                  bottom: 10,
                  right: 12,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: .22),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.greenAccent.withValues(alpha: .65),
                          width: 1.5),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),

              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 190;
                  final padding = compact ? 14.0 : 18.0;
                  final textWidth = constraints.maxWidth - (padding * 2);
                  return Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                              padding: EdgeInsets.all(compact ? 12 : 16),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: .15),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6))
                                  ]),
                              child: Icon(icon,
                                  color: iconColor, size: compact ? 30 : 36)),
                          SizedBox(height: compact ? 8 : 12),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: textWidth,
                                child: Text(title,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    style: TextStyle(
                                        fontSize: compact ? 15 : 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.25,
                                        shadows: const [
                                          Shadow(
                                              color: Colors.black26,
                                              offset: Offset(1, 1),
                                              blurRadius: 3)
                                        ])),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: textWidth,
                              child: Text(subtitle,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  style: TextStyle(
                                      fontSize: compact ? 10 : 11,
                                      color: Colors.white.withValues(alpha: .8),
                                      fontWeight: FontWeight.w500)),
                            ),
                          ),
                          SizedBox(height: compact ? 7 : 10),
                          Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .25),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.arrow_back_ios_new,
                                  size: 12, color: Colors.white)),
                        ]),
                  );
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

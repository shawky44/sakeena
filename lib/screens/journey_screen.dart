// lib/screens/journey_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/journey_model.dart';
import '../models/zikr_model.dart';
import '../services/journey_service.dart';
import '../services/journey_refresh_service.dart';
import '../services/azkar_storage_service.dart';
import '../data/morning_azkar.dart';
import '../data/evening_azkar.dart';
import '../data/sleep_azkar.dart';
import '../screens/azkar_category_screen.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});
  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final JourneyService _journeyService = JourneyService();
  JourneyData? _journeyData;
  bool _isLoading = true;
  bool _prayerCelebrationShown = false;

  // ✅ Stream subscription للـ refresh الفوري
  StreamSubscription? _refreshSub;

  Map<String, DateTime?> _prayerDateTimes = {
    'الفجر': null, 'الظهر': null, 'العصر': null, 'المغرب': null, 'العشاء': null,
  };

  Timer? _prayerRefreshTimer;

  late AnimationController _headerCtrl;
  late AnimationController _statsCtrl;
  late Animation<double> _headerAnim;
  late Animation<double> _statsAnim;

  static const List<String> _prayerOrder = [
    'الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAnimations();
    _loadPrayerTimesFromCache();
    _loadData();
    _journeyService.scheduleMidnightReset(_handleMidnightReset);

    // ✅ الحل الرئيسي: استمع للـ stream
    // أي شاشة تانية (أذكار، azkar_screen) تنادي notifyRefresh() يجي refresh فوري هنا
    _refreshSub = JourneyRefreshService.instance.onRefresh.listen((_) {
      if (mounted) _loadData();
    });

    // refresh كل دقيقة لمواعيد الصلاة
    _prayerRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _loadPrayerTimesFromCache();
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPrayerTimesFromCache();
      _loadData();
    }
  }

  void _setupAnimations() {
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _statsCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _headerAnim = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic);
    _statsAnim  = CurvedAnimation(parent: _statsCtrl,  curve: Curves.easeOutCubic);
    _headerCtrl.forward();
  }

  Future<void> _loadPrayerTimesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now   = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final cachedTimesJson = prefs.getString('cached_prayer_times');
      if (cachedTimesJson == null) return;

      final Map<String, DateTime?> result = {};
      final cleaned = cachedTimesJson.replaceAll('{', '').replaceAll('}', '');
      final entries = cleaned.split('","');

      for (var entry in entries) {
        entry = entry.replaceAll('"', '').trim();
        final colonIdx = entry.indexOf(':');
        if (colonIdx == -1) continue;
        final name    = entry.substring(0, colonIdx).trim();
        final timeStr = entry.substring(colonIdx + 1).trim();
        if (!_prayerOrder.contains(name)) continue;
        try {
          final parsed = DateFormat('h:mm a', 'en_US').parse(timeStr);
          result[name] = DateTime(today.year, today.month, today.day, parsed.hour, parsed.minute);
        } catch (_) {
          result[name] = null;
        }
      }

      if (mounted) setState(() => _prayerDateTimes = {..._prayerDateTimes, ...result});
    } catch (e) {
      debugPrint('Error loading prayer times: $e');
    }
  }
bool _isPrayerAvailable(String prayerName) {
  final prayerTime = _prayerDateTimes[prayerName];
  if (prayerTime == null) return false;
  final now = DateTime.now();
  
  if (prayerTime.isAfter(now)) return false;
  
  if (prayerName == 'العشاء') {
    final fajrTomorrow = _prayerDateTimes['الفجر'];
    if (fajrTomorrow == null) return true;
    final tomorrowFajr = fajrTomorrow.add(const Duration(days: 1));
    return now.isBefore(tomorrowFajr);
  }
  
  return now.isBefore(DateTime(now.year, now.month, now.day + 1));
}

  String _timeUntilPrayer(String prayerName) {
    final prayerTime = _prayerDateTimes[prayerName];
    if (prayerTime == null) return '';
    final now = DateTime.now();
    if (prayerTime.isBefore(now)) return '';
    final diff = prayerTime.difference(now);
    if (diff.inMinutes < 60) return 'بعد ${diff.inMinutes} د';
    return 'بعد ${diff.inHours}س ${diff.inMinutes % 60}د';
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final isFirstLoad = _journeyData == null;
    if (isFirstLoad) setState(() => _isLoading = true);

    final data = await _journeyService.loadJourneyData();
    await _syncAzkarFromStorage(data);

    if (mounted) {
      setState(() {
        _journeyData = data;
        _isLoading   = false;
        if (data.prayersCompleted.values.every((v) => v)) _prayerCelebrationShown = true;
      });
    }

    if (isFirstLoad) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) { _statsCtrl.reset(); _statsCtrl.forward(); }
      });
    }
  }

  Future<void> _syncAzkarFromStorage(JourneyData data) async {
    final morning = getMorningAzkar();
    final evening = getEveningAzkar();
    final sleep   = getSleepAzkar();
    await AzkarStorageService.loadAndApplyProgress('morning', morning);
    await AzkarStorageService.loadAndApplyProgress('evening', evening);
    await AzkarStorageService.loadAndApplyProgress('sleep',   sleep);
    await _journeyService.updateAzkarProgress(data, 'morning', morning.where((z) => z.isCompleted).length, morning.length);
    await _journeyService.updateAzkarProgress(data, 'evening', evening.where((z) => z.isCompleted).length, evening.length);
    await _journeyService.updateAzkarProgress(data, 'sleep',   sleep.where((z) => z.isCompleted).length,   sleep.length);
  }

  Future<void> _handleMidnightReset() async {
    if (_journeyData != null) {
      await AzkarStorageService.clearAll();
      _journeyData!.resetForNewDay();
      await _journeyService.saveJourneyData(_journeyData!);
      _prayerCelebrationShown = false;
      await _loadPrayerTimesFromCache();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🌙 تم تحديث البيانات ليوم جديد'),
          backgroundColor: Color(0xFF5F7C7A), duration: Duration(seconds: 3)));
      }
    }
  }

  Future<void> _togglePrayer(String name) async {
    if (_journeyData == null) return;
    if (!_isPrayerAvailable(name)) {
      final timeUntil = _timeUntilPrayer(name);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(timeUntil.isNotEmpty
            ? 'صلاة $name لسه ما جاش وقتها ($timeUntil)'
            : 'صلاة $name غير متاحة الآن'),
        backgroundColor: const Color(0xFF5F7C7A).withValues(alpha: .9),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      HapticFeedback.heavyImpact();
      return;
    }
    await _journeyService.togglePrayer(_journeyData!, name);
    HapticFeedback.lightImpact();
    setState(() {});
    final allDone = _journeyData!.prayersCompleted.values.every((v) => v);
    if (allDone && !_prayerCelebrationShown) {
      _prayerCelebrationShown = true;
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) _showPrayerDialog();
    }
  }

  void _showPrayerDialog() {
    HapticFeedback.heavyImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true, barrierLabel: '', barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => const SizedBox(),
      transitionBuilder: (ctx, anim, _, __) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim,
          child: Center(child: Material(color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF5F7C7A), Color(0xFF3E5A51)]),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: const Color(0xFF5F7C7A).withValues(alpha: .45), blurRadius: 35, offset: const Offset(0,12))]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (_, v, __) => Transform.scale(scale: v,
                    child: Container(width: 82, height: 82,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: .35), width: 2)),
                      child: const Center(child: Text('🕌', style: TextStyle(fontSize: 42)))))),
                const SizedBox(height: 18),
                const Text('ما شاء الله! 🎉', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('أكملت الصلوات الخمس اليوم\nبارك الله فيك وتقبل منك',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: 14, height: 1.65)),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 350 + i * 90),
                    curve: Curves.elasticOut,
                    builder: (_, v, __) => Transform.scale(scale: v,
                      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('⭐', style: TextStyle(fontSize: 20))))))),
                const SizedBox(height: 22),
                GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 13),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .15), blurRadius: 10, offset: const Offset(0,4))]),
                    child: const Text('شكراً 🤲', style: TextStyle(color: Color(0xFF3E5A51), fontWeight: FontWeight.bold, fontSize: 16)))),
              ]),
            ))))),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshSub?.cancel();       
    _prayerRefreshTimer?.cancel();
    _headerCtrl.dispose();
    _statsCtrl.dispose();
    _journeyService.dispose();
    super.dispose();
  }

  Map<String, String> _motivational() {
    final s = _journeyData?.currentStreak ?? 0;
    final p = _journeyData?.dailyCompletionPercentage ?? 0.0;
    if (s == 0 && p == 0.0) return {'msg': 'ابدأ رحلتك اليوم 🌱', 'sub': 'كل خطوة تحسب'};
    if (s == 0 && p >  0.0) return {'msg': 'أحسنت! استمر 💪',     'sub': 'أكمل يومك بإذن الله'};
    if (s < 3)  return {'msg': 'بداية موفقة 🌿',        'sub': '$s أيام متتالية'};
    if (s < 7)  return {'msg': 'ماشي على بركة الله 🔥', 'sub': '$s أيام متتالية'};
    if (s < 14) return {'msg': 'أسبوع كامل! رائع 🌟',    'sub': '$s أيام متتالية'};
    if (s < 30) return {'msg': 'مداومة نور على نور ✨',  'sub': '$s أيام متتالية'};
    return            {'msg': 'بطل حقيقي 🏆',            'sub': '$s أيام متتالية'};
  }

  List<_WeekSlot> _weekSlots() {
    final history = _journeyData?.weeklyHistory ?? [];
    final today   = DateTime.now();
    return List.generate(7, (i) {
      final day     = today.subtract(Duration(days: 6 - i));
      final dayOnly = DateTime(day.year, day.month, day.day);
      DayCompletion? match;
      for (final h in history) {
        if (DateTime(h.date.year, h.date.month, h.date.day) == dayOnly) { match = h; break; }
      }
      return _WeekSlot(date: day, isToday: i == 6, completion: match);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _journeyData == null) {
      return const Scaffold(backgroundColor: Color(0xFFF8F8F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF5F7C7A))));
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F5),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color.fromARGB(255,100,138,128), Color.fromARGB(223,81,107,104), Color.fromARGB(244,62,90,81)])),
        child: SafeArea(child: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
          _buildHeader(),
          _buildPrayerSection(),
          _buildAzkarSection(),
          _buildStatsSection(),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ])),
      ),
    );
  }

  Widget _buildHeader() {
    final pct     = _journeyData!.dailyCompletionPercentage;
    final allDone = pct >= 1.0;
    return SliverToBoxAdapter(
      child: FadeTransition(opacity: _headerAnim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0,-0.2), end: Offset.zero).animate(_headerAnim),
          child: Padding(padding: const EdgeInsets.fromLTRB(16,24,16,8),
            child: AnimatedContainer(duration: const Duration(milliseconds: 500), padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: allDone
                    ? [const Color(0xFF4A8C5C).withValues(alpha:.88), const Color(0xFF2D6040).withValues(alpha:.88)]
                    : [Colors.white.withValues(alpha:.22), Colors.white.withValues(alpha:.10)]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: allDone ? Colors.greenAccent.withValues(alpha:.35) : Colors.white.withValues(alpha:.28), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:.16), blurRadius: 18, offset: const Offset(0,8))]),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                SizedBox(width: 54, height: 54,
                  child: Stack(alignment: Alignment.center, children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: pct),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => CircularProgressIndicator(value: v, strokeWidth: 4,
                        backgroundColor: Colors.white.withValues(alpha:.2),
                        valueColor: AlwaysStoppedAnimation<Color>(allDone ? Colors.greenAccent : Colors.white),
                        strokeCap: StrokeCap.round)),
                    Text('${(pct*100).toInt()}%',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  AnimatedSwitcher(duration: const Duration(milliseconds: 400),
                    child: Text(allDone ? 'يوم مكتمل! 🎉' : 'رحلتي اليومية', key: ValueKey(allDone),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white,
                        shadows: [Shadow(color: Colors.black26, offset: Offset(1,2), blurRadius: 4)]))),
                  const SizedBox(height: 2),
                  Text('تتبع عباداتك اليومية',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha:.75), fontWeight: FontWeight.w500)),
                ]),
              ]),
            ))),
      ),
    );
  }

  Widget _buildPrayerSection() {
    final done    = _journeyData!.prayersCompleted.values.where((v) => v).length;
    final allDone = done == 5;
    return SliverToBoxAdapter(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (_, v, child) => Transform.translate(offset: Offset(0,18*(1-v)), child: Opacity(opacity: v, child: child)),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AnimatedContainer(duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: allDone
                  ? [const Color(0xFF3D7A55), const Color(0xFF2A5C3F)]
                  : [const Color(0xFF5F7C7A), const Color(0xFF4A625F)]),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: allDone ? Colors.greenAccent.withValues(alpha:.28) : Colors.white.withValues(alpha:.16), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:.22), blurRadius: 20, offset: const Offset(0,8))]),
            child: Padding(padding: const EdgeInsets.all(20),
              child: Column(children: [
                Row(children: [
                  SizedBox(width: 100, height: 100,
                    child: Stack(alignment: Alignment.center, children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(value: 1.0, strokeWidth: 7,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha:.1))),
                      ),
                      SizedBox.expand(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: _journeyData!.prayerCompletionPercentage),
                          duration: const Duration(milliseconds: 1400),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => CircularProgressIndicator(value: v, strokeWidth: 7,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(allDone ? Colors.greenAccent : Colors.white),
                            strokeCap: StrokeCap.round)),
                      ),
                      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.mosque_rounded, color: Colors.white, size: 28),
                        const SizedBox(height: 3),
                        Text('$done/5', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                      ]),
                    ])),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('الصلوات اليومية', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(allDone ? 'أكملت صلوات اليوم 🎉' : 'اضغط على الصلاة بعد أدائها',
                      style: TextStyle(color: Colors.white.withValues(alpha:.72), fontSize: 12)),
                    const SizedBox(height: 10),
                    Row(children: List.generate(5, (i) {
                      final prayers = _journeyData!.prayersCompleted.values.toList();
                      final d = i < prayers.length && prayers[i];
                      return AnimatedContainer(duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 5), width: d ? 18 : 9, height: 7,
                        decoration: BoxDecoration(
                          color: d ? (allDone ? Colors.greenAccent : Colors.white) : Colors.white.withValues(alpha:.22),
                          borderRadius: BorderRadius.circular(4)));
                    })),
                  ])),
                ]),
                const SizedBox(height: 14),
                Container(height: 1, color: Colors.white.withValues(alpha:.18)),
                const SizedBox(height: 10),
                ...(_journeyData!.prayersCompleted.entries.map((e) => _prayerTile(e.key, e.value))),
              ]),
            ),
          )),
      ),
    );
  }

  Widget _prayerTile(String name, bool isDone) {
    final isAvailable = _isPrayerAvailable(name);
    final timeUntil   = _timeUntilPrayer(name);
    return GestureDetector(
      onTap: () => _togglePrayer(name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isDone ? Colors.white.withValues(alpha:.2)
              : isAvailable ? Colors.white.withValues(alpha:.07)
              : Colors.white.withValues(alpha:.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone ? Colors.white.withValues(alpha:.38)
                : isAvailable ? Colors.white.withValues(alpha:.12)
                : Colors.white.withValues(alpha:.06),
            width: 1.2)),
        child: Row(children: [
          AnimatedContainer(duration: const Duration(milliseconds: 280),
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: isDone ? Colors.white : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? Colors.white : isAvailable ? Colors.white.withValues(alpha:.38) : Colors.white.withValues(alpha:.15),
                width: 2)),
            child: isDone
                ? const Icon(Icons.check_rounded, color: Color(0xFF5F7C7A), size: 15)
                : !isAvailable
                    ? Icon(Icons.lock_outline_rounded, color: Colors.white.withValues(alpha:.3), size: 13)
                    : null),
          const SizedBox(width: 12),
          Text(name, style: TextStyle(
            color: isDone ? Colors.white : isAvailable ? Colors.white : Colors.white.withValues(alpha:.4),
            fontSize: 15,
            fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
            decoration: isDone ? TextDecoration.lineThrough : null,
            decorationColor: Colors.white54)),
          const Spacer(),
          if (!isDone && !isAvailable && timeUntil.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha:.08), borderRadius: BorderRadius.circular(8)),
              child: Text(timeUntil, style: TextStyle(color: Colors.white.withValues(alpha:.45), fontSize: 10))),
          if (isDone) ...[
            const SizedBox(width: 4),
            Icon(Icons.mosque_rounded, color: Colors.white.withValues(alpha:.45), size: 15),
          ],
        ]),
      ),
    );
  }

  Widget _buildAzkarSection() {
    return SliverToBoxAdapter(
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Padding(padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              const Text('الأذكار اليومية', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha:.18), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 13)),
            ])),
          _azkarCard('morning', 'أذكار الصباح', Icons.wb_sunny_rounded,  const Color(0xFFFFB347)),
          const SizedBox(height: 10),
          _azkarCard('evening', 'أذكار المساء', Icons.nightlight_round,   const Color(0xFF9B8FCC)),
          const SizedBox(height: 10),
          _azkarCard('sleep',   'أذكار النوم',  Icons.bedtime_rounded,    const Color(0xFF6ECFCF)),
        ])),
    );
  }

  Widget _azkarCard(String type, String title, IconData icon, Color accent) {
    final progress = _journeyData!.azkarProgress[type]!;
    final isDone   = progress.isCompleted;
    return GestureDetector(
      onTap: () async {
        List<Zikr> list;
        switch (type) {
          case 'morning': list = getMorningAzkar(); break;
          case 'evening': list = getEveningAzkar(); break;
          default:        list = getSleepAzkar();
        }
        await AzkarStorageService.loadAndApplyProgress(type, list);
        await Navigator.push(context, PageRouteBuilder(
          pageBuilder: (_, __, ___) => AzkarCategoryScreen(
            title: title, azkarList: list, themeColor: const Color(0xFF5F7C7A), azkarType: type),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(0,0.06), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: FadeTransition(opacity: anim, child: child)),
          transitionDuration: const Duration(milliseconds: 320)));
        await _loadData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDone ? accent.withValues(alpha:.4) : Colors.transparent, width: isDone ? 2 : 0),
          boxShadow: [BoxShadow(
            color: isDone ? accent.withValues(alpha:.14) : Colors.black.withValues(alpha:.07),
            blurRadius: 12, offset: const Offset(0,4))]),
        child: Stack(children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(color: accent.withValues(alpha:.12), borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, color: accent, size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              const SizedBox(height: 2),
              Text('${progress.completed} / ${progress.total}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: progress.percentage, minHeight: 6,
                  backgroundColor: accent.withValues(alpha:.1),
                  valueColor: AlwaysStoppedAnimation<Color>(accent))),
            ])),
            const SizedBox(width: 12),
            Text('${(progress.percentage*100).toInt()}%',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accent)),
          ]),
          if (isDone)
            Positioned(bottom: 0, left: 0,
              child: AnimatedScale(scale: 1.0, duration: const Duration(milliseconds: 300), curve: Curves.elasticOut,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 14)))),
        ]),
      ),
    );
  }

  Widget _buildStatsSection() {
    final mot   = _motivational();
    final slots = _weekSlots();
    final data  = _journeyData!;
    return SliverToBoxAdapter(
      child: FadeTransition(opacity: _statsAnim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0,0.1), end: Offset.zero).animate(_statsAnim),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:.09), blurRadius: 18, offset: const Offset(0,6))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF5F7C7A).withValues(alpha:.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF5F7C7A), size: 20)),
                  const SizedBox(width: 10),
                  const Text('الإحصائيات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                ]),
                const SizedBox(height: 16),
                _motivBanner(mot['msg']!, mot['sub']!),
                const SizedBox(height: 16),
                _dailyProgress(data),
                const SizedBox(height: 16),
                _heatmap(slots),
                const SizedBox(height: 16),
                _statCards(data),
              ]),
            )),
        )),
    );
  }

  Widget _motivBanner(String msg, String sub) {
    final active = (_journeyData?.currentStreak ?? 0) > 0 || (_journeyData?.dailyCompletionPercentage ?? 0) > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: active ? [const Color(0xFF5F7C7A), const Color(0xFF3E5A51)] : [const Color(0xFFB0BEC5), const Color(0xFF90A4AE)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Text(active ? '🔥' : '🌱', style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(msg, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          Text(sub, style: TextStyle(color: Colors.white.withValues(alpha:.8), fontSize: 11)),
        ])),
      ]),
    );
  }

  Widget _dailyProgress(JourneyData data) {
    final pct = data.dailyCompletionPercentage;
    final cp  = data.prayersCompleted.values.where((v) => v).length;
    final ca  = data.azkarProgress.values.where((a) => a.isCompleted).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('${(pct*100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5F7C7A))),
        const Text('إنجاز اليوم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
      ]),
      const SizedBox(height: 7),
      ClipRRect(borderRadius: BorderRadius.circular(8),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: pct),
          duration: const Duration(milliseconds: 1200), curve: Curves.easeOutCubic,
          builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 10,
            backgroundColor: const Color(0xFF5F7C7A).withValues(alpha:.1),
            valueColor: AlwaysStoppedAnimation<Color>(pct >= 1.0 ? const Color(0xFF4CAF50) : const Color(0xFF5F7C7A))))),
      const SizedBox(height: 7),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _chip('📿 $ca/3 أذكار', ca == 3),
        _chip('🕌 $cp/5 صلوات', cp == 5),
      ]),
    ]);
  }

  Widget _chip(String label, bool done) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: done ? const Color(0xFF5F7C7A).withValues(alpha:.1) : Colors.grey.withValues(alpha:.07),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: done ? const Color(0xFF5F7C7A).withValues(alpha:.28) : Colors.grey.withValues(alpha:.12))),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
        color: done ? const Color(0xFF5F7C7A) : Colors.grey[500])),
  );

  Widget _heatmap(List<_WeekSlot> slots) {
    const days = ['أحد','إثن','ثلا','أرب','خمس','جمع','سبت'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('آخر ٧ أيام', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: slots.map((s) {
          final idx = s.date.weekday % 7;
          Color c;
          if (s.isToday) {
            final p = _journeyData!.dailyCompletionPercentage;
            c = p == 0 ? Colors.grey.withValues(alpha:.16) : p >= 1.0 ? const Color(0xFF5F7C7A) : const Color(0xFFFFB347);
          } else if (s.completion == null) {
            c = Colors.grey.withValues(alpha:.16);
          } else {
            final d = s.completion!;
            c = d.isComplete ? const Color(0xFF5F7C7A)
                : (d.prayersCompleted > 0 || d.azkarCompleted > 0) ? const Color(0xFFFFB347)
                : Colors.grey.withValues(alpha:.16);
          }
          final empty = c == Colors.grey.withValues(alpha:.16);
          return Column(children: [
            AnimatedContainer(duration: const Duration(milliseconds: 500),
              width: 36, height: 36,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10),
                border: s.isToday ? Border.all(color: const Color(0xFF5F7C7A), width: 2) : null,
                boxShadow: !empty ? [BoxShadow(color: c.withValues(alpha:.3), blurRadius: 6, offset: const Offset(0,3))] : null),
              child: s.isToday ? const Center(child: Text('●', style: TextStyle(fontSize: 9, color: Colors.white70))) : null),
            const SizedBox(height: 4),
            Text(days[idx], style: TextStyle(fontSize: 9,
              color: s.isToday ? const Color(0xFF5F7C7A) : Colors.grey[500],
              fontWeight: s.isToday ? FontWeight.bold : FontWeight.normal)),
          ]);
        }).toList()),
      const SizedBox(height: 7),
      Row(children: [
        _dot(const Color(0xFF5F7C7A), 'مكتمل'),
        const SizedBox(width: 10),
        _dot(const Color(0xFFFFB347), 'جزئي'),
        const SizedBox(width: 10),
        _dot(Colors.grey.withValues(alpha:.22), 'لا يوجد'),
      ]),
    ]);
  }

  Widget _dot(Color c, String l) => Row(children: [
    Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(l, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
  ]);

  Widget _statCards(JourneyData data) => Column(children: [
    Row(children: [
      Expanded(child: _card('🔥', data.currentStreak,         'أيام متتالية', const Color(0xFFFF6B6B), 0)),
      const SizedBox(width: 10),
      Expanded(child: _card('🏆', data.longestStreak,         'أطول سلسلة',   const Color(0xFFFFD93D), 1)),
    ]),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _card('🕌', data.totalPrayersCompleted, 'صلاة مكتملة',  const Color(0xFF6BCB77), 2)),
      const SizedBox(width: 10),
      Expanded(child: _card('📿', data.totalAzkarCompleted,   'أذكار مكتملة', const Color(0xFF4D96FF), 3)),
    ]),
  ]);

  Widget _card(String emoji, int val, String label, Color color, int i) =>
    TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + i * 100),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: v.clamp(0.0,1.0), child: Opacity(opacity: v.clamp(0.0,1.0), child: child)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withValues(alpha:.08), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha:.22), width: 1.2)),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 6),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: val),
            duration: const Duration(milliseconds: 900), curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(v.toString(),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color))),
          const SizedBox(height: 3),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ]),
      ),
    );
}

class _WeekSlot {
  final DateTime date;
  final bool isToday;
  final DayCompletion? completion;
  const _WeekSlot({required this.date, required this.isToday, required this.completion});
}
import 'package:flutter/material.dart';

import '../services/background_service.dart';
import '../services/prayer_notification_service.dart';

class AdhanSettingsScreen extends StatefulWidget {
  const AdhanSettingsScreen({super.key});

  @override
  State<AdhanSettingsScreen> createState() => _AdhanSettingsScreenState();
}

class _AdhanSettingsScreenState extends State<AdhanSettingsScreen> {
  final PrayerNotificationService _service = PrayerNotificationService();

  bool _adhanEnabled = true;
  bool _shortAdhan = false;
  bool _canScheduleExact = true;
  bool _loading = true;
  final Map<String, bool> _enabledPrayers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.ensureInitialized();
    final adhanEnabled = await _service.isAdhanEnabled();
    final shortAdhan = await _service.isShortAdhanEnabled();
    final canScheduleExact = await _service.canScheduleExactAlarms();
    final enabledPrayers = <String, bool>{};
    for (final key in prayerNamesEng) {
      enabledPrayers[key] = await _service.isPrayerEnabled(key);
    }

    if (!mounted) return;
    setState(() {
      _adhanEnabled = adhanEnabled;
      _shortAdhan = shortAdhan;
      _canScheduleExact = canScheduleExact;
      _enabledPrayers
        ..clear()
        ..addAll(enabledPrayers);
      _loading = false;
    });
  }

  Future<void> _setAdhanEnabled(bool value) async {
    await _service.setAdhanEnabled(value);
    await _reschedule();
    if (!mounted) return;
    setState(() => _adhanEnabled = value);
  }

  Future<void> _setShortAdhan(bool value) async {
    await _service.setShortAdhanEnabled(value);
    await _reschedule();
    if (!mounted) return;
    setState(() => _shortAdhan = value);
  }

  Future<void> _setPrayerEnabled(String key, bool value) async {
    await _service.setPrayerEnabled(key, value);
    await _reschedule();
    if (!mounted) return;
    setState(() => _enabledPrayers[key] = value);
  }

  Future<void> _reschedule() async {
    await PrayerBackgroundService().scheduleDailyPrayers();
  }

  Future<void> _openExactAlarmSettings() async {
    await _service.openExactAlarmSettings();
  }

  Future<void> _openNotificationSettings() async {
    await _service.openAdhanNotificationSettings();
  }

  Future<void> _requestBatteryOptimizationExemption() async {
    await _service.requestBatteryOptimizationExemption();
  }

  Future<void> _stopAdhan() async {
    await _service.stopAdhan();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إيقاف الأذان')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFE8ECE8),
        appBar: AppBar(
          title: const Text('إعدادات الأذان'),
          centerTitle: true,
          backgroundColor: const Color(0xFF5F7C7A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _heroPanel(),
                  const SizedBox(height: 14),
                  _switchTile(
                    icon: Icons.notifications_active_rounded,
                    title: 'تشغيل الأذان',
                    subtitle: 'تشغيل صوت الأذان تلقائيا عند دخول وقت الصلاة',
                    value: _adhanEnabled,
                    onChanged: _setAdhanEnabled,
                  ),
                  _switchTile(
                    icon: Icons.graphic_eq_rounded,
                    title: 'الأذان القصير',
                    subtitle: 'يشغل أول 70 ثانية من الأذان بدل النسخة الكاملة',
                    value: _shortAdhan,
                    onChanged: _adhanEnabled ? _setShortAdhan : null,
                  ),
                  const SizedBox(height: 14),
                  _sectionTitle('الصلوات'),
                  ...List.generate(prayerNamesEng.length, (index) {
                    final key = prayerNamesEng[index];
                    return _switchTile(
                      icon: Icons.mosque_rounded,
                      title: prayerNames[index],
                      subtitle: 'تشغيل الأذان وقت صلاة ${prayerNames[index]}',
                      value: _enabledPrayers[key] ?? true,
                      onChanged: _adhanEnabled
                          ? (value) => _setPrayerEnabled(key, value)
                          : null,
                    );
                  }),
                  const SizedBox(height: 14),
                  _sectionTitle('صلاحيات وتشخيص'),
                  _permissionTile(),
                  _actionTile(
                    icon: Icons.tune_rounded,
                    title: 'إعدادات صوت الأذان في النظام',
                    subtitle:
                        'افتح قناة الإشعار لو الصوت مقفول من إعدادات Android',
                    onTap: _openNotificationSettings,
                  ),
                  _actionTile(
                    icon: Icons.battery_saver_rounded,
                    title: 'السماح بعمل الأذان في الخلفية',
                    subtitle:
                        'افتح إعدادات البطارية واسمح للتطبيق بالعمل بدون تقييد.',
                    onTap: _requestBatteryOptimizationExemption,
                  ),
                  _actionTile(
                    icon: Icons.stop_circle_rounded,
                    title: 'إيقاف الأذان الآن',
                    subtitle: 'يوقف الصوت الحالي لو كان يعمل',
                    onTap: _stopAdhan,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _heroPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5F7C7A), Color(0xFF2F4542)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.volume_up_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أذان دقيق في موعده',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'يتم جدولة الأذان كمنبه دقيق وتشغيله بخدمة صوت مستقلة.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF2F4542),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return _settingsShell(
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        secondary: Icon(icon, color: const Color(0xFF5F7C7A)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        value: value,
        activeThumbColor: const Color(0xFF5F7C7A),
        onChanged: onChanged,
      ),
    );
  }

  Widget _permissionTile() {
    return _actionTile(
      icon: _canScheduleExact
          ? Icons.verified_rounded
          : Icons.warning_amber_rounded,
      title: _canScheduleExact
          ? 'صلاحية المنبه الدقيق مفعلة'
          : 'صلاحية المنبه الدقيق غير مفعلة',
      subtitle: _canScheduleExact
          ? 'الأذان قادر على العمل في الموعد المحدد.'
          : 'افتح الإعدادات وفعل السماح بالمنبهات الدقيقة.',
      onTap: _canScheduleExact ? _load : _openExactAlarmSettings,
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return _settingsShell(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(icon, color: const Color(0xFF5F7C7A)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left_rounded),
        onTap: onTap,
      ),
    );
  }

  Widget _settingsShell({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

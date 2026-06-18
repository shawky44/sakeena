import 'package:flutter/material.dart';
import '../services/azkar_settings_service.dart';
import '../services/zikr_popup_notification.dart';

class AzkarSettingsScreen extends StatefulWidget {
  const AzkarSettingsScreen({super.key});

  @override
  State<AzkarSettingsScreen> createState() => _AzkarSettingsScreenState();
}

class _AzkarSettingsScreenState extends State<AzkarSettingsScreen> {
  final AzkarSettingsService _settingsService = AzkarSettingsService();
  final ZikrPopupNotification _zikrNotifications = ZikrPopupNotification();

  double _fontSize = 22.0;
  Color _cardColor = const Color.fromARGB(240, 230, 237, 205);
  bool _zikrNotificationsEnabled = false;

  final List<Color> _availableColors = [
    const Color.fromARGB(240, 230, 237, 205),
    const Color.fromARGB(240, 205, 230, 237),
    const Color.fromARGB(240, 237, 205, 230),
    const Color.fromARGB(240, 205, 237, 205),
    const Color.fromARGB(240, 237, 230, 205),
    const Color.fromARGB(240, 225, 215, 235),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final fontSize = await _settingsService.getFontSize();
    final cardColor = await _settingsService.getCardColor();
    final zikrNotificationsEnabled = await _zikrNotifications.isEnabled();
    if (!mounted) return;
    setState(() {
      _fontSize = fontSize;
      _cardColor = cardColor;
      _zikrNotificationsEnabled = zikrNotificationsEnabled;
    });
  }

  Future<void> _setZikrNotificationsEnabled(bool enabled) async {
    setState(() => _zikrNotificationsEnabled = enabled);
    if (enabled) {
      await _zikrNotifications.start(intervalHours: 4);
    } else {
      await _zikrNotifications.stop();
    }
  }

  Future<void> _saveFontSize(double size) async {
    await _settingsService.saveFontSize(size);
    setState(() {
      _fontSize = size;
    });
  }

  Future<void> _saveCardColor(Color color) async {
    await _settingsService.saveCardColor(color);
    setState(() {
      _cardColor = color;
    });
  }

  Future<void> _resetToDefault() async {
    await _settingsService.resetToDefault();
    await _loadSettings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم استعادة الإعدادات الافتراضية'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(246, 205, 205, 205),
      appBar: AppBar(
        title: const Text(
          'إعدادات الأذكار',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF5F7C7A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPreviewCard(),
            const SizedBox(height: 30),
            _buildFontSizeSection(),
            const SizedBox(height: 25),
            _buildColorSection(),
            const SizedBox(height: 25),
            _buildNotificationSection(),
            const SizedBox(height: 30),
            _buildResetButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          const Text(
            'معاينة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5F7C7A),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _fontSize,
                height: 2.0,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.format_size, color: Color(0xFF5F7C7A)),
              SizedBox(width: 12),
              Text(
                'حجم الخط',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'صغير',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 18.0,
                  max: 32.0,
                  divisions: 7,
                  activeColor: const Color(0xFF5F7C7A),
                  inactiveColor: const Color(0xFF5F7C7A).withValues(alpha: .3),
                  onChanged: (value) {
                    _saveFontSize(value);
                  },
                ),
              ),
              const Text(
                'كبير',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          Center(
            child: Text(
              'الحجم: ${_fontSize.toInt()}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5F7C7A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.palette, color: Color(0xFF5F7C7A)),
              SizedBox(width: 12),
              Text(
                'لون الكارت',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableColors.map((color) {
              // ignore: deprecated_member_use
              final isSelected = color.value == _cardColor.value;
              return GestureDetector(
                onTap: () => _saveCardColor(color),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF5F7C7A)
                          : Colors.grey.shade300,
                      width: isSelected ? 4 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Color(0xFF5F7C7A),
                          size: 30,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        secondary: const Icon(
          Icons.notifications_active_rounded,
          color: Color(0xFF5F7C7A),
        ),
        title: const Text(
          'تذكيرات الذكر',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        subtitle: const Text('إظهار ذكر مختار كل 4 ساعات'),
        value: _zikrNotificationsEnabled,
        activeThumbColor: const Color(0xFF5F7C7A),
        onChanged: _setZikrNotificationsEnabled,
      ),
    );
  }

  Widget _buildResetButton() {
    return ElevatedButton.icon(
      onPressed: _resetToDefault,
      icon: const Icon(Icons.restore),
      label: const Text(
        'استعادة الإعدادات الافتراضية',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5F7C7A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 2,
      ),
    );
  }
}

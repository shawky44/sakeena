import 'package:flutter/material.dart';
import '../services/azkar_settings_service.dart';

class AzkarSettingsScreen extends StatefulWidget {
  const AzkarSettingsScreen({super.key});

  @override
  State<AzkarSettingsScreen> createState() => _AzkarSettingsScreenState();
}

class _AzkarSettingsScreenState extends State<AzkarSettingsScreen> {
  final AzkarSettingsService _settingsService = AzkarSettingsService();

  double _fontSize = 20.0;
  Color _cardColor = const Color.fromARGB(240, 230, 237, 205);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final fontSize = await _settingsService.getFontSize();
    final cardColor = await _settingsService.getCardColor();
    if (!mounted) return;
    setState(() {
      _fontSize = fontSize;
      _cardColor = cardColor;
    });
  }

  Future<void> _saveFontSize(double size) async {
    await _settingsService.saveFontSize(size);
    setState(() {
      _fontSize = size;
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
                  min: 14.0,
                  max: 32.0,
                  divisions: 18,
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

  // 🎨 زرار استعادة الإعدادات الافتراضية بشكل أشيك
  Widget _buildResetButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _resetToDefault,
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.white.withValues(alpha: .15),
        highlightColor: Colors.white.withValues(alpha: .08),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5F7C7A), Color(0xFF3E5654)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3E5654).withValues(alpha: .35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restore_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'استعادة الإعدادات الافتراضية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: .2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
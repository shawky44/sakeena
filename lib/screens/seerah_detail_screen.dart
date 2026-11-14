// lib/screens/seerah_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/seerah_story.dart';

// 🎨 ألوان غامقة دافئة للقراءة
const Color _kPaper = Color(0xFFEADBBE);
const Color _kCard = Color(0xFFF4E8CF);
const Color _kBorder = Color(0xFFD3C09A);
const Color _kInk = Color(0xFF3B2F22);
const Color _kInkSoft = Color(0xFF6F5E47);
const Color _kGold = Color(0xFF8A6A3B);
const Color _kGoldSoft = Color(0xFFE3D1AA);
const Color _kGreen = Color(0xFF4F6F6A);

class SeerahDetailScreen extends StatefulWidget {
  final SeerahStory story;

  const SeerahDetailScreen({super.key, required this.story});

  @override
  State<SeerahDetailScreen> createState() => _SeerahDetailScreenState();
}

class _SeerahDetailScreenState extends State<SeerahDetailScreen>
    with SingleTickerProviderStateMixin {
  static const String _fontSizeKey = 'seerah_reading_font_size';
  static const double _minFont = 15;
  static const double _maxFont = 28;

  int? _selectedAnswer;
  bool _showExplanation = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isCompleted = false;
  double _fontSize = 20;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble(_fontSizeKey);
      if (saved != null && mounted) {
        setState(() => _fontSize = saved.clamp(_minFont, _maxFont));
      }
    } catch (_) {}
  }

  Future<void> _changeFont(double delta) async {
    final next = (_fontSize + delta).clamp(_minFont, _maxFont).toDouble();
    if (next == _fontSize) return;
    setState(() => _fontSize = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontSizeKey, next);
    } catch (_) {}
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkAnswer(int index) {
    setState(() {
      _selectedAnswer = index;
      _showExplanation = true;
      if (index == widget.story.question.correctAnswer) {
        _isCompleted = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔒 Directionality ثابتة على RTL عشان الشكل ميتأثرش بلغة النظام
    return Directionality(
      textDirection: TextDirection.rtl,
      // ignore: deprecated_member_use
      child: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, _isCompleted);
          return false;
        },
        child: Scaffold(
          backgroundColor: _kPaper,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStoryCard(),
                          const SizedBox(height: 14),
                          _buildLessonsCard(),
                          const SizedBox(height: 14),
                          _buildPracticalCard(),
                          const SizedBox(height: 14),
                          _buildQuestionCard(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: _buildFloatingActions(),
        ),
      ),
    );
  }

  // هيدر صغير: رجوع + تصنيف + تكبير/تصغير الخط
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 10, 2),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _kInk, size: 20),
            onPressed: () => Navigator.pop(context, _isCompleted),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _kGoldSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.story.category,
              style: const TextStyle(
                fontSize: 12.5,
                color: _kGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          _fontButton('أ-', () => _changeFont(-1.5)),
          const SizedBox(width: 6),
          _fontButton('أ+', () => _changeFont(1.5)),
        ],
      ),
    );
  }

  Widget _fontButton(String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: _kGold,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({Color? color, Color? borderColor}) {
    return BoxDecoration(
      color: color ?? _kCard,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor ?? _kBorder),
    );
  }

  Widget _sectionTitle(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: _kGoldSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _kGold, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: _kInk,
          ),
        ),
      ],
    );
  }

  // بوكس القراءة: عريض، والعنوان مضغوط فالنص يبدأ بسرعة
  Widget _buildStoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: _kGoldSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(widget.story.emoji,
                    style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.story.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _kInk,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.story.subtitle,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: _kInkSoft,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildInfoTag(Icons.schedule_rounded,
                  '${widget.story.readingMinutes} دقائق'),
              _buildInfoTag(Icons.location_on_outlined, widget.story.location),
            ],
          ),
          const SizedBox(height: 14),
          _ornamentDivider(),
          const SizedBox(height: 16),
          ...widget.story.storyParagraphs.map(
            (paragraph) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                paragraph,
                style: TextStyle(
                  fontSize: _fontSize,
                  height: 2.15,
                  color: _kInk,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ornamentDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: _kBorder, thickness: 1.2)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.star_rounded,
              size: 14, color: _kGold.withValues(alpha: .7)),
        ),
        const Expanded(child: Divider(color: _kBorder, thickness: 1.2)),
      ],
    );
  }

  Widget _buildInfoTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: _kGreen.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _kGreen),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              color: _kGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.lightbulb_outline_rounded, 'العبرة من القصة'),
          const SizedBox(height: 16),
          ...widget.story.lessons.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(
                      color: _kGold,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        color: _kPaper,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: _fontSize - 2,
                        height: 1.95,
                        color: _kInk,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPracticalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(
        color: _kGoldSoft.withValues(alpha: .6),
        borderColor: _kGold.withValues(alpha: .4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.check_circle_outline_rounded, 'تطبيق عملي'),
          const SizedBox(height: 14),
          Text(
            widget.story.practicalApplication,
            style: TextStyle(
              fontSize: _fontSize - 2,
              height: 2.0,
              color: _kInk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.help_outline_rounded, 'سؤال تفاعلي'),
          const SizedBox(height: 16),
          Text(
            widget.story.question.question,
            style: TextStyle(
              fontSize: _fontSize - 1,
              height: 1.85,
              color: _kInk,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.story.question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = _selectedAnswer == index;
            final isCorrect = index == widget.story.question.correctAnswer;
            final showResult = _showExplanation;

            Color backgroundColor;
            Color textColor;
            Color borderColor;
            IconData? icon;

            if (showResult) {
              if (isCorrect) {
                backgroundColor = const Color(0xFFE1EBD6);
                textColor = const Color(0xFF3F6B4A);
                borderColor = const Color(0xFF6E9E78);
                icon = Icons.check_circle_rounded;
              } else if (isSelected) {
                backgroundColor = const Color(0xFFF3DDD3);
                textColor = const Color(0xFF9C4A38);
                borderColor = const Color(0xFFC98776);
                icon = Icons.cancel_rounded;
              } else {
                backgroundColor = _kPaper.withValues(alpha: .5);
                textColor = _kInkSoft;
                borderColor = _kBorder;
                icon = null;
              }
            } else {
              backgroundColor =
                  isSelected ? _kGoldSoft : _kPaper.withValues(alpha: .5);
              textColor = isSelected ? _kGold : _kInk;
              borderColor = isSelected ? _kGold : _kBorder;
              icon = null;
            }

            return GestureDetector(
              onTap: _showExplanation ? null : () => _checkAnswer(index),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: _fontSize - 3,
                          height: 1.6,
                          color: textColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 10),
                      Icon(icon, color: textColor, size: 22),
                    ],
                  ],
                ),
              ),
            );
          }),
          if (_showExplanation) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kGreen.withValues(alpha: .4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: _kGreen, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.story.question.explanation,
                      style: TextStyle(
                        fontSize: _fontSize - 3,
                        height: 1.85,
                        color: _kInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isCompleted)
          FloatingActionButton(
            heroTag: 'completed',
            backgroundColor: const Color(0xFF4F7A5A),
            elevation: 1,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('أحسنت! أكملت القصة بنجاح 🎉'),
                  backgroundColor: Color(0xFF4F7A5A),
                ),
              );
            },
            child: const Icon(Icons.check_rounded, color: Colors.white),
          ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: 'copy',
          backgroundColor: _kCard,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _kBorder),
          ),
          onPressed: () {
            final textToCopy = '''
${widget.story.title}

${widget.story.storyParagraphs.join('\n\n')}

العبرة:
${widget.story.lessons.join('\n')}''';
            Clipboard.setData(ClipboardData(text: textToCopy));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم نسخ القصة'),
                backgroundColor: Color(0xFF6B5535),
              ),
            );
          },
          child: const Icon(Icons.copy_rounded, color: _kGold),
        ),
      ],
    );
  }
}
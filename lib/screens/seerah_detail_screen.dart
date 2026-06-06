// lib/screens/seerah_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/seerah_story.dart';

class SeerahDetailScreen extends StatefulWidget {
  final SeerahStory story;

  const SeerahDetailScreen({super.key, required this.story});

  @override
  State<SeerahDetailScreen> createState() => _SeerahDetailScreenState();
}

class _SeerahDetailScreenState extends State<SeerahDetailScreen> with SingleTickerProviderStateMixin {
  int? _selectedAnswer;
  bool _showExplanation = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _isCompleted);
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A5F7A),
                Color(0xFF159895),
                Color(0xFF57C5B6),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildStoryCard(),
                          const SizedBox(height: 20),
                          _buildLessonsCard(),
                          const SizedBox(height: 20),
                          _buildPracticalCard(),
                          const SizedBox(height: 20),
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
        ),
        floatingActionButton: _buildFloatingActions(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context, _isCompleted),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.story.emoji,
                style: const TextStyle(fontSize: 35),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.story.category,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            widget.story.title,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A5F7A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.story.subtitle,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildInfoTag(Icons.access_time, '${widget.story.readingMinutes} دقائق'),
              const SizedBox(width: 10),
              _buildInfoTag(Icons.location_on, widget.story.location),
            ],
          ),
          const Divider(height: 40, thickness: 1.5),
          ...widget.story.storyParagraphs.map((paragraph) => Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Text(
              paragraph,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 17,
                height: 2.0,
                color: Color(0xFF2C3E50),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF159895).withValues(alpha: .1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF159895),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 5),
          Icon(icon, size: 16, color: const Color(0xFF159895)),
        ],
      ),
    );
  }

  Widget _buildLessonsCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'العبرة من القصة',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5F7A),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A5F7A).withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF1A5F7A),
                  size: 28,
                ),
              ),
            ],
          ),
          const Divider(height: 30, thickness: 1.5),
          ...widget.story.lessons.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      entry.value,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.8,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF159895), Color(0xFF57C5B6)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFF159895).withValues(alpha: .3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'تطبيق عملي',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5F7A),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF159895).withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF159895),
                  size: 28,
                ),
              ),
            ],
          ),
          const Divider(height: 30, thickness: 1.5, color: Color(0xFF159895)),
          Text(
            widget.story.practicalApplication,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontSize: 16,
              height: 1.9,
              color: Color(0xFF2C3E50),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'سؤال تفاعلي',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5F7A),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A5F7A).withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.quiz,
                  color: Color(0xFF1A5F7A),
                  size: 28,
                ),
              ),
            ],
          ),
          const Divider(height: 30, thickness: 1.5),
          Text(
            widget.story.question.question,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontSize: 18,
              height: 1.8,
              color: Color(0xFF2C3E50),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          ...widget.story.question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = _selectedAnswer == index;
            final isCorrect = index == widget.story.question.correctAnswer;
            final showResult = _showExplanation;

            Color backgroundColor;
            Color textColor;
            IconData? icon;

            if (showResult) {
              if (isCorrect) {
                backgroundColor = Colors.green.shade50;
                textColor = Colors.green.shade700;
                icon = Icons.check_circle;
              } else if (isSelected && !isCorrect) {
                backgroundColor = Colors.red.shade50;
                textColor = Colors.red.shade700;
                icon = Icons.cancel;
              } else {
                backgroundColor = Colors.grey.shade50;
                textColor = Colors.grey.shade700;
                icon = null;
              }
            } else {
              backgroundColor = isSelected
                  ? const Color(0xFF159895).withValues(alpha: .1)
                  : Colors.grey.shade50;
              textColor = isSelected ? const Color(0xFF159895) : Colors.grey.shade700;
              icon = null;
            }

            return GestureDetector(
              onTap: _showExplanation ? null : () => _checkAnswer(index),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isSelected
                        ? (showResult
                            ? (isCorrect ? Colors.green : Colors.red)
                            : const Color(0xFF159895))
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        option,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 10),
                      Icon(icon, color: textColor, size: 24),
                    ],
                  ],
                ),
              ),
            );
          }),
          if (_showExplanation) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.shade200, width: 2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      widget.story.question.explanation,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.8,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
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
            backgroundColor: Colors.green,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('أحسنت! أكملت القصة بنجاح 🎉'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Icon(Icons.check, color: Colors.white),
          ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: 'copy',
          backgroundColor: Colors.white,
          onPressed: () {
            final textToCopy = '''
${widget.story.title}

${widget.story.storyParagraphs.join('\n\n')}

العبرة:
${widget.story.lessons.join('\n')}
            ''';
            Clipboard.setData(ClipboardData(text: textToCopy));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم نسخ القصة'),
                backgroundColor: Color(0xFF159895),
              ),
            );
          },
          child: const Icon(Icons.copy, color: Color(0xFF1A5F7A)),
        ),
      ],
    );
  }
}
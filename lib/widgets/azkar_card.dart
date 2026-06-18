// lib/widgets/azkar_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../models/zikr_model.dart';

class AzkarCard extends StatefulWidget {
  final Zikr zikr;
  final VoidCallback? onCountChanged;
  final double fontSize;
  final Color cardColor;

  const AzkarCard({
    super.key,
    required this.zikr,
    required this.fontSize,
    required this.cardColor,
    this.onCountChanged,
  });

  @override
  State<AzkarCard> createState() => _AzkarCardState();
}

class _AzkarCardState extends State<AzkarCard>
    with AutomaticKeepAliveClientMixin {
  static const Color _themeColor = Color(0xFF5F7C7A);
  static const Color _doneColorStart = Color(0xFFD39A74);
  static const Color _doneColorEnd = Color(0xFFA86F4F);
  static const Color _borderColor = Color(0xFFD8CDB9);
  static const Color _inkColor = Color(0xFF616A64);
  static const Color _surfaceTint = Color(0xFFFBFAF4);

  @override
  bool get wantKeepAlive => true;

  void _incrementCount() {
    if (widget.zikr.currentCount < widget.zikr.count) {
      setState(widget.zikr.increment);
      Vibration.vibrate(duration: 50);
      HapticFeedback.lightImpact();
      widget.onCountChanged?.call();
    }
  }

  void _resetCount() {
    setState(widget.zikr.reset);
    widget.onCountChanged?.call();
  }

  void _copyZikr() {
    Clipboard.setData(ClipboardData(text: widget.zikr.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم نسخ الذكر',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color.fromARGB(188, 95, 124, 122),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final completed = widget.zikr.isCompleted;

    return GestureDetector(
      onTap: _incrementCount,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                _surfaceTint.withValues(alpha: .92),
                widget.cardColor,
              ),
              Color.alphaBlend(
                _surfaceTint.withValues(alpha: .78),
                widget.cardColor,
              ),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _borderColor.withValues(alpha: .85),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .055),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _AzkarCornerPainter(
                    color: _borderColor.withValues(alpha: .28),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.zikr.text,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        height: 2.05,
                        fontWeight: FontWeight.w600,
                        color: _inkColor,
                      ),
                    ),
                    if (widget.zikr.reference != null) ...[
                      const SizedBox(height: 16),
                      _referenceBox(widget.zikr.reference!),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 46,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _softIconButton(
                              icon: Icons.copy_rounded,
                              tooltip: 'نسخ',
                              onTap: _copyZikr,
                            ),
                          ),
                          _counterBadge(completed),
                        ],
                      ),
                    ),
                    if (widget.zikr.currentCount > 0) ...[
                      const SizedBox(height: 8),
                      Center(child: _resetButton()),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _referenceBox(String reference) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EFE6).withValues(alpha: .70),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor.withValues(alpha: .60)),
      ),
      child: Text(
        reference,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: (widget.fontSize - 3).clamp(13, 20).toDouble(),
          color: _themeColor.withValues(alpha: .92),
          height: 1.65,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _counterBadge(bool completed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      decoration: BoxDecoration(
        gradient: completed
            ? const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [_doneColorStart, _doneColorEnd],
              )
            : null,
        color: completed ? null : _themeColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: (completed ? _doneColorEnd : _themeColor)
                .withValues(alpha: .18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: completed
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 26)
          : Text(
              '${widget.zikr.currentCount}/${widget.zikr.count}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }

  Widget _resetButton() {
    return InkWell(
      onTap: _resetCount,
      borderRadius: BorderRadius.circular(20),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, size: 18, color: _themeColor),
            SizedBox(width: 6),
            Text(
              'إعادة',
              style: TextStyle(
                color: _themeColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _softIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 38,
          height: 38,
          child:
              Icon(icon, color: _themeColor.withValues(alpha: .82), size: 22),
        ),
      ),
    );
  }
}

class _AzkarCornerPainter extends CustomPainter {
  final Color color;

  const _AzkarCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    void drawCorner(bool left) {
      final dx = left ? 22.0 : size.width - 22.0;
      final direction = left ? 1.0 : -1.0;

      final path = Path()
        ..moveTo(dx, 20)
        ..quadraticBezierTo(dx + direction * 12, 20, dx + direction * 12, 32)
        ..quadraticBezierTo(dx + direction * 12, 42, dx + direction * 22, 42);
      canvas.drawPath(path, paint);

      canvas.drawArc(
        Rect.fromCircle(center: Offset(dx + direction * 12, 32), radius: 6),
        left ? -1.57 : 3.14,
        1.57,
        false,
        paint,
      );

      final dotPaint = Paint()
        ..color = color.withValues(alpha: .70)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dx + direction * 27, 42), 1.3, dotPaint);
    }

    drawCorner(true);
    drawCorner(false);
  }

  @override
  bool shouldRepaint(covariant _AzkarCornerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

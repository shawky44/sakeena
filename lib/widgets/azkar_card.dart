import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/zikr_model.dart';

class AzkarCard extends StatefulWidget {
  final Zikr zikr;
  final VoidCallback? onCountChanged;

  const AzkarCard({super.key, required this.zikr, this.onCountChanged});

  @override
  State<AzkarCard> createState() => _AzkarCardState();
}

class _AzkarCardState extends State<AzkarCard> {
  void _incrementCount() {
    if (widget.zikr.currentCount < widget.zikr.count) {
      setState(() {
        widget.zikr.increment();
      });
      // Vibration عادي (متوسط)
      HapticFeedback.vibrate();
      // لو خلص العداد
      if (widget.zikr.isCompleted) {
        HapticFeedback.mediumImpact();
        widget.onCountChanged?.call();
      } else {
        widget.onCountChanged?.call();
      }
    }
  }

  void _resetCount() {
    setState(() {
      widget.zikr.reset();
    });
    widget.onCountChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _incrementCount, // الكارد كله قابل للضغط
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(240, 230, 237, 205), // بيج فاتح زي الصورة
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // نص الذكر
            Text(
              widget.zikr.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                height: 2.0,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C3E50),
              ),
            ),

            // الفضل (إن وجد)
            if (widget.zikr.reference != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(99, 85, 111, 110),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  widget.zikr.reference!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Color.fromARGB(255, 255, 255, 255),
                    height: 1.6,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // العداد (شكل مستطيل دائري زي الصورة)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: widget.zikr.isCompleted
                        ? const Color.fromARGB(229, 167, 129, 101)
                        : const Color(0xFF5F7C7A), // اللون البترولي من الصورة
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .25),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: widget.zikr.isCompleted
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_rounded,

                              color: Colors.white,

                              size: 26,
                            ),
                            // SizedBox(width: 8),
                            // Text(
                            //   '',
                            //   style: TextStyle(
                            //     fontSize: 18,
                            //     fontWeight: FontWeight.bold,
                            //     color: Colors.white,
                            //   ),
                            // ),
                          ],
                        )
                      : Text(
                          '${widget.zikr.currentCount}/${widget.zikr.count}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),

            // زر إعادة
            if (widget.zikr.currentCount > 0) ...[
              const SizedBox(height: 12),
              Center(
                child: InkWell(
                  onTap: _resetCount,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: Color(0xFF5F7C7A),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'إعادة',
                          style: TextStyle(
                            color: Color(0xFF5F7C7A),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

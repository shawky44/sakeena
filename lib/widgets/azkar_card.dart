
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../models/zikr_model.dart';
import '../services/azkar_settings_service.dart';

class AzkarCard extends StatefulWidget {
  final Zikr zikr;
  final VoidCallback? onCountChanged;

  const AzkarCard({super.key, required this.zikr, this.onCountChanged});

  @override
  State<AzkarCard> createState() => _AzkarCardState();
}

class _AzkarCardState extends State<AzkarCard>
    with AutomaticKeepAliveClientMixin {
  final AzkarSettingsService _settingsService = AzkarSettingsService();

  double _fontSize = 24.0;
  Color _cardColor = const Color.fromARGB(240, 230, 237, 205);
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final fontSize = await _settingsService.getFontSize();
    final cardColor = await _settingsService.getCardColor();
    if (mounted) {
      setState(() {
        _fontSize = fontSize;
        _cardColor = cardColor;
        _isLoading = false;
      });
    }
  }

  void _incrementCount() {
    if (widget.zikr.currentCount < widget.zikr.count) {
      setState(() {
        widget.zikr.increment();
      });
      Vibration.vibrate(duration: 50);
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

    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _incrementCount,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.zikr.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _fontSize,
                    height: 2.0,
                    fontWeight: FontWeight.w500,
                    color: const Color.fromARGB(255, 80, 44, 44),
                  ),
                ),

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
                      style: TextStyle(
                        fontSize: _fontSize - 2,
                        color: const Color.fromARGB(255, 255, 255, 255),
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: _copyZikr,
                      icon: const Icon(Icons.copy_rounded),
                      color: const Color(0xFF5F7C7A),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'نسخ',
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: widget.zikr.isCompleted
                            ? const Color.fromARGB(229, 167, 129, 101)
                            : const Color(0xFF5F7C7A),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
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

                    const SizedBox(width: 40),
                  ],
                ),

                if (widget.zikr.currentCount > 0) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: InkWell(
                      onTap: _resetCount,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
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
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/zikr_model.dart';
import '../widgets/azkar_card.dart';

class AzkarCategoryScreen extends StatefulWidget {
  final String title;
  final List<Zikr> azkarList;
  final Color themeColor;
  final bool isCustomAzkar; // معرفة إذا كانت وردي الخاص
  final Function(int)? onDeleteZikr; // دالة لحذف ذكر

  const AzkarCategoryScreen({
    super.key,
    required this.title,
    required this.azkarList,
    this.themeColor = const Color(0xFF5F7C7A),
    this.isCustomAzkar = false,
    this.onDeleteZikr,
  });

  @override
  State<AzkarCategoryScreen> createState() => _AzkarCategoryScreenState();
}

class _AzkarCategoryScreenState extends State<AzkarCategoryScreen> {
  int get _completedCount {
    return widget.azkarList.where((zikr) => zikr.isCompleted).length;
  }

  void _resetAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إعادة تعيين', textAlign: TextAlign.right),
        content: const Text(
          'هل تريد إعادة تعيين جميع الأذكار؟',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                for (var zikr in widget.azkarList) {
                  zikr.reset();
                }
              });
              Navigator.pop(context);
            },
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );
  }

  void _deleteZikr(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف الذكر', textAlign: TextAlign.right),
        content: const Text(
          'هل تريد حذف هذا الذكر من وردك؟',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDeleteZikr?.call(index);
              setState(() {});
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 0, 0, 0),
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F5),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // عداد الإنجاز
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 20),
                const SizedBox(width: 6),
                Text(
                  '$_completedCount/${widget.azkarList.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // زر إعادة تعيين الكل
          IconButton(
            onPressed: _resetAll,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'إعادة تعيين الكل',
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط التقدم
          Container(
            height: 6,
            color: widget.themeColor.withValues(alpha: .2),
            child: LinearProgressIndicator(
              value: widget.azkarList.isEmpty
                  ? 0
                  : _completedCount / widget.azkarList.length,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(widget.themeColor),
            ),
          ),
          // رسالة لو الورد فاضي
          if (widget.azkarList.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border_rounded,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لم تقم بإضافة أي أذكار بعد',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            // قائمة الأذكار (تحت بعض - Scrollable)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: widget.azkarList.length,
                itemBuilder: (context, index) {
                  return widget.isCustomAzkar
                      ? Dismissible(
                          key: Key(widget.azkarList[index].id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 24),
                            child: const Icon(
                              Icons.delete_rounded,
                              color: Color.fromARGB(255, 0, 0, 0),
                              size: 32,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: const Text(
                                  'حذف الذكر',
                                  textAlign: TextAlign.right,
                                ),
                                content: const Text(
                                  'هل تريد حذف هذا الذكر من وردك؟',
                                  textAlign: TextAlign.right,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('إلغاء'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color.fromARGB(
                                        255,
                                        0,
                                        0,
                                        0,
                                      ),
                                    ),
                                    child: const Text('حذف'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) {
                            widget.onDeleteZikr?.call(index);
                          },
                          child: Stack(
                            children: [
                              AzkarCard(
                                zikr: widget.azkarList[index],
                                onCountChanged: () {
                                  setState(() {});
                                },
                              ),
                              // زر الحذف في الزاوية
                              Positioned(
                                top: 16,
                                left: 24,
                                child: IconButton(
                                  onPressed: () => _deleteZikr(index),
                                  icon: const Icon(
                                    Icons.delete_rounded,
                                    color: Color.fromARGB(182, 35, 30, 30),
                                  ),
                                  tooltip: 'حذف',
                                ),
                              ),
                            ],
                          ),
                        )
                      : AzkarCard(
                          zikr: widget.azkarList[index],
                          onCountChanged: () {
                            setState(() {});
                          },
                        );
                },
              ),
            ),
        ],
      ),
    );
  }
}

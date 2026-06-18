// lib/screens/azkar_category_screen.dart

import 'package:flutter/material.dart';
import '../models/zikr_model.dart';
import '../widgets/azkar_card.dart';
import '../widgets/completion_dialog.dart';
import '../services/azkar_storage_service.dart';
import '../services/azkar_settings_service.dart';
import '../services/journey_refresh_service.dart';

class AzkarCategoryScreen extends StatefulWidget {
  final String title;
  final List<Zikr> azkarList;
  final Color themeColor;
  final bool isCustomAzkar;
  final String? azkarType;
  final Function(int)? onDeleteZikr;
  final Function(int, int)? onReorder;

  const AzkarCategoryScreen({
    super.key,
    required this.title,
    required this.azkarList,
    this.themeColor = const Color(0xFF5F7C7A),
    this.isCustomAzkar = false,
    this.azkarType,
    this.onDeleteZikr,
    this.onReorder,
  });

  @override
  State<AzkarCategoryScreen> createState() => _AzkarCategoryScreenState();
}

class _AzkarCategoryScreenState extends State<AzkarCategoryScreen> {
  bool _completionShown = false;
  bool _isLoading = true;

  double _fontSize = 22.0;
  Color _cardColor = const Color.fromARGB(240, 230, 237, 205);

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  Future<void> _initScreen() async {
    await Future.wait([_loadSettings(), _loadProgress()]);
    if (mounted) {
      setState(() => _isLoading = false);
      if (_allCompleted) _completionShown = true;
    }
  }

  Future<void> _loadSettings() async {
    final service = AzkarSettingsService();
    _fontSize = await service.getFontSize();
    _cardColor = await service.getCardColor();
  }

  Future<void> _loadProgress() async {
    if (widget.azkarType != null) {
      await AzkarStorageService.loadAndApplyProgress(
          widget.azkarType!, widget.azkarList);
    }
  }

  int get _completedCount =>
      widget.azkarList.where((z) => z.isCompleted).length;
  bool get _allCompleted =>
      widget.azkarList.isNotEmpty &&
      widget.azkarList.every((z) => z.isCompleted);

  Future<void> _onCountChanged() async {
    setState(() {});
    if (widget.azkarType != null) {
      await AzkarStorageService.stampToday(widget.azkarType!);
      await AzkarStorageService.saveProgress(
          widget.azkarType!, widget.azkarList);
      JourneyRefreshService.instance.notifyRefresh();
    }
    if (_allCompleted && !_completionShown) {
      _completionShown = true;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) showCompletionDialog(context, azkarTitle: widget.title);
      });
    }
  }

  void _resetAll() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('إعادة تعيين', textAlign: TextAlign.right),
              content: const Text('هل تريد إعادة تعيين جميع الأذكار؟',
                  textAlign: TextAlign.right),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء')),
                TextButton(
                  onPressed: () async {
                    for (var z in widget.azkarList) {
                      z.currentCount = 0;
                      z.isCompleted = false;
                    }
                    _completionShown = false;
                    if (widget.azkarType != null) {
                      await AzkarStorageService.saveProgress(
                          widget.azkarType!, widget.azkarList);
                    }
                    if (mounted) {
                      setState(() {});
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('إعادة تعيين'),
                ),
              ],
            ));
  }

  void _deleteZikr(int index) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('حذف الذكر', textAlign: TextAlign.right),
              content: const Text('هل تريد حذف هذا الذكر من وردك؟',
                  textAlign: TextAlign.right),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء')),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onDeleteZikr?.call(index);
                      setState(() {});
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('حذف')),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F8F5),
        appBar: AppBar(
            title: Text(widget.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: widget.themeColor,
            foregroundColor: Colors.white,
            elevation: 0),
        body: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: 3,
          itemBuilder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 155,
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                        height: 13,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(7))),
                    const SizedBox(height: 8),
                    Container(
                        height: 13,
                        width: 180,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(7))),
                    const Spacer(),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                            height: 34,
                            width: 80,
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(18)))),
                  ]),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1E8D8),
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.check_circle_outline, size: 20),
              const SizedBox(width: 6),
              Text('$_completedCount/${widget.azkarList.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ),
          IconButton(
              onPressed: _resetAll,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'إعادة تعيين الكل'),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3E9D8),
              Color(0xFFEDE1CD),
              Color(0xFFF6F0E5),
            ],
          ),
        ),
        child: Column(children: [
          Container(
              height: 6,
              color: widget.themeColor.withValues(alpha: .2),
              child: LinearProgressIndicator(
                  value: widget.azkarList.isEmpty
                      ? 0
                      : _completedCount / widget.azkarList.length,
                  backgroundColor: Colors.transparent,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(widget.themeColor))),
          if (widget.azkarList.isEmpty)
            Expanded(
                child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                  Icon(Icons.bookmark_border_rounded,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('لم تقم بإضافة أي أذكار بعد',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ])))
          else
            Expanded(
              child: widget.isCustomAzkar
                  ? ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: widget.azkarList.length,
                      onReorder: (o, n) {
                        widget.onReorder?.call(o, n);
                        setState(() {});
                      },
                      proxyDecorator: (child, index, anim) => Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(20),
                          child: child),
                      itemBuilder: (context, index) => Dismissible(
                        key: Key(widget.azkarList[index].id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20)),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 24),
                            child: const Icon(Icons.delete_rounded,
                                color: Colors.white, size: 32)),
                        confirmDismiss: (_) async => showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  title: const Text('حذف الذكر',
                                      textAlign: TextAlign.right),
                                  content: const Text(
                                      'هل تريد حذف هذا الذكر من وردك؟',
                                      textAlign: TextAlign.right),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('إلغاء')),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: TextButton.styleFrom(
                                            foregroundColor: Colors.red),
                                        child: const Text('حذف')),
                                  ],
                                )),
                        onDismissed: (_) => widget.onDeleteZikr?.call(index),
                        child: Stack(children: [
                          AzkarCard(
                              zikr: widget.azkarList[index],
                              onCountChanged: _onCountChanged,
                              fontSize: _fontSize,
                              cardColor: _cardColor),
                          Positioned(
                              top: 16,
                              right: 24,
                              child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                      color: widget.themeColor
                                          .withValues(alpha: .1),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Icon(Icons.drag_handle_rounded,
                                      color: widget.themeColor, size: 17))),
                          Positioned(
                              top: 16,
                              left: 24,
                              child: IconButton(
                                  onPressed: () => _deleteZikr(index),
                                  icon: const Icon(Icons.delete_rounded,
                                      color: Color.fromARGB(182, 35, 30, 30)),
                                  tooltip: 'حذف')),
                        ]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: widget.azkarList.length,
                      itemBuilder: (_, index) => AzkarCard(
                          zikr: widget.azkarList[index],
                          onCountChanged: _onCountChanged,
                          fontSize: _fontSize,
                          cardColor: _cardColor),
                    ),
            ),
        ]),
      ),
    );
  }
}

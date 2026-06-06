// // todo_screen.dart
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import 'dart:async';

// // Data Models
// enum ItemShape { square, rounded, circular }

// class TodoItem {
//   String title;
//   bool isCompleted;

//   TodoItem({required this.title, required this.isCompleted});

//   Map<String, dynamic> toJson() => {'title': title, 'isCompleted': isCompleted};

//   factory TodoItem.fromJson(Map<String, dynamic> json) =>
//       TodoItem(title: json['title'], isCompleted: json['isCompleted']);
// }

// class TodoSection {
//   String title;
//   IconData icon;
//   Color backgroundColor;
//   ItemShape itemShape;
//   List<TodoItem> items;
//   bool isSpecialPrayerSection;

//   TodoSection({
//     required this.title,
//     required this.icon,
//     required this.backgroundColor,
//     required this.itemShape,
//     required this.items,
//     this.isSpecialPrayerSection = false, 
//   });

//   void sortItems() {
//     items.sort((a, b) {
//       if (a.isCompleted == b.isCompleted) return 0;
//       return a.isCompleted ? 1 : -1;
//     });
//   }

//   Map<String, dynamic> toJson() => {
//     'title': title,
//     'iconCodePoint': icon.codePoint,
//     // ignore: deprecated_member_use
//     'backgroundColorValue': backgroundColor.value,
//     'itemShape': itemShape.index,
//     'items': items.map((item) => item.toJson()).toList(),
//     'isSpecialPrayerSection': isSpecialPrayerSection, 
//   };

//   factory TodoSection.fromJson(Map<String, dynamic> json) => TodoSection(
//     title: json['title'],
//     icon: IconData(json['iconCodePoint'], fontFamily: 'MaterialIcons'),
//     backgroundColor: Color(json['backgroundColorValue']),
//     itemShape: ItemShape.values[json['itemShape']],
//     items: (json['items'] as List)
//         .map((item) => TodoItem.fromJson(item))
//         .toList(),
//     isSpecialPrayerSection: json['isSpecialPrayerSection'] ?? false, 
//   );
// }

// class TodoPage {
//   String title;
//   List<TodoSection> sections;

//   TodoPage({required this.title, required this.sections});

//   Map<String, dynamic> toJson() => {
//     'title': title,
//     'sections': sections.map((section) => section.toJson()).toList(),
//   };

//   factory TodoPage.fromJson(Map<String, dynamic> json) => TodoPage(
//     title: json['title'],
//     sections: (json['sections'] as List)
//         .map((section) => TodoSection.fromJson(section))
//         .toList(),
//   );
// }

// class TodoScreen extends StatefulWidget {
//   const TodoScreen({super.key});

//   @override
//   State<TodoScreen> createState() => _TodoScreenState();
// }

// class _TodoScreenState extends State<TodoScreen> with TickerProviderStateMixin {
//   List<TodoPage> _pages = [];
//   int _currentPageIndex = 0;
//   late TabController _tabController;
//   final TextEditingController _newItemController = TextEditingController();
//   final TextEditingController _newSectionController = TextEditingController();
//   final TextEditingController _newPageController = TextEditingController();
//   bool _isLoading = true;
//   Timer? _midnightTimer; 

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//     _scheduleMidnightRefresh(); 
//   }

//   void _scheduleMidnightRefresh() {
//     final now = DateTime.now();
//     final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
//     final durationUntilMidnight = nextMidnight.difference(now);

//     debugPrint('⏰ جدولة تحديث الصلوات عند: $nextMidnight');
//     debugPrint('⏰ الوقت المتبقي: ${durationUntilMidnight.inHours} ساعة و ${durationUntilMidnight.inMinutes % 60} دقيقة');

//     _midnightTimer = Timer(durationUntilMidnight, () {
//       _resetPrayerSection();
//       _scheduleMidnightRefresh();
//     });
//   }

//   Future<void> _resetPrayerSection() async {
//     debugPrint('🔄 بدء إعادة تعيين الصلوات...');
    
//     final prefs = await SharedPreferences.getInstance();
//     final String currentDate = DateTime.now().toIso8601String().split('T')[0];
//     final String? lastResetDate = prefs.getString('last_prayer_reset_date');

//     if (lastResetDate == currentDate) {
//       debugPrint('✅ تم التحديث بالفعل اليوم');
//       return;
//     }

//     setState(() {
//       for (var page in _pages) {
//         if (page.title == "🕌 الصلوات الخمس") {
//           for (var i = 0; i < page.sections.length; i++) {
//             if (page.sections[i].isSpecialPrayerSection) {
//               page.sections[i] = _getDefaultPrayerSection();
//               debugPrint('✅ تم تحديث سكشن الصلوات بنجاح');
//               break;
//             }
//           }
//           break;
//         }
//       }
//     });

//     await prefs.setString('last_prayer_reset_date', currentDate);
//     await _saveData();
    
//     debugPrint('✅ اكتمل تحديث الصلوات للتاريخ: $currentDate');
//   }

//   TodoSection _getDefaultPrayerSection() {
//     return TodoSection(
//       title: "Five Prayers",
//       icon: Icons.access_time,
//       backgroundColor: Colors.green.shade50,
//       itemShape: ItemShape.rounded,
//       isSpecialPrayerSection: true, 
//       items: [
//         TodoItem(title: "Fajr (الفجر)", isCompleted: false),
//         TodoItem(title: "Dhuhr (الظهر)", isCompleted: false),
//         TodoItem(title: "Asr (العصر)", isCompleted: false),
//         TodoItem(title: "Maghrib (المغرب)", isCompleted: false),
//         TodoItem(title: "Isha (العشاء)", isCompleted: false),
//       ],
//     );
//   }

//   Future<void> _loadData() async {
//     final prefs = await SharedPreferences.getInstance();
//     final String? pagesJson = prefs.getString('todo_pages');

//     if (pagesJson != null) {
//       try {
//         final List<dynamic> decodedPages = jsonDecode(pagesJson);
//         _pages = decodedPages.map((page) => TodoPage.fromJson(page)).toList();
//       } catch (e) {
//         if (kDebugMode) {
//           print('Error loading data: $e');
//         }
//         _pages = _getDefaultPages();
//       }
//     } else {
//       _pages = _getDefaultPages();
//     }

//     await _checkAndResetIfNeeded();

//     _tabController = TabController(length: _pages.length, vsync: this);
//     _tabController.addListener(() {
//       setState(() {
//         _currentPageIndex = _tabController.index;
//       });
//     });

//     setState(() {
//       _isLoading = false;
//     });
//   }

//   Future<void> _checkAndResetIfNeeded() async {
//     final prefs = await SharedPreferences.getInstance();
//     final String currentDate = DateTime.now().toIso8601String().split('T')[0];
//     final String? lastResetDate = prefs.getString('last_prayer_reset_date');

//     if (lastResetDate != currentDate) {
//       debugPrint('🔄 يوم جديد! إعادة تعيين الصلوات...');
//       await _resetPrayerSection();
//     } else {
//       debugPrint('✅ الصلوات محدثة لليوم الحالي');
//     }
//   }

//   Future<void> _saveData() async {
//     final prefs = await SharedPreferences.getInstance();
//     final String pagesJson = jsonEncode(
//       _pages.map((page) => page.toJson()).toList(),
//     );
//     await prefs.setString('todo_pages', pagesJson);
//   }

//   List<TodoPage> _getDefaultPages() {
//     return [
//       TodoPage(
//         title: "🕌 الصلوات الخمس",
//         sections: [
//           _getDefaultPrayerSection(), 
//         ],
//       ),
//     ];
//   }

//   @override
//   void dispose() {
//     _midnightTimer?.cancel(); 
//     _tabController.dispose();
//     _newItemController.dispose();
//     _newSectionController.dispose();
//     _newPageController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     return Scaffold(
//       backgroundColor: const Color(0xFFD9D9D9),
//       appBar: AppBar(
//         backgroundColor: const Color.fromARGB(199, 107, 143, 127),
//         title: const Text('📋 المهام اليومية'),
//         bottom: TabBar(
//           controller: _tabController,
//           isScrollable: true,
//           indicatorColor: const Color.fromARGB(255, 53, 43, 43),
//           labelColor: const Color.fromARGB(255, 29, 26, 26),
//           tabAlignment: TabAlignment.start,
//           tabs: _pages.asMap().entries.map((entry) {
//           final index = entry.key;
//           final page = entry.value;
//           return Tab(
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(page.title),
//                 if (_pages.length > 1 && page.title != "🕌 الصلوات الخمس") ...[
//                   const SizedBox(width: 8),
//                   InkWell(
//                     onTap: () => _deletePage(index),
//                     child: const Icon(Icons.close_rounded, size: 18),
//                   ),
//                 ],
//               ],
//             ),
//           );
//         }).toList(),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add_box),
//             onPressed: _showAddPageDialog,
//             tooltip: 'اضافة صفحة جديدة',
//           ),
//           IconButton(
//             icon: const Icon(Icons.reorder),
//             onPressed: _showReorderDialog,
//             tooltip: 'ترتيب الصفحات',
//           ),
//         ],
//       ),
//       body: SafeArea(
//         bottom: false,
//         child: Padding(
//           padding: const EdgeInsets.only(bottom: 85.0),
//           child: TabBarView(
//             controller: _tabController,
//             children: _pages.map((page) {
//               return _buildPageContent(page);
//             }).toList(),
//           ),
//         ),
//       ),
//       floatingActionButton: Padding(
//         padding: const EdgeInsets.only(bottom: 120.0, left: 20),
//         child: FloatingActionButton(
//           backgroundColor: const Color.fromARGB(179, 107, 143, 127),
//           onPressed: _showAddSectionDialog,
//           child: const Icon(Icons.add),
//         ),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
//     );
//   }

//   Widget _buildPageContent(TodoPage page) {
//     if (page.sections.isEmpty) {
//       return _buildEmptyPageState(page);
//     }

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final isWideScreen = constraints.maxWidth > 600;
//         final horizontalPadding = isWideScreen ? 16.0 : 8.0;

//         return ReorderableListView.builder(
//           padding: EdgeInsets.symmetric(
//             horizontal: horizontalPadding,
//             vertical: 8.0,
//           ),
//           itemCount: page.sections.length,
//           onReorder: (oldIndex, newIndex) {
//             setState(() {
//               if (oldIndex < newIndex) {
//                 newIndex -= 1;
//               }
//               final section = page.sections.removeAt(oldIndex);
//               page.sections.insert(newIndex, section);
//               _saveData();
//             });
//           },
//           itemBuilder: (context, index) {
//             final section = page.sections[index];
//             return _buildSection(section, index, page, constraints.maxWidth);
//           },
//         );
//       },
//     );
//   }

//   Widget _buildEmptyPageState(TodoPage page) {
//     return Center(
//       child: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.list_alt, size: 64, color: Colors.grey),
//               const SizedBox(height: 16),
//               Text(
//                 'No sections in "${page.title}"',
//                 style: const TextStyle(fontSize: 18, color: Colors.grey),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 'Add your first section to start organizing tasks',
//                 style: TextStyle(color: Colors.grey),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 24),
//               ElevatedButton.icon(
//                 onPressed: _showAddSectionDialog,
//                 icon: const Icon(Icons.add),
//                 label: const Text('اضف قائمة جديدة'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSection(
//     TodoSection section,
//     int sectionIndex,
//     TodoPage page,
//     double screenWidth,
//   ) {
//     final isWideScreen = screenWidth > 600;
//     final sectionMargin = isWideScreen ? 12.0 : 8.0;
//     final sectionPadding = isWideScreen ? 20.0 : 16.0;

//     return Container(
//       key: Key('section_$sectionIndex'),
//       margin: EdgeInsets.all(sectionMargin),
//       constraints: BoxConstraints(
//         maxWidth: isWideScreen ? 800 : double.infinity,
//       ),
//       decoration: BoxDecoration(
//         color: section.backgroundColor,
//         borderRadius: BorderRadius.circular(12.0),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withValues(alpha: 0.2),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: EdgeInsets.all(sectionPadding),
//             child: Row(
//               children: [
//                 ReorderableDragStartListener(
//                   index: sectionIndex,
//                   child: const Icon(Icons.drag_handle, color: Colors.grey),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     section.title,
//                     style: const TextStyle(
//                       color: Colors.black,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 if (!section.isSpecialPrayerSection) ...[
//                   IconButton(
//                     icon: const Icon(Icons.color_lens, size: 20),
//                     onPressed: () => _showColorPickerDialog(sectionIndex, page),
//                     tooltip: 'Change Color',
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.add, size: 20),
//                     onPressed: () => _showAddItemToSectionDialog(sectionIndex),
//                     tooltip: 'Add Task',
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.delete, size: 20),
//                     onPressed: () => _deleteSection(sectionIndex, page),
//                     tooltip: 'Delete Section',
//                   ),
//                 ] else ...[
//                   const Padding(
//                     padding: EdgeInsets.only(right: 8.0),
//                     child: Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           ...section.items.asMap().entries.map((entry) {
//             final itemIndex = entry.key;
//             final item = entry.value;
//             return _buildTodoItem(item, sectionIndex, itemIndex, page, section);
//           }),
//           const SizedBox(height: 8),
//         ],
//       ),
//     );
//   }

//   Widget _buildTodoItem(
//     TodoItem item,
//     int sectionIndex,
//     int itemIndex,
//     TodoPage page,
//     TodoSection section,
//   ) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withValues(alpha: .1),
//             blurRadius: 2,
//             offset: const Offset(0, 1),
//           ),
//         ],
//       ),
//       child: ListTile(
//         leading: Checkbox(
//           value: item.isCompleted,
//           onChanged: (value) {
//             setState(() {
//               page.sections[sectionIndex].items[itemIndex].isCompleted = value!;
//               page.sections[sectionIndex].sortItems();
//               _saveData();
//             });
//           },
//         ),
//         title: Text(
//           item.title,
//           style: TextStyle(
//             fontSize: 13,
//             decoration: item.isCompleted ? TextDecoration.lineThrough : null,
//             color: item.isCompleted ? Colors.grey : Colors.black,
//           ),
//         ),
//         trailing: !section.isSpecialPrayerSection
//             ? IconButton(
//                 icon: const Icon(Icons.delete, size: 18),
//                 onPressed: () => _deleteItem(sectionIndex, itemIndex, page),
//               )
//             : null,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       ),
//     );
//   }

//   void _showColorPickerDialog(int sectionIndex, TodoPage page) {
//     final List<Color> colorOptions = [
//       Colors.blue.shade50,
//       Colors.green.shade50,
//       Colors.orange.shade50,
//       Colors.red.shade50,
//       Colors.purple.shade50,
//       Colors.teal.shade50,
//       Colors.pink.shade50,
//       Colors.indigo.shade50,
//       Colors.amber.shade50,
//       Colors.cyan.shade50,
//     ];

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Choose Section Color'),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: GridView.builder(
//             shrinkWrap: true,
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 4,
//               crossAxisSpacing: 8,
//               mainAxisSpacing: 8,
//             ),
//             itemCount: colorOptions.length,
//             itemBuilder: (context, index) {
//               final color = colorOptions[index];
//               final isSelected =
//                   page.sections[sectionIndex].backgroundColor == color;
//               return GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     page.sections[sectionIndex].backgroundColor = color;
//                     _saveData();
//                   });
//                   Navigator.pop(context);
//                 },
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: color,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: isSelected ? Colors.blue : Colors.transparent,
//                       width: 3,
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('الغاء'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showReorderDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('ترتيب الصفحات'),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: ReorderableListView(
//             shrinkWrap: true,
//             onReorder: (oldIndex, newIndex) {
//               setState(() {
//                 if (oldIndex < newIndex) {
//                   newIndex -= 1;
//                 }
//                 final page = _pages.removeAt(oldIndex);
//                 _pages.insert(newIndex, page);
//                 _saveData();
//               });
//             },
//             children: _pages.asMap().entries.map((entry) {
//               final index = entry.key;
//               final page = entry.value;
//               return ListTile(
//                 key: Key('page_$index'),
//                 title: Text(page.title),
//                 trailing: Text('${index + 1}'),
//               );
//             }).toList(),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('الغاء'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showAddItemToSectionDialog(int sectionIndex) {
//     _newItemController.clear();
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('اضافة مهمة جديدة'),
//         content: TextField(
//           controller: _newItemController,
//           decoration: const InputDecoration(hintText: '...أدخل اسم المهمة'),
//           autofocus: true,
//           onSubmitted: (_) => _addItemToSection(sectionIndex),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('الغاء'),
//           ),
//           TextButton(
//             onPressed: () => _addItemToSection(sectionIndex),
//             child: const Text('إضافة'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _addItemToSection(int sectionIndex) {
//     if (_newItemController.text.isNotEmpty) {
//       setState(() {
//         _pages[_currentPageIndex].sections[sectionIndex].items.add(
//           TodoItem(title: _newItemController.text, isCompleted: false),
//         );
//         _saveData();
//       });
//       _newItemController.clear();
//       Navigator.pop(context);
//     }
//   }

//   void _showAddSectionDialog() {
//     _newSectionController.clear();
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('اضافة قائمة جديدة'),
//         content: TextField(
//           controller: _newSectionController,
//           decoration: const InputDecoration(hintText: ' ...أدخل اسم القائمة'),
//           autofocus: true,
//           onSubmitted: (_) => _addSection(),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('الغاء'),
//           ),
//           TextButton(onPressed: _addSection, child: const Text('إضافة')),
//         ],
//       ),
//     );
//   }

//   void _addSection() {
//     if (_newSectionController.text.isNotEmpty) {
//       setState(() {
//         _pages[_currentPageIndex].sections.add(
//           TodoSection(
//             title: _newSectionController.text,
//             icon: Icons.list,
//             backgroundColor: _getDefaultColor(),
//             itemShape: ItemShape.rounded,
//             items: [],
//           ),
//         );
//         _saveData();
//       });
//       _newSectionController.clear();
//       Navigator.pop(context);
//     }
//   }

//   void _showAddPageDialog() {
//     _newPageController.clear();
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('اضافة صفحة جديدة'),
//         content: TextField(
//           controller: _newPageController,
//           decoration: const InputDecoration(hintText: '...أدخل اسم الصفحة'),
//           autofocus: true,
//           onSubmitted: (_) => _addPage(),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('الغاء'),
//           ),
//           TextButton(onPressed: _addPage, child: const Text('إضافة')),
//         ],
//       ),
//     );
//   }

//   void _addPage() {
//     if (_newPageController.text.isNotEmpty) {
//       setState(() {
//         _pages.add(TodoPage(title: _newPageController.text, sections: []));
//         _tabController.dispose();
//         _tabController = TabController(
//           length: _pages.length,
//           vsync: this,
//           initialIndex: _pages.length - 1,
//         );
//         _tabController.addListener(() {
//           setState(() {
//             _currentPageIndex = _tabController.index;
//           });
//         });
//         _currentPageIndex = _pages.length - 1;
//         _saveData();
//       });
//       _newPageController.clear();
//       Navigator.pop(context);
//     }
//   }

//   Color _getDefaultColor() {
//     final List<Color> defaultColors = [
//       Colors.blue.shade50,
//       Colors.green.shade50,
//       Colors.orange.shade50,
//       Colors.purple.shade50,
//     ];
//     return defaultColors[_pages[_currentPageIndex].sections.length %
//         defaultColors.length];
//   }

//   void _deleteItem(int sectionIndex, int itemIndex, TodoPage page) {
//     setState(() {
//       page.sections[sectionIndex].items.removeAt(itemIndex);
//       _saveData();
//     });
//   }

//   void _deleteSection(int sectionIndex, TodoPage page) {
//     setState(() {
//       page.sections.removeAt(sectionIndex);
//       _saveData();
//     });
//   }

//   void _deletePage(int pageIndex) {
//   if (_pages[pageIndex].title == "🕌 الصلوات الخمس") {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('⚠️ لا يمكن حذف صفحة الصلوات الخمس'),
//         backgroundColor: Colors.red,
//         duration: Duration(seconds: 2),
//       ),
//     );
//     return;
//   }

//   if (_pages.length <= 1) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('⚠️ لا يمكن حذف آخر صفحة'),
//         backgroundColor: Colors.orange,
//       ),
//     );
//     return;
//   }

//   setState(() {
//     _pages.removeAt(pageIndex);
//     _tabController.dispose();
//     final newIndex = pageIndex > 0 ? pageIndex - 1 : 0;
//     _tabController = TabController(
//       length: _pages.length,
//       vsync: this,
//       initialIndex: newIndex,
//     );
//     _tabController.addListener(() {
//       setState(() {
//         _currentPageIndex = _tabController.index;
//       });
//     });
//     _currentPageIndex = _tabController.index;
//     _saveData();
//   });
// }
// }
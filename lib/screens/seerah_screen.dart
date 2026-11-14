// lib/screens/seerah_screen.dart
import 'package:flutter/material.dart';
import '../models/seerah_story.dart';
import '../data/seerah_data.dart';
import '../services/storage_service.dart';
import '../utils/instant_page_route.dart';
import 'seerah_detail_screen.dart';

// 🎨 ألوان دافئة بطابع ورق الكتب
const Color _kPaper = Color(0xFFEADBBE);
const Color _kCard = Color(0xFFF4E8CF);
const Color _kBorder = Color(0xFFD3C09A);
const Color _kInk = Color(0xFF3B2F22);
const Color _kInkSoft = Color(0xFF6F5E47);
const Color _kGold = Color(0xFF8A6A3B);
const Color _kGoldSoft = Color(0xFFE3D1AA);
const Color _kGreen = Color(0xFF4F6F6A);

class SeerahScreen extends StatefulWidget {
  const SeerahScreen({super.key});

  @override
  State<SeerahScreen> createState() => _SeerahScreenState();
}

class _SeerahScreenState extends State<SeerahScreen>
    with SingleTickerProviderStateMixin {
  List<SeerahStory> _filteredStories = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'الكل';
  Set<int> _favorites = {};
  Set<int> _completed = {};
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _filteredStories = SeerahData.stories;
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final favorites = await StorageService.getFavorites();
    final completed = await StorageService.getCompleted();

    if (!mounted) return;
    setState(() {
      _favorites = favorites;
      _completed = completed;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _filterStories(String query) {
    setState(() {
      if (query.isEmpty && _selectedCategory == 'الكل') {
        _filteredStories = SeerahData.stories;
      } else {
        _filteredStories = SeerahData.stories.where((story) {
          final matchesSearch = query.isEmpty ||
              story.title.contains(query) ||
              story.subtitle.contains(query);
          final matchesCategory =
              _selectedCategory == 'الكل' || story.category == _selectedCategory;
          return matchesSearch && matchesCategory;
        }).toList();
      }
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _filterStories(_searchController.text);
    });
  }

  Future<void> _toggleFavorite(int id) async {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
    await StorageService.saveFavorites(_favorites);
  }

  Future<void> _markAsCompleted(int id) async {
    setState(() {
      _completed.add(id);
    });
    await StorageService.saveCompleted(_completed);
  }

  @override
  Widget build(BuildContext context) {
    // 🔒 Directionality ثابتة على RTL عشان الشكل ميتأثرش بلغة النظام
    return Directionality(
      textDirection: TextDirection.rtl,
      child: _isLoading
          ? const Scaffold(
              backgroundColor: _kPaper,
              body: Center(child: CircularProgressIndicator(color: _kGold)),
            )
          : Scaffold(
              backgroundColor: _kPaper,
              body: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildTabBar(),
                    // 🔽 البحث والتصنيفات بيتحركوا مع إصبعك بالظبط:
                    // بيطلعوا لما تنزل بالقصص، وبيرجعوا أول ما تسحب لفوق
                    Expanded(
                      child: NestedScrollView(
                        floatHeaderSlivers: true,
                        headerSliverBuilder: (context, innerBoxIsScrolled) => [
                          SliverAppBar(
                            floating: true,
                            snap: true,
                            pinned: false,
                            automaticallyImplyLeading: false,
                            backgroundColor: _kPaper,
                            surfaceTintColor: Colors.transparent,
                            elevation: 0,
                            scrolledUnderElevation: 0,
                            toolbarHeight: _collapsibleHeight,
                            flexibleSpace: ClipRect(
                              child: OverflowBox(
                                alignment: Alignment.topCenter,
                                minHeight: 0,
                                maxHeight: _collapsibleHeight,
                                child: SizedBox(
                                  height: _collapsibleHeight,
                                  child: Column(
                                    children: [
                                      _buildSearchBar(),
                                      _buildCategoryChips(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        body: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildStoriesList(),
                            _buildFavoritesList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              floatingActionButton: _buildProgressFAB(),
            ),
    );
  }

  // ارتفاع الجزء اللي بيتقفل (بحث 16+50+12 + تصنيفات 42 + مسافة 6)
  static const double _searchHeight = 50;
  static const double _chipsHeight = 42;
  static const double _collapsibleHeight = 16 + _searchHeight + 12 + _chipsHeight + 6;

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _kInk, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'قصص الصحابة والأنبياء',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _kInk,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    'رحلة في حياة خير البشر ﷺ',
                    style: TextStyle(fontSize: 13, color: _kInkSoft),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder, width: 1.2)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: _kGold,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: _kInk,
        unselectedLabelColor: _kInkSoft,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        unselectedLabelStyle: const TextStyle(fontSize: 15),
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: const [
          Tab(text: 'جميع القصص'),
          Tab(text: 'المفضلة'),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: _searchHeight,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        onChanged: _filterStories,
        style: const TextStyle(color: _kInk),
        cursorColor: _kGold,
        decoration: InputDecoration(
          hintText: 'ابحث في القصص...',
          hintStyle: const TextStyle(color: _kInkSoft, fontSize: 14),
          hintTextDirection: TextDirection.rtl,
          prefixIcon: const Icon(Icons.search_rounded, color: _kGold),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: _kInkSoft),
                  onPressed: () {
                    _searchController.clear();
                    _filterStories('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: _chipsHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: SeerahData.categories.length,
        itemBuilder: (context, index) {
          final category = SeerahData.categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () => _selectCategory(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsetsDirectional.only(end: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? _kGold : _kCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: isSelected ? _kGold : _kBorder),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? _kPaper : _kInk,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, [String? subtitle]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: _kGold.withValues(alpha: .5)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, color: _kInk)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(fontSize: 13, color: _kInkSoft)),
          ],
        ],
      ),
    );
  }

  Widget _buildStoriesList() {
    if (_filteredStories.isEmpty) {
      return _buildEmptyState(Icons.search_off_rounded, 'لا توجد قصص');
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 14, bottom: 100),
      itemCount: _filteredStories.length,
      itemBuilder: (context, index) {
        final story = _filteredStories[index];
        final isFavorite = _favorites.contains(story.id);
        final isCompleted = _completed.contains(story.id);
        return _buildStoryCard(story, isFavorite, isCompleted);
      },
    );
  }

  Widget _buildFavoritesList() {
    final favoriteStories =
        SeerahData.stories.where((s) => _favorites.contains(s.id)).toList();

    if (favoriteStories.isEmpty) {
      return _buildEmptyState(
        Icons.favorite_border_rounded,
        'لا توجد قصص مفضلة',
        'اضغط على ♡ لإضافة قصص للمفضلة',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 14, bottom: 100),
      itemCount: favoriteStories.length,
      itemBuilder: (context, index) {
        final story = favoriteStories[index];
        final isCompleted = _completed.contains(story.id);
        return _buildStoryCard(story, true, isCompleted);
      },
    );
  }

  Widget _buildStoryCard(SeerahStory story, bool isFavorite, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: _kGoldSoft,
          highlightColor: _kGoldSoft.withValues(alpha: .5),
          onTap: () async {
            final result = await Navigator.push(
              context,
              InstantPageRoute(
                builder: (context) => SeerahDetailScreen(story: story),
              ),
            );
            if (result == true) {
              _markAsCompleted(story.id);
            }
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الأيقونة (على اليمين في RTL)
                Container(
                  width: 52,
                  height: 52,
                  margin: const EdgeInsetsDirectional.only(start: 6, top: 2),
                  decoration: const BoxDecoration(
                    color: _kGoldSoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(story.emoji, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _kInk,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        story.subtitle,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: _kInkSoft,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildChip(Icons.menu_book_rounded, story.category,
                              _kGold),
                          _buildChip(Icons.location_on_outlined, story.location,
                              _kGreen),
                          _buildChip(Icons.schedule_rounded,
                              '${story.readingMinutes} دقائق', _kInkSoft),
                          if (isCompleted)
                            _buildChip(Icons.check_circle_outline_rounded,
                                'مكتملة', const Color(0xFF4F7A5A)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite ? const Color(0xFFB5523B) : _kInkSoft,
                    size: 24,
                  ),
                  onPressed: () => _toggleFavorite(story.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressFAB() {
    final completedCount = _completed.length;
    final totalCount = SeerahData.stories.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return FloatingActionButton.extended(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: _kPaper,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: _kBorder),
              ),
              title: const Text(
                'إحصائيات التقدم',
                style: TextStyle(color: _kInk, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أكملت $completedCount من $totalCount قصة',
                    style: const TextStyle(fontSize: 16, color: _kInk),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: _kBorder,
                      valueColor: const AlwaysStoppedAnimation(_kGold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _kGold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('حسناً', style: TextStyle(color: _kGold)),
                ),
              ],
            ),
          ),
        );
      },
      backgroundColor: _kCard,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: _kBorder),
      ),
      icon: const Icon(Icons.auto_stories_rounded, color: _kGold),
      label: Text(
        '$completedCount/$totalCount',
        style: const TextStyle(color: _kInk, fontWeight: FontWeight.bold),
      ),
    );
  }
}
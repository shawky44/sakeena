// lib/screens/seerah_screen.dart
import 'package:flutter/material.dart';
import '../models/seerah_story.dart';
import '../data/seerah_data.dart';
import '../services/storage_service.dart';
import 'seerah_detail_screen.dart';

class SeerahScreen extends StatefulWidget {
  const SeerahScreen({super.key});

  @override
  State<SeerahScreen> createState() => _SeerahScreenState();
}

class _SeerahScreenState extends State<SeerahScreen> with SingleTickerProviderStateMixin {
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

  // تحميل البيانات المحفوظة
  Future<void> _loadData() async {
    final favorites = await StorageService.getFavorites();
    final completed = await StorageService.getCompleted();
    
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
          final matchesCategory = _selectedCategory == 'الكل' ||
              story.category == _selectedCategory;
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
    // حفظ فوري
    await StorageService.saveFavorites(_favorites);
  }

  Future<void> _markAsCompleted(int id) async {
    setState(() {
      _completed.add(id);
    });
    // حفظ فوري
    await StorageService.saveCompleted(_completed);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF159895),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
              _buildTabBar(),
              _buildSearchBar(),
              _buildCategoryChips(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStoriesList(),
                    _buildFavoritesList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildProgressFAB(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'قصص الصحابة والأنبياء',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'رحلة في حياة خير البشر ﷺ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(25),
      ),
        child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(3),
        labelPadding: const EdgeInsets.symmetric(horizontal: 20),
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: const Color(0xFF1A5F7A),
        unselectedLabelColor: Colors.white,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'جميع القصص'),
          Tab(text: 'المفضلة'),
        ],
      ),

    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        onChanged: _filterStories,
        decoration: InputDecoration(
          hintText: 'ابحث في القصص...',
          hintTextDirection: TextDirection.rtl,
          prefixIcon: const Icon(Icons.search, color: Color(0xFF1A5F7A)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterStories('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: SeerahData.categories.length,
        itemBuilder: (context, index) {
          final category = SeerahData.categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () => _selectCategory(category),
            child: Container(
              margin: const EdgeInsets.only(left: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Colors.white, Colors.white],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: .2),
                          Colors.white.withValues(alpha: .1),
                        ],
                      ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: .3),
                  width: 2,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF1A5F7A) : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoriesList() {
    if (_filteredStories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.white.withValues(alpha: .5)),
            const SizedBox(height: 20),
            Text(
              'لا توجد قصص',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white.withValues(alpha: .7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 15, bottom: 100),
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
    final favoriteStories = SeerahData.stories.where((s) => _favorites.contains(s.id)).toList();

    if (favoriteStories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.white.withValues(alpha: .5)),
            const SizedBox(height: 20),
            Text(
              'لا توجد قصص مفضلة',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white.withValues(alpha: .7),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'اضغط على ♡ لإضافة قصص للمفضلة',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: .5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 15, bottom: 100),
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SeerahDetailScreen(story: story),
              ),
            );
            if (result == true) {
              _markAsCompleted(story.id);
            }
          },
          child: Stack(
            children: [
              // Completed Badge
              if (isCompleted)
                Positioned(
                  top: 15,
                  left: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'مكتملة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey,
                            size: 28,
                          ),
                          onPressed: () => _toggleFavorite(story.id),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    story.emoji,
                                    style: const TextStyle(fontSize: 30),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      story.title,
                                      textDirection: TextDirection.rtl,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A5F7A),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                story.subtitle,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Divider(),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildInfoChip(
                          Icons.location_on,
                          story.location,
                          const Color(0xFF1A5F7A),
                        ),
                        const SizedBox(width: 10),
                        _buildInfoChip(
                          Icons.access_time,
                          '${story.readingMinutes} دقائق',
                          const Color(0xFF159895),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF57C5B6).withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        story.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1A5F7A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 5),
          Icon(icon, size: 14, color: color),
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
          builder: (context) => AlertDialog(
            title: const Text('إحصائيات التقدم', textDirection: TextDirection.rtl),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'أكملت $completedCount من $totalCount قصة',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 15),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF159895)),
                ),
                const SizedBox(height: 10),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF159895),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      },
      backgroundColor: Colors.white,
      icon: const Icon(Icons.trending_up, color: Color(0xFF1A5F7A)),
      label: Text(
        '$completedCount/$totalCount',
        style: const TextStyle(
          color: Color(0xFF1A5F7A),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
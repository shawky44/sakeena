// lib/screens/arbaeen_screen.dart
import 'package:flutter/material.dart';
import '../models/hadith_model.dart';
import '../data/hadith_data.dart';
import '../utils/instant_page_route.dart';
import 'hadith_detail_screen.dart';

class ArbaeenScreen extends StatefulWidget {
  const ArbaeenScreen({super.key});

  @override
  State<ArbaeenScreen> createState() => _ArbaeenScreenState();
}

class _ArbaeenScreenState extends State<ArbaeenScreen> {
  List<Hadith> _filteredHadiths = [];
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _favorites = {};

  @override
  void initState() {
    super.initState();
    _filteredHadiths = HadithData.arbaeen;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterHadiths(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredHadiths = HadithData.arbaeen;
      } else {
        _filteredHadiths = HadithData.arbaeen.where((hadith) {
          return hadith.arabicText.contains(query) ||
                 hadith.keywords.any((keyword) => keyword.contains(query)) ||
                 hadith.number.toString().contains(query);
        }).toList();
      }
    });
  }

  void _toggleFavorite(int number) {
    setState(() {
      if (_favorites.contains(number)) {
        _favorites.remove(number);
      } else {
        _favorites.add(number);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E7D6E),
              Color(0xFF4A9B8E),
              Color(0xFF6BB9AD),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(child: _buildHadithList()),
            ],
          ),
        ),
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
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'الأربعون النووية',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'للإمام النووي رحمه الله',
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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        onChanged: _filterHadiths,
        decoration: InputDecoration(
          hintText: 'ابحث في الأحاديث...',
          hintTextDirection: TextDirection.rtl,
          prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D6E)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterHadiths('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildHadithList() {
    if (_filteredHadiths.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.white.withValues(alpha: .5)),
            const SizedBox(height: 20),
            Text(
              'لا توجد نتائج',
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
      padding: const EdgeInsets.only(bottom: 100, top: 10),
      itemCount: _filteredHadiths.length,
      itemBuilder: (context, index) {
        final hadith = _filteredHadiths[index];
        final isFavorite = _favorites.contains(hadith.number);

        return _buildHadithCard(hadith, isFavorite);
      },
    );
  }

  Widget _buildHadithCard(Hadith hadith, bool isFavorite) {
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
          onTap: () {
            Navigator.push(
              context,
              InstantPageRoute(
                builder: (context) => HadithDetailScreen(hadith: hadith),
              ),
            );
          },
          child: Padding(
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
                      ),
                      onPressed: () => _toggleFavorite(hadith.number),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E7D6E), Color(0xFF4A9B8E)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'الحديث ${hadith.number}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  hadith.arabicText.length > 150
                      ? '${hadith.arabicText.substring(0, 150)}...'
                      : hadith.arabicText,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    color: Color(0xFF2C3E50),
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      hadith.narrator,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: hadith.keywords.take(3).map((keyword) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D6E).withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        keyword,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E7D6E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

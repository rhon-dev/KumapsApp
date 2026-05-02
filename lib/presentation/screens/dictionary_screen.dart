import 'package:flutter/material.dart';
import 'package:kumpas/theme/app_theme.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Greetings',
    'Numbers',
    'Emotions',
    'Daily Activities',
    'Family',
    'Food',
  ];

  final List<Map<String, String>> dictionaryItems = [
    {
      'word': 'Hello',
      'category': 'Greetings',
      'pronunciation': 'Hag-AH-pap',
    },
    {
      'word': 'Thank You',
      'category': 'Greetings',
      'pronunciation': 'MAR-sah-ming POW',
    },
    {
      'word': 'One',
      'category': 'Numbers',
      'pronunciation': 'Eee-SAH',
    },
    {
      'word': 'Two',
      'category': 'Numbers',
      'pronunciation': 'Dah-WAH',
    },
    {
      'word': 'Happy',
      'category': 'Emotions',
      'pronunciation': 'Mah-YAH',
    },
    {
      'word': 'Sad',
      'category': 'Emotions',
      'pronunciation': 'Loon-GOH',
    },
  ];

  List<Map<String, String>> get filteredItems {
    return dictionaryItems.where((item) {
      final matchesSearch =
          item['word']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item['pronunciation']!
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || item['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dictionary'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search signs...',
                    hintStyle: TextStyle(color: AppColors.disabled),
                    border: InputBorder.none,
                    prefixIcon:
                        Icon(Icons.search, color: AppColors.textSecondary),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category filter
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        onSelected: (selected) {
                          setState(() => _selectedCategory = category);
                        },
                        label: Text(category),
                        selected: isSelected,
                        backgroundColor: Colors.transparent,
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.borderLight,
                          width: isSelected ? 2 : 1,
                        ),
                        labelStyle: AppTypography.labelSmall(context).copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Dictionary items
              if (filteredItems.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off_outlined,
                          size: 48,
                          color: AppColors.disabled,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No signs found',
                          style: AppTypography.bodyMedium(context).copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: filteredItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDictionaryItem(context, item),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDictionaryItem(
    BuildContext context,
    Map<String, String> item,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          // Video/Sign thumbnail
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.videocam_outlined,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['word']!,
                  style: AppTypography.titleMedium(context),
                ),
                const SizedBox(height: 4),
                Text(
                  item['pronunciation']!,
                  style: AppTypography.labelSmall(context).copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 6),
                Chip(
                  label: Text(
                    item['category']!,
                    style: AppTypography.labelSmall(context).copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  padding: EdgeInsets.zero,
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
              ],
            ),
          ),

          // Action button
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.play_arrow_outlined),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

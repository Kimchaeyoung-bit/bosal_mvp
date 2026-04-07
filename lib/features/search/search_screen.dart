import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_shadow.dart';
import '../../providers/search_provider.dart';
import '../../providers/region_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/bosal_provider.dart';
import '../../features/home/widgets/ad_banner_placeholder.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recentSearches = ref.watch(recentSearchesProvider);
    final selectedRegions = ref.watch(selectedSubRegionsProvider);
    final categories = ref.watch(categoriesProvider);
    final recentlyViewed = ref.watch(recentlyViewedBosalsProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search header
          Container(
            padding: EdgeInsets.fromLTRB(8, topPadding + 8, 20, 12),
            color: AppColors.surface,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 24),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded,
                            color: AppColors.textSub, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            style: AppTextStyles.body,
                            decoration: InputDecoration(
                              hintText: '궁금한 분야, 보살 이름을 검색해보세요.',
                              hintStyle: AppTextStyles.body
                                  .copyWith(color: AppColors.textSub),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (query) {
                              if (query.trim().isNotEmpty) {
                                ref
                                    .read(recentSearchesProvider.notifier)
                                    .add(query.trim());
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Region filter chips
                  if (selectedRegions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          _FilterChip(
                            label: '지역 ${selectedRegions.length}개',
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),

                  // Recent searches
                  if (recentSearches.isNotEmpty) ...[
                    Text('최근 검색어', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: recentSearches.map((term) {
                        return GestureDetector(
                          onTap: () {
                            _controller.text = term;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(term, style: AppTextStyles.chip),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Categories
                  Text('관심 카테고리', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return GestureDetector(
                        onTap: () {
                          ref.read(selectedCategoryProvider.notifier).state =
                              cat;
                          context.push('/bosal-list?category=${cat.id}');
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: appShadow,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(cat.icon,
                                  size: 28, color: AppColors.primary),
                              const SizedBox(height: 6),
                              Text(cat.name, style: AppTextStyles.category),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  const AdBannerPlaceholder(),

                  // Recently viewed
                  if (recentlyViewed.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('최근 본 보살', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 12),
                    ...recentlyViewed.map((bosal) {
                      return GestureDetector(
                        onTap: () => context.push('/bosal/${bosal.id}'),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: appShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_rounded,
                                    color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Text(bosal.name,
                                  style: AppTextStyles.cardTitle),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  const _FilterChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.chip.copyWith(color: color),
      ),
    );
  }
}

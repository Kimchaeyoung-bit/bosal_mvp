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
            padding: EdgeInsets.fromLTRB(8, topPadding + 8, 16, 14),
            color: AppColors.surface,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 24),
                ),
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(14),
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
                        if (_controller.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _controller.clear();
                              setState(() {});
                            },
                            child: const Icon(Icons.cancel_rounded,
                                color: AppColors.textSub, size: 18),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Region filter chip row
          if (selectedRegions.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: GestureDetector(
                onTap: () => context.push('/region-select'),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '지역 ${selectedRegions.length}개',
                            style: AppTextStyles.chip
                                .copyWith(color: AppColors.primary),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recent searches
                  if (recentSearches.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('최근 검색어',
                            style: AppTextStyles.sectionTitle
                                .copyWith(fontSize: 15)),
                        GestureDetector(
                          onTap: () => ref
                              .read(recentSearchesProvider.notifier)
                              .clear(),
                          child: Text('전체삭제',
                              style: AppTextStyles.moreLink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(term, style: AppTextStyles.chip),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => ref
                                      .read(recentSearchesProvider.notifier)
                                      .remove(term),
                                  child: const Icon(Icons.close_rounded,
                                      size: 13, color: AppColors.textSub),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Categories
                  Text('관심 카테고리',
                      style:
                          AppTextStyles.sectionTitle.copyWith(fontSize: 15)),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.95,
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
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(cat.icon,
                                  size: 28, color: AppColors.primary),
                            ),
                            const SizedBox(height: 8),
                            Text(cat.name,
                                style: AppTextStyles.category
                                    .copyWith(fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),
                  const AdBannerPlaceholder(),

                  // Recently viewed
                  if (recentlyViewed.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text('최근 본 보살',
                        style: AppTextStyles.sectionTitle
                            .copyWith(fontSize: 15)),
                    const SizedBox(height: 14),
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
                                width: 52,
                                height: 52,
                                decoration: const BoxDecoration(
                                  color: AppColors.primarySoft,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_rounded,
                                    color: AppColors.primary, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(bosal.name,
                                        style: AppTextStyles.cardTitle),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded,
                                            size: 12, color: AppColors.accent),
                                        const SizedBox(width: 2),
                                        Text('${bosal.rating}',
                                            style: AppTextStyles.small.copyWith(
                                                color: AppColors.text,
                                                fontWeight: FontWeight.w600)),
                                        Text(' (${bosal.reviewCount})',
                                            style: AppTextStyles.small),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.textSub, size: 20),
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

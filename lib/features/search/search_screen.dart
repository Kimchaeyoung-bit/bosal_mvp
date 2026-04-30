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
import '../../data/models/bosal.dart';
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
      ref.read(searchQueryProvider.notifier).state = '';
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _applyQuery(String raw) {
    final trimmed = raw.trim();
    ref.read(searchQueryProvider.notifier).state = trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final recentSearches = ref.watch(recentSearchesProvider);
    final selectedRegions = ref.watch(selectedSubRegionsProvider);
    final categories = ref.watch(categoriesProvider);
    final recentlyViewed = ref.watch(recentlyViewedBosalsProvider);
    final query = ref.watch(searchQueryProvider);
    final isSearching = query.isNotEmpty;
    final List<Bosal> results =
        isSearching ? ref.watch(filteredBosalsProvider) : const [];
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search header
          Container(
            padding: EdgeInsets.fromLTRB(8, topPadding + 8, 16, 14),
            color: AppColors.surface.withValues(alpha: 0.9),
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
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: '궁금한 분야, 보살 이름을 검색해보세요.',
                              hintStyle: AppTextStyles.body
                                  .copyWith(color: AppColors.textSub),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) {
                              _applyQuery(value);
                              setState(() {});
                            },
                            onSubmitted: (value) {
                              final trimmed = value.trim();
                              _applyQuery(trimmed);
                              if (trimmed.isNotEmpty) {
                                ref
                                    .read(recentSearchesProvider.notifier)
                                    .add(trimmed);
                              }
                            },
                          ),
                        ),
                        if (_controller.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _controller.clear();
                              _applyQuery('');
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
            child: isSearching
                ? _SearchResults(query: query, results: results)
                : SingleChildScrollView(
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
                            _applyQuery(term);
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.75),
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
                  const SizedBox(height: 4),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: categories.length > 7 ? 8 : categories.length,
                    itemBuilder: (context, index) {
                      if (index == 7) {
                        return GestureDetector(
                          onTap: () => context.push('/other-categories'),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: appShadow,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.more_horiz_rounded,
                                    size: 22, color: AppColors.text),
                                const SizedBox(height: 6),
                                Text(
                                  '기타',
                                  style: AppTextStyles.category.copyWith(
                                    fontSize: 11,
                                    color: AppColors.text,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final cat = categories[index];
                      return GestureDetector(
                        onTap: () {
                          ref.read(selectedCategoryProvider.notifier).state =
                              cat;
                          context.push('/bosal-list?category=${cat.id}');
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: appShadow,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(cat.icon,
                                  size: 22, color: AppColors.text),
                              const SizedBox(height: 6),
                              Text(
                                cat.name,
                                style: AppTextStyles.category.copyWith(
                                  fontSize: 11,
                                  color: AppColors.text,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
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
                            color: AppColors.surface.withValues(alpha: 0.75),
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
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  final String query;
  final List<Bosal> results;

  const _SearchResults({required this.query, required this.results});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Text(
              '"$query" 검색 결과가 없습니다',
              style: AppTextStyles.body.copyWith(color: AppColors.textSub),
            ),
            const SizedBox(height: 6),
            Text('다른 키워드를 입력해보세요', style: AppTextStyles.small),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final bosal = results[index];
        return GestureDetector(
          onTap: () {
            ref.read(recentlyViewedProvider.notifier).add(bosal.id);
            context.push('/bosal/${bosal.id}');
          },
          child: Container(
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
                      Row(
                        children: [
                          Text(bosal.name, style: AppTextStyles.cardTitle),
                          const SizedBox(width: 6),
                          Text('경력 ${bosal.experienceYears}년',
                              style: AppTextStyles.small),
                        ],
                      ),
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
                      if (bosal.features.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: bosal.features
                              .take(2)
                              .map((f) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(f, style: AppTextStyles.tag),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSub, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}


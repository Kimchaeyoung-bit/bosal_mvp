import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/category_provider.dart';
import '../../providers/region_provider.dart';
import 'widgets/home_header.dart';
import 'widgets/popular_bosal_list.dart';
import 'widgets/category_grid.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 + 검색
            const HomeHeader(),
            const SizedBox(height: 20),

            // 카테고리 수평 칩
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = selectedCategory?.id == cat.id ||
                      (selectedCategory == null && cat.id == 'all');
                  return GestureDetector(
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).state =
                          cat.id == 'all' ? null : cat;
                      if (cat.id != 'all') {
                        context.push('/bosal-list?category=${cat.id}');
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : AppColors.border,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Icon(cat.icon,
                              size: 13,
                              color: isSelected
                                  ? AppColors.black
                                  : AppColors.textSub),
                          const SizedBox(width: 5),
                          Text(
                            cat.name,
                            style: AppTextStyles.caption.copyWith(
                              color: isSelected
                                  ? AppColors.black
                                  : AppColors.textSub,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // 인기 보살 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('인기 보살', style: AppTextStyles.sectionTitle),
                  GestureDetector(
                    onTap: () => context.push('/bosal-list'),
                    child: Text('전체보기', style: AppTextStyles.moreLink),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const PopularBosalList(),
            const SizedBox(height: 24),

            // 지도로 보살 찾기 — 심플 바 스타일
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => context.go('/region-tab'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '지도로 보살 찾기',
                              style: AppTextStyles.bodyBold
                                  .copyWith(color: AppColors.white),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '내 주변 보살 위치 확인',
                              style: AppTextStyles.small.copyWith(
                                  color: Colors.white.withOpacity(0.55)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: AppColors.black, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // 지역 선택
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _RegionBar(onTap: () => context.push('/region-select')),
            ),
            const SizedBox(height: 28),

            // 상담 분야 그리드
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('상담 분야', style: AppTextStyles.sectionTitle),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CategoryGrid(
                onCategoryTap: (category) {
                  ref.read(selectedCategoryProvider.notifier).state = category;
                  context.push('/bosal-list?category=${category.id}');
                },
              ),
            ),
            const SizedBox(height: 28),

            // 광고 배너
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _AdBanner(),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _RegionBar extends ConsumerWidget {
  final VoidCallback onTap;
  const _RegionBar({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRegions = ref.watch(selectedSubRegionsProvider);
    final hasSelection = selectedRegions.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasSelection ? AppColors.accent : AppColors.border,
            width: hasSelection ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.place_rounded,
              color: hasSelection ? AppColors.text : AppColors.textSub,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasSelection
                    ? selectedRegions.map((r) => r.name).join(', ')
                    : '원하는 지역을 선택해주세요',
                style: AppTextStyles.body.copyWith(
                  color: hasSelection ? AppColors.text : AppColors.textSub,
                  fontWeight:
                      hasSelection ? FontWeight.w600 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSub,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.black, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('첫 상담 특별 할인',
                  style: AppTextStyles.bodyBold
                      .copyWith(color: AppColors.black)),
              const SizedBox(height: 3),
              Text('신규 회원 최대 40% 할인',
                  style: AppTextStyles.small
                      .copyWith(color: Colors.black.withOpacity(0.55))),
            ],
          ),
          const Spacer(),
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward_rounded,
                color: AppColors.black, size: 16),
          ),
        ],
      ),
    );
  }
}

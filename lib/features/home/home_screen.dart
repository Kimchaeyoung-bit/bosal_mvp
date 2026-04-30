import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/category_provider.dart';
import '../../providers/region_provider.dart';
import '../../shared/widgets/app_shadow.dart';
import 'widgets/home_header.dart';
import 'widgets/top_actions_row.dart';
import 'widgets/category_grid.dart';
import 'widgets/ad_banner_placeholder.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeHeader(),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _RegionSearchCard(
                  onRegionTap: () => context.push('/region-select'),
                  onSearchTap: () => context.push('/search'),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TopActionsRow(
                  onNearbyTap: () => context.go('/region-tab'),
                  onBosalTap: (id) => context.push('/bosal/$id'),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('관심 카테고리', style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 52),
                child: CategoryGrid(
                  onCategoryTap: (category) {
                    ref.read(selectedCategoryProvider.notifier).state = category;
                    context.push('/bosal-list?category=${category.id}');
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: AdBannerPlaceholder(),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegionSearchCard extends ConsumerWidget {
  final VoidCallback onRegionTap;
  final VoidCallback onSearchTap;

  const _RegionSearchCard({
    required this.onRegionTap,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRegions = ref.watch(selectedSubRegionsProvider);
    final hasSelection = selectedRegions.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        boxShadow: appShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 지역 선택 행
          GestureDetector(
            onTap: onRegionTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    color: hasSelection ? AppColors.primary : AppColors.textSub,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasSelection
                          ? selectedRegions.map((r) => r.name).join(', ')
                          : '원하는 지역을 선택해주세요...',
                      style: AppTextStyles.body.copyWith(
                        color: hasSelection ? AppColors.text : AppColors.textSub,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSub, size: 20),
                ],
              ),
            ),
          ),
          // 구분선
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          // 검색 행
          GestureDetector(
            onTap: onSearchTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: AppColors.textSub, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    '궁금한 분야, 보살 이름을 검색해보세요.',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSub),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

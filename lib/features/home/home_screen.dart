import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/category_provider.dart';
import 'widgets/home_header.dart';
import 'widgets/top_actions_row.dart';
import 'widgets/region_selector_button.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/category_grid.dart';
import 'widgets/ad_banner_placeholder.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeHeader(),
            Transform.translate(
              offset: const Offset(0, -18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TopActionsRow(
                  onNearbyTap: () => context.push('/region-select'),
                  onBosalTap: (id) => context.push('/bosal/$id'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
              child: RegionSelectorButton(
                onTap: () => context.push('/region-select'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: HomeSearchBar(
                onTap: () => context.push('/search'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('관심 카테고리', style: AppTextStyles.sectionTitle),
                  GestureDetector(
                    onTap: () => context.push('/bosal-list'),
                    child: Text('전체보기 ›', style: AppTextStyles.moreLink),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CategoryGrid(
                onCategoryTap: (category) {
                  ref.read(selectedCategoryProvider.notifier).state = category;
                  context.push('/bosal-list?category=${category.id}');
                },
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: AdBannerPlaceholder(),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/category_provider.dart';
import '../../shared/widgets/app_shadow.dart';
import 'widgets/home_header.dart';
import 'widgets/mascot_card.dart';
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
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: MascotCard(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _NearbyBosalButton(
                onTap: () => context.push('/region-select'),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: RegionSelectorButton(
                onTap: () => context.push('/region-select'),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: HomeSearchBar(
                onTap: () => context.push('/search'),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('관심 카테고리', style: AppTextStyles.sectionTitle),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CategoryGrid(
                onCategoryTap: (category) {
                  ref.read(selectedCategoryProvider.notifier).state = category;
                  context.push('/bosal-list?category=${category.id}');
                },
              ),
            ),
            const SizedBox(height: 24),
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

class _NearbyBosalButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NearbyBosalButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(16),
          boxShadow: appShadow,
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              '내 주변 보살들',
              style: AppTextStyles.cardLabel.copyWith(color: AppColors.primary),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/region_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../shared/widgets/app_shadow.dart';
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
              const _GreetingHeader(),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _RegionSearchCard(
                  onRegionTap: () => context.push('/region-select?redirect=map'),
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
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: appShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('관심 카테고리', style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
                      const SizedBox(height: 10),
                      CategoryGrid(
                        onCategoryTap: (category) {
                          ref.read(selectedCategoryProvider.notifier).state = category;
                          context.push('/bosal-list?category=${category.id}');
                        },
                      ),
                    ],
                  ),
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

class _GreetingHeader extends ConsumerWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    final user = ref.watch(authProvider);
    final unread = ref.watch(unreadCountProvider);

    return Stack(
      children: [
        // 본문: 좌측 텍스트 + 우측 이미지
        Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 62, 0, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user != null ? '${user.displayName}, 안녕하세요!' : '안녕하세요!',
                        style: AppTextStyles.sectionTitle.copyWith(fontSize: 14),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '오늘 어떤 고민이 있으신가요?',
                        style: AppTextStyles.body.copyWith(color: AppColors.textSub),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 28),
                      GestureDetector(
                        onTap: () => context.push('/fortune'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '오늘의 운세보기',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 30, top: 30),
                child: Image.asset(
                  'assets/images/logo_real.png',
                  width: 130,
                  height: 130,
                  fit: BoxFit.contain,
                  opacity: const AlwaysStoppedAnimation(0.9),
                ),
              ),
            ],
          ),
        ),
        // 강남보살 텍스트: 좌측 상단
        Positioned(
          top: topPadding + 8,
          left: 26,
          child: Text(
            '강남보살',
            style: GoogleFonts.doHyeon(
              fontSize: 22,
              color: AppColors.primary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        // 벨 아이콘: 상태바 바로 아래 우측 최상단
        Positioned(
          top: topPadding + 4,
          right: 8,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: const Icon(Icons.notifications_outlined, size: 28, color: AppColors.text),
              ),
              if (unread > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
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
          const Divider(height: 1, thickness: 1, color: AppColors.border),
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

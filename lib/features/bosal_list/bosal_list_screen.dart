import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_shadow.dart';
import '../../providers/bosal_provider.dart';
import '../../providers/region_provider.dart';
import '../../providers/category_provider.dart';

class BosalListScreen extends ConsumerWidget {
  final String? categoryId;
  const BosalListScreen({super.key, this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bosals = ref.watch(filteredBosalsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedRegions = ref.watch(selectedSubRegionsProvider);

    final title = selectedCategory?.name ?? '전체';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(title),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Region filter chip
          if (selectedRegions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: GestureDetector(
                onTap: () => context.push('/region-select'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '지역 ${selectedRegions.length}개',
                        style:
                            AppTextStyles.chip.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Bosal list
          Expanded(
            child: bosals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded,
                            size: 48, color: AppColors.textSub),
                        const SizedBox(height: 12),
                        Text(
                          '조건에 맞는 보살이 없습니다',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textSub),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: bosals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final bosal = bosals[index];
                      return GestureDetector(
                        onTap: () {
                          ref
                              .read(recentlyViewedProvider.notifier)
                              .add(bosal.id);
                          context.push('/bosal/${bosal.id}');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: appShadow,
                          ),
                          child: Row(
                            children: [
                              // Profile image placeholder
                              Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: AppColors.primarySoft,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_rounded,
                                    color: AppColors.primary, size: 32),
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
                                            size: 14, color: AppColors.accent),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${bosal.rating}',
                                          style: AppTextStyles.small.copyWith(
                                              color: AppColors.text,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          ' (${bosal.reviewCount})',
                                          style: AppTextStyles.small,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.textSub),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

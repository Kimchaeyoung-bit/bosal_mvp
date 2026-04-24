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
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            color: AppColors.surface,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/region-select'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selectedRegions.isNotEmpty
                          ? AppColors.primarySoft
                          : AppColors.bg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selectedRegions.isNotEmpty
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.place_rounded,
                          size: 14,
                          color: selectedRegions.isNotEmpty
                              ? AppColors.primary
                              : AppColors.textSub,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          selectedRegions.isEmpty
                              ? '지역 선택'
                              : '지역 ${selectedRegions.length}개',
                          style: AppTextStyles.chip.copyWith(
                            color: selectedRegions.isNotEmpty
                                ? AppColors.primary
                                : AppColors.textSub,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: selectedRegions.isNotEmpty
                              ? AppColors.primary
                              : AppColors.textSub,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '총 ${bosals.length}명',
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),

          Container(height: 8, color: AppColors.bg),

          // Bosal list
          Expanded(
            child: bosals.isEmpty
                ? Center(
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
                          '조건에 맞는 보살이 없습니다',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textSub),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '다른 지역이나 카테고리를 선택해보세요',
                          style: AppTextStyles.small,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: appShadow,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile image
                              Stack(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.primarySoft,
                                          Color(0xFFE5D7F5),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person_rounded,
                                        color: AppColors.primary, size: 36),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        border: Border.all(
                                            color: AppColors.surface,
                                            width: 1.5),
                                      ),
                                      child: const Text(
                                        '인증',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(bosal.name,
                                            style: AppTextStyles.cardTitle),
                                        const SizedBox(width: 6),
                                        Text(
                                          '경력 ${bosal.experienceYears}년',
                                          style: AppTextStyles.small,
                                        ),
                                      ],
                                    ),
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
                                              fontWeight: FontWeight.w700),
                                        ),
                                        Text(' (${bosal.reviewCount})',
                                            style: AppTextStyles.small),
                                        const SizedBox(width: 8),
                                        const Icon(
                                            Icons.favorite_rounded,
                                            size: 11,
                                            color: AppColors.primary),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${bosal.consultRequests}명 상담',
                                          style: AppTextStyles.small,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: bosal.features
                                          .take(2)
                                          .map((f) => Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 8,
                                                    vertical: 3),
                                                decoration: BoxDecoration(
                                                  color:
                                                      AppColors.primarySoft,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  f,
                                                  style: AppTextStyles.tag,
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
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

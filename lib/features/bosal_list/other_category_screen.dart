import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_shadow.dart';
import '../../providers/bosal_provider.dart';
import '../../providers/category_provider.dart';
import '../../data/models/category.dart';

class OtherCategoryScreen extends ConsumerStatefulWidget {
  const OtherCategoryScreen({super.key});

  @override
  ConsumerState<OtherCategoryScreen> createState() =>
      _OtherCategoryScreenState();
}

class _OtherCategoryScreenState extends ConsumerState<OtherCategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedCategoryProvider.notifier).state = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allCategories = ref.watch(categoriesProvider);
    final otherCategories = allCategories.skip(9).toList();
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final bosals = ref.watch(filteredBosalsProvider);

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
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: appShadow,
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            size: 20, color: AppColors.text),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('기타 카테고리',
                        style: AppTextStyles.sectionTitle
                            .copyWith(fontSize: 17)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 카테고리 칩
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: otherCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = otherCategories[index];
                    final isSelected = selectedCategory?.id == cat.id;
                    return _CategoryChip(
                      category: cat,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(selectedCategoryProvider.notifier).state =
                            isSelected ? null : cat;
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // 구분선 + 카운트
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.7),
                ),
                child: Row(
                  children: [
                    Text(
                      selectedCategory != null
                          ? '${selectedCategory.name} 보살'
                          : '카테고리를 선택하면 보살을 볼 수 있어요',
                      style: AppTextStyles.small.copyWith(
                        color: selectedCategory != null
                            ? AppColors.text
                            : AppColors.textSub,
                      ),
                    ),
                    if (selectedCategory != null) ...[
                      const Spacer(),
                      Text('총 ${bosals.length}명',
                          style: AppTextStyles.small),
                    ],
                  ],
                ),
              ),

              // 보살 목록
              Expanded(
                child: selectedCategory == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.surface
                                    .withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                                boxShadow: appShadow,
                              ),
                              child: const Icon(Icons.touch_app_outlined,
                                  size: 32, color: AppColors.textSub),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '위에서 카테고리를 선택해주세요',
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.textSub),
                            ),
                          ],
                        ),
                      )
                    : bosals.isEmpty
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
                                  child: const Icon(
                                      Icons.search_off_rounded,
                                      size: 36,
                                      color: AppColors.primary),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  '해당 카테고리의 보살이 없습니다',
                                  style: AppTextStyles.body
                                      .copyWith(color: AppColors.textSub),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 20),
                            itemCount: bosals.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
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
                                    color: AppColors.surface
                                        .withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: appShadow,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Stack(
                                        children: [
                                          Container(
                                            width: 64,
                                            height: 64,
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  AppColors.primarySoft,
                                                  Color(0xFFE5D7F5),
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                                Icons.person_rounded,
                                                color: AppColors.primary,
                                                size: 32),
                                          ),
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 1),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(bosal.name,
                                                    style: AppTextStyles
                                                        .cardTitle),
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
                                                const Icon(
                                                    Icons.star_rounded,
                                                    size: 14,
                                                    color: AppColors.accent),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${bosal.rating}',
                                                  style: AppTextStyles.small
                                                      .copyWith(
                                                          color: AppColors.text,
                                                          fontWeight:
                                                              FontWeight.w700),
                                                ),
                                                Text(' (${bosal.reviewCount})',
                                                    style:
                                                        AppTextStyles.small),
                                                const SizedBox(width: 8),
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
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 3),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppColors
                                                              .primarySoft,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: Text(f,
                                                            style:
                                                                AppTextStyles
                                                                    .tag),
                                                      ))
                                                  .toList(),
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
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          boxShadow: appShadow,
          border: isSelected
              ? null
              : Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 15,
              color: isSelected ? AppColors.white : AppColors.text,
            ),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: AppTextStyles.chip.copyWith(
                color: isSelected ? AppColors.white : AppColors.text,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

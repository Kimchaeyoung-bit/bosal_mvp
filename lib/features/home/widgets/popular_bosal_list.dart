import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/bosal_provider.dart';

class PopularBosalList extends ConsumerWidget {
  const PopularBosalList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bosals = ref.watch(allBosalsProvider);
    final sorted = [...bosals]..sort((a, b) => b.rating.compareTo(a.rating));
    final top = sorted.take(6).toList();

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: top.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final bosal = top[index];
          return GestureDetector(
            onTap: () => context.push('/bosal/${bosal.id}'),
            child: Container(
              width: 130,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 상단 아바타 영역
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: index.isEven
                          ? AppColors.accent.withValues(alpha:0.15)
                          : AppColors.primarySoft,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index.isEven
                                  ? AppColors.accent
                                  : AppColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: (index.isEven
                                          ? AppColors.accent
                                          : AppColors.primary)
                                      .withValues(alpha:0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                bosal.name[0],
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: index.isEven
                                      ? AppColors.black
                                      : AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 인기 뱃지
                        if (index == 0)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '인기',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 하단 정보
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bosal.name,
                            style: AppTextStyles.smallBold
                                .copyWith(color: AppColors.text),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppColors.accent, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                bosal.rating.toStringAsFixed(1),
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_shadow.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bosal_provider.dart';

class BosalReviewsScreen extends ConsumerWidget {
  const BosalReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final bosals = ref.watch(allBosalsProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    final myBosal = user?.bosalId != null
        ? bosals.where((b) => b.id == user!.bosalId).firstOrNull
        : null;

    final mockReviews = [
      _ReviewData('김**', 5.0, '정말 정확하고 따뜻한 상담이었어요', '2일 전'),
      _ReviewData('이**', 4.5, '현실적인 조언 감사합니다', '5일 전'),
      _ReviewData('박**', 5.0, '연애 고민 해결에 큰 도움이 됐어요', '1주 전'),
      _ReviewData('최**', 4.0, '다음에도 또 방문하고 싶어요', '2주 전'),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 16),
            color: AppColors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('리뷰 관리',
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 20)),
                Text('총 ${myBosal?.reviewCount ?? 0}개',
                    style: AppTextStyles.small),
              ],
            ),
          ),

          // Stats
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.accent, size: 28),
                          const SizedBox(width: 4),
                          Text(
                            '${myBosal?.rating ?? 0}',
                            style: AppTextStyles.priceDiscount
                                .copyWith(fontSize: 28),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('평균 별점', style: AppTextStyles.small),
                    ],
                  ),
                ),
                Container(width: 1, height: 48, color: AppColors.border),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${myBosal?.reviewCount ?? 0}',
                        style:
                            AppTextStyles.priceDiscount.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 4),
                      Text('전체 리뷰', style: AppTextStyles.small),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Review list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: mockReviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final review = mockReviews[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: appShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(review.name,
                                    style: AppTextStyles.bodyBold),
                                Row(
                                  children: [
                                    ...List.generate(
                                      5,
                                      (i) => Icon(
                                        i < review.rating.floor()
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        size: 14,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(review.date,
                                        style: AppTextStyles.small),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(review.content, style: AppTextStyles.body),
                    ],
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

class _ReviewData {
  final String name;
  final double rating;
  final String content;
  final String date;
  const _ReviewData(this.name, this.rating, this.content, this.date);
}

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
      _ReviewData('김**', 5.0, '정말 정확하고 따뜻한 상담이었어요. 고민이 많이 해소됐습니다.', '2일 전'),
      _ReviewData('이**', 4.5, '현실적인 조언 감사합니다. 다음에도 또 오고 싶어요.', '5일 전'),
      _ReviewData('박**', 5.0, '연애 고민 해결에 큰 도움이 됐어요!', '1주 전'),
      _ReviewData('최**', 4.0, '다음에도 또 방문하고 싶어요', '2주 전'),
      _ReviewData('정**', 5.0, '정확한 사주풀이에 놀랐습니다', '3주 전'),
    ];

    // 별점 분포 (5점: 3개, 4.5점: 1개, 4점: 1개)
    final distribution = {5: 3, 4: 2, 3: 0, 2: 0, 1: 0};
    final total = distribution.values.fold(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // 헤더
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

          // 평점 통계
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.surface,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 평균 평점 크게
                Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${myBosal?.rating ?? 0}',
                          style: AppTextStyles.priceDiscount
                              .copyWith(fontSize: 36, height: 1),
                        ),
                        const SizedBox(width: 2),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('/10',
                              style: AppTextStyles.small.copyWith(fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(Icons.star_rounded,
                            size: 16, color: AppColors.accent),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${myBosal?.reviewCount ?? 0}개 리뷰',
                        style: AppTextStyles.small),
                  ],
                ),
                const SizedBox(width: 24),
                Container(width: 1, height: 80, color: AppColors.border),
                const SizedBox(width: 20),
                // 별점 분포 바
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1].map((star) {
                      final count = distribution[star] ?? 0;
                      final ratio = total > 0 ? count / total : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text('$star', style: AppTextStyles.small.copyWith(fontSize: 11)),
                            const SizedBox(width: 4),
                            Icon(Icons.star_rounded,
                                size: 11, color: AppColors.accent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 7,
                                  backgroundColor: AppColors.bg,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    ratio > 0 ? AppColors.primary : AppColors.border,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 16,
                              child: Text(
                                '$count',
                                style: AppTextStyles.small.copyWith(fontSize: 11),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 리뷰 목록
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
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
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: AppColors.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                review.name[0],
                                style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(review.name, style: AppTextStyles.bodyBold),
                                Row(
                                  children: [
                                    ...List.generate(
                                      5,
                                      (i) => Icon(
                                        i < review.rating.floor()
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        size: 13,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(review.rating.toString(),
                                        style: AppTextStyles.small),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(review.date, style: AppTextStyles.small),
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

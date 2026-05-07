import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/review.dart';
import '../../shared/widgets/app_shadow.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bosal_provider.dart';
import '../../providers/review_provider.dart';
import '../report/report_dialog.dart';

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

          // bosalId 없으면 안내
          if (user?.bosalId == null)
            const Expanded(
              child: Center(child: Text('보살 계정으로 로그인이 필요합니다.')),
            )
          else ...[
            // 평점 통계 (분포 + 평균)
            _RatingSummary(
              bosalId: user!.bosalId!,
              avgRating: myBosal?.rating ?? 0,
              reviewCount: myBosal?.reviewCount ?? 0,
            ),

            const SizedBox(height: 8),

            // 리뷰 목록
            Expanded(child: _ReviewList(bosalId: user.bosalId!)),
          ],
        ],
      ),
    );
  }
}

class _RatingSummary extends ConsumerWidget {
  final String bosalId;
  final double avgRating;
  final int reviewCount;

  const _RatingSummary({
    required this.bosalId,
    required this.avgRating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distAsync = ref.watch(bosalRatingDistributionProvider(bosalId));

    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 평균 평점
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: AppTextStyles.priceDiscount
                        .copyWith(fontSize: 36, height: 1),
                  ),
                  const SizedBox(width: 2),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('/10',
                        style:
                            AppTextStyles.small.copyWith(fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(
                  5,
                  (i) => const Icon(Icons.star_rounded,
                      size: 16, color: AppColors.accent),
                ),
              ),
              const SizedBox(height: 4),
              Text('$reviewCount개 리뷰', style: AppTextStyles.small),
            ],
          ),
          const SizedBox(width: 24),
          Container(width: 1, height: 80, color: AppColors.border),
          const SizedBox(width: 20),
          // 분포 바
          Expanded(
            child: distAsync.when(
              loading: () => const SizedBox(
                height: 56,
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (e, _) => Text('분포 로드 실패',
                  style:
                      AppTextStyles.small.copyWith(color: AppColors.danger)),
              data: (dist) => _DistributionBars(distribution: dist),
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionBars extends StatelessWidget {
  /// 1..10 점별 카운트.
  final Map<int, int> distribution;

  const _DistributionBars({required this.distribution});

  @override
  Widget build(BuildContext context) {
    // DB는 1-10이지만 UI는 5단계로 묶어서 표시: 5★(9-10), 4★(7-8), 3★(5-6), 2★(3-4), 1★(1-2)
    final buckets = <int, int>{
      5: (distribution[10] ?? 0) + (distribution[9] ?? 0),
      4: (distribution[8] ?? 0) + (distribution[7] ?? 0),
      3: (distribution[6] ?? 0) + (distribution[5] ?? 0),
      2: (distribution[4] ?? 0) + (distribution[3] ?? 0),
      1: (distribution[2] ?? 0) + (distribution[1] ?? 0),
    };
    final total = buckets.values.fold<int>(0, (a, b) => a + b);

    return Column(
      children: [5, 4, 3, 2, 1].map((star) {
        final count = buckets[star] ?? 0;
        final ratio = total > 0 ? count / total : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Text('$star',
                  style: AppTextStyles.small.copyWith(fontSize: 11)),
              const SizedBox(width: 4),
              const Icon(Icons.star_rounded,
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
                width: 20,
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
    );
  }
}

class _ReviewList extends ConsumerWidget {
  final String bosalId;
  const _ReviewList({required this.bosalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(bosalReviewsProvider(bosalId));
    return reviewsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 36, color: AppColors.danger),
              const SizedBox(height: 12),
              Text('리뷰를 불러오지 못했습니다', style: AppTextStyles.bodyBold),
              const SizedBox(height: 6),
              Text('$e',
                  style: AppTextStyles.small
                      .copyWith(color: AppColors.textSub)),
            ],
          ),
        ),
      ),
      data: (reviews) {
        if (reviews.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.rate_review_outlined,
                        size: 32, color: AppColors.primary),
                  ),
                  const SizedBox(height: 14),
                  Text('아직 작성된 후기가 없습니다',
                      style: AppTextStyles.bodyBold),
                  const SizedBox(height: 6),
                  Text('상담 완료 후 회원이 후기를 남길 수 있어요',
                      style: AppTextStyles.small
                          .copyWith(color: AppColors.textSub)),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _ReviewCard(review: reviews[i]),
        );
      },
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maskedName = _maskName(review.userDisplayName ?? '회원');
    final stars = (review.rating / 2).round().clamp(1, 5);

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
                    maskedName.isNotEmpty ? maskedName[0] : '회',
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(maskedName, style: AppTextStyles.bodyBold),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < stars
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 13,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text((review.rating / 2).toStringAsFixed(1),
                            style: AppTextStyles.small),
                      ],
                    ),
                  ],
                ),
              ),
              Text(_relativeDate(review.createdAt),
                  style: AppTextStyles.small),
              const SizedBox(width: 4),
              SizedBox(
                width: 28,
                height: 28,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  tooltip: '메뉴',
                  onSelected: (v) {
                    if (v == 'report') {
                      showReportDialog(context, ref,
                          kind: ReportTargetKind.review,
                          targetId: review.id);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'report',
                      child: ListTile(
                        leading: Icon(Icons.flag_outlined,
                            size: 18, color: AppColors.danger),
                        title: Text('신고',
                            style: TextStyle(color: AppColors.danger)),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((review.body ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.body!, style: AppTextStyles.body),
          ],
        ],
      ),
    );
  }

  String _maskName(String name) {
    if (name.isEmpty) return '회원';
    if (name.length == 1) return '$name*';
    return '${name[0]}${'*' * (name.length - 1)}';
  }

  String _relativeDate(DateTime created) {
    final diff = DateTime.now().difference(created);
    if (diff.inDays < 1) return '오늘';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}주 전';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}달 전';
    return '${(diff.inDays / 365).floor()}년 전';
  }
}

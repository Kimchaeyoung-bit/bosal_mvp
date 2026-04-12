import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/bosal_provider.dart';

final _priceFormat = NumberFormat('#,###');

class BosalDetailScreen extends ConsumerWidget {
  final String bosalId;
  const BosalDetailScreen({super.key, required this.bosalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bosals = ref.watch(allBosalsProvider);
    final bosal = bosals.firstWhere((b) => b.id == bosalId);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recentlyViewedProvider.notifier).add(bosalId);
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_rounded, size: 22),
          ),
        ],
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Profile section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    color: AppColors.surface,
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primarySoft,
                                    Color(0xFFDDC8F0),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.person_rounded,
                                  color: AppColors.primary, size: 56),
                            ),
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: AppColors.surface, width: 2),
                                ),
                                child: const Text(
                                  '인증',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(bosal.name, style: AppTextStyles.largeName),
                        const SizedBox(height: 6),
                        Text(
                          '경력 ${bosal.experienceYears}년 · ${bosal.consultStyle}',
                          style: AppTextStyles.small,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 18, color: AppColors.accent),
                            const SizedBox(width: 2),
                            Text(
                              '${bosal.rating}',
                              style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            Text(' (${bosal.reviewCount})',
                                style: AppTextStyles.small),
                            Container(
                              width: 1,
                              height: 12,
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              color: AppColors.border,
                            ),
                            Text('Q&A ${bosal.qnaCount}',
                                style: AppTextStyles.small),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Features card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    color: AppColors.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('보살 특징',
                                style: AppTextStyles.bodyBold
                                    .copyWith(fontSize: 15)),
                            GestureDetector(
                              onTap: () {},
                              child: Row(
                                children: [
                                  Text('전체보기', style: AppTextStyles.moreLink),
                                  const Icon(Icons.chevron_right_rounded,
                                      size: 16, color: AppColors.textSub),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ...bosal.features.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: AppTextStyles.body
                                        .copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Pricing card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    color: AppColors.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('상담료',
                            style: AppTextStyles.bodyBold
                                .copyWith(fontSize: 15)),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${bosal.discountPercent}%',
                              style: AppTextStyles.priceDiscount.copyWith(
                                color: AppColors.danger,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${_priceFormat.format(bosal.originalPrice)}원',
                                style: AppTextStyles.priceOriginal.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_priceFormat.format(bosal.discountedPrice)}원',
                          style: AppTextStyles.priceDiscount.copyWith(fontSize: 24),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '첫방문',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${_priceFormat.format(bosal.firstVisitPrice)}원',
                                style: AppTextStyles.priceFirstVisit,
                              ),
                              const Spacer(),
                              Text('내 예약 적용가',
                                  style: AppTextStyles.small.copyWith(
                                      fontWeight: FontWeight.w600)),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 16, color: AppColors.textSub),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    color: AppColors.primary, size: 18),
                                const SizedBox(width: 8),
                                Text('위치 보기',
                                    style: AppTextStyles.body
                                        .copyWith(fontWeight: FontWeight.w600)),
                                const Spacer(),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.textSub, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Points & social proof
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    color: AppColors.surface,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppColors.accentSoft,
                                Color(0xFFFAE8C0),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.monetization_on_rounded,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '포인트 최대 ${_priceFormat.format(bosal.maxPoints)}P 적립',
                                style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.textSub, size: 20),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.favorite_rounded,
                                color: AppColors.primary, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '총 ',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSub,
                              ),
                            ),
                            Text(
                              '${bosal.consultRequests}명',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '이 상담 신청했어요.',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSub,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {},
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_border_rounded,
                      color: AppColors.textSub, size: 22),
                  const SizedBox(height: 2),
                  Text('찜', style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 1,
              height: 32,
              color: AppColors.border,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${bosal.name} 예약이 신청되었습니다!'),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('예약하기'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

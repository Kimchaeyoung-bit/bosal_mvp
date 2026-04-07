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

    // Track as recently viewed
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
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    color: AppColors.surface,
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: AppColors.primary, size: 48),
                        ),
                        const SizedBox(height: 14),
                        Text(bosal.name, style: AppTextStyles.largeName),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Info card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    color: AppColors.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name & rating
                        Text(bosal.name, style: AppTextStyles.cardTitle.copyWith(fontSize: 17)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 16, color: AppColors.accent),
                            const SizedBox(width: 2),
                            Text(
                              '${bosal.rating}',
                              style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700),
                            ),
                            Text(' (${bosal.reviewCount})',
                                style: AppTextStyles.small),
                            const SizedBox(width: 12),
                            Text('Q&A (${bosal.qnaCount})',
                                style: AppTextStyles.small),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: 16),

                        // Features
                        Text('보살 특징', style: AppTextStyles.bodyBold),
                        const SizedBox(height: 10),
                        ...bosal.features.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.key + 1}. ',
                                  style: AppTextStyles.body,
                                ),
                                Expanded(
                                  child:
                                      Text(entry.value, style: AppTextStyles.body),
                                ),
                              ],
                            ),
                          );
                        }),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text('전체보기',
                                style: AppTextStyles.moreLink),
                          ),
                        ),

                        const Divider(color: AppColors.border),
                        const SizedBox(height: 16),

                        // Pricing
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${bosal.discountPercent}%',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_priceFormat.format(bosal.originalPrice)}원',
                              style: AppTextStyles.priceOriginal.copyWith(
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_priceFormat.format(bosal.discountedPrice)}원',
                          style: AppTextStyles.priceDiscount,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '${_priceFormat.format(bosal.firstVisitPrice)}원',
                              style: AppTextStyles.priceFirstVisit,
                            ),
                            const SizedBox(width: 4),
                            Text('첫방문 시', style: AppTextStyles.small),
                            const Spacer(),
                            Text('내 예약 적용가 ▼',
                                style: AppTextStyles.small),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Location button
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  color: AppColors.textSub, size: 20),
                              const SizedBox(width: 8),
                              Text('위치', style: AppTextStyles.body),
                              const Spacer(),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.textSub, size: 20),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Points
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.monetization_on_rounded,
                                  color: AppColors.accent, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '포인트 최대 ${_priceFormat.format(bosal.maxPoints)}P 적립',
                                style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.textSub, size: 20),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Social proof
                        Row(
                          children: [
                            const Icon(Icons.favorite_rounded,
                                color: AppColors.primary, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${bosal.consultRequests}명이 상담 신청했어요.',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSub,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom booking bar
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                // Rating button
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.rate_review_outlined,
                        color: AppColors.textSub, size: 22),
                  ),
                ),
                const SizedBox(width: 8),
                // Chat button
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded,
                        color: AppColors.textSub, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                // Booking button
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${bosal.name} 예약이 신청되었습니다!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/auth_guard.dart';
import '../../providers/bosal_provider.dart';
import '../../providers/data_source_providers.dart';
import '../../providers/favorite_provider.dart';
import '../booking/booking_sheet.dart';

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
              onTap: () => requireAuth(
                context,
                ref,
                onAuthenticated: () async {
                  final toggle = ref.read(favoriteToggleProvider);
                  final wasLiked =
                      ref.read(favoritesProvider).contains(bosal.id);
                  try {
                    await toggle(bosal.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          wasLiked ? '찜을 해제했어요' : '찜 목록에 추가되었습니다',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('오류: $e')),
                    );
                  }
                },
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    ref.watch(favoritesProvider).contains(bosal.id)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: ref.watch(favoritesProvider).contains(bosal.id)
                        ? AppColors.accent
                        : AppColors.textSub,
                    size: 22,
                  ),
                  const SizedBox(height: 2),
                  Text('찜', style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(width: 1, height: 32, color: AppColors.border),
            const SizedBox(width: 16),
            if (bosal.phoneNumber != null) ...[
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => requireAuth(context, ref,
                      onAuthenticated: () async {
                        // fire-and-forget 전화 탭 로깅 (실패 무시)
                        unawaited(ref
                            .read(analyticsDataSourceProvider)
                            .logCallTap(bosalId: bosal.id));
                        final uri = Uri(
                          scheme: 'tel',
                          path: bosal.phoneNumber!.replaceAll('-', ''),
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('전화 상담',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => requireAuth(context, ref,
                      onAuthenticated: () {
                        unawaited(ref
                            .read(analyticsDataSourceProvider)
                            .logReservationButtonTap(bosalId: bosal.id));
                        showBookingSheet(context, bosal);
                      }),
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

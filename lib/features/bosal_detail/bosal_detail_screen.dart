import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/auth_guard.dart';
import '../../providers/bosal_provider.dart';
import '../../shared/widgets/app_shadow.dart';
import '../booking/booking_sheet.dart';

class BosalDetailScreen extends ConsumerWidget {
  final String bosalId;
  const BosalDetailScreen({super.key, required this.bosalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bosals = ref.watch(allBosalsProvider);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (bosals.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final bosalIndex = bosals.indexWhere((b) => b.id == bosalId);
    if (bosalIndex < 0) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: const Center(child: Text('보살을 찾을 수 없습니다')),
      );
    }
    final bosal = bosals[bosalIndex];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recentlyViewedProvider.notifier).add(bosalId);
    });

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
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8, topPadding + 8, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.text),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.share_rounded,
                        size: 22, color: AppColors.text),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    // Profile card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: appShadow,
                      ),
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
                                      color: AppColors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
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
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                color: AppColors.border,
                              ),
                              Text('Q&A ${bosal.qnaCount}',
                                  style: AppTextStyles.small),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Features card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: appShadow,
                      ),
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
                                    Text('전체보기',
                                        style: AppTextStyles.moreLink),
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
                                    decoration: const BoxDecoration(
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

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 12),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => requireAuth(context, ref,
                  onAuthenticated: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('찜 목록에 추가되었습니다')),
                    );
                  }),
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
            Container(width: 1, height: 32, color: AppColors.border),
            const SizedBox(width: 16),
            if (bosal.phoneNumber != null) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => requireAuth(context, ref,
                      onAuthenticated: () async {
                        final uri = Uri(
                          scheme: 'tel',
                          path: bosal.phoneNumber!.replaceAll('-', ''),
                        );
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      }),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_rounded,
                            size: 18, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          '전화 상담',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: GestureDetector(
                onTap: () => requireAuth(context, ref,
                    onAuthenticated: () => showBookingSheet(context, bosal)),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '예약하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

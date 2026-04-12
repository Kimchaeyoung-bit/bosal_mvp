import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_shadow.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bosal_provider.dart';
import '../../providers/booking_provider.dart';

class BosalDashboardScreen extends ConsumerWidget {
  const BosalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final bosals = ref.watch(allBosalsProvider);
    final bookings = ref.watch(bookingsProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    final myBosal = user?.bosalId != null
        ? bosals.where((b) => b.id == user!.bosalId).firstOrNull
        : null;

    final myBookings = user?.bosalId != null
        ? bookings.where((b) => b.bosalId == user!.bosalId).toList()
        : <dynamic>[];

    final pendingCount =
        myBookings.where((b) => b.status.name == 'pending').length;
    final confirmedCount =
        myBookings.where((b) => b.status.name == 'confirmed').length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('보살 대시보드', style: AppTextStyles.logo),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: AppColors.primary, size: 32),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            myBosal?.name ?? user?.displayName ?? '',
                            style: AppTextStyles.cardTitle
                                .copyWith(color: AppColors.white, fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          if (myBosal != null)
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 14, color: AppColors.accent),
                                const SizedBox(width: 2),
                                Text(
                                  '${myBosal.rating} (${myBosal.reviewCount})',
                                  style: AppTextStyles.small.copyWith(
                                    color: AppColors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '경력 ${myBosal.experienceYears}년',
                                  style: AppTextStyles.small.copyWith(
                                    color: AppColors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stats cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _StatCard(
                    icon: Icons.pending_actions_rounded,
                    label: '대기중',
                    value: '$pendingCount',
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.check_circle_outline_rounded,
                    label: '확정',
                    value: '$confirmedCount',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.people_outline_rounded,
                    label: '총 상담',
                    value: '${myBosal?.consultRequests ?? 0}',
                    color: AppColors.danger,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Today's bookings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('오늘의 예약', style: AppTextStyles.sectionTitle),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: myBookings.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: appShadow,
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.event_available_rounded,
                              size: 40, color: AppColors.textSub),
                          const SizedBox(height: 8),
                          Text('오늘 예약이 없습니다',
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.textSub)),
                        ],
                      ),
                    )
                  : Column(
                      children: myBookings.take(3).map<Widget>((booking) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: appShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.person_rounded,
                                    color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('예약 고객',
                                        style: AppTextStyles.bodyBold),
                                    Text(booking.consultType,
                                        style: AppTextStyles.small),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: booking.status.name == 'pending'
                                      ? AppColors.accentSoft
                                      : AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  booking.status.name == 'pending'
                                      ? '대기중'
                                      : '확정',
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 24),

            // Revenue summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('수익 요약', style: AppTextStyles.sectionTitle),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: appShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('이번 달 수익', style: AppTextStyles.body),
                        Text('550,000원',
                            style: AppTextStyles.priceDiscount
                                .copyWith(fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('완료 상담', style: AppTextStyles.small),
                        Text('10건',
                            style: AppTextStyles.body
                                .copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: appShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: AppTextStyles.priceDiscount.copyWith(fontSize: 20)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.small),
          ],
        ),
      ),
    );
  }
}

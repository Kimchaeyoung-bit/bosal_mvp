import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_shadow.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bosal_provider.dart';
import '../../data/models/booking.dart';
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
        : <Booking>[];

    final pendingBookings =
        myBookings.where((b) => b.status == BookingStatus.pending).toList();
    final confirmedBookings =
        myBookings.where((b) => b.status == BookingStatus.confirmed).toList();
    final completedBookings =
        myBookings.where((b) => b.status == BookingStatus.completed).toList();


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
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더 ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('보살 대시보드',
                      style: AppTextStyles.logo.copyWith(
                          color: AppColors.textSub,
                          fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (myBosal?.name ?? '보')[0],
                            style: AppTextStyles.sectionTitle
                                .copyWith(color: AppColors.primary, fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '안녕하세요, ${myBosal?.name ?? user?.displayName ?? ''}',
                              style: AppTextStyles.cardTitle.copyWith(
                                  color: AppColors.text, fontSize: 17),
                            ),
                            const SizedBox(height: 4),
                            if (myBosal != null)
                              Row(
                                children: [
                                  Icon(Icons.star_rounded,
                                      size: 13, color: AppColors.accent),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${myBosal.rating}  ·  경력 ${myBosal.experienceYears}년',
                                    style: AppTextStyles.small.copyWith(
                                        color: AppColors.textSub),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 통계 카드 3개 ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _StatCard(
                    icon: Icons.pending_actions_rounded,
                    label: '대기중',
                    value: '${pendingBookings.length}건',
                    color: const Color(0xFFFF8C00),
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.check_circle_outline_rounded,
                    label: '확정',
                    value: '${confirmedBookings.length}건',
                    color: const Color(0xFF2ECC71),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 오늘의 예약 (빠른 액션) ──────────────────────────────
            _SectionHeader(title: '대기중 예약', count: pendingBookings.length),
            const SizedBox(height: 10),
            if (pendingBookings.isEmpty)
              _EmptyCard(
                  icon: Icons.event_available_rounded, text: '대기중인 예약이 없습니다')
            else
              ...pendingBookings.take(3).map((booking) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: _QuickActionCard(
                      booking: booking,
                      onReject: () => ref
                          .read(bookingsProvider.notifier)
                          .reject(booking.id),
                      onConfirm: () => ref
                          .read(bookingsProvider.notifier)
                          .confirm(booking.id),
                    ),
                  )),

            const SizedBox(height: 24),

            // ── 확정 예약 ────────────────────────────────────────────
            _SectionHeader(title: '확정 예약', count: confirmedBookings.length),
            const SizedBox(height: 10),
            if (confirmedBookings.isEmpty)
              _EmptyCard(
                  icon: Icons.calendar_today_rounded, text: '확정된 예약이 없습니다')
            else
              ...confirmedBookings.take(2).map((booking) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: _ConfirmedCard(
                      booking: booking,
                      onComplete: () => ref
                          .read(bookingsProvider.notifier)
                          .complete(booking.id),
                    ),
                  )),

            const SizedBox(height: 24),

            // ── 최근 리뷰 미리보기 ───────────────────────────────────
            const _SectionHeader(title: '최근 리뷰'),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _ReviewPreviewCard(
                      name: '김**', rating: 5.0, content: '정말 정확하고 따뜻한 상담이었어요', date: '2일 전'),
                  const SizedBox(height: 8),
                  _ReviewPreviewCard(
                      name: '이**', rating: 4.5, content: '현실적인 조언 감사합니다', date: '5일 전'),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      ),
    );
  }
}

// ─── 섹션 헤더 ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;

  const _SectionHeader({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.sectionTitle),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── 빈 상태 카드 ────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
          boxShadow: appShadow,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textSub),
            const SizedBox(width: 10),
            Text(text,
                style: AppTextStyles.body.copyWith(color: AppColors.textSub)),
          ],
        ),
      ),
    );
  }
}

// ─── 대기중 예약 빠른 액션 카드 ──────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onReject;
  final VoidCallback onConfirm;

  const _QuickActionCard({
    required this.booking,
    required this.onReject,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        boxShadow: appShadow,
        border: Border.all(color: const Color(0xFFFF8C00).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_rounded,
                    color: Color(0xFFFF8C00), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('예약 고객', style: AppTextStyles.bodyBold),
                    Text(
                      '${booking.consultType}  ·  ${_fmtDate(booking.consultDate)}',
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('거절'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('수락'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime? date) {
    if (date == null) return '날짜 미정';
    return DateFormat('M/d HH:mm').format(date);
  }
}

// ─── 확정 예약 카드 ──────────────────────────────────────────────────────────

class _ConfirmedCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onComplete;

  const _ConfirmedCard({required this.booking, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        boxShadow: appShadow,
        border: Border.all(
            color: const Color(0xFF2ECC71).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: Color(0xFF2ECC71), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('예약 고객', style: AppTextStyles.bodyBold),
                Text(
                  '${booking.consultType}  ·  ${_fmtDate(booking.consultDate)}',
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onComplete,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppColors.border),
              ),
            ),
            child: Text('완료 처리',
                style: AppTextStyles.caption
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime? date) {
    if (date == null) return '날짜 미정';
    return DateFormat('M/d HH:mm').format(date);
  }
}

// ─── 최근 리뷰 미리보기 ──────────────────────────────────────────────────────

class _ReviewPreviewCard extends StatelessWidget {
  final String name;
  final double rating;
  final String content;
  final String date;

  const _ReviewPreviewCard({
    required this.name,
    required this.rating,
    required this.content,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        boxShadow: appShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(name[0],
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: AppTextStyles.smallBold),
                    const SizedBox(width: 6),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < rating.floor()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 12,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(date, style: AppTextStyles.small),
                  ],
                ),
                const SizedBox(height: 4),
                Text(content,
                    style: AppTextStyles.body.copyWith(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 통계 카드 ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool small;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
          boxShadow: appShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.bodyBold.copyWith(
                fontSize: small ? 13 : 18,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.small.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

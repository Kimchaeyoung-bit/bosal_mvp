import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/booking.dart';
import '../../data/models/bosal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/bosal_provider.dart';
import '../../shared/widgets/login_required_view.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  BookingStatus? _selectedFilter; // null = 전체

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isLoggedInProvider);

    if (!isLoggedIn) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(child: LoginRequiredView()),
      );
    }

    final bookings = ref.watch(bookingsProvider);
    final allBosals = ref.watch(allBosalsProvider);

    final filtered = _selectedFilter == null
        ? bookings
        : bookings.where((b) => b.status == _selectedFilter).toList();

    // 상태별 카운트
    final pendingCount =
        bookings.where((b) => b.status == BookingStatus.pending).length;
    final confirmedCount =
        bookings.where((b) => b.status == BookingStatus.confirmed).length;
    final completedCount =
        bookings.where((b) => b.status == BookingStatus.completed).length;
    final cancelledCount =
        bookings.where((b) => b.status == BookingStatus.cancelled).length;

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
        child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text('예약 내역', style: AppTextStyles.sectionTitle.copyWith(fontSize: 22)),
            ),
            const SizedBox(height: 16),

            // 필터 칩
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _FilterChip(
                    label: '전체',
                    count: bookings.length,
                    isSelected: _selectedFilter == null,
                    onTap: () => setState(() => _selectedFilter = null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '대기중',
                    count: pendingCount,
                    isSelected: _selectedFilter == BookingStatus.pending,
                    onTap: () => setState(() => _selectedFilter = BookingStatus.pending),
                    color: const Color(0xFFFF8C00),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '확정',
                    count: confirmedCount,
                    isSelected: _selectedFilter == BookingStatus.confirmed,
                    onTap: () => setState(() => _selectedFilter = BookingStatus.confirmed),
                    color: const Color(0xFF2ECC71),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '완료',
                    count: completedCount,
                    isSelected: _selectedFilter == BookingStatus.completed,
                    onTap: () => setState(() => _selectedFilter = BookingStatus.completed),
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '취소',
                    count: cancelledCount,
                    isSelected: _selectedFilter == BookingStatus.cancelled,
                    onTap: () => setState(() => _selectedFilter = BookingStatus.cancelled),
                    color: AppColors.textSub,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 예약 목록
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(
                      filter: _selectedFilter,
                      onGoHome: () => context.go('/home'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final booking = filtered[index];
                        final bosal = allBosals
                            .where((b) => b.id == booking.bosalId)
                            .firstOrNull;
                        if (bosal == null) {
                          // 보살 정보 미동기화 — 라이트 카드만 표시
                          return _BookingCardSkeleton(
                            booking: booking,
                            onCancel: () => _showCancelDialog(booking),
                          );
                        }
                        return _BookingCard(
                          booking: booking,
                          bosal: bosal,
                          onCancel: () => _showCancelDialog(booking),
                          onDetail: () => context.push('/bosal/${bosal.id}'),
                        );
                      },
                    ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _showCancelDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('예약 취소', style: AppTextStyles.cardTitle),
        content: Text('예약을 취소하시겠어요?', style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('아니요', style: AppTextStyles.body.copyWith(color: AppColors.textSub)),
          ),
          TextButton(
            onPressed: () {
              ref.read(bookingsProvider.notifier).cancel(booking.id);
              Navigator.pop(ctx);
            },
            child: Text('취소하기', style: AppTextStyles.bodyBold.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// ─── 필터 칩 ────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.chip.copyWith(
                color: isSelected ? AppColors.white : AppColors.text,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.white.withValues(alpha: 0.25)
                    : AppColors.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? AppColors.white : AppColors.textSub,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 예약 카드 ───────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final Bosal bosal;
  final VoidCallback onCancel;
  final VoidCallback onDetail;

  const _BookingCard({
    required this.booking,
    required this.bosal,
    required this.onCancel,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusInfo(booking.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 보살 정보 + 상태 뱃지
          Row(
            children: [
              // 아바타
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primarySoft,
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    bosal.name[0],
                    style: AppTextStyles.bodyBold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bosal.name, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 3),
                    Text(
                      bosal.features.take(2).join(' · '),
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ),
              // 상태 뱃지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: status.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.label,
                  style: AppTextStyles.caption.copyWith(
                    color: status.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),

          // 상담 정보
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: AppColors.textSub),
              const SizedBox(width: 6),
              Text(
                booking.consultDate != null
                    ? _formatDate(booking.consultDate!)
                    : '날짜 미정',
                style: AppTextStyles.small,
              ),
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 14, color: AppColors.textSub),
              const SizedBox(width: 6),
              Text(booking.consultType, style: AppTextStyles.small),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.monetization_on_outlined,
                  size: 14, color: AppColors.textSub),
              const SizedBox(width: 6),
              Text(
                '${_formatPrice(booking.price)}원',
                style: AppTextStyles.smallBold
                    .copyWith(color: AppColors.text),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 액션 버튼
          Row(
            children: _buildActions(booking.status),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return [
          Expanded(
            child: _ActionButton(
              label: '예약 취소',
              onTap: onCancel,
              isOutlined: true,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(label: '상세 보기', onTap: onDetail),
          ),
        ];
      case BookingStatus.confirmed:
        return [
          Expanded(
            child: _ActionButton(
              label: '예약 취소',
              onTap: onCancel,
              isOutlined: true,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(label: '상세 보기', onTap: onDetail),
          ),
        ];
      case BookingStatus.completed:
        return [
          Expanded(
            child: _ActionButton(
              label: '리뷰 쓰기',
              onTap: onDetail,
              isOutlined: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(label: '다시 예약', onTap: onDetail),
          ),
        ];
      case BookingStatus.cancelled:
        return [
          Expanded(
            child: _ActionButton(label: '다시 예약하기', onTap: onDetail),
          ),
        ];
    }
  }

  _StatusInfo _statusInfo(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return _StatusInfo(
          label: '대기중',
          bgColor: const Color(0xFFFFF3E0),
          textColor: const Color(0xFFFF8C00),
        );
      case BookingStatus.confirmed:
        return _StatusInfo(
          label: '확정',
          bgColor: const Color(0xFFE8F8F0),
          textColor: const Color(0xFF2ECC71),
        );
      case BookingStatus.completed:
        return _StatusInfo(
          label: '완료',
          bgColor: AppColors.primarySoft,
          textColor: AppColors.primary,
        );
      case BookingStatus.cancelled:
        return _StatusInfo(
          label: '취소',
          bgColor: const Color(0xFFF5F5F5),
          textColor: AppColors.textSub,
        );
    }
  }

  String _formatDate(DateTime date) {
    const weeks = ['월', '화', '수', '목', '금', '토', '일'];
    final week = weeks[date.weekday - 1];
    final hour = date.hour >= 12 ? '오후' : '오전';
    final h = date.hour > 12 ? date.hour - 12 : date.hour;
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}($week) $hour $h시';
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

class _StatusInfo {
  final String label;
  final Color bgColor;
  final Color textColor;
  _StatusInfo({required this.label, required this.bgColor, required this.textColor});
}

// ─── 액션 버튼 ───────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isOutlined;
  final Color color;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.isOutlined = false,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isOutlined ? AppColors.surface.withValues(alpha: 0.75) : color,
          borderRadius: BorderRadius.circular(12),
          border: isOutlined ? Border.all(color: color) : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyBold.copyWith(
            color: isOutlined ? color : AppColors.white,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final BookingStatus? filter;
  final VoidCallback onGoHome;

  const _EmptyState({required this.filter, required this.onGoHome});

  @override
  Widget build(BuildContext context) {
    final message = filter == null ? '아직 예약 내역이 없어요' : '해당 상태의 예약이 없어요';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today_rounded,
                size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          Text('마음에 드는 보살을 찾아 예약해보세요',
              style: AppTextStyles.small),
          if (filter == null) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onGoHome,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '보살 찾으러 가기',
                  style: AppTextStyles.bodyBold.copyWith(color: AppColors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 보살 정보가 아직 로드되지 않은 경우의 fallback 카드.
/// (Supabase 로딩 중이거나 보살이 삭제된 예약 표시용)
class _BookingCardSkeleton extends StatelessWidget {
  final Booking booking;
  final VoidCallback onCancel;

  const _BookingCardSkeleton({required this.booking, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.bg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_off_outlined,
                size: 22, color: AppColors.textSub),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('보살 정보를 불러올 수 없습니다',
                    style: AppTextStyles.bodyBold),
                const SizedBox(height: 4),
                Text('${booking.consultType} · ${booking.price}원',
                    style: AppTextStyles.small),
              ],
            ),
          ),
          if (booking.status == BookingStatus.pending ||
              booking.status == BookingStatus.confirmed)
            TextButton(onPressed: onCancel, child: const Text('취소')),
        ],
      ),
    );
  }
}

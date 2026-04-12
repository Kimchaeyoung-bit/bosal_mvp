import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_shadow.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../data/models/booking.dart';

class BosalBookingsScreen extends ConsumerStatefulWidget {
  const BosalBookingsScreen({super.key});

  @override
  ConsumerState<BosalBookingsScreen> createState() =>
      _BosalBookingsScreenState();
}

class _BosalBookingsScreenState extends ConsumerState<BosalBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _dateFormat = DateFormat('MM/dd HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final bookings = ref.watch(bookingsProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    final myBookings = user?.bosalId != null
        ? bookings.where((b) => b.bosalId == user!.bosalId).toList()
        : <Booking>[];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 0),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('예약 관리', style: AppTextStyles.sectionTitle.copyWith(fontSize: 20)),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSub,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2.5,
                  labelStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 14),
                  tabs: const [
                    Tab(text: '대기중'),
                    Tab(text: '확정'),
                    Tab(text: '완료'),
                    Tab(text: '취소'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _BookingList(
                  bookings: myBookings
                      .where((b) => b.status == BookingStatus.pending)
                      .toList(),
                  emptyText: '대기중인 예약이 없습니다',
                  showActions: true,
                  dateFormat: _dateFormat,
                  onConfirm: (id) =>
                      ref.read(bookingsProvider.notifier).confirm(id),
                  onCancel: (id) =>
                      ref.read(bookingsProvider.notifier).reject(id),
                ),
                _BookingList(
                  bookings: myBookings
                      .where((b) => b.status == BookingStatus.confirmed)
                      .toList(),
                  emptyText: '확정된 예약이 없습니다',
                  showComplete: true,
                  dateFormat: _dateFormat,
                  onComplete: (id) =>
                      ref.read(bookingsProvider.notifier).complete(id),
                ),
                _BookingList(
                  bookings: myBookings
                      .where((b) => b.status == BookingStatus.completed)
                      .toList(),
                  emptyText: '완료된 예약이 없습니다',
                  dateFormat: _dateFormat,
                ),
                _BookingList(
                  bookings: myBookings
                      .where((b) => b.status == BookingStatus.cancelled)
                      .toList(),
                  emptyText: '취소된 예약이 없습니다',
                  dateFormat: _dateFormat,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<Booking> bookings;
  final String emptyText;
  final bool showActions;
  final bool showComplete;
  final DateFormat dateFormat;
  final void Function(String)? onConfirm;
  final void Function(String)? onCancel;
  final void Function(String)? onComplete;

  const _BookingList({
    required this.bookings,
    required this.emptyText,
    this.showActions = false,
    this.showComplete = false,
    required this.dateFormat,
    this.onConfirm,
    this.onCancel,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy_rounded,
                size: 48, color: AppColors.textSub),
            const SizedBox(height: 12),
            Text(emptyText,
                style: AppTextStyles.body.copyWith(color: AppColors.textSub)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final booking = bookings[index];
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
                        Text('예약 고객', style: AppTextStyles.bodyBold),
                        Text(
                          '${booking.consultDate != null ? dateFormat.format(booking.consultDate!) : '미정'} · ${booking.consultType}',
                          style: AppTextStyles.small,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${NumberFormat('#,###').format(booking.price)}원',
                    style: AppTextStyles.bodyBold,
                  ),
                ],
              ),
              if (showActions) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onCancel?.call(booking.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('거절'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => onConfirm?.call(booking.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('수락'),
                      ),
                    ),
                  ],
                ),
              ],
              if (showComplete) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => onComplete?.call(booking.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('상담 완료 처리'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

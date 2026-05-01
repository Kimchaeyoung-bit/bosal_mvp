import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/booking.dart';
import '../../data/models/bosal.dart';
import '../../data/models/review.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/bosal_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/review_provider.dart';
import '../../shared/widgets/app_shadow.dart';
import '../../shared/widgets/login_required_view.dart';

enum MyActivityType { bookings, favorites, recent, reviews }

class MyActivityScreen extends ConsumerWidget {
  final MyActivityType type;

  const MyActivityScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final title = _titleFor(type);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(title),
        centerTitle: false,
      ),
      body: SafeArea(
        child: !isLoggedIn ? const LoginRequiredView() : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (type) {
      case MyActivityType.bookings:
        return const _BookingsList();
      case MyActivityType.favorites:
        return const _FavoritesList();
      case MyActivityType.recent:
        return const _RecentList();
      case MyActivityType.reviews:
        return const _ReviewsPlaceholder();
    }
  }

  String _titleFor(MyActivityType type) {
    switch (type) {
      case MyActivityType.bookings:
        return '예약 내역';
      case MyActivityType.favorites:
        return '찜한 보살';
      case MyActivityType.recent:
        return '최근 본 보살';
      case MyActivityType.reviews:
        return '내 후기';
    }
  }
}

// =============================================================
// 찜한 보살 — favoritesStream + allBosalsAsync 두 비동기 합성
// =============================================================
class _FavoritesList extends ConsumerWidget {
  const _FavoritesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIdsAsync = ref.watch(favoritesStreamProvider);
    final bosalsAsync = ref.watch(allBosalsAsyncProvider);

    return favIdsAsync.when(
      loading: () => const _Loading(),
      error: (e, _) => _ErrorView(message: '찜 목록을 불러오지 못했습니다', detail: '$e'),
      data: (favIds) {
        if (favIds.isEmpty) {
          return const _EmptyState(
            icon: Icons.favorite_border_rounded,
            title: '아직 찜한 보살이 없어요',
            hint: '마음에 드는 보살을 찾아 ♡ 아이콘을 눌러보세요',
          );
        }
        return bosalsAsync.when(
          loading: () => const _Loading(),
          error: (e, _) =>
              _ErrorView(message: '보살 정보를 불러오지 못했습니다', detail: '$e'),
          data: (bosals) {
            final favBosals = bosals
                .where((b) => favIds.contains(b.id))
                .toList(growable: false);
            if (favBosals.isEmpty) {
              // ID는 있는데 매칭되는 보살 데이터가 사라진 경우 (drift)
              return const _EmptyState(
                icon: Icons.help_outline_rounded,
                title: '찜한 보살 정보를 불러올 수 없어요',
                hint: '잠시 후 다시 시도해주세요',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: favBosals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _BosalCard(bosal: favBosals[i]),
            );
          },
        );
      },
    );
  }
}

// =============================================================
// 최근 본 보살 — in-memory recentlyViewedBosalsProvider
// =============================================================
class _RecentList extends ConsumerWidget {
  const _RecentList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentlyViewedBosalsProvider);
    if (recents.isEmpty) {
      return const _EmptyState(
        icon: Icons.history_rounded,
        title: '최근 본 보살이 없어요',
        hint: '둘러본 보살이 여기에 자동으로 모입니다',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: recents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _BosalCard(bosal: recents[i]),
    );
  }
}

// =============================================================
// 예약 내역 — bookingsProvider (StateNotifier)
// =============================================================
class _BookingsList extends ConsumerWidget {
  const _BookingsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider);
    if (bookings.isEmpty) {
      return const _EmptyState(
        icon: Icons.calendar_today_outlined,
        title: '예약 내역이 없어요',
        hint: '보살 상세에서 예약을 시작해보세요',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
    );
  }
}

// =============================================================
// 내 후기 — myReviewsProvider (Async)
// =============================================================
class _ReviewsPlaceholder extends ConsumerWidget {
  const _ReviewsPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(myReviewsProvider);
    return reviewsAsync.when(
      loading: () => const _Loading(),
      error: (e, _) =>
          _ErrorView(message: '후기 목록을 불러오지 못했습니다', detail: '$e'),
      data: (reviews) {
        if (reviews.isEmpty) {
          return const _EmptyState(
            icon: Icons.rate_review_outlined,
            title: '아직 작성한 후기가 없어요',
            hint: '예약을 완료하면 보살에게 후기를 남길 수 있어요',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _MyReviewCard(review: reviews[i]),
        );
      },
    );
  }
}

class _MyReviewCard extends StatelessWidget {
  final Review review;
  const _MyReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final stars = (review.rating / 2).round().clamp(1, 5);
    return GestureDetector(
      onTap: () => context.push('/bosal/${review.bosalId}'),
      child: Container(
        padding: const EdgeInsets.all(14),
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
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < stars
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 6),
                Text((review.rating / 2).toStringAsFixed(1),
                    style: AppTextStyles.bodyBold),
                const Spacer(),
                if (!review.isPublic)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.textSub.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('비공개',
                        style: AppTextStyles.tag
                            .copyWith(color: AppColors.textSub)),
                  ),
              ],
            ),
            if ((review.body ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.body!, style: AppTextStyles.body),
            ],
            const SizedBox(height: 8),
            Text(
              '${review.createdAt.year}.${review.createdAt.month.toString().padLeft(2, '0')}.${review.createdAt.day.toString().padLeft(2, '0')}',
              style: AppTextStyles.small,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// 공용 컴포넌트
// =============================================================

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _ErrorView extends StatelessWidget {
  final String message;
  final String? detail;
  const _ErrorView({required this.message, this.detail});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 36, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(message, style: AppTextStyles.bodyBold),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                style: AppTextStyles.small.copyWith(color: AppColors.textSub),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.hint,
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
                boxShadow: appShadow,
              ),
              child: Icon(icon, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.bodyBold),
            const SizedBox(height: 6),
            Text(
              hint,
              style: AppTextStyles.small.copyWith(color: AppColors.textSub),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BosalCard extends StatelessWidget {
  final Bosal bosal;
  const _BosalCard({required this.bosal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/bosal/${bosal.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: appShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                bosal.name.isNotEmpty ? bosal.name[0] : '보',
                style: AppTextStyles.bodyBold.copyWith(
                  color: AppColors.primary,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bosal.name, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 2),
                      Text(
                        '${bosal.rating}',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(' (${bosal.reviewCount})',
                          style: AppTextStyles.small),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bosal.consultStyle,
                          style: AppTextStyles.small,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textSub),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(booking.status);
    final canReview = booking.status == BookingStatus.completed;
    return GestureDetector(
      onTap: () => context.push('/bosal/${booking.bosalId}'),
      child: Container(
        padding: const EdgeInsets.all(14),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusInfo.$2.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusInfo.$1,
                    style: AppTextStyles.tag.copyWith(color: statusInfo.$2),
                  ),
                ),
                const Spacer(),
                Text('${booking.price.toString()}원',
                    style: AppTextStyles.bodyBold),
              ],
            ),
            const SizedBox(height: 10),
            Text(booking.consultType, style: AppTextStyles.cardTitle),
            const SizedBox(height: 4),
            if (booking.consultDate != null)
              Text(
                '${booking.consultDate!.year}.${booking.consultDate!.month.toString().padLeft(2, '0')}.${booking.consultDate!.day.toString().padLeft(2, '0')} '
                '${booking.consultDate!.hour.toString().padLeft(2, '0')}:${booking.consultDate!.minute.toString().padLeft(2, '0')}',
                style: AppTextStyles.small,
              ),
            if (canReview) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    '/review/compose?bosalId=${booking.bosalId}&reservationId=${booking.id}',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.rate_review_outlined, size: 16),
                  label: const Text('후기 작성'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (String, Color) _statusInfo(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return ('대기', AppColors.accent);
      case BookingStatus.confirmed:
        return ('확정', AppColors.primary);
      case BookingStatus.completed:
        return ('완료', AppColors.primaryDark);
      case BookingStatus.cancelled:
        return ('취소', AppColors.textSub);
    }
  }
}

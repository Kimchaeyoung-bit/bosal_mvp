import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/review.dart';
import 'auth_provider.dart';
import 'data_source_providers.dart';

/// 보살별 공개 리뷰. UI에서 `ref.watch(bosalReviewsProvider(bosalId))` 로 사용.
final bosalReviewsProvider =
    FutureProvider.autoDispose.family<List<Review>, String>((ref, bosalId) async {
  final ds = ref.watch(reviewDataSourceProvider);
  return ds.listForBosal(bosalId);
});

/// 보살 평점 분포 (1..10 → count).
final bosalRatingDistributionProvider =
    FutureProvider.autoDispose.family<Map<int, int>, String>((ref, bosalId) async {
  final ds = ref.watch(reviewDataSourceProvider);
  return ds.ratingDistribution(bosalId);
});

/// 본인 작성 리뷰. 로그인 안 됐으면 빈 리스트.
final myReviewsProvider =
    FutureProvider.autoDispose<List<Review>>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return const <Review>[];
  final ds = ref.watch(reviewDataSourceProvider);
  return ds.listForUser(user.id);
});

/// 리뷰 액션 (생성/수정/삭제). 호출자가 try/catch.
class ReviewActions {
  ReviewActions(this._ref);
  final Ref _ref;

  Future<Review> create({
    required String bosalId,
    String? reservationId,
    required int rating,
    String? body,
    bool isPublic = true,
  }) async {
    final ds = _ref.read(reviewDataSourceProvider);
    final review = await ds.create(
      bosalId: bosalId,
      reservationId: reservationId,
      rating: rating,
      body: body,
      isPublic: isPublic,
    );
    // 관련 캐시 무효화 (해당 보살 리뷰·분포·내 리뷰)
    // ignore: invalid_use_of_protected_member, invalid_use_of_internal_member
    _ref.invalidate(bosalReviewsProvider(bosalId));
    // ignore: invalid_use_of_protected_member, invalid_use_of_internal_member
    _ref.invalidate(bosalRatingDistributionProvider(bosalId));
    _ref.invalidate(myReviewsProvider);
    return review;
  }

  Future<Review> update({
    required String reviewId,
    required String bosalId,
    int? rating,
    String? body,
    bool? isPublic,
  }) async {
    final ds = _ref.read(reviewDataSourceProvider);
    final review = await ds.update(
      reviewId: reviewId,
      rating: rating,
      body: body,
      isPublic: isPublic,
    );
    _ref.invalidate(bosalReviewsProvider(bosalId));
    _ref.invalidate(bosalRatingDistributionProvider(bosalId));
    _ref.invalidate(myReviewsProvider);
    return review;
  }

  Future<void> delete({required String reviewId, required String bosalId}) async {
    final ds = _ref.read(reviewDataSourceProvider);
    await ds.delete(reviewId);
    _ref.invalidate(bosalReviewsProvider(bosalId));
    _ref.invalidate(bosalRatingDistributionProvider(bosalId));
    _ref.invalidate(myReviewsProvider);
  }
}

final reviewActionsProvider = Provider<ReviewActions>(
  (ref) => ReviewActions(ref),
);

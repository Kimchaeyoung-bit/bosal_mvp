import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/review.dart';

/// 리뷰 도메인 인터페이스.
///
/// DB: [supabase/migrations/20260424000600_reviews_favorites.sql]
/// - INSERT: trigger `reviews_enforce_completed` 가 completed 예약 보유 검증
/// - rating/avg/count 자동 갱신 (`tg_reviews_recalc_bosal`)
/// - is_public=false 면 본인/소유자/관리자만 조회
abstract class ReviewDataSource {
  /// 보살의 공개 리뷰 (최신순).
  Future<List<Review>> listForBosal(String bosalId, {int limit = 50});

  /// 본인이 작성한 리뷰 목록 (공개/비공개 모두).
  Future<List<Review>> listForUser(String userId, {int limit = 50});

  /// 리뷰 작성. completed 예약 검증은 DB 트리거가 수행.
  Future<Review> create({
    required String bosalId,
    String? reservationId,
    required int rating,
    String? body,
    bool isPublic = true,
  });

  /// 리뷰 수정 (본인). rating/body/is_public 만 변경 가능.
  Future<Review> update({
    required String reviewId,
    int? rating,
    String? body,
    bool? isPublic,
  });

  /// 리뷰 삭제 (본인). RLS 가 권한 강제.
  Future<void> delete(String reviewId);

  /// 보살 평점 분포 — 1~10 점 별 개수. UI 시각화용.
  /// 키: 정수(1..10), 값: 해당 점수 리뷰 개수. 비어있는 점수는 0.
  Future<Map<int, int>> ratingDistribution(String bosalId);
}

// ================================================================
// Mock
// ================================================================
class MockReviewDataSource implements ReviewDataSource {
  final List<Review> _store = _seed();

  static List<Review> _seed() {
    final base = DateTime.now();
    final samples = <_M>[
      _M('1', 'user_2', '김지원', 10, '정말 정확하고 따뜻한 상담이었어요. 감사합니다.', 2),
      _M('1', 'user_3', '이수민', 9, '시원하게 답해주셔서 마음이 가벼워졌습니다.', 7),
      _M('1', 'user_4', '박서연', 10, null, 14),
      _M('2', 'user_5', '정유진', 9, '취업 방향에 큰 도움이 되었습니다.', 3),
      _M('2', 'user_2', '김지원', 8, '공감 가는 상담이었어요.', 12),
      _M('3', 'user_6', '최하늘', 9, '재물운에 대한 디테일한 분석.', 5),
      _M('4', 'user_3', '이수민', 10, '타로 풀이가 인상적이었습니다.', 1),
      _M('5', 'user_7', '윤도현', 9, '가족 상담 후 마음이 편안해졌어요.', 9),
    ];
    return List.generate(
      samples.length,
      (i) {
        final s = samples[i];
        return Review(
          id: 'mock_review_${i + 1}',
          bosalId: s.bosalId,
          userId: s.userId,
          userDisplayName: s.name,
          rating: s.rating,
          body: s.body,
          createdAt: base.subtract(Duration(days: s.daysAgo)),
        );
      },
    );
  }

  @override
  Future<List<Review>> listForBosal(String bosalId, {int limit = 50}) async {
    return _store
        .where((r) => r.bosalId == bosalId && r.isPublic)
        .take(limit)
        .toList();
  }

  @override
  Future<List<Review>> listForUser(String userId, {int limit = 50}) async {
    return _store.where((r) => r.userId == userId).take(limit).toList();
  }

  @override
  Future<Review> create({
    required String bosalId,
    String? reservationId,
    required int rating,
    String? body,
    bool isPublic = true,
  }) async {
    final r = Review(
      id: 'mock_review_${DateTime.now().microsecondsSinceEpoch}',
      bosalId: bosalId,
      reservationId: reservationId,
      userId: 'user_1',
      userDisplayName: '나',
      rating: rating,
      body: body,
      isPublic: isPublic,
      createdAt: DateTime.now(),
    );
    _store.insert(0, r);
    return r;
  }

  @override
  Future<Review> update({
    required String reviewId,
    int? rating,
    String? body,
    bool? isPublic,
  }) async {
    final i = _store.indexWhere((r) => r.id == reviewId);
    if (i < 0) throw StateError('review not found');
    final cur = _store[i];
    final updated = Review(
      id: cur.id,
      bosalId: cur.bosalId,
      reservationId: cur.reservationId,
      userId: cur.userId,
      userDisplayName: cur.userDisplayName,
      userAvatarUrl: cur.userAvatarUrl,
      rating: rating ?? cur.rating,
      body: body ?? cur.body,
      isPublic: isPublic ?? cur.isPublic,
      createdAt: cur.createdAt,
    );
    _store[i] = updated;
    return updated;
  }

  @override
  Future<void> delete(String reviewId) async {
    _store.removeWhere((r) => r.id == reviewId);
  }

  @override
  Future<Map<int, int>> ratingDistribution(String bosalId) async {
    final dist = {for (var i = 1; i <= 10; i++) i: 0};
    for (final r in _store.where((r) => r.bosalId == bosalId && r.isPublic)) {
      dist[r.rating] = (dist[r.rating] ?? 0) + 1;
    }
    return dist;
  }
}

class _M {
  final String bosalId;
  final String userId;
  final String name;
  final int rating;
  final String? body;
  final int daysAgo;
  const _M(this.bosalId, this.userId, this.name, this.rating, this.body, this.daysAgo);
}

// ================================================================
// Supabase
// ================================================================
class SupabaseReviewDataSource implements ReviewDataSource {
  SupabaseReviewDataSource(this._client);
  final SupabaseClient _client;

  static const _table = 'reviews';
  // PostgREST: profiles join via user_id FK
  static const _selectSpec =
      '*,author:profiles!reviews_user_id_fkey(display_name,avatar_url)';

  @override
  Future<List<Review>> listForBosal(String bosalId, {int limit = 50}) async {
    final rows = await _client
        .from(_table)
        .select(_selectSpec)
        .eq('bosal_id', bosalId)
        .eq('is_public', true)
        .filter('deleted_at', 'is', null)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.cast<Map<String, dynamic>>().map(Review.fromMap).toList();
  }

  @override
  Future<List<Review>> listForUser(String userId, {int limit = 50}) async {
    final rows = await _client
        .from(_table)
        .select(_selectSpec)
        .eq('user_id', userId)
        .filter('deleted_at', 'is', null)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.cast<Map<String, dynamic>>().map(Review.fromMap).toList();
  }

  @override
  Future<Review> create({
    required String bosalId,
    String? reservationId,
    required int rating,
    String? body,
    bool isPublic = true,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('인증이 필요합니다');
    }
    final row = await _client
        .from(_table)
        .insert({
          'bosal_id': bosalId,
          if (reservationId != null) 'reservation_id': reservationId,
          'user_id': uid,
          'rating': rating,
          if (body != null) 'body': body,
          'is_public': isPublic,
        })
        .select(_selectSpec)
        .single();
    return Review.fromMap(row);
  }

  @override
  Future<Review> update({
    required String reviewId,
    int? rating,
    String? body,
    bool? isPublic,
  }) async {
    final patch = <String, dynamic>{
      if (rating != null) 'rating': rating,
      if (body != null) 'body': body,
      if (isPublic != null) 'is_public': isPublic,
    };
    if (patch.isEmpty) {
      // 변경 없음 — 그냥 현재 값 반환
      final row = await _client
          .from(_table)
          .select(_selectSpec)
          .eq('id', reviewId)
          .single();
      return Review.fromMap(row);
    }
    final row = await _client
        .from(_table)
        .update(patch)
        .eq('id', reviewId)
        .select(_selectSpec)
        .single();
    return Review.fromMap(row);
  }

  @override
  Future<void> delete(String reviewId) async {
    // Soft delete via deleted_at column
    await _client
        .from(_table)
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', reviewId);
  }

  @override
  Future<Map<int, int>> ratingDistribution(String bosalId) async {
    // 단순 클라이언트 집계. 리뷰 수가 매우 많아지면 RPC 또는 view 도입 권장.
    final rows = await _client
        .from(_table)
        .select('rating')
        .eq('bosal_id', bosalId)
        .eq('is_public', true)
        .filter('deleted_at', 'is', null);
    final dist = {for (var i = 1; i <= 10; i++) i: 0};
    for (final r in rows.cast<Map<String, dynamic>>()) {
      final score = (r['rating'] as num).toInt();
      dist[score] = (dist[score] ?? 0) + 1;
    }
    return dist;
  }
}

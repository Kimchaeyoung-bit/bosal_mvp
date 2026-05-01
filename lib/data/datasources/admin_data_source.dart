import 'package:supabase_flutter/supabase_flutter.dart';

/// 관리자 초대 생성 결과.
class BosalInviteResult {
  final String bosalId;
  final String inviteCode;
  const BosalInviteResult({required this.bosalId, required this.inviteCode});
}

class BosalInviteSummary {
  final String code;
  final String? bosalId;
  final String? bosalName;
  final String? email;
  final DateTime? expiresAt;
  final DateTime? usedAt;
  final String status; // 'active' | 'used' | 'expired'

  const BosalInviteSummary({
    required this.code,
    this.bosalId,
    this.bosalName,
    this.email,
    this.expiresAt,
    this.usedAt,
    required this.status,
  });

  factory BosalInviteSummary.fromMap(Map<String, dynamic> m) =>
      BosalInviteSummary(
        code: m['code'] as String,
        bosalId: m['bosal_id'] as String?,
        bosalName: m['bosal_name'] as String?,
        email: m['email'] as String?,
        expiresAt: m['expires_at'] == null
            ? null
            : DateTime.parse(m['expires_at'] as String),
        usedAt: m['used_at'] == null
            ? null
            : DateTime.parse(m['used_at'] as String),
        status: m['status'] as String? ?? 'active',
      );
}

/// 보살별 분석 요약 — admin 전용.
///
/// 데이터 출처: `admin_list_bosal_analytics()` RPC (집계 뷰 + bosals 컬럼 합성).
class BosalAnalytics {
  final String bosalId;
  final String bosalName;
  final bool isPublished;
  final double ratingAvg;
  final int reviewCount;
  final int consultRequestCount;
  final int callTotal;
  final int call24h;
  final int call7d;
  final int call30d;
  final int resvBtnTotal;
  final int resvBtn24h;
  final int resvBtn7d;
  final int resvBtn30d;

  const BosalAnalytics({
    required this.bosalId,
    required this.bosalName,
    required this.isPublished,
    required this.ratingAvg,
    required this.reviewCount,
    required this.consultRequestCount,
    required this.callTotal,
    required this.call24h,
    required this.call7d,
    required this.call30d,
    required this.resvBtnTotal,
    required this.resvBtn24h,
    required this.resvBtn7d,
    required this.resvBtn30d,
  });

  factory BosalAnalytics.fromMap(Map<String, dynamic> m) => BosalAnalytics(
        bosalId: m['bosal_id'] as String,
        bosalName: m['bosal_name'] as String? ?? '',
        isPublished: (m['is_published'] as bool?) ?? false,
        ratingAvg: (m['rating_avg'] as num?)?.toDouble() ?? 0.0,
        reviewCount: (m['review_count'] as num?)?.toInt() ?? 0,
        consultRequestCount:
            (m['consult_request_count'] as num?)?.toInt() ?? 0,
        callTotal: (m['call_total'] as num?)?.toInt() ?? 0,
        call24h: (m['call_24h'] as num?)?.toInt() ?? 0,
        call7d: (m['call_7d'] as num?)?.toInt() ?? 0,
        call30d: (m['call_30d'] as num?)?.toInt() ?? 0,
        resvBtnTotal: (m['resv_btn_total'] as num?)?.toInt() ?? 0,
        resvBtn24h: (m['resv_btn_24h'] as num?)?.toInt() ?? 0,
        resvBtn7d: (m['resv_btn_7d'] as num?)?.toInt() ?? 0,
        resvBtn30d: (m['resv_btn_30d'] as num?)?.toInt() ?? 0,
      );
}

enum AnalyticsWindow { h24, d7, d30 }

extension AnalyticsWindowX on AnalyticsWindow {
  int call(BosalAnalytics a) => switch (this) {
        AnalyticsWindow.h24 => a.call24h,
        AnalyticsWindow.d7 => a.call7d,
        AnalyticsWindow.d30 => a.call30d,
      };
  int resv(BosalAnalytics a) => switch (this) {
        AnalyticsWindow.h24 => a.resvBtn24h,
        AnalyticsWindow.d7 => a.resvBtn7d,
        AnalyticsWindow.d30 => a.resvBtn30d,
      };
  String get label => switch (this) {
        AnalyticsWindow.h24 => '24시간',
        AnalyticsWindow.d7 => '7일',
        AnalyticsWindow.d30 => '30일',
      };
}

abstract class AdminDataSource {
  /// 기존 보살에 초대 코드 발급.
  Future<String> createInviteForBosal({
    required String bosalId,
    int expiresDays = 30,
    String? email,
  });

  /// 빈 보살 레코드 + 초대 코드를 한번에 생성.
  Future<BosalInviteResult> createBosalWithInvite({
    required String name,
    String? phoneDisplay,
    String? regionCode,
    String? subRegionCode,
    int expiresDays = 30,
    String? email,
  });

  /// 살아있는 초대 코드 리스트 (관리자 대시보드용).
  Future<List<BosalInviteSummary>> listInvites();

  /// 보살별 분석 요약 (전체 집계 + 24h/7d/30d 윈도우).
  Future<List<BosalAnalytics>> listBosalAnalytics();
}

class MockAdminDataSource implements AdminDataSource {
  @override
  Future<String> createInviteForBosal({
    required String bosalId,
    int expiresDays = 30,
    String? email,
  }) async =>
      throw UnsupportedError('Mock admin not supported');

  @override
  Future<BosalInviteResult> createBosalWithInvite({
    required String name,
    String? phoneDisplay,
    String? regionCode,
    String? subRegionCode,
    int expiresDays = 30,
    String? email,
  }) async =>
      throw UnsupportedError('Mock admin not supported');

  @override
  Future<List<BosalInviteSummary>> listInvites() async => const [];

  @override
  Future<List<BosalAnalytics>> listBosalAnalytics() async {
    // Mock: 데모용 더미 row 몇 개. 실제 분석은 Supabase 모드에서.
    return [
      const BosalAnalytics(
        bosalId: '1',
        bosalName: '가가 보살',
        isPublished: true,
        ratingAvg: 9.9,
        reviewCount: 14,
        consultRequestCount: 45,
        callTotal: 220,
        call24h: 12,
        call7d: 58,
        call30d: 187,
        resvBtnTotal: 88,
        resvBtn24h: 5,
        resvBtn7d: 21,
        resvBtn30d: 71,
      ),
      const BosalAnalytics(
        bosalId: '2',
        bosalName: '나나 보살',
        isPublished: true,
        ratingAvg: 9.7,
        reviewCount: 22,
        consultRequestCount: 38,
        callTotal: 180,
        call24h: 7,
        call7d: 39,
        call30d: 142,
        resvBtnTotal: 70,
        resvBtn24h: 2,
        resvBtn7d: 14,
        resvBtn30d: 53,
      ),
    ];
  }
}

class SupabaseAdminDataSource implements AdminDataSource {
  SupabaseAdminDataSource(this._client);
  final SupabaseClient _client;

  @override
  Future<String> createInviteForBosal({
    required String bosalId,
    int expiresDays = 30,
    String? email,
  }) async {
    final result = await _client.rpc('create_bosal_invite', params: {
      'p_bosal_id': bosalId,
      'p_expires_days': expiresDays,
      'p_email': email,
    });
    return result as String;
  }

  @override
  Future<BosalInviteResult> createBosalWithInvite({
    required String name,
    String? phoneDisplay,
    String? regionCode,
    String? subRegionCode,
    int expiresDays = 30,
    String? email,
  }) async {
    final rows = await _client.rpc('create_bosal_with_invite', params: {
      'p_name': name,
      'p_phone_display': phoneDisplay,
      'p_region_code': regionCode,
      'p_sub_region_code': subRegionCode,
      'p_expires_days': expiresDays,
      'p_email': email,
    });
    final row = (rows is List ? rows.first : rows) as Map<String, dynamic>;
    return BosalInviteResult(
      bosalId: row['bosal_id'] as String,
      inviteCode: row['invite_code'] as String,
    );
  }

  @override
  Future<List<BosalInviteSummary>> listInvites() async {
    final rows = await _client
        .from('v_active_bosal_invites')
        .select()
        .order('expires_at', ascending: false);
    return rows
        .cast<Map<String, dynamic>>()
        .map(BosalInviteSummary.fromMap)
        .toList();
  }

  @override
  Future<List<BosalAnalytics>> listBosalAnalytics() async {
    final rows = await _client.rpc('admin_list_bosal_analytics');
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(BosalAnalytics.fromMap)
        .toList();
  }
}

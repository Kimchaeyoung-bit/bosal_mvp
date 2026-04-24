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
}

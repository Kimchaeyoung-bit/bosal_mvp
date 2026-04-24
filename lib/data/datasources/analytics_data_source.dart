import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AnalyticsDataSource {
  Future<void> logCallTap({required String bosalId, String? sessionId});
  Future<void> logReservationButtonTap({required String bosalId, String? sessionId});
}

/// Mock: no-op (keeps non-network dev loop simple).
class MockAnalyticsDataSource implements AnalyticsDataSource {
  @override
  Future<void> logCallTap({required String bosalId, String? sessionId}) async {}
  @override
  Future<void> logReservationButtonTap({required String bosalId, String? sessionId}) async {}
}

/// Supabase: append to event tables. Fire-and-forget with silent failure —
/// analytics must never break the user flow.
class SupabaseAnalyticsDataSource implements AnalyticsDataSource {
  SupabaseAnalyticsDataSource(this._client);
  final SupabaseClient _client;

  @override
  Future<void> logCallTap({required String bosalId, String? sessionId}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return; // RLS requires authenticated
    try {
      await _client.from('call_events').insert({
        'bosal_id': bosalId,
        'user_id': uid,
        'session_id': sessionId,
        'client_ts': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // swallow rate-limit / network errors
    }
  }

  @override
  Future<void> logReservationButtonTap({
    required String bosalId,
    String? sessionId,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _client.from('reservation_button_events').insert({
        'bosal_id': bosalId,
        'user_id': uid,
        'session_id': sessionId,
        'client_ts': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }
}

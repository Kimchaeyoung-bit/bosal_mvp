import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reservation.dart';

abstract class ReservationDataSource {
  Future<Reservation> createPending({
    required String bosalId,
    required String userId,
    required DateTime consultAt,
    required int priceAmount,
    ConsultChannel channel,
    int durationMin,
    Map<String, dynamic> metadata,
  });

  Future<List<Reservation>> listForUser(String userId);
  Future<List<Reservation>> listForBosal(String bosalId);

  /// Realtime stream of bosal's incoming reservations (for dashboard).
  Stream<List<Reservation>> watchForBosal(String bosalId);

  /// Realtime stream of user's own reservations.
  Stream<List<Reservation>> watchForUser(String userId);

  Future<Reservation> confirm(String id, DateTime consultAt);
  Future<Reservation> cancel(String id, {String? reason});
  Future<Reservation> complete(String id);
  Future<Reservation> reject(String id, {String? reason});
}

// ================================================================
// In-memory mock (no DB) — preserves current booking_provider behavior.
// Realtime streams replayed locally via StreamController.
// ================================================================
class MockReservationDataSource implements ReservationDataSource {
  final List<Reservation> _store = [];

  @override
  Future<Reservation> createPending({
    required String bosalId,
    required String userId,
    required DateTime consultAt,
    required int priceAmount,
    ConsultChannel channel = ConsultChannel.inPerson,
    int durationMin = 60,
    Map<String, dynamic> metadata = const {},
  }) async {
    final now = DateTime.now().toUtc();
    final r = Reservation(
      id: 'mock_${now.microsecondsSinceEpoch}',
      bosalId: bosalId,
      userId: userId,
      channel: channel,
      requestedAt: now,
      consultAt: consultAt,
      durationMin: durationMin,
      priceAmount: priceAmount,
      metadata: metadata,
      createdAt: now,
    );
    _store.insert(0, r);
    return r;
  }

  @override
  Future<List<Reservation>> listForUser(String userId) async =>
      _store.where((r) => r.userId == userId).toList(growable: false);

  @override
  Future<List<Reservation>> listForBosal(String bosalId) async =>
      _store.where((r) => r.bosalId == bosalId).toList(growable: false);

  @override
  Stream<List<Reservation>> watchForBosal(String bosalId) async* {
    yield await listForBosal(bosalId);
  }

  @override
  Stream<List<Reservation>> watchForUser(String userId) async* {
    yield await listForUser(userId);
  }

  Reservation _mutate(String id, Reservation Function(Reservation) f) {
    final i = _store.indexWhere((r) => r.id == id);
    if (i < 0) throw StateError('reservation not found');
    final updated = f(_store[i]);
    _store[i] = updated;
    return updated;
  }

  @override
  Future<Reservation> confirm(String id, DateTime consultAt) async =>
      _mutate(id, (r) => Reservation(
            id: r.id,
            bosalId: r.bosalId,
            userId: r.userId,
            channel: r.channel,
            requestedAt: r.requestedAt,
            consultAt: consultAt,
            durationMin: r.durationMin,
            status: ReservationStatus.confirmed,
            priceAmount: r.priceAmount,
            priceCurrency: r.priceCurrency,
            paymentStatus: r.paymentStatus,
            paymentProvider: r.paymentProvider,
            paymentProviderTxnId: r.paymentProviderTxnId,
            metadata: r.metadata,
            createdAt: r.createdAt,
            updatedAt: DateTime.now().toUtc(),
          ));

  @override
  Future<Reservation> cancel(String id, {String? reason}) async => _mutate(
        id,
        (r) => Reservation(
          id: r.id,
          bosalId: r.bosalId,
          userId: r.userId,
          channel: r.channel,
          requestedAt: r.requestedAt,
          consultAt: r.consultAt,
          durationMin: r.durationMin,
          status: ReservationStatus.cancelled,
          cancellationReason: reason,
          priceAmount: r.priceAmount,
          priceCurrency: r.priceCurrency,
          paymentStatus: r.paymentStatus,
          paymentProvider: r.paymentProvider,
          paymentProviderTxnId: r.paymentProviderTxnId,
          metadata: r.metadata,
          createdAt: r.createdAt,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

  @override
  Future<Reservation> complete(String id) async => _mutate(
        id,
        (r) => Reservation(
          id: r.id,
          bosalId: r.bosalId,
          userId: r.userId,
          channel: r.channel,
          requestedAt: r.requestedAt,
          consultAt: r.consultAt,
          durationMin: r.durationMin,
          status: ReservationStatus.completed,
          priceAmount: r.priceAmount,
          priceCurrency: r.priceCurrency,
          paymentStatus: r.paymentStatus,
          paymentProvider: r.paymentProvider,
          paymentProviderTxnId: r.paymentProviderTxnId,
          metadata: r.metadata,
          createdAt: r.createdAt,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

  @override
  Future<Reservation> reject(String id, {String? reason}) async => cancel(
        id,
        reason: reason ?? 'rejected_by_bosal',
      );
}

// ================================================================
// Supabase
// ================================================================
class SupabaseReservationDataSource implements ReservationDataSource {
  SupabaseReservationDataSource(this._client);
  final SupabaseClient _client;

  @override
  Future<Reservation> createPending({
    required String bosalId,
    required String userId,
    required DateTime consultAt,
    required int priceAmount,
    ConsultChannel channel = ConsultChannel.inPerson,
    int durationMin = 60,
    Map<String, dynamic> metadata = const {},
  }) async {
    final row = await _client
        .from('reservations')
        .insert({
          'bosal_id': bosalId,
          'user_id': userId,
          'channel': channel.dbValue,
          'consult_at': consultAt.toUtc().toIso8601String(),
          'duration_min': durationMin,
          'price_amount': priceAmount,
          'price_currency': 'KRW',
          'metadata': metadata,
        })
        .select()
        .single();
    return Reservation.fromMap(row);
  }

  @override
  Future<List<Reservation>> listForUser(String userId) async {
    final rows = await _client
        .from('reservations')
        .select()
        .eq('user_id', userId)
        .order('requested_at', ascending: false);
    return rows.cast<Map<String, dynamic>>().map(Reservation.fromMap).toList();
  }

  @override
  Future<List<Reservation>> listForBosal(String bosalId) async {
    final rows = await _client
        .from('reservations')
        .select()
        .eq('bosal_id', bosalId)
        .order('requested_at', ascending: false);
    return rows.cast<Map<String, dynamic>>().map(Reservation.fromMap).toList();
  }

  @override
  Stream<List<Reservation>> watchForBosal(String bosalId) {
    return _client
        .from('reservations')
        .stream(primaryKey: ['id'])
        .eq('bosal_id', bosalId)
        .order('requested_at', ascending: false)
        .map((rows) =>
            rows.map((r) => Reservation.fromMap(r)).toList(growable: false));
  }

  @override
  Stream<List<Reservation>> watchForUser(String userId) {
    return _client
        .from('reservations')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('requested_at', ascending: false)
        .map((rows) =>
            rows.map((r) => Reservation.fromMap(r)).toList(growable: false));
  }

  @override
  Future<Reservation> confirm(String id, DateTime consultAt) async {
    final row = await _client.rpc('confirm_reservation', params: {
      'p_reservation_id': id,
      'p_consult_at': consultAt.toUtc().toIso8601String(),
    });
    return Reservation.fromMap(Map<String, dynamic>.from(row as Map));
  }

  @override
  Future<Reservation> cancel(String id, {String? reason}) async {
    final row = await _client.rpc('cancel_reservation', params: {
      'p_reservation_id': id,
      'p_reason': reason,
    });
    return Reservation.fromMap(Map<String, dynamic>.from(row as Map));
  }

  @override
  Future<Reservation> complete(String id) async {
    final row = await _client.rpc('complete_reservation', params: {
      'p_reservation_id': id,
    });
    return Reservation.fromMap(Map<String, dynamic>.from(row as Map));
  }

  @override
  Future<Reservation> reject(String id, {String? reason}) async {
    final row = await _client.rpc('reject_reservation', params: {
      'p_reservation_id': id,
      'p_reason': reason,
    });
    return Reservation.fromMap(Map<String, dynamic>.from(row as Map));
  }
}

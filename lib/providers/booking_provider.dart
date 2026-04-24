import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/reservation_data_source.dart';
import '../data/models/booking.dart';
import '../data/models/reservation.dart';
import 'auth_provider.dart';
import 'data_source_providers.dart';

/// 예약 목록 (UI 호환을 위해 `Booking` 리스트로 노출).
///
/// - `DATA_SOURCE=mock`: 이전처럼 in-memory 상태 (앱 재시작 시 휘발, mock 초기 샘플 없음).
/// - `DATA_SOURCE=supabase`: 현재 사용자 role에 따라 본인 예약 또는 보살 예약 로드.
///
/// 상태 변경(add/confirm/complete/reject/cancel)은 data source를 통해 원격에 반영된 뒤
/// 로컬 state를 갱신한다. Realtime은 `reservationsStreamProvider`에서 제공.
final bookingsProvider =
    StateNotifierProvider<BookingsNotifier, List<Booking>>((ref) {
  final ds = ref.watch(reservationDataSourceProvider);
  final user = ref.watch(authProvider);
  final notifier = BookingsNotifier(ds, user?.id, user?.bosalId);
  // 사용자 변경 시 자동 리로드
  notifier._load();
  return notifier;
});

class BookingsNotifier extends StateNotifier<List<Booking>> {
  BookingsNotifier(this._ds, this._userId, this._bosalId) : super(const []);

  final ReservationDataSource _ds;
  final String? _userId;
  final String? _bosalId;

  Future<void> _load() async {
    if (_userId == null) {
      state = const [];
      return;
    }
    try {
      // 보살 역할이면 bosal 기준, 일반 사용자면 user 기준
      final list = _bosalId != null
          ? await _ds.listForBosal(_bosalId)
          : await _ds.listForUser(_userId);
      state = list.map(Booking.fromReservation).toList(growable: false);
    } catch (_) {
      state = const [];
    }
  }

  /// 새 예약 생성. 기존 UI signature 호환.
  Future<void> add({
    required String bosalId,
    required DateTime consultDate,
    required String consultType,
    required int price,
  }) async {
    final uid = _userId;
    if (uid == null) return;
    final channel = _channelFromType(consultType);
    final r = await _ds.createPending(
      bosalId: bosalId,
      userId: uid,
      consultAt: consultDate,
      priceAmount: price,
      channel: channel,
    );
    state = [Booking.fromReservation(r), ...state];
  }

  Future<void> confirm(String bookingId) => _apply(
        bookingId,
        (r) => _ds.confirm(r.id, r.consultAt ?? DateTime.now().toUtc()),
      );

  Future<void> complete(String bookingId) =>
      _apply(bookingId, (r) => _ds.complete(r.id));

  Future<void> reject(String bookingId) =>
      _apply(bookingId, (r) => _ds.reject(r.id, reason: 'rejected_by_bosal'));

  Future<void> cancel(String bookingId) =>
      _apply(bookingId, (r) => _ds.cancel(r.id, reason: 'cancelled_by_user'));

  Future<void> _apply(
    String bookingId,
    Future<Reservation> Function(Reservation r) op,
  ) async {
    // Lookup-by-id from state (uses the Reservation-derived Booking id 그대로).
    // Data source 호출은 id만 있으면 되므로 Reservation 생성을 stub으로 진행.
    final stub = Reservation(
      id: bookingId,
      bosalId: '',
      userId: '',
      requestedAt: DateTime.fromMillisecondsSinceEpoch(0).toUtc(),
      consultAt: null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0).toUtc(),
    );
    try {
      final updated = await op(stub);
      state = [
        for (final b in state)
          if (b.id == bookingId) Booking.fromReservation(updated) else b,
      ];
    } catch (_) {
      // 실패 시 전체 리로드
      await _load();
    }
  }

  ConsultChannel _channelFromType(String label) {
    switch (label) {
      case '전화 상담':
        return ConsultChannel.phone;
      case '화상 상담':
        return ConsultChannel.video;
      case '채팅 상담':
        return ConsultChannel.chat;
      case '대면 상담':
      default:
        return ConsultChannel.inPerson;
    }
  }
}

/// 선택적 Realtime 스트림 (Phase 4 UI 연동 시 사용).
final userReservationsStreamProvider =
    StreamProvider.autoDispose<List<Reservation>>((ref) {
  final ds = ref.watch(reservationDataSourceProvider);
  final user = ref.watch(authProvider);
  if (user == null) return const Stream.empty();
  return ds.watchForUser(user.id);
});

final bosalReservationsStreamProvider =
    StreamProvider.autoDispose<List<Reservation>>((ref) {
  final ds = ref.watch(reservationDataSourceProvider);
  final user = ref.watch(authProvider);
  final bid = user?.bosalId;
  if (bid == null) return const Stream.empty();
  return ds.watchForBosal(bid);
});

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification.dart';

/// 사용자 알림 도메인 인터페이스.
///
/// 모든 메서드는 본인 알림에 한정. RLS와 RPC가 권한을 강제하므로 datasource
/// 호출부는 user_id를 직접 검증할 필요 없음.
abstract class NotificationDataSource {
  /// 본인 알림 목록 (최신순). 한 번만 fetch — 실시간은 [watch] 사용.
  Future<List<AppNotification>> listForUser({int limit = 50});

  /// Realtime stream of notifications for current user.
  /// Returns full snapshot on each change (newly inserted/updated/deleted).
  Stream<List<AppNotification>> watch();

  /// 단일 알림 읽음 처리.
  Future<AppNotification> markAsRead(String id);

  /// 본인 미읽음 전부 읽음 처리. 갱신된 row count 반환.
  Future<int> markAllAsRead();

  /// 단일 알림 삭제.
  Future<void> delete(String id);
}

// ================================================================
// Mock — 메모리 기반. 앱 재시작 시 초기 시드로 리셋.
// ================================================================
class MockNotificationDataSource implements NotificationDataSource {
  final List<AppNotification> _store;
  final _controller = StreamController<List<AppNotification>>.broadcast();

  MockNotificationDataSource() : _store = _seed();

  static List<AppNotification> _seed() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'mock_1',
        userId: 'user_1',
        type: NotificationType.booking,
        title: '예약 확정',
        body: '가가 보살님과의 상담이 내일 오후 2시로 확정되었습니다.',
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      AppNotification(
        id: 'mock_2',
        userId: 'user_1',
        type: NotificationType.booking,
        title: '상담 리마인더',
        body: '가가 보살님과의 상담이 1시간 후 시작됩니다.',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: 'mock_3',
        userId: 'user_1',
        type: NotificationType.review,
        title: '리뷰 요청',
        body: '나나 보살님과의 상담은 어떠셨나요? 리뷰를 남겨주세요.',
        isRead: true,
        readAt: now.subtract(const Duration(hours: 12)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      AppNotification(
        id: 'mock_4',
        userId: 'user_1',
        type: NotificationType.system,
        title: '보살 앱 업데이트',
        body: '더 나은 서비스를 위해 앱이 업데이트되었습니다.',
        isRead: true,
        readAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  void _emit() => _controller.add(List<AppNotification>.from(_store));

  @override
  Future<List<AppNotification>> listForUser({int limit = 50}) async {
    return List<AppNotification>.from(_store.take(limit));
  }

  @override
  Stream<List<AppNotification>> watch() async* {
    yield List<AppNotification>.from(_store);
    yield* _controller.stream;
  }

  @override
  Future<AppNotification> markAsRead(String id) async {
    final idx = _store.indexWhere((n) => n.id == id);
    if (idx < 0) {
      throw StateError('notification not found: $id');
    }
    final now = DateTime.now();
    _store[idx] = _store[idx].copyWith(isRead: true, readAt: now);
    _emit();
    return _store[idx];
  }

  @override
  Future<int> markAllAsRead() async {
    final now = DateTime.now();
    var count = 0;
    for (var i = 0; i < _store.length; i++) {
      if (!_store[i].isRead) {
        _store[i] = _store[i].copyWith(isRead: true, readAt: now);
        count++;
      }
    }
    if (count > 0) _emit();
    return count;
  }

  @override
  Future<void> delete(String id) async {
    _store.removeWhere((n) => n.id == id);
    _emit();
  }
}

// ================================================================
// Supabase — RLS·RPC 기반. user_id 필터는 RLS가 강제.
// ================================================================
class SupabaseNotificationDataSource implements NotificationDataSource {
  SupabaseNotificationDataSource(this._client);
  final SupabaseClient _client;

  static const _table = 'notifications';

  @override
  Future<List<AppNotification>> listForUser({int limit = 50}) async {
    final rows = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.cast<Map<String, dynamic>>().map(AppNotification.fromMap).toList();
  }

  @override
  Stream<List<AppNotification>> watch() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return Stream.value(const <AppNotification>[]);
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(AppNotification.fromMap).toList(growable: false));
  }

  @override
  Future<AppNotification> markAsRead(String id) async {
    final row = await _client.rpc('mark_notification_read', params: {'p_id': id});
    return AppNotification.fromMap(Map<String, dynamic>.from(row as Map));
  }

  @override
  Future<int> markAllAsRead() async {
    final result = await _client.rpc('mark_all_notifications_read');
    return (result as num).toInt();
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}

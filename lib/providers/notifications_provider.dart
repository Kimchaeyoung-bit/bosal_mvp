import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../data/models/notification.dart';
import 'auth_provider.dart';
import 'data_source_providers.dart';

/// 본인 알림 Realtime stream. 로그인 상태 변경 시 자동 재구독.
final notificationsStreamProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final user = ref.watch(authProvider);
  final ds = ref.watch(notificationDataSourceProvider);
  if (user == null) return Stream.value(const <AppNotification>[]);
  return ds.watch();
});

/// AsyncValue → 동기 리스트 (UI 빠른 액세스용). 로딩/에러 시 빈 리스트.
final notificationsProvider = Provider<List<AppNotification>>((ref) {
  return ref.watch(notificationsStreamProvider).maybeWhen(
        data: (v) => v,
        orElse: () => const <AppNotification>[],
      );
});

/// 미읽음 카운트.
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.isRead).length;
});

/// 알림 액션 묶음 (읽음/일괄읽음/삭제).
class NotificationActions {
  NotificationActions(this._ref);
  final Ref _ref;

  Future<void> markAsRead(String id) async {
    final ds = _ref.read(notificationDataSourceProvider);
    try {
      await ds.markAsRead(id);
    } catch (_) {
      // Realtime stream 으로 자동 재동기화. 토스트는 호출자가 결정.
      rethrow;
    }
  }

  Future<int> markAllAsRead() async {
    final ds = _ref.read(notificationDataSourceProvider);
    return ds.markAllAsRead();
  }

  Future<void> delete(String id) async {
    final ds = _ref.read(notificationDataSourceProvider);
    await ds.delete(id);
  }
}

final notificationActionsProvider = Provider<NotificationActions>(
  (ref) => NotificationActions(ref),
);

// ----- UI 헬퍼 -----

IconData notifIcon(NotificationType type) {
  switch (type) {
    case NotificationType.booking:
      return Icons.calendar_today_rounded;
    case NotificationType.review:
      return Icons.star_rounded;
    case NotificationType.invite:
      return Icons.mail_outline_rounded;
    case NotificationType.system:
      return Icons.notifications_rounded;
  }
}

Color notifColor(NotificationType type) {
  switch (type) {
    case NotificationType.booking:
      return AppColors.primary;
    case NotificationType.review:
      return AppColors.accent;
    case NotificationType.invite:
      return AppColors.primaryDark;
    case NotificationType.system:
      return AppColors.textSub;
  }
}

/// 작성 시각 → 사용자 친화적 상대 표기.
String formatRelativeTime(DateTime created, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final diff = n.difference(created);
  if (diff.inSeconds < 60) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  return '${created.year}.${created.month.toString().padLeft(2, '0')}.${created.day.toString().padLeft(2, '0')}';
}

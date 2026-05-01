import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NotifType { booking, review, system }

class NotifItem {
  final NotifType type;
  final String title;
  final String body;
  final String time;
  final bool isRead;

  const NotifItem({
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });

  NotifItem copyWith({bool? isRead}) => NotifItem(
        type: type,
        title: title,
        body: body,
        time: time,
        isRead: isRead ?? this.isRead,
      );
}

final _initialNotifs = [
  const NotifItem(
    type: NotifType.booking,
    title: '예약 확정',
    body: '가가 보살님과의 상담이 내일 오후 2시로 확정되었습니다.',
    time: '방금 전',
  ),
  const NotifItem(
    type: NotifType.booking,
    title: '상담 리마인더',
    body: '가가 보살님과의 상담이 1시간 후 시작됩니다.',
    time: '1시간 전',
  ),
  const NotifItem(
    type: NotifType.review,
    title: '리뷰 요청',
    body: '나나 보살님과의 상담은 어떠셨나요? 리뷰를 남겨주세요.',
    time: '어제',
    isRead: true,
  ),
  const NotifItem(
    type: NotifType.booking,
    title: '예약 취소',
    body: '다다 보살님의 일정으로 인해 상담이 취소되었습니다.',
    time: '2일 전',
    isRead: true,
  ),
  const NotifItem(
    type: NotifType.system,
    title: '보살 앱 업데이트',
    body: '더 나은 서비스를 위해 앱이 업데이트되었습니다.',
    time: '3일 전',
    isRead: true,
  ),
];

class NotificationsNotifier extends StateNotifier<List<NotifItem>> {
  NotificationsNotifier() : super(_initialNotifs);

  void markAsRead(int index) {
    if (index < 0 || index >= state.length) return;
    if (state[index].isRead) return;
    final updated = [...state];
    updated[index] = updated[index].copyWith(isRead: true);
    state = updated;
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<NotifItem>>(
  (ref) => NotificationsNotifier(),
);

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.isRead).length;
});

IconData notifIcon(NotifType type) {
  switch (type) {
    case NotifType.booking:
      return Icons.calendar_today_rounded;
    case NotifType.review:
      return Icons.star_rounded;
    case NotifType.system:
      return Icons.notifications_rounded;
  }
}

Color notifColor(NotifType type) {
  switch (type) {
    case NotifType.booking:
      return const Color(0xFF7B5EA7); // AppColors.primary
    case NotifType.review:
      return const Color(0xFFFF8C42); // AppColors.accent
    case NotifType.system:
      return const Color(0xFF9E9E9E); // AppColors.textSub
  }
}

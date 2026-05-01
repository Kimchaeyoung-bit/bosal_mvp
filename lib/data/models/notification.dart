/// 알림 종류. DB CHECK 제약 (`type in ('booking','review','system','invite')`)와 매칭.
enum NotificationType { booking, review, system, invite }

extension NotificationTypeX on NotificationType {
  String get dbValue => toString().split('.').last;

  static NotificationType fromDb(String s) {
    switch (s) {
      case 'booking':
        return NotificationType.booking;
      case 'review':
        return NotificationType.review;
      case 'invite':
        return NotificationType.invite;
      case 'system':
      default:
        return NotificationType.system;
    }
  }
}

/// 사용자 알림.
///
/// DB: [supabase/migrations/20260424002000_notifications.sql]
/// `notifications` 테이블 1:1 매핑. `data`는 jsonb로 deep-link 페이로드 자유.
class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    this.updatedAt,
  });

  /// PostgREST select 결과 → AppNotification.
  factory AppNotification.fromMap(Map<String, dynamic> m) {
    final dataRaw = m['data'];
    final dataMap = dataRaw is Map<String, dynamic>
        ? dataRaw
        : (dataRaw is Map ? Map<String, dynamic>.from(dataRaw) : <String, dynamic>{});
    return AppNotification(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      type: NotificationTypeX.fromDb(m['type'] as String? ?? 'system'),
      title: m['title'] as String? ?? '',
      body: m['body'] as String? ?? '',
      data: dataMap,
      isRead: (m['is_read'] as bool?) ?? false,
      readAt: m['read_at'] == null ? null : DateTime.parse(m['read_at'] as String),
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: m['updated_at'] == null
          ? null
          : DateTime.parse(m['updated_at'] as String),
    );
  }

  AppNotification copyWith({
    bool? isRead,
    DateTime? readAt,
  }) =>
      AppNotification(
        id: id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        data: data,
        isRead: isRead ?? this.isRead,
        readAt: readAt ?? this.readAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// 본 알림이 가리키는 라우트 (deep link). null이면 액션 없음.
  String? get deepLink {
    final reservationId = data['reservation_id'];
    final bosalId = data['bosal_id'];
    switch (type) {
      case NotificationType.booking:
        if (reservationId is String) return '/booking-tab';
        if (bosalId is String) return '/bosal/$bosalId';
        return null;
      case NotificationType.review:
        if (bosalId is String) return '/bosal/$bosalId';
        return null;
      case NotificationType.invite:
        return '/bosal-onboarding';
      case NotificationType.system:
        return null;
    }
  }
}

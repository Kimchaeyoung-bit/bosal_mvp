import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/notification.dart';
import '../../shared/widgets/app_shadow.dart';
import '../../shared/widgets/login_required_view.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final unread = ref.watch(unreadCountProvider);
    final stream = ref.watch(notificationsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Container(
              padding: EdgeInsets.fromLTRB(8, topPadding + 8, 16, 14),
              color: AppColors.surface.withValues(alpha: 0.9),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 24),
                  ),
                  const SizedBox(width: 4),
                  Text('알림',
                      style: AppTextStyles.sectionTitle.copyWith(fontSize: 17)),
                  if (unread > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$unread',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (isLoggedIn && unread > 0)
                    TextButton(
                      onPressed: () async {
                        try {
                          await ref
                              .read(notificationActionsProvider)
                              .markAllAsRead();
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('읽음 처리 실패: $e')),
                          );
                        }
                      },
                      child: const Text('모두 읽음'),
                    ),
                ],
              ),
            ),

            // 본문
            Expanded(
              child: !isLoggedIn
                  ? const LoginRequiredView()
                  : stream.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => _ErrorBody(message: '$e'),
                      data: (notifs) =>
                          notifs.isEmpty ? const _EmptyBody() : _List(notifs),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _List extends ConsumerWidget {
  final List<AppNotification> notifs;
  const _List(this.notifs);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: notifs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final n = notifs[index];
        return Dismissible(
          key: ValueKey('notif_${n.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppColors.white),
          ),
          onDismissed: (_) async {
            try {
              await ref.read(notificationActionsProvider).delete(n.id);
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('삭제 실패: $e')),
              );
            }
          },
          child: _NotifCard(notif: n),
        );
      },
    );
  }
}

class _NotifCard extends ConsumerWidget {
  final AppNotification notif;
  const _NotifCard({required this.notif});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = notifColor(notif.type);
    return GestureDetector(
      onTap: () async {
        // 읽음 처리는 fire-and-forget — 실패해도 deep link는 진행
        if (!notif.isRead) {
          // ignore: unawaited_futures
          ref.read(notificationActionsProvider).markAsRead(notif.id);
        }
        final link = notif.deepLink;
        if (link != null && context.mounted) {
          context.push(link);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead
              ? AppColors.surface.withValues(alpha: 0.7)
              : AppColors.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: appShadow,
          border: notif.isRead
              ? null
              : Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(notifIcon(notif.type), size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: AppTextStyles.cardTitle.copyWith(
                            color: notif.isRead
                                ? AppColors.textSub
                                : AppColors.text,
                          ),
                        ),
                      ),
                      Text(
                        formatRelativeTime(notif.createdAt),
                        style: AppTextStyles.small,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      color:
                          notif.isRead ? AppColors.textSub : AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            if (!notif.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_off_rounded,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text('새로운 알림이 없습니다',
              style: AppTextStyles.body.copyWith(color: AppColors.textSub)),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  const _ErrorBody({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 36, color: AppColors.danger),
            const SizedBox(height: 12),
            Text('알림을 불러오지 못했습니다', style: AppTextStyles.bodyBold),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTextStyles.small.copyWith(color: AppColors.textSub),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

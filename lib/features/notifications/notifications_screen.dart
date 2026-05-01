import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_shadow.dart';
import '../../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    final notifs = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);

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
                  Text('알림', style: AppTextStyles.sectionTitle.copyWith(fontSize: 17)),
                  if (unread > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                ],
              ),
            ),

            // 알림 목록
            Expanded(
              child: notifs.isEmpty
                  ? Center(
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
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: notifs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notif = notifs[index];
                        final color = notifColor(notif.type);
                        return GestureDetector(
                          onTap: () => ref
                              .read(notificationsProvider.notifier)
                              .markAsRead(index),
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
                                  : Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.2)),
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
                                  child: Icon(notifIcon(notif.type),
                                      size: 20, color: color),
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
                                          Text(notif.time, style: AppTextStyles.small),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif.body,
                                        style: AppTextStyles.body.copyWith(
                                          fontSize: 13,
                                          color: notif.isRead
                                              ? AppColors.textSub
                                              : AppColors.text,
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
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

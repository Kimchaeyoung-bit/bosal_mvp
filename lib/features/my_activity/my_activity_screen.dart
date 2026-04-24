import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bosal_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../shared/widgets/coming_soon_view.dart';
import '../../shared/widgets/login_required_view.dart';

enum MyActivityType { bookings, favorites, recent, reviews }

class MyActivityScreen extends ConsumerWidget {
  final MyActivityType type;

  const MyActivityScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final title = _titleFor(type);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(title),
        centerTitle: false,
      ),
      body: SafeArea(
        child: !isLoggedIn
            ? const LoginRequiredView()
            : _bodyFor(context, ref),
      ),
    );
  }

  Widget _bodyFor(BuildContext context, WidgetRef ref) {
    switch (type) {
      case MyActivityType.favorites:
        return const _FavoritesList();
      case MyActivityType.bookings:
        return const ComingSoonView(message: '예약 내역 기능은 준비 중입니다');
      case MyActivityType.recent:
        return const ComingSoonView(message: '최근 본 보살 기능은 준비 중입니다');
      case MyActivityType.reviews:
        return const ComingSoonView(message: '내 후기 기능은 준비 중입니다');
    }
  }

  String _titleFor(MyActivityType type) {
    switch (type) {
      case MyActivityType.bookings:
        return '예약 내역';
      case MyActivityType.favorites:
        return '찜한 보살';
      case MyActivityType.recent:
        return '최근 본 보살';
      case MyActivityType.reviews:
        return '내 후기';
    }
  }
}

class _FavoritesList extends ConsumerWidget {
  const _FavoritesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoritesProvider);
    final bosalsAsync = ref.watch(allBosalsAsyncProvider);

    return bosalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('불러오기 실패: $e')),
      data: (all) {
        final list = all.where((b) => favoriteIds.contains(b.id)).toList();
        if (list.isEmpty) {
          return _Empty(
            message: '찜한 보살이 없습니다',
            hint: '마음에 드는 보살의 상세 화면에서 하트를 눌러보세요',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final b = list[i];
            return InkWell(
              onTap: () => context.push('/bosal/${b.id}'),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primarySoft,
                      backgroundImage: b.profileImageUrl == null
                          ? null
                          : NetworkImage(b.profileImageUrl!),
                      child: b.profileImageUrl == null
                          ? const Icon(Icons.person,
                              color: AppColors.primary, size: 28)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.name,
                              style: AppTextStyles.bodyBold
                                  .copyWith(fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(
                            b.oneLiner ?? b.description ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.small
                                .copyWith(color: AppColors.textSub),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '★ ${b.rating.toStringAsFixed(1)}  ·  경력 ${b.experienceYears}년',
                            style: AppTextStyles.small.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite_rounded,
                          color: AppColors.accent),
                      onPressed: () async {
                        await ref.read(favoriteToggleProvider)(b.id);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;
  final String? hint;
  const _Empty({required this.message, this.hint});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_border_rounded,
              size: 48, color: AppColors.textSub),
          const SizedBox(height: 12),
          Text(message, style: AppTextStyles.bodyBold),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: AppTextStyles.small.copyWith(color: AppColors.textSub),
            ),
          ],
        ],
      ),
    );
  }
}

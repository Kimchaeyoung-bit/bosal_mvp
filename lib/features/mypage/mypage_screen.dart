import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_shadow.dart';
import '../../providers/auth_provider.dart';

class MypageScreen extends ConsumerWidget {
  const MypageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final isLoggedIn = user != null;
    final topPadding = MediaQuery.of(context).padding.top;

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
        child: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('마이페이지',
                          style: AppTextStyles.logo.copyWith(color: AppColors.text)),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.settings_outlined,
                              color: AppColors.primary, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.primary, size: 40),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isLoggedIn ? user.displayName : '로그인이 필요합니다',
                    style: AppTextStyles.cardTitle.copyWith(
                      color: AppColors.text,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isLoggedIn
                        ? '환영합니다!'
                        : '로그인하고 나에게 맞는 보살을 찾아보세요',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSub,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      if (isLoggedIn) {
                        ref.read(authProvider.notifier).logout();
                      } else {
                        context.push<bool>('/login');
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isLoggedIn ? '로그아웃' : '로그인 / 회원가입',
                        style: AppTextStyles.bodyBold.copyWith(
                          color: AppColors.primary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _MenuSection(
                    title: '나의 활동',
                    items: [
                      _MenuItem(
                        icon: Icons.calendar_today_outlined,
                        label: '예약 내역',
                        onTap: () => context.push('/my/bookings'),
                      ),
                      _MenuItem(
                        icon: Icons.favorite_border_rounded,
                        label: '찜한 보살',
                        onTap: () => context.push('/my/favorites'),
                      ),
                      _MenuItem(
                        icon: Icons.history_rounded,
                        label: '최근 본 보살',
                        onTap: () => context.push('/my/recent'),
                      ),
                      _MenuItem(
                        icon: Icons.rate_review_outlined,
                        label: '내 후기',
                        onTap: () => context.push('/my/reviews'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _MenuSection(
                    title: '고객 지원',
                    items: [
                      _MenuItem(
                        icon: Icons.headset_mic_outlined,
                        label: '고객센터',
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.info_outline_rounded,
                        label: '공지사항',
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.description_outlined,
                        label: '이용약관',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Text(
              '앱 버전 1.0.0',
              style: AppTextStyles.small.copyWith(fontSize: 12),
            ),

            const SizedBox(height: 100),
          ],
        ),
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        boxShadow: appShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: AppTextStyles.smallBold.copyWith(
                color: AppColors.textSub,
                fontSize: 12,
              ),
            ),
          ),
          ...items.map((item) => item),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.text),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textSub),
          ],
        ),
      ),
    );
  }
}

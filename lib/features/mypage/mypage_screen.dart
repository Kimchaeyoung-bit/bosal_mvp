import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_shadow.dart';

class MypageScreen extends StatelessWidget {
  const MypageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.5, -1),
                  end: Alignment(0.5, 1),
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('마이페이지', style: AppTextStyles.logo),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.settings_outlined,
                              color: AppColors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Profile
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.white, size: 40),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '로그인이 필요합니다',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '로그인하고 나에게 맞는 보살을 찾아보세요',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('로그인 / 회원가입'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Menu sections
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
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.favorite_border_rounded,
                        label: '찜한 보살',
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.history_rounded,
                        label: '최근 본 보살',
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.rate_review_outlined,
                        label: '내 후기',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _MenuSection(
                    title: '포인트 & 혜택',
                    items: [
                      _MenuItem(
                        icon: Icons.monetization_on_outlined,
                        label: '포인트',
                        trailing: '0P',
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.card_giftcard_rounded,
                        label: '쿠폰함',
                        trailing: '0장',
                        onTap: () {},
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
        color: AppColors.surface,
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
  final String? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.trailing,
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
            if (trailing != null)
              Text(
                trailing!,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textSub),
          ],
        ),
      ),
    );
  }
}

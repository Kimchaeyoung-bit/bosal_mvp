import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 로고 + 알림
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('✦',
                          style: TextStyle(fontSize: 14, color: AppColors.black)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('강남보살', style: AppTextStyles.logo),
                ],
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_none_rounded,
                    color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 22),
          // 인사말
          Text(
            '안녕하세요 👋',
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '나에게 맞는 ',
                  style: AppTextStyles.headerTitle,
                ),
                TextSpan(
                  text: '보살',
                  style: AppTextStyles.headerTitle.copyWith(
                    color: AppColors.accent,
                  ),
                ),
                TextSpan(
                  text: '을\n찾아보세요',
                  style: AppTextStyles.headerTitle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 검색바
          GestureDetector(
            onTap: () => context.push('/search'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: AppColors.textSub, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '보살 이름, 상담 분야 검색',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSub),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '검색',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 부처 일러스트 (우측)
          Positioned(
            right: -10,
            top: -8,
            child: Image.asset(
              'assets/images/logo_real.png',
              width: 130,
              height: 130,
              fit: BoxFit.contain,
              opacity: const AlwaysStoppedAnimation(0.9),
            ),
          ),
          // 메인 콘텐츠
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 좌측: 제목 + 부제목
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '강남보살',
                          style: AppTextStyles.headerTitle.copyWith(
                            color: AppColors.text,
                            fontSize: 26,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '인연을 잇는 현명한 선택',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSub,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.auto_awesome,
                          size: 11,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 우측 상단: SVG 로고
              Image.asset(
                'assets/images/logo_real.png',
                width: 72,
                height: 72,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

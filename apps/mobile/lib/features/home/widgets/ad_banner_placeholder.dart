import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AdBannerPlaceholder extends StatelessWidget {
  const AdBannerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bannerStart, AppColors.bannerEnd],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // 우측 부처 일러스트
          Positioned(
            right: -10,
            bottom: -10,
            child: Image.asset(
              'assets/images/logo_real.png',
              width: 110,
              height: 110,
              fit: BoxFit.contain,
              opacity: const AlwaysStoppedAnimation(0.25),
            ),
          ),
          // 텍스트 콘텐츠
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 100, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '마음의 답을 찾고 싶을 때,',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '강남보살',
                      style: GoogleFonts.doHyeon(
                        color: AppColors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.auto_awesome,
                        color: AppColors.white, size: 14),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '당신의 고민, 인연이 되어 답을 드립니다.',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '지금 상담하기 →',
                  style: AppTextStyles.smallBold.copyWith(
                    color: AppColors.ctaPink,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
            right: 30,
            top: -16,
            child: Transform.scale(
              scaleX: -1,
              child: Image.asset(
                'assets/images/logo_real.png',
                width: 135,
                height: 135,
                fit: BoxFit.contain,
                opacity: const AlwaysStoppedAnimation(0.9),
              ),
            ),
          ),
          // 메인 콘텐츠
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 24),
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '강남보살',
                      style: GoogleFonts.sunflower(
                        color: AppColors.text,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '인연을 잇는 현명한 선택',
                      style: GoogleFonts.sunflower(
                        color: AppColors.textSub,
                        fontSize: 13,
                      ),
                    ),
                  ],
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

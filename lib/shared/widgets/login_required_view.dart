import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class LoginRequiredView extends StatelessWidget {
  final String? title;
  final String? description;

  const LoginRequiredView({
    super.key,
    this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 42,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title ?? '로그인이 필요한 서비스입니다',
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 8),
            Text(
              description ?? '로그인하고 나에게 맞는 보살을 만나보세요',
              textAlign: TextAlign.center,
              style: AppTextStyles.small.copyWith(color: AppColors.textSub),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 220,
              height: 48,
              child: ElevatedButton(
                onPressed: () => context.push('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('로그인하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/mascot.png',
              width: 140,
              height: 140,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text('안녕! 나는 보보야 🌈', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 8),
            Text(
              '곧 상담 도우미로 찾아올게요!',
              style: AppTextStyles.small,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '준비중이에요',
                style: AppTextStyles.bodyBold.copyWith(color: AppColors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

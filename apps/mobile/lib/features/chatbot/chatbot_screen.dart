import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(8, topPadding + 8, 20, 14),
            color: AppColors.surface,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close_rounded, size: 24),
                ),
                const SizedBox(width: 4),
                Text('AI 챗봇 상담', style: AppTextStyles.sectionTitle),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_rounded,
                        size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  Text('AI 챗봇 준비중', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 8),
                  Text(
                    '곧 나에게 맞는 보살을\n추천받을 수 있어요!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.small.copyWith(fontSize: 14),
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

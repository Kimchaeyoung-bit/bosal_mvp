import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_shadow.dart';

class HomeSearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const HomeSearchBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: appShadow,
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded,
                color: AppColors.textSub, size: 18),
            const SizedBox(width: 10),
            Text(
              '궁금한 분야, 보살 이름을 검색해보세요.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }
}

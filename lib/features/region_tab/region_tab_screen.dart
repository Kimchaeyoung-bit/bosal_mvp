import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class RegionTabScreen extends StatelessWidget {
  const RegionTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_rounded, size: 64, color: AppColors.textSub),
            const SizedBox(height: 16),
            Text('지역 준비중', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 8),
            Text('곧 만나요!', style: AppTextStyles.small),
          ],
        ),
      ),
    );
  }
}

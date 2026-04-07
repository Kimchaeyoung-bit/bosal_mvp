import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 20),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '✦',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 22,
                ),
              ),
              const SizedBox(width: 6),
              Text('강남보살', style: AppTextStyles.logo),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_outline_rounded,
                color: AppColors.white, size: 24),
          ),
        ],
      ),
    );
  }
}

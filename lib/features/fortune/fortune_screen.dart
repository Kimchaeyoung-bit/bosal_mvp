import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_shadow.dart';

class FortuneScreen extends StatelessWidget {
  const FortuneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(8, topPadding + 8, 16, 14),
              color: AppColors.surface.withValues(alpha: 0.9),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 24),
                  ),
                  const SizedBox(width: 4),
                  Text('오늘의 운세', style: AppTextStyles.sectionTitle.copyWith(fontSize: 17)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: appShadow,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.auto_awesome_rounded,
                                size: 36, color: AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          Text('오늘의 총운', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(
                            '오늘은 새로운 시작에 좋은 날입니다.\n주변의 인연을 소중히 여기고,\n작은 것에 감사하는 마음을 가져보세요.',
                            style: AppTextStyles.body.copyWith(color: AppColors.textSub, height: 1.7),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._fortuneItems.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: appShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(item.$2, size: 22, color: AppColors.primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.$1, style: AppTextStyles.cardTitle),
                                  const SizedBox(height: 4),
                                  Text(item.$3,
                                      style: AppTextStyles.body.copyWith(
                                          color: AppColors.textSub, fontSize: 13)),
                                ],
                              ),
                            ),
                            _StarRating(score: item.$4),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _fortuneItems = [
  ('애정운', Icons.favorite_rounded, '인연이 찾아올 수 있는 날, 마음을 열어두세요.', 4),
  ('재물운', Icons.monetization_on_rounded, '작은 지출을 조심하되, 큰 흐름은 좋습니다.', 3),
  ('건강운', Icons.self_improvement_rounded, '무리하지 말고 충분한 휴식을 취하세요.', 5),
  ('직업운', Icons.work_rounded, '노력한 만큼 결실이 맺히는 시기입니다.', 4),
];

class _StarRating extends StatelessWidget {
  final int score;
  const _StarRating({required this.score});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) => Icon(
        i < score ? Icons.star_rounded : Icons.star_outline_rounded,
        size: 16,
        color: AppColors.primary,
      )),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_shadow.dart';
import '../../../providers/bosal_provider.dart';

class TopActionsRow extends ConsumerWidget {
  final VoidCallback onNearbyTap;
  final void Function(String bosalId) onBosalTap;

  const TopActionsRow({
    super.key,
    required this.onNearbyTap,
    required this.onBosalTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bosals = ref.watch(allBosalsProvider);
    final topBosals = bosals.take(3).toList();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: _PopularBosalCard(
              bosals: topBosals,
              onBosalTap: onBosalTap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _NearbyCard(onTap: onNearbyTap),
          ),
        ],
      ),
    );
  }
}

class _PopularBosalCard extends StatelessWidget {
  final List<dynamic> bosals;
  final void Function(String) onBosalTap;

  const _PopularBosalCard({
    required this.bosals,
    required this.onBosalTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: appShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  size: 16, color: AppColors.danger),
              const SizedBox(width: 4),
              Text(
                '이번 주 인기 보살',
                style: AppTextStyles.smallBold.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...bosals.asMap().entries.map((entry) {
            final index = entry.key;
            final bosal = entry.value;
            return GestureDetector(
              onTap: () => onBosalTap(bosal.id),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? AppColors.accent
                            : AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: index == 0
                              ? AppColors.white
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bosal.name,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.star_rounded,
                        size: 12, color: AppColors.accent),
                    const SizedBox(width: 2),
                    Text(
                      '${bosal.rating}',
                      style: AppTextStyles.small.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NearbyCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.accentSoft, Color(0xFFF5E7C7)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: appShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.place_rounded,
                color: AppColors.accent,
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '내 주변\n보살들',
              style: AppTextStyles.cardLabel.copyWith(
                fontSize: 14,
                height: 1.3,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '지역 설정하기 ›',
              style: AppTextStyles.small.copyWith(
                fontSize: 11,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

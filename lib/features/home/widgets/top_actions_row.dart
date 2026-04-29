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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        boxShadow: appShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 좌측: 인기 보살
            Expanded(
              flex: 3,
              child: _PopularBosalSection(
                bosals: topBosals,
                onBosalTap: onBosalTap,
              ),
            ),
            // 구분선
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: AppColors.border,
            ),
            // 우측: 내 주변 보살들
            Expanded(
              flex: 2,
              child: _NearbySection(onTap: onNearbyTap),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularBosalSection extends StatelessWidget {
  final List<dynamic> bosals;
  final void Function(String) onBosalTap;

  const _PopularBosalSection({
    required this.bosals,
    required this.onBosalTap,
  });

  static const _rankColors = [
    AppColors.rankOne,
    AppColors.rankTwo,
    AppColors.rankThree,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.local_fire_department_rounded,
                size: 15, color: AppColors.danger),
            const SizedBox(width: 4),
            Text(
              '이번 주 인기 보살',
              style: AppTextStyles.smallBold.copyWith(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: bosals.asMap().entries.map((entry) {
            final index = entry.key;
            final bosal = entry.value;
            return Expanded(
              child: GestureDetector(
                onTap: () => onBosalTap(bosal.id),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primarySoft,
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo_real.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -4,
                          left: -4,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _rankColors[index],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bosal.name,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 11, color: AppColors.accent),
                        const SizedBox(width: 2),
                        Text(
                          '${bosal.rating}',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            color: AppColors.textSub,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _NearbySection extends StatelessWidget {
  final VoidCallback onTap;
  const _NearbySection({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 지도 아이콘
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accent, width: 1.5),
            ),
            child: const Icon(
              Icons.place_outlined,
              color: AppColors.accent,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '내 주변 보살들',
            style: AppTextStyles.cardLabel.copyWith(
              fontSize: 13,
              height: 1.4,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '지금 내 주변의\n보살을 확인해보세요',
            style: AppTextStyles.small.copyWith(
              fontSize: 10,
              color: AppColors.textSub,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

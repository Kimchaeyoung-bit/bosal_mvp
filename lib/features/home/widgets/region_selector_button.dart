import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_shadow.dart';
import '../../../providers/region_provider.dart';

class RegionSelectorButton extends ConsumerWidget {
  final VoidCallback onTap;
  const RegionSelectorButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRegions = ref.watch(selectedSubRegionsProvider);
    final hasSelection = selectedRegions.isNotEmpty;

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
            Icon(
              Icons.place_outlined,
              color: hasSelection ? AppColors.primary : AppColors.textSub,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasSelection
                    ? selectedRegions.map((r) => r.name).join(', ')
                    : '원하는 지역을 선택해주세요...',
                style: AppTextStyles.body.copyWith(
                  color: hasSelection ? AppColors.text : AppColors.textSub,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSub, size: 20),
          ],
        ),
      ),
    );
  }
}

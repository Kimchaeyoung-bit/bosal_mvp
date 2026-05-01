import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/region_provider.dart';

class RegionSelectionScreen extends ConsumerStatefulWidget {
  final bool goToMapOnConfirm;
  const RegionSelectionScreen({super.key, this.goToMapOnConfirm = false});

  @override
  ConsumerState<RegionSelectionScreen> createState() =>
      _RegionSelectionScreenState();
}

class _RegionSelectionScreenState extends ConsumerState<RegionSelectionScreen> {
  String _selectedRegionId = 'seoul';

  @override
  Widget build(BuildContext context) {
    final regions = ref.watch(regionsProvider);
    final selectedSubRegions = ref.watch(selectedSubRegionsProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    if (regions.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final currentRegion = regions.firstWhere(
      (r) => r.id == _selectedRegionId,
      orElse: () => regions.first,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Drag handle + Header
          Container(
            padding: EdgeInsets.fromLTRB(20, topPadding + 12, 8, 16),
            color: AppColors.surface,
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('지역',
                        style: AppTextStyles.sectionTitle
                            .copyWith(fontSize: 20)),
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close_rounded, size: 24),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // GPS button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location_rounded,
                      color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '내 주변 지역으로 설정하기',
                    style:
                        AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSub, size: 18),
                ],
              ),
            ),
          ),

          // Selected chips
          if (selectedSubRegions.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => ref
                          .read(selectedSubRegionsProvider.notifier)
                          .clear(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.refresh_rounded,
                                size: 14, color: AppColors.textSub),
                            const SizedBox(width: 4),
                            Text('초기화', style: AppTextStyles.chip),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ...selectedSubRegions.map((sub) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                sub.name,
                                style: AppTextStyles.chip
                                    .copyWith(color: AppColors.primary),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => ref
                                    .read(
                                        selectedSubRegionsProvider.notifier)
                                    .remove(sub),
                                child: const Icon(Icons.close_rounded,
                                    size: 14, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          const Divider(height: 1, color: AppColors.border),

          // Two-column layout
          Expanded(
            child: Row(
              children: [
                // Left: Region list
                SizedBox(
                  width: 110,
                  child: Container(
                    color: AppColors.bg,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: regions.length,
                      itemBuilder: (context, index) {
                        final region = regions[index];
                        final isSelected = region.id == _selectedRegionId;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedRegionId = region.id),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.surface
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                if (isSelected)
                                  Container(
                                    width: 4,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                if (isSelected) const SizedBox(width: 10),
                                Text(
                                  region.name,
                                  style: AppTextStyles.body.copyWith(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSub,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Right: Sub-region checklist
                Expanded(
                  child: Container(
                    color: AppColors.surface,
                    child: currentRegion.subRegions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.hourglass_empty_rounded,
                                    size: 36, color: AppColors.textSub),
                                const SizedBox(height: 12),
                                Text(
                                  '준비중입니다',
                                  style: AppTextStyles.body
                                      .copyWith(color: AppColors.textSub),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: currentRegion.subRegions.length,
                            itemBuilder: (context, index) {
                              final sub = currentRegion.subRegions[index];
                              final isChecked = selectedSubRegions
                                  .any((s) => s.id == sub.id);
                              return GestureDetector(
                                onTap: () => ref
                                    .read(selectedSubRegionsProvider.notifier)
                                    .toggle(sub),
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 14),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: isChecked
                                              ? AppColors.primary
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isChecked
                                                ? AppColors.primary
                                                : AppColors.border,
                                            width: 2,
                                          ),
                                        ),
                                        child: isChecked
                                            ? const Icon(Icons.check_rounded,
                                                size: 15,
                                                color: AppColors.white)
                                            : null,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          sub.name,
                                          style: AppTextStyles.body.copyWith(
                                            color: isChecked
                                                ? AppColors.text
                                                : AppColors.textSub,
                                            fontWeight: isChecked
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom button
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: selectedSubRegions.isEmpty
                    ? null
                    : () {
                        if (widget.goToMapOnConfirm) {
                          context.pushReplacement('/map');
                        } else {
                          context.pop();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.border,
                  disabledForegroundColor: AppColors.textSub,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(
                  selectedSubRegions.isEmpty
                      ? '지역을 선택해주세요'
                      : '${selectedSubRegions.length}개 지역 선택 완료',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/region_provider.dart';

class RegionSelectionScreen extends ConsumerStatefulWidget {
  const RegionSelectionScreen({super.key});

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
    final currentRegion = regions.firstWhere((r) => r.id == _selectedRegionId);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20, topPadding + 12, 8, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('지역', style: AppTextStyles.sectionTitle.copyWith(fontSize: 20)),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close_rounded, size: 24),
                ),
              ],
            ),
          ),

          // GPS button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppColors.surface,
            child: Row(
              children: [
                const Icon(Icons.my_location_rounded,
                    color: AppColors.danger, size: 18),
                const SizedBox(width: 8),
                Text(
                  '내 주변 지역으로 설정하기',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Selected chips
          if (selectedSubRegions.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: AppColors.surface,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        ref.read(selectedSubRegionsProvider.notifier).clear(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text('초기화', style: AppTextStyles.chip),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: selectedSubRegions.map((sub) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
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
                                  const SizedBox(width: 4),
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
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1, color: AppColors.border),

          // Two-column layout
          Expanded(
            child: Row(
              children: [
                // Left: Region list
                SizedBox(
                  width: 100,
                  child: Container(
                    color: AppColors.bg,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: regions.length,
                      itemBuilder: (context, index) {
                        final region = regions[index];
                        final isSelected = region.id == _selectedRegionId;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedRegionId = region.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.surface
                                  : Colors.transparent,
                              border: isSelected
                                  ? const Border(
                                      left: BorderSide(
                                          color: AppColors.primary, width: 3),
                                    )
                                  : null,
                            ),
                            child: Text(
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
                            child: Text(
                              '준비중입니다',
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.textSub),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: currentRegion.subRegions.length,
                            itemBuilder: (context, index) {
                              final sub = currentRegion.subRegions[index];
                              final isChecked = selectedSubRegions
                                  .any((s) => s.id == sub.id);
                              return GestureDetector(
                                onTap: () => ref
                                    .read(selectedSubRegionsProvider.notifier)
                                    .toggle(sub),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: isChecked
                                              ? AppColors.primary
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: isChecked
                                                ? AppColors.primary
                                                : AppColors.border,
                                            width: 2,
                                          ),
                                        ),
                                        child: isChecked
                                            ? const Icon(Icons.check_rounded,
                                                size: 16,
                                                color: AppColors.white)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          sub.name,
                                          style: AppTextStyles.body.copyWith(
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
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('필터 선택 완료'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

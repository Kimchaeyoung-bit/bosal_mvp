import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/bosal.dart';
import '../../providers/bosal_provider.dart';
import '../../providers/region_provider.dart';
import '../map/widgets/bosal_map_widget.dart';

class RegionTabScreen extends ConsumerStatefulWidget {
  const RegionTabScreen({super.key});

  @override
  ConsumerState<RegionTabScreen> createState() => _RegionTabScreenState();
}

class _RegionTabScreenState extends ConsumerState<RegionTabScreen> {
  Bosal? _selectedBosal;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bosals = ref.watch(filteredBosalsProvider);
    final bosalsWithLocation =
        bosals.where((b) => b.latitude != null && b.longitude != null).toList();
    final selectedSubRegions = ref.watch(selectedSubRegionsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ── 지도 (전체 화면) ──────────────────────────────────────
          Positioned.fill(
            child: BosalMapWidget(
              bosals: bosalsWithLocation,
              selectedBosal: _selectedBosal,
              onMarkerTap: (bosal) {
                setState(() {
                  _selectedBosal =
                      _selectedBosal?.id == bosal.id ? null : bosal;
                });
                // 마커 탭 시 시트 올리기
                _sheetController.animateTo(
                  0.45,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
            ),
          ),

          // ── 상단 플로팅 칩 ────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  // 필터 버튼
                  _TopChip(
                    icon: Icons.tune_rounded,
                    label: '필터',
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  // 지역 칩
                  _TopChip(
                    icon: Icons.location_on_rounded,
                    label: selectedSubRegions.isEmpty
                        ? '내 주변'
                        : selectedSubRegions.first.name,
                    onTap: () => context.push('/region-select'),
                    isPrimary: true,
                  ),
                  const Spacer(),
                  // 현위치 버튼
                  _CircleIconButton(
                    icon: Icons.my_location_rounded,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          // ── 하단 드래그 시트 ──────────────────────────────────────
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.28,
            minChildSize: 0.12,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [0.12, 0.28, 0.55, 0.88],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 24,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 핸들
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 4),
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // 시트 헤더
                    GestureDetector(
                      onTap: () => _sheetController.animateTo(
                        0.55,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                        child: Row(
                          children: [
                            Text(
                              '이 지역 보살',
                              style: AppTextStyles.sectionTitle,
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${bosalsWithLocation.length}명',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.keyboard_arrow_up_rounded,
                                color: AppColors.textSub, size: 20),
                          ],
                        ),
                      ),
                    ),

                    // 선택된 보살 강조 카드 (마커 탭 시)
                    if (_selectedBosal != null)
                      _SelectedBosalBanner(
                        bosal: _selectedBosal!,
                        onTap: () =>
                            context.push('/bosal/${_selectedBosal!.id}'),
                        onClose: () => setState(() => _selectedBosal = null),
                      ),

                    Divider(height: 1, color: AppColors.border),

                    // 보살 카드 리스트
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: bosalsWithLocation.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: AppColors.border),
                        itemBuilder: (_, i) {
                          final bosal = bosalsWithLocation[i];
                          final isSelected = _selectedBosal?.id == bosal.id;
                          return _BosalListTile(
                            bosal: bosal,
                            isSelected: isSelected,
                            onTap: () => context.push('/bosal/${bosal.id}'),
                            onMapTap: () {
                              setState(() => _selectedBosal = bosal);
                              _sheetController.animateTo(
                                0.28,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── 상단 플로팅 칩 ──────────────────────────────────────────────────────────

class _TopChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _TopChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isPrimary ? AppColors.white : AppColors.text,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.chip.copyWith(
                color: isPrimary ? AppColors.white : AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.text),
      ),
    );
  }
}

// ─── 선택 보살 배너 ──────────────────────────────────────────────────────────

class _SelectedBosalBanner extends StatelessWidget {
  final Bosal bosal;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _SelectedBosalBanner({
    required this.bosal,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            // 아바타
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: Center(
                child: Text(
                  bosal.name[0],
                  style: AppTextStyles.bodyBold
                      .copyWith(color: AppColors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(bosal.name, style: AppTextStyles.cardTitle),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          bosal.consultStyle,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 13, color: AppColors.accent),
                      const SizedBox(width: 3),
                      Text(
                        bosal.rating.toStringAsFixed(1),
                        style: AppTextStyles.smallBold,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '첫방문 ${_fmt(bosal.firstVisitPrice)}원',
                        style: AppTextStyles.smallBold
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onClose,
              child: Icon(Icons.close_rounded,
                  size: 18, color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int price) => price
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},');
}

// ─── 보살 리스트 타일 ────────────────────────────────────────────────────────

class _BosalListTile extends StatelessWidget {
  final Bosal bosal;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onMapTap;

  const _BosalListTile({
    required this.bosal,
    required this.isSelected,
    required this.onTap,
    required this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        color: isSelected
            ? AppColors.primarySoft
            : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아바타
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : AppColors.bg,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  bosal.name[0],
                  style: AppTextStyles.bodyBold.copyWith(
                    color: isSelected ? AppColors.white : AppColors.text,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이름 + 스타일 뱃지
                  Row(
                    children: [
                      Text(bosal.name, style: AppTextStyles.cardTitle),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          bosal.consultStyle,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // 평점 + 리뷰
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 13, color: AppColors.accent),
                      const SizedBox(width: 3),
                      Text(
                        bosal.rating.toStringAsFixed(1),
                        style: AppTextStyles.smallBold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '리뷰 ${bosal.reviewCount}',
                        style: AppTextStyles.small,
                      ),
                      const SizedBox(width: 4),
                      Text('·', style: AppTextStyles.small),
                      const SizedBox(width: 4),
                      Text(
                        '경력 ${bosal.experienceYears}년',
                        style: AppTextStyles.small,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 특징 태그
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: bosal.features
                        .take(2)
                        .map(
                          (f) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              f,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSub),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),

            // 우측: 가격 + 지도핀 버튼
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: onMapTap,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(Icons.location_on_rounded,
                        size: 16, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 10),
                Text('첫방문', style: AppTextStyles.small),
                Text(
                  '${_fmt(bosal.firstVisitPrice)}원',
                  style: AppTextStyles.smallBold
                      .copyWith(color: AppColors.primary, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int price) => price
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},');
}

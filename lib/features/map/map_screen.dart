import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/bosal.dart';
import '../../providers/bosal_provider.dart';
import 'widgets/bosal_map_widget.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  Bosal? _selectedBosal;

  @override
  Widget build(BuildContext context) {
    final bosals = ref.watch(allBosalsProvider);
    final bosalsWithLocation =
        bosals.where((b) => b.latitude != null && b.longitude != null).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // 지도
          BosalMapWidget(
            bosals: bosalsWithLocation,
            selectedBosal: _selectedBosal,
            onMarkerTap: (bosal) {
              setState(() {
                _selectedBosal = _selectedBosal?.id == bosal.id ? null : bosal;
              });
            },
          ),

          // 상단 플로팅 헤더
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  // 뒤로가기 버튼
                  _FloatingIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 10),
                  // 검색바
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded,
                              color: AppColors.textSub, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '보살 이름, 지역 검색',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.textSub),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 보살 수 뱃지
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 76),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha:0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '이 지역 보살 ${bosalsWithLocation.length}명',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 하단 선택된 보살 카드
          if (_selectedBosal != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              child: _BosalDetailCard(
                bosal: _selectedBosal!,
                onClose: () => setState(() => _selectedBosal = null),
                onTap: () => context.push('/bosal/${_selectedBosal!.id}'),
              ),
            ),

          // 카드 없을 때 하단 힌트
          if (_selectedBosal == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha:0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    '마커를 눌러 보살 정보를 확인하세요',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.textSub),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FloatingIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FloatingIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.text, size: 22),
      ),
    );
  }
}

class _BosalDetailCard extends StatelessWidget {
  final Bosal bosal;
  final VoidCallback onClose;
  final VoidCallback onTap;

  const _BosalDetailCard({
    required this.bosal,
    required this.onClose,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.13),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 아바타
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primarySoft,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      bosal.name[0],
                      style: AppTextStyles.sectionTitle
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(bosal.name, style: AppTextStyles.cardTitle),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              bosal.consultStyle,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.accent, size: 15),
                          const SizedBox(width: 3),
                          Text(
                            bosal.rating.toStringAsFixed(1),
                            style: AppTextStyles.smallBold
                                .copyWith(color: AppColors.accent),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '리뷰 ${bosal.reviewCount}',
                            style: AppTextStyles.small,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '경력 ${bosal.experienceYears}년',
                            style: AppTextStyles.small,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.textSub, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // 특징 태그들
            Wrap(
              spacing: 6,
              children: bosal.features
                  .take(3)
                  .map(
                    (f) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        f,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.accent),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            // 가격 + 예약 버튼
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('첫방문가', style: AppTextStyles.small),
                    Text(
                      '${_formatPrice(bosal.firstVisitPrice)}원',
                      style: AppTextStyles.priceFirstVisit,
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '상세 보기',
                      style: AppTextStyles.bodyBold
                          .copyWith(color: AppColors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

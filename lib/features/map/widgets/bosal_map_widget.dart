// 지도 구현체를 교체할 때는 이 파일만 수정하면 됩니다.
// flutter_map → google_maps_flutter 교체 시:
//   1. pubspec.yaml에서 패키지 변경
//   2. 이 파일의 FlutterMap 위젯을 GoogleMap 위젯으로 교체
//   3. LatLng import만 latlong2 → google_maps_flutter로 변경
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/bosal.dart';

class BosalMapWidget extends StatelessWidget {
  final List<Bosal> bosals;
  final Bosal? selectedBosal;
  final void Function(Bosal) onMarkerTap;
  final LatLng? initialCenter;
  final double? initialZoom;

  const BosalMapWidget({
    super.key,
    required this.bosals,
    required this.selectedBosal,
    required this.onMarkerTap,
    this.initialCenter,
    this.initialZoom,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: initialCenter ?? const LatLng(37.5040, 127.0245),
        initialZoom: initialZoom ?? 12.5,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.gangnam_bosal',
        ),
        MarkerLayer(
          markers: bosals
              .where((b) => b.latitude != null && b.longitude != null)
              .map((bosal) {
            final isSelected = selectedBosal?.id == bosal.id;
            return Marker(
              point: LatLng(bosal.latitude!, bosal.longitude!),
              width: 52,
              height: 66,
              child: GestureDetector(
                onTap: () => onMarkerTap(bosal),
                child: _AvatarMarker(bosal: bosal, isSelected: isSelected),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AvatarMarker extends StatelessWidget {
  final Bosal bosal;
  final bool isSelected;

  const _AvatarMarker({required this.bosal, required this.isSelected});

  String get _avatarUrl =>
      'https://i.pravatar.cc/100?u=bosal_${bosal.id}';

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 44.0 : 36.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.18),
                blurRadius: isSelected ? 14 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              _avatarUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _InitialsFallback(bosal: bosal, isSelected: isSelected, size: size),
              errorBuilder: (context, error, stackTrace) =>
                  _InitialsFallback(bosal: bosal, isSelected: isSelected, size: size),
            ),
          ),
        ),
        // 아래 꼬리 삼각형
        CustomPaint(
          size: const Size(10, 6),
          painter: _TailPainter(
            color: isSelected ? AppColors.primary : AppColors.surface,
          ),
        ),
      ],
    );
  }
}

class _InitialsFallback extends StatelessWidget {
  final Bosal bosal;
  final bool isSelected;
  final double size;

  const _InitialsFallback({
    required this.bosal,
    required this.isSelected,
    required this.size,
  });

  String get _initials {
    final parts = bosal.name.replaceAll(' 보살', '').replaceAll(' 도령', '');
    return parts.isNotEmpty ? parts[0] : '보';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: isSelected ? AppColors.primarySoft : AppColors.surface,
      child: Center(
        child: Text(
          _initials,
          style: AppTextStyles.bodyBold.copyWith(
            color: isSelected ? AppColors.primary : AppColors.text,
            fontSize: isSelected ? 20 : 16,
          ),
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  final Color color;
  const _TailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}

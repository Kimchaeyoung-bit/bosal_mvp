class AppConstants {
  AppConstants._();

  // Border radius
  static const double radiusSmall = 6.0;
  static const double radiusMedium = 14.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 28.0;
  static const double radiusFull = 999.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 12.0;
  static const double spacingLG = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 28.0;

  // Shadow
  static const List<BoxShadowData> shadow = [
    BoxShadowData(
      blurRadius: 12,
      offsetY: 2,
      opacity: 0.06,
    ),
  ];

  // Sizes
  static const double bottomNavHeight = 80.0;
  static const double profileImageSmall = 56.0;
  static const double profileImageMedium = 88.0;
  static const double profileImageLarge = 120.0;
  static const double thumbnailSize = 88.0;
}

class BoxShadowData {
  final double blurRadius;
  final double offsetY;
  final double opacity;

  const BoxShadowData({
    required this.blurRadius,
    required this.offsetY,
    required this.opacity,
  });
}

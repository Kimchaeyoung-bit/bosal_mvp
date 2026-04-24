import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.text,
    double? height,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.notoSansKr(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // Logo
  static TextStyle get logo => _base(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        letterSpacing: -0.3,
      );

  // Header title
  static TextStyle get headerTitle => _base(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        height: 1.4,
        letterSpacing: -0.5,
      );

  // Header subtitle
  static TextStyle get headerSubtitle => _base(
        fontSize: 14,
        color: AppColors.white.withValues(alpha: 0.75),
      );

  // Section heading
  static TextStyle get sectionTitle => _base(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      );

  // Body
  static TextStyle get body => _base(fontSize: 14);

  static TextStyle get bodyBold => _base(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      );

  // Small
  static TextStyle get small => _base(
        fontSize: 12,
        color: AppColors.textSub,
      );

  static TextStyle get smallBold => _base(
        fontSize: 12,
        fontWeight: FontWeight.w700,
      );

  // Caption
  static TextStyle get caption => _base(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      );

  // Card title
  static TextStyle get cardTitle => _base(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      );

  // Card label
  static TextStyle get cardLabel => _base(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      );

  // Card sublabel
  static TextStyle get cardSublabel => _base(
        fontSize: 12,
        color: AppColors.textSub,
      );

  // Chip
  static TextStyle get chip => _base(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      );

  // Category
  static TextStyle get category => _base(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );

  // Tab label
  static TextStyle get tabLabel => _base(
        fontSize: 11,
        color: AppColors.textSub,
      );

  static TextStyle get tabLabelActive => _base(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      );

  // Tag
  static TextStyle get tag => _base(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
      );

  // More link
  static TextStyle get moreLink => _base(
        fontSize: 13,
        color: AppColors.textSub,
      );

  // Price
  static TextStyle get priceOriginal => _base(
        fontSize: 14,
        color: AppColors.textSub,
      );

  static TextStyle get priceDiscount => _base(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get priceFirstVisit => _base(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.danger,
      );

  // Large name (detail page)
  static TextStyle get largeName => _base(
        fontSize: 22,
        fontWeight: FontWeight.w700,
      );
}

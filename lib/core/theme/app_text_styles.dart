import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Display Large - used for total balance, hero numbers
  static TextStyle displayLg = GoogleFonts.manrope(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    color: AppColors.onSurface,
    height: 1.2,
  );

  // Headline Medium - section titles, card names
  static TextStyle headlineMd = GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.24,
    color: AppColors.onSurface,
    height: 1.3,
  );

  // Headline Small
  static TextStyle headlineSm = GoogleFonts.manrope(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.onSurface,
    height: 1.3,
  );

  // Body Large - descriptions, readable text
  static TextStyle bodyLg = GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.6,
  );

  // Body Medium - primary body text
  static TextStyle bodyMd = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
    height: 1.5,
  );

  // Body Small
  static TextStyle bodySm = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.5,
  );

  // Label Small - uppercase metadata, category tags
  static TextStyle labelSm = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.52,
    color: AppColors.onSurfaceVariant,
    height: 1.0,
  );

  // Label Extra Small
  static TextStyle labelXs = GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.44,
    color: AppColors.onSurfaceVariant,
    height: 1.0,
  );

  // Price Display - product prices, totals
  static TextStyle priceDisplay = GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.22,
    color: AppColors.onSurface,
    height: 1.0,
  );

  // Price Small
  static TextStyle priceSm = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.16,
    color: AppColors.primary,
    height: 1.0,
  );

  // Nav Label
  static TextStyle navLabel = GoogleFonts.manrope(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AppColors.onSurfaceVariant,
    height: 1.2,
  );
}

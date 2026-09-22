import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // EB Garamond - Editorial, luxurious clinic serif typography
  static TextStyle get headingDisplay => GoogleFonts.ebGaramond(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        letterSpacing: -0.5,
      );

  static TextStyle get headingLarge => GoogleFonts.ebGaramond(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        letterSpacing: -0.3,
      );

  static TextStyle get headingMedium => GoogleFonts.ebGaramond(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  static TextStyle get headingSmall => GoogleFonts.ebGaramond(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  static TextStyle get metricValue => GoogleFonts.ebGaramond(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        height: 1.1,
      );

  static TextStyle get quote => GoogleFonts.ebGaramond(
        fontSize: 15,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get patientNameHeader => GoogleFonts.ebGaramond(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      );

  // Plus Jakarta Sans - Modern, highly legible sans-serif for UI, tables, buttons
  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelBold => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get button => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  static TextStyle get badge => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get tableHeader => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      );
}

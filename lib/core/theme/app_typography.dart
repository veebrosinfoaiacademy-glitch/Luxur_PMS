import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // Outfit - Contemporary, geometric, modern display typography
  static TextStyle get headingDisplay => GoogleFonts.outfit(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        letterSpacing: -0.6,
      );

  static TextStyle get headingLarge => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        letterSpacing: -0.4,
      );

  static TextStyle get headingMedium => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        letterSpacing: -0.3,
      );

  static TextStyle get headingSmall => GoogleFonts.outfit(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        letterSpacing: -0.2,
      );

  static TextStyle get metricValue => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        height: 1.1,
        letterSpacing: -0.5,
      );

  static TextStyle get quote => GoogleFonts.inter(
        fontSize: 14,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        letterSpacing: -0.1,
      );

  static TextStyle get patientNameHeader => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        letterSpacing: -0.4,
      );

  // Inter - Ultra-clean, modern, highly legible sans-serif for UI, tables, buttons
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        letterSpacing: -0.1,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        letterSpacing: -0.05,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        letterSpacing: 0,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: -0.05,
      );

  static TextStyle get labelBold => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.05,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  static TextStyle get badge => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  static TextStyle get tableHeader => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      );
}

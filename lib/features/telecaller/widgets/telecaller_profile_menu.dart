import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class TelecallerProfileMenu extends StatelessWidget {
  final AuthService authService;

  const TelecallerProfileMenu({
    super.key,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final name = authService.displayName;
    final initials = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : '?';

    return PopupMenuButton<String>(
      key: const Key('telecaller_header_profile_menu'),
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      onSelected: (value) {
        if (value == 'logout') authService.logout();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 18, color: AppColors.statusUrgent),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Sign out',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.statusUrgent,
                ),
              ),
            ],
          ),
        ),
      ],
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Veebros Clinic',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF64748B),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

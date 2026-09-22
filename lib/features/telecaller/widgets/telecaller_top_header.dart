import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

const double _headerHeight = 64;
const double _searchBarHeight = 38;

/// Mirrors shared/widgets/top_header.dart's layout (search bar, bell,
/// profile dropdown) but built fresh for the Telecaller area with real
/// account data instead of the Admin widget's hardcoded "Admin"/"AD" — that
/// file is coupled to the Admin AppViewModel and out of scope to touch here.
///
/// [searchFocusNode] is owned by TelecallerShell (not this widget) so a
/// shell-wide Ctrl+K shortcut can focus this field regardless of what else
/// currently has focus elsewhere in the Telecaller area.
class TelecallerTopHeader extends StatelessWidget {
  final AuthService authService;
  final ValueChanged<String> onSearchSubmitted;
  final FocusNode searchFocusNode;

  const TelecallerTopHeader({
    super.key,
    required this.authService,
    required this.onSearchSubmitted,
    required this.searchFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _buildSearchBar()),
          const SizedBox(width: AppSpacing.lg),
          _buildNotificationBell(context),
          const SizedBox(width: AppSpacing.sm),
          _buildProfileMenu(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          height: _searchBarHeight,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_rounded,
                color: Color(0xFF94A399),
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  key: const Key('telecaller_header_search_field'),
                  focusNode: searchFocusNode,
                  onSubmitted: onSearchSubmitted,
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone number...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF8F9E94),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Real shortcut hint — Ctrl/Cmd+K actually focuses this field;
              // see the CallbackShortcuts in TelecallerShell.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Ctrl + K',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
    return IconButton(
      key: const Key('telecaller_header_notifications'),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No new notifications.'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF334155),
            size: 22,
          ),
          Positioned(
            top: -1,
            right: -1,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
      tooltip: 'Notifications',
    );
  }

  Widget _buildProfileMenu() {
    final name = authService.displayName;
    final initials = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : '?';

    return PopupMenuButton<String>(
      key: const Key('telecaller_header_profile_menu'),
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
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
                style: GoogleFonts.plusJakartaSans(
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
                  style: GoogleFonts.plusJakartaSans(
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  'Veebros Clinic',
                  style: GoogleFonts.plusJakartaSans(
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

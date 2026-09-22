import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';

/// Mirrors shared/widgets/top_header.dart's layout (search bar, bell,
/// profile dropdown) but built fresh for the Telecaller area with real
/// account data instead of the Admin widget's hardcoded "Admin"/"AD" — that
/// file is coupled to the Admin AppViewModel and out of scope to touch here.
class TelecallerTopHeader extends StatelessWidget {
  final AuthService authService;
  final ValueChanged<String> onSearchSubmitted;

  const TelecallerTopHeader({
    super.key,
    required this.authService,
    required this.onSearchSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final name = authService.displayName;
    final initials = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.sidebarBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Color(0xFF94A399), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          key: const Key('telecaller_header_search_field'),
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
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const Key('telecaller_header_notifications'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No new notifications.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF334155), size: 23),
                tooltip: 'Notifications',
              ),
              const SizedBox(width: 14),
              PopupMenuButton<String>(
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
                        const SizedBox(width: 10),
                        Text('Sign out', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.statusUrgent)),
                      ],
                    ),
                  ),
                ],
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
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
                      const SizedBox(width: 10),
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
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

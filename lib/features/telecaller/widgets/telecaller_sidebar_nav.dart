import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/clinic_logo.dart';
import '../../../shared/widgets/botanical_decoration.dart';
import '../presentation/telecaller_shell.dart';

/// Telecaller-scoped sidebar. Deliberately a separate small widget rather
/// than reusing shared/widgets/sidebar_nav.dart, which is coupled to the
/// Admin AppViewModel/AppNavSection and out of scope to modify here.
class TelecallerSidebarNav extends StatelessWidget {
  final TelecallerSection currentSection;
  final ValueChanged<TelecallerSection> onSectionSelected;
  final AuthService authService;

  const TelecallerSidebarNav({
    super.key,
    required this.currentSection,
    required this.onSectionSelected,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 24, top: 26, bottom: 32, right: 16),
              child: ClinicLogo(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  _NavItem(
                    key: const Key('nav_telecaller_dashboard'),
                    icon: Icons.home_outlined,
                    label: 'Dashboard',
                    isSelected: currentSection == TelecallerSection.dashboard,
                    onTap: () => onSectionSelected(TelecallerSection.dashboard),
                  ),
                  const SizedBox(height: 6),
                  _NavItem(
                    key: const Key('nav_telecaller_add_lead'),
                    icon: Icons.person_add_alt_1_outlined,
                    label: 'Add Converted Lead',
                    isSelected: currentSection == TelecallerSection.addLead,
                    onTap: () => onSectionSelected(TelecallerSection.addLead),
                  ),
                  const SizedBox(height: 6),
                  _NavItem(
                    key: const Key('nav_telecaller_import'),
                    icon: Icons.upload_file_outlined,
                    label: 'Import Excel',
                    isSelected: currentSection == TelecallerSection.import,
                    onTap: () => onSectionSelected(TelecallerSection.import),
                  ),
                  const SizedBox(height: 6),
                  _NavItem(
                    key: const Key('nav_telecaller_leads'),
                    icon: Icons.list_alt_outlined,
                    label: 'My Leads',
                    isSelected: currentSection == TelecallerSection.leadList,
                    onTap: () => onSectionSelected(TelecallerSection.leadList),
                  ),
                  const SizedBox(height: 14),
                  Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 10),
                  _ProfileTile(authService: authService),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const BotanicalDecoration(),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatefulWidget {
  final AuthService authService;
  const _ProfileTile({required this.authService});

  @override
  State<_ProfileTile> createState() => _ProfileTileState();
}

class _ProfileTileState extends State<_ProfileTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.authService.displayName;
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.primaryBgLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Telecaller',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Tooltip(
              message: 'Sign out',
              child: InkWell(
                key: const Key('telecaller_sign_out'),
                onTap: widget.authService.logout,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 17,
                    color: _isHovered ? AppColors.primary : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? AppColors.primary
        : (_isHovered ? AppColors.primaryBgLight : Colors.transparent);
    final contentColor = widget.isSelected
        ? Colors.white
        : (_isHovered ? AppColors.primary : const Color(0xFF374151));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          width: double.infinity,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Icon(widget.icon, color: contentColor, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: contentColor,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

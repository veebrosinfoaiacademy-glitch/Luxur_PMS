import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/clinic_logo.dart';
import '../../../shared/widgets/botanical_decoration.dart';
import '../presentation/telecaller_shell.dart';

const double _sidebarWidth = 248;
const double _navItemHeight = 42;

/// Telecaller-scoped sidebar. Deliberately a separate small widget rather
/// than reusing shared/widgets/sidebar_nav.dart, which is coupled to the
/// Admin AppViewModel/AppNavSection and out of scope to modify here.
///
/// Only Dashboard / Patients / Settings are top-level destinations here —
/// Add Patient and Import Patients are actions reached from the Dashboard
/// (and from the Patients list), not separate nav items, matching the
/// approved design. Account/sign-out now lives in the top header's profile
/// menu instead of a sidebar tile.
class TelecallerSidebarNav extends StatelessWidget {
  final TelecallerSection currentSection;
  final ValueChanged<TelecallerSection> onSectionSelected;

  const TelecallerSidebarNav({
    super.key,
    required this.currentSection,
    required this.onSectionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final onDashboardOrItsActions =
        currentSection == TelecallerSection.dashboard ||
        currentSection == TelecallerSection.addLead ||
        currentSection == TelecallerSection.import;

    return Container(
      width: _sidebarWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.xl,
              ),
              child: ClinicLogo(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  _NavItem(
                    key: const Key('nav_telecaller_dashboard'),
                    icon: Icons.home_outlined,
                    label: 'Dashboard',
                    isSelected: onDashboardOrItsActions,
                    onTap: () => onSectionSelected(TelecallerSection.dashboard),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _NavItem(
                    key: const Key('nav_telecaller_leads'),
                    icon: Icons.people_outline_rounded,
                    label: 'Patients',
                    isSelected: currentSection == TelecallerSection.leadList,
                    onTap: () => onSectionSelected(TelecallerSection.leadList),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _NavItem(
                    key: const Key('nav_telecaller_settings'),
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    isSelected: currentSection == TelecallerSection.settings,
                    onTap: () => onSectionSelected(TelecallerSection.settings),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            const BotanicalDecoration(compact: true),
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
          height: _navItemHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(widget.icon, color: contentColor, size: 19),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
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

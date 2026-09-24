import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/clinic_logo.dart';
import '../presentation/telecaller_shell.dart';

const double _sidebarWidth = 248;
const double _navItemHeight = 44;

/// Telecaller-scoped sidebar navigation. Designed with a clean, executive
/// aesthetic featuring workspace badges, refined navigation states with soft
/// gradients and micro-indicators, and a pinned clinic footer.
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
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Header
                    const Padding(
                      padding: EdgeInsets.only(
                        left: 16,
                        top: 22,
                        right: 16,
                        bottom: 16,
                      ),
                      child: Center(
                        child: ClinicLogo(
                          height: 44,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(
                        color: Color(0xFFF1F5F9),
                        height: 16,
                        thickness: 1,
                      ),
                    ),

                    // Section Heading
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        top: 10,
                        bottom: 8,
                        right: 20,
                      ),
                      child: Text(
                        'MAIN NAVIGATION',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),

                    // Navigation Items
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          _NavItem(
                            key: const Key('nav_telecaller_dashboard'),
                            activeIcon: Icons.dashboard_rounded,
                            inactiveIcon: Icons.dashboard_outlined,
                            label: 'Dashboard',
                            isSelected: onDashboardOrItsActions,
                            onTap: () => onSectionSelected(TelecallerSection.dashboard),
                          ),
                          const SizedBox(height: 4),
                          _NavItem(
                            key: const Key('nav_telecaller_leads'),
                            activeIcon: Icons.people_alt_rounded,
                            inactiveIcon: Icons.people_outline_rounded,
                            label: 'Patients',
                            isSelected: currentSection == TelecallerSection.leadList,
                            onTap: () => onSectionSelected(TelecallerSection.leadList),
                          ),
                          const SizedBox(height: 4),
                          _NavItem(
                            key: const Key('nav_telecaller_settings'),
                            activeIcon: Icons.settings_rounded,
                            inactiveIcon: Icons.settings_outlined,
                            label: 'Settings',
                            isSelected: currentSection == TelecallerSection.settings,
                            onTap: () => onSectionSelected(TelecallerSection.settings),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Telecaller Desk badge centered at the bottom
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 20),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFDDD6FE),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'TELECALLER DESK',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    super.key,
    required this.activeIcon,
    required this.inactiveIcon,
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
    final isSelected = widget.isSelected;

    final Color contentColor = isSelected
        ? Colors.white
        : (_isHovered ? AppColors.primary : const Color(0xFF334155));

    final IconData icon = isSelected ? widget.activeIcon : widget.inactiveIcon;

    final BoxDecoration decoration = isSelected
        ? BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF5E35B1),
                Color(0xFF4527A0),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5E35B1).withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          )
        : BoxDecoration(
            color: _isHovered ? const Color(0xFFF3F0FA) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          if (!_isHovered) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (_isHovered) setState(() => _isHovered = false);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => widget.onTap(),
          onTap: widget.onTap,
          child: Container(
            width: double.infinity,
            height: _navItemHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: decoration,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: contentColor,
                  size: 19,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: contentColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 3.5,
                    height: 15,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

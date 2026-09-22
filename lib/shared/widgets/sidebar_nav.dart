import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/state/app_view_model.dart';
import 'clinic_logo.dart';
import 'botanical_decoration.dart';

class SidebarNav extends StatelessWidget {
  final AppViewModel viewModel;

  const SidebarNav({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clinic Logo Area
          const Padding(
            padding: EdgeInsets.only(left: 24, top: 26, bottom: 32, right: 16),
            child: ClinicLogo(),
          ),

          // Navigation Links
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  label: 'Dashboard',
                  isSelected: viewModel.currentSection == AppNavSection.dashboard,
                  onTap: () => viewModel.navigateTo(AppNavSection.dashboard),
                ),
                const SizedBox(height: 6),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Patients',
                  isSelected: viewModel.currentSection == AppNavSection.patients ||
                      viewModel.currentSection == AppNavSection.patientDetail,
                  onTap: () => viewModel.navigateTo(AppNavSection.patients),
                ),
                const SizedBox(height: 6),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Pharmacy Bills',
                  isSelected: viewModel.currentSection == AppNavSection.pharmacyBills,
                  onTap: () => viewModel.navigateTo(AppNavSection.pharmacyBills),
                ),
                const SizedBox(height: 6),
                _NavItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  isSelected: viewModel.currentSection == AppNavSection.settings,
                  onTap: () => viewModel.navigateTo(AppNavSection.settings),
                ),
                const SizedBox(height: 14),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 10),

                // Integrated Admin Profile & Signout Tile
                _AdminProfileTile(),
              ],
            ),
          ),

          const Spacer(),

          // Botanical Leaf Branch & Slogan
          const BotanicalDecoration(),
        ],
      ),
    );
  }
}

class _AdminProfileTile extends StatefulWidget {
  @override
  State<_AdminProfileTile> createState() => _AdminProfileTileState();
}

class _AdminProfileTileState extends State<_AdminProfileTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
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
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'AD',
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
                    'Admin',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Veebros Clinic',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Tooltip(
              message: 'Sign out',
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Admin signed out successfully (Visual Mode)'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
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
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: contentColor,
                size: 20,
              ),
              const SizedBox(width: 14),
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: contentColor,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

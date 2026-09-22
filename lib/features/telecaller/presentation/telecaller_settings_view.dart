import 'package:flutter/material.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Minimal, real account settings — name, email, role, sign out. Not a
/// placeholder: there's nothing else Telecaller-appropriate to configure
/// per the approved requirements (no admin-style clinic settings for this
/// role), so this stays small rather than inventing options.
class TelecallerSettingsView extends StatelessWidget {
  final AuthService authService;

  const TelecallerSettingsView({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final email = authService.currentUser?.getStringValue('email') ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: AppTypography.headingDisplay),
            const SizedBox(height: 4),
            Text(
              'Your account details.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Name', authService.displayName),
                  const SizedBox(height: 16),
                  _infoRow('Email', email),
                  const SizedBox(height: 16),
                  _infoRow('Role', 'Telecaller'),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const Key('settings_sign_out_button'),
                      onPressed: authService.logout,
                      icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.statusUrgent),
                      label: const Text('Sign out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusUrgent,
                        side: const BorderSide(color: AppColors.statusUrgent),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text(label, style: AppTypography.labelBold)),
        Expanded(child: Text(value, style: AppTypography.bodyMedium)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/clinic_logo.dart';

class _DevAccount {
  final String role;
  final String label;
  final String email;
  const _DevAccount(this.role, this.label, this.email);
}

// Matches scripts/seed_dev_data.mjs — same accounts, same password. Only
// ever shown when AppConfig.isProd is false, so this never reaches a
// production build regardless of what's typed here.
const _devPassword = 'DevPass123!';
const _devAccounts = [
  _DevAccount('admin', 'Admin', 'admin@luxurpms.local'),
  _DevAccount('doctor', 'Doctor', 'doctor@luxurpms.local'),
  _DevAccount('hr', 'HR', 'hr@luxurpms.local'),
  _DevAccount('chairman', 'Chairman', 'chairman@luxurpms.local'),
  _DevAccount('telecaller', 'Telecaller', 'telecaller@luxurpms.local'),
];

class LoginView extends StatefulWidget {
  final AuthService authService;

  const LoginView({super.key, required this.authService});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      // AuthService notifies listeners on success; the root widget swaps
      // to the appropriate shell. Nothing else to do here.
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid email or password.';
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _quickLogin(_DevAccount account) {
    _emailController.text = account.email;
    _passwordController.text = _devPassword;
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLoginCard(),
                if (!AppConfig.isProd) ...[
                  const SizedBox(height: 20),
                  _buildQuickLoginCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: ClinicLogo()),
            const SizedBox(height: 28),
            Text('Sign in', style: AppTypography.headingMedium),
            const SizedBox(height: 6),
            Text(
              'Use your PMS account credentials.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 24),
            Text('Email', style: AppTypography.labelBold),
            const SizedBox(height: 6),
            TextFormField(
              key: const Key('login_email_field'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration('you@luxurpms.local'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text('Password', style: AppTypography.labelBold),
            const SizedBox(height: 6),
            TextFormField(
              key: const Key('login_password_field'),
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: _inputDecoration('••••••••').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required.';
                }
                return null;
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                key: const Key('login_error_message'),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.statusUrgentBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: AppColors.statusUrgent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('login_submit_button'),
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        'Sign in',
                        style: AppTypography.button.copyWith(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLoginCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Quick login (dev only)', style: AppTypography.labelBold),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Fills the form above and signs in instantly. Never shown in a production build.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _devAccounts.map((account) {
              return OutlinedButton(
                key: Key('quick_login_${account.role}'),
                onPressed: _isSubmitting ? null : () => _quickLogin(account),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  account.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.statusUrgent),
      ),
    );
  }
}

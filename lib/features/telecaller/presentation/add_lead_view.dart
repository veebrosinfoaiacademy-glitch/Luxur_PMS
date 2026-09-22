import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/phone_utils.dart';
import '../state/telecaller_view_model.dart';

class AddLeadView extends StatefulWidget {
  final TelecallerViewModel viewModel;

  const AddLeadView({super.key, required this.viewModel});

  @override
  State<AddLeadView> createState() => _AddLeadViewState();
}

class _AddLeadViewState extends State<AddLeadView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _concernController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _concernController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final result = await widget.viewModel.addLead(
      name: _nameController.text,
      rawPhone: _phoneController.text,
      address: _addressController.text,
      concern: _concernController.text,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      _nameController.clear();
      _phoneController.clear();
      _addressController.clear();
      _concernController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('add_lead_success_snackbar'),
          content: const Text('Converted lead added successfully.'),
          backgroundColor: AppColors.statusUpcoming,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('add_lead_error_snackbar'),
          content: Text(result.errorMessage ?? 'Something went wrong.'),
          backgroundColor: AppColors.statusUrgent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Converted Lead', style: AppTypography.headingDisplay),
            const SizedBox(height: 4),
            Text(
              'This is added to your lead list only — not the main clinic patient database. '
              'Admin will convert it once the patient arrives at the clinic.',
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
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Full Name *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const Key('lead_name_field'),
                      controller: _nameController,
                      decoration: _decoration('e.g. Priya Menon'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required.' : null,
                    ),
                    const SizedBox(height: 16),
                    _label('Mobile Number *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const Key('lead_phone_field'),
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _decoration('e.g. 98765 43210'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Mobile number is required.';
                        if (PhoneUtils.normalizeIndianMobile(v) == null) {
                          return 'Enter a valid 10-digit Indian mobile number.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _label('Address'),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const Key('lead_address_field'),
                      controller: _addressController,
                      maxLines: 2,
                      decoration: _decoration('Optional'),
                    ),
                    const SizedBox(height: 16),
                    _label('Concern'),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const Key('lead_concern_field'),
                      controller: _concernController,
                      decoration: _decoration('e.g. Laser hair reduction enquiry'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const Key('add_lead_submit_button'),
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
                                'Save Converted Lead',
                                style: AppTypography.button.copyWith(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: AppTypography.labelBold);

  InputDecoration _decoration(String hint) {
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

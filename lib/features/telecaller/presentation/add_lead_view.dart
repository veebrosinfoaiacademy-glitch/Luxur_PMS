import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/phone_utils.dart';
import '../models/telecaller_lead.dart';
import '../state/telecaller_view_model.dart';
import '../widgets/telecaller_profile_menu.dart';

final _expectedArrivalDisplayFormat = DateFormat('d MMMM yyyy');

class AddLeadView extends StatefulWidget {
  final TelecallerViewModel viewModel;
  final AuthService? authService;
  final bool isDialog;
  final VoidCallback? onClose;
  /// When set, this view edits [existingLead]'s own fields (name, phone,
  /// address, concern, expected arrival date) instead of creating a new
  /// lead. Conversion status and telecaller attribution are never touched
  /// here — that's Admin's conversion workflow.
  final TelecallerLead? existingLead;

  const AddLeadView({
    super.key,
    required this.viewModel,
    this.authService,
    this.isDialog = false,
    this.onClose,
    this.existingLead,
  });

  @override
  State<AddLeadView> createState() => _AddLeadViewState();
}

class _AddLeadViewState extends State<AddLeadView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _concernController = TextEditingController();
  DateTime? _expectedArrivalDate;

  bool _isSubmitting = false;

  bool get _isEditing => widget.existingLead != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingLead;
    if (existing != null) {
      _nameController.text = existing.name;
      _phoneController.text = existing.phone;
      _addressController.text = existing.address;
      _concernController.text = existing.concern;
      _expectedArrivalDate = existing.expectedArrivalDate;
    }
  }

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
    final existing = widget.existingLead;
    final result = existing == null
        ? await widget.viewModel.addLead(
            name: _nameController.text,
            rawPhone: _phoneController.text,
            address: _addressController.text,
            concern: _concernController.text,
            expectedArrivalDate: _expectedArrivalDate,
          )
        : await widget.viewModel.updateLead(
            id: existing.id,
            name: _nameController.text,
            rawPhone: _phoneController.text,
            address: _addressController.text,
            concern: _concernController.text,
            expectedArrivalDate: _expectedArrivalDate,
          );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      if (existing == null) {
        _nameController.clear();
        _phoneController.clear();
        _addressController.clear();
        _concernController.clear();
        setState(() => _expectedArrivalDate = null);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: Key(existing == null ? 'add_lead_success_snackbar' : 'edit_lead_success_snackbar'),
          content: Text(existing == null
              ? 'Converted lead added successfully.'
              : 'Patient details updated.'),
          backgroundColor: AppColors.statusUpcoming,
        ),
      );
      if (widget.isDialog) {
        if (widget.onClose != null) {
          widget.onClose!();
        } else if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: Key(existing == null ? 'add_lead_error_snackbar' : 'edit_lead_error_snackbar'),
          content: Text(result.errorMessage ?? 'Something went wrong.'),
          backgroundColor: AppColors.statusUrgent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog) {
      return _buildDialogLayout();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'Edit Patient' : 'Add Patient',
                        style: AppTypography.headingDisplay,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isEditing
                            ? 'Update this patient\'s saved details.'
                            : 'This is added to your lead list only — not the main clinic patient database. '
                                'Admin will convert it once the patient arrives at the clinic.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (widget.authService != null)
                  TelecallerProfileMenu(authService: widget.authService!),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: _buildFormContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogLayout() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isEditing ? Icons.edit_rounded : Icons.person_add_alt_1_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'Edit Patient' : 'Add Patient',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isEditing
                            ? 'Update this patient\'s saved details.'
                            : 'Record a patient inquiry or converted lead.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                  splashRadius: 18,
                  onPressed: () {
                    if (widget.onClose != null) {
                      widget.onClose!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Form
          Padding(
            padding: const EdgeInsets.all(22),
            child: _buildFormContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Form(
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
          _label('Expected Clinic Arrival Date *'),
          const SizedBox(height: 6),
          FormField<DateTime>(
            key: const Key('lead_expected_arrival_field'),
            initialValue: _expectedArrivalDate,
            validator: (v) =>
                v == null ? 'Expected clinic arrival date is required.' : null,
            builder: (field) {
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: field.value ?? now,
                    firstDate: now.subtract(const Duration(days: 365)),
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _expectedArrivalDate = picked);
                    field.didChange(picked);
                  }
                },
                child: InputDecorator(
                  decoration: _decoration(
                    'Select a date',
                  ).copyWith(
                    errorText: field.errorText,
                    suffixIcon: const Icon(
                      Icons.calendar_today_outlined,
                      size: 17,
                    ),
                  ),
                  child: Text(
                    field.value == null
                        ? 'Select a date'
                        : _expectedArrivalDisplayFormat.format(field.value!),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: field.value == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
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
                      _isEditing ? 'Save Changes' : 'Save Converted Lead',
                      style: AppTypography.button.copyWith(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text, style: AppTypography.labelBold);

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
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

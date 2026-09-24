import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/state/app_view_model.dart';
import '../../../core/state/clinic_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/phone_utils.dart';
import '../../telecaller/models/telecaller_lead.dart';
import '../models/patient.dart';
import '../repositories/patient_repository.dart';

/// Registration is phone-first: the mobile number is what tells us whether
/// this person is already a patient or a lead a Telecaller has been working.
///
/// There is deliberately no Assigned Doctor field — a patient is never tied
/// to a doctor, only individual consultations and sessions are.
class AddPatientDialog extends StatefulWidget {
  final AppViewModel viewModel;
  final ClinicViewModel clinic;

  const AddPatientDialog({super.key, required this.viewModel, required this.clinic});

  static Future<void> show(
    BuildContext context,
    AppViewModel viewModel,
    ClinicViewModel clinic,
  ) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => AddPatientDialog(viewModel: viewModel, clinic: clinic),
    );
  }

  @override
  State<AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<AddPatientDialog> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _concernController = TextEditingController();
  final _referralController = TextEditingController();

  String _selectedGender = 'Female';
  String _selectedSource = PatientSource.directWalkIn;

  Timer? _lookupDebounce;
  bool _isLookingUp = false;
  bool _isSaving = false;
  String? _formError;

  /// The existing patient this number already belongs to — registration is
  /// blocked, and we offer to open them instead.
  Patient? _existingPatient;

  /// An un-converted Telecaller lead for this number. Keeping it means the
  /// Telecaller keeps credit for the patient.
  TelecallerLead? _matchedLead;

  final _genders = ['Female', 'Male', 'Other'];

  @override
  void dispose() {
    _lookupDebounce?.cancel();
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _concernController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String raw) {
    _lookupDebounce?.cancel();
    if (_existingPatient != null || _matchedLead != null) {
      setState(() {
        _existingPatient = null;
        _matchedLead = null;
      });
    }
    final normalized = PhoneUtils.normalizeIndianMobile(raw);
    if (normalized == null) return;
    _lookupDebounce = Timer(const Duration(milliseconds: 350), () => _lookup(normalized));
  }

  Future<void> _lookup(String normalized) async {
    setState(() => _isLookingUp = true);
    try {
      final existing = await widget.clinic.patients.findByPhone(normalized);
      if (!mounted) return;
      if (existing != null) {
        setState(() {
          _existingPatient = existing;
          _matchedLead = null;
        });
        return;
      }

      final lead = await widget.clinic.patients.findMatchingTelecallerLead(normalized);
      if (!mounted) return;
      if (lead != null) {
        setState(() {
          _matchedLead = lead;
          // Auto-fill what the Telecaller already collected, without
          // overwriting anything the front desk has typed.
          if (_nameController.text.trim().isEmpty) _nameController.text = lead.name;
          if (_addressController.text.trim().isEmpty) {
            _addressController.text = lead.address;
          }
          if (_concernController.text.trim().isEmpty) {
            _concernController.text = lead.concern;
          }
          _selectedSource = PatientSource.telecalling;
        });
      }
    } catch (_) {
      // A failed lookup must not block registration — the duplicate check
      // runs again server-side on save.
    } finally {
      if (mounted) setState(() => _isLookingUp = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final normalized = PhoneUtils.normalizeIndianMobile(_phoneController.text);

    if (name.isEmpty) {
      setState(() => _formError = 'Enter the patient’s full name.');
      return;
    }
    if (normalized == null) {
      setState(() => _formError = 'Enter a valid 10-digit mobile number.');
      return;
    }

    setState(() {
      _isSaving = true;
      _formError = null;
    });

    try {
      final patient = await widget.clinic.patients.create(
        name: name,
        normalizedPhone: normalized,
        source: _selectedSource,
        age: int.tryParse(_ageController.text.trim()),
        gender: _selectedGender,
        address: _addressController.text.trim(),
        referralName: _referralController.text.trim(),
        concern: _concernController.text.trim(),
        telecallerLeadId: _matchedLead?.id,
        telecallerId: _matchedLead?.telecallerId,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      _open(patient.id);
    } on DuplicatePatientException catch (e) {
      if (!mounted) return;
      setState(() {
        _existingPatient = e.existing;
        _isSaving = false;
        _formError = 'That number already belongs to a registered patient.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _formError = 'Could not register the patient. Please try again.';
      });
    }
  }

  void _open(String patientId) {
    widget.clinic.openPatient(patientId);
    widget.clinic.refreshDashboard();
    widget.viewModel.navigateTo(AppNavSection.patientDetail);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 540,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add New Patient',
                    style: AppTypography.headingSmall.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF6B7280)),
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Mobile number first — it drives everything below it.
              _buildLabel('Mobile Number *'),
              const SizedBox(height: 6),
              TextField(
                key: const Key('add_patient_phone'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                onChanged: _onPhoneChanged,
                decoration: _inputDecoration('98765 43210').copyWith(
                  prefixText: '+91 ',
                  suffixIcon: _isLookingUp
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
              ),

              if (_existingPatient != null) ...[
                const SizedBox(height: 10),
                _existingPatientBanner(_existingPatient!),
              ],
              if (_matchedLead != null) ...[
                const SizedBox(height: 10),
                _leadBanner(_matchedLead!),
              ],
              const SizedBox(height: 14),

              // Full Name
              _buildLabel('Full Name *'),
              const SizedBox(height: 6),
              TextField(
                key: const Key('add_patient_name'),
                controller: _nameController,
                decoration: _inputDecoration('e.g. Maya Lakshmi'),
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
              ),
              const SizedBox(height: 14),

              // Age & Gender
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Age'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('e.g. 28'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Gender'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGender,
                          decoration: _inputDecoration(''),
                          items: _genders
                              .map((g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedGender = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Source & Concern
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Source'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          key: const Key('add_patient_source'),
                          initialValue: _selectedSource,
                          decoration: _inputDecoration(''),
                          items: PatientSource.all
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedSource = v);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Concern'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _concernController,
                          decoration: _inputDecoration('e.g. Hair fall'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Only a doctor referral needs a referrer's name.
              if (_selectedSource == PatientSource.doctorRecommendation) ...[
                const SizedBox(height: 14),
                _buildLabel('Referred By'),
                const SizedBox(height: 6),
                TextField(
                  controller: _referralController,
                  decoration: _inputDecoration('Name of the referring doctor'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                ),
              ],
              const SizedBox(height: 14),

              // Address
              _buildLabel('Address'),
              const SizedBox(height: 6),
              TextField(
                controller: _addressController,
                maxLines: 2,
                decoration: _inputDecoration('Enter residential address'),
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
              ),

              if (_formError != null) ...[
                const SizedBox(height: 14),
                Text(
                  _formError!,
                  key: const Key('add_patient_error'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
              const SizedBox(height: 26),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('add_patient_save'),
                      onPressed: (_isSaving || _existingPatient != null) ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save & Open Profile',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _existingPatientBanner(Patient patient) {
    return Container(
      key: const Key('add_patient_existing_banner'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Already registered as ${patient.name} (#${patient.patientCode}).',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF991B1B),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _open(patient.id);
            },
            child: Text(
              'Open Profile',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leadBanner(TelecallerLead lead) {
    final expected = lead.expectedArrivalDate;
    return Container(
      key: const Key('add_patient_lead_banner'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        border: Border.all(color: const Color(0xFFBBF7D0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.how_to_reg_outlined, size: 18, color: Color(0xFF16A34A)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Telecaller lead — added by ${lead.telecallerName ?? 'a telecaller'}.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF166534),
                  ),
                ),
                Text(
                  expected == null
                      ? 'Details below have been filled in from the lead.'
                      : 'Expected ${DateFormat('d MMM yyyy').format(expected)} — details filled in from the lead.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: const Color(0xFF9CA3AF),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

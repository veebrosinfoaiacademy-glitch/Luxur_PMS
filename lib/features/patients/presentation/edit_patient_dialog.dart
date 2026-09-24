import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/state/clinic_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/phone_utils.dart';
import '../models/patient.dart';
import '../repositories/patient_repository.dart';

/// Corrects a registered patient's own details.
///
/// This edits nothing clinical: consultations, treatments, sessions and
/// bills are untouched, and the patient code and any Telecaller attribution
/// are not editable at all.
class EditPatientDialog extends StatefulWidget {
  final ClinicViewModel clinic;
  final Patient patient;

  const EditPatientDialog({super.key, required this.clinic, required this.patient});

  static Future<void> show(BuildContext context, ClinicViewModel clinic, Patient patient) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => EditPatientDialog(clinic: clinic, patient: patient),
    );
  }

  @override
  State<EditPatientDialog> createState() => _EditPatientDialogState();
}

class _EditPatientDialogState extends State<EditPatientDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _concernController;
  late final TextEditingController _referralController;

  late String _selectedGender;
  late String _selectedSource;

  bool _isSaving = false;
  String? _formError;

  final _genders = ['Female', 'Male', 'Other'];

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _nameController = TextEditingController(text: p.name);
    _ageController = TextEditingController(text: p.age?.toString() ?? '');
    _phoneController = TextEditingController(text: p.phone);
    _addressController = TextEditingController(text: p.address);
    _concernController = TextEditingController(text: p.concern);
    _referralController = TextEditingController(text: p.referralName);
    _selectedGender = _genders.contains(p.gender) ? p.gender : _genders.first;
    _selectedSource =
        PatientSource.all.contains(p.source) ? p.source : PatientSource.directWalkIn;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _concernController.dispose();
    _referralController.dispose();
    super.dispose();
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
      await widget.clinic.patients.update(
        widget.patient.id,
        name: name,
        normalizedPhone: normalized,
        source: _selectedSource,
        age: int.tryParse(_ageController.text.trim()),
        gender: _selectedGender,
        address: _addressController.text.trim(),
        referralName: _referralController.text.trim(),
        concern: _concernController.text.trim(),
      );
      await widget.clinic.reloadProfile();
      await widget.clinic.loadPatients();
      if (!mounted) return;
      Navigator.of(context).pop();
    } on DuplicatePatientException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _formError =
            'That number already belongs to ${e.existing.name} (#${e.existing.patientCode}).';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _formError = 'Could not save the changes. Please try again.';
      });
    }
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Patient Details',
                        style: AppTypography.headingSmall.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${widget.patient.patientCode}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
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

              _buildLabel('Full Name *'),
              const SizedBox(height: 6),
              TextField(
                key: const Key('edit_patient_name'),
                controller: _nameController,
                decoration: _inputDecoration('e.g. Maya Lakshmi'),
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
              ),
              const SizedBox(height: 14),

              _buildLabel('Mobile Number *'),
              const SizedBox(height: 6),
              TextField(
                key: const Key('edit_patient_phone'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('98765 43210').copyWith(prefixText: '+91 '),
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Age'),
                        const SizedBox(height: 6),
                        TextField(
                          key: const Key('edit_patient_age'),
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
                          isExpanded: true,
                          decoration: _inputDecoration(''),
                          items: _genders
                              .map((g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g,
                                        overflow: TextOverflow.ellipsis,
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

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Source'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          key: const Key('edit_patient_source'),
                          initialValue: _selectedSource,
                          // "Doctor Recommendation" is wider than half the
                          // dialog, so the field has to give rather than the
                          // label overflow it.
                          isExpanded: true,
                          decoration: _inputDecoration(''),
                          items: PatientSource.all
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s,
                                        overflow: TextOverflow.ellipsis,
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
                  key: const Key('edit_patient_error'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
              const SizedBox(height: 26),

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
                      key: const Key('edit_patient_save'),
                      onPressed: _isSaving ? null : _save,
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
                              'Save Changes',
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

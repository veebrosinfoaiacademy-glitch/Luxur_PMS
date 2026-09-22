import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_view_model.dart';

class AddPatientDialog extends StatefulWidget {
  final AppViewModel viewModel;

  const AddPatientDialog({super.key, required this.viewModel});

  static Future<void> show(BuildContext context, AppViewModel viewModel) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => AddPatientDialog(viewModel: viewModel),
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
  final _sourceController = TextEditingController(text: 'Instagram');

  String _selectedGender = 'Female';
  String _selectedConcern = 'Skin';
  String _selectedDoctor = 'Dr. Anjali Nair';

  final List<String> _genders = ['Female', 'Male', 'Other'];
  final List<String> _concerns = ['Hair', 'Skin', 'Laser', 'Body Aesthetics'];
  final List<String> _doctors = [
    'Dr. Anjali Nair',
    'Dr. Rohit Kumar',
    'Dr. Karthik Iyer',
    'Dr. Meera Thomas',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _sourceController.dispose();
    super.dispose();
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

              // Full Name
              _buildLabel('Full Name *'),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: _inputDecoration('e.g. Maya Lakshmi'),
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
              ),
              const SizedBox(height: 14),

              // Age & Gender Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Age *'),
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
                        _buildLabel('Gender *'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGender,
                          decoration: _inputDecoration(''),
                          items: _genders.map((g) {
                            return DropdownMenuItem(
                              value: g,
                              child: Text(g, style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
                            );
                          }).toList(),
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

              // Phone Number & Source
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Mobile Number *'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _phoneController,
                          decoration: _inputDecoration('+91 98765 00000'),
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
                        _buildLabel('Source'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _sourceController,
                          decoration: _inputDecoration('e.g. Instagram, Referral'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Concern Category & Assigned Doctor
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Concern Category *'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedConcern,
                          decoration: _inputDecoration(''),
                          items: _concerns.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(c, style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedConcern = v);
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
                        _buildLabel('Assigned Doctor *'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDoctor,
                          decoration: _inputDecoration(''),
                          items: _doctors.map((d) {
                            return DropdownMenuItem(
                              value: d,
                              child: Text(d, style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedDoctor = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
              const SizedBox(height: 26),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
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
                      onPressed: () {
                        final name = _nameController.text.trim();
                        final age = int.tryParse(_ageController.text.trim()) ?? 25;
                        final phone = _phoneController.text.trim();
                        final address = _addressController.text.trim();
                        final source = _sourceController.text.trim();

                        if (name.isNotEmpty) {
                          widget.viewModel.addNewPatient(
                            name: name,
                            age: age,
                            gender: _selectedGender,
                            phone: phone.isEmpty ? '+91 98000 11111' : phone,
                            address: address.isEmpty ? 'Kochi, Kerala' : address,
                            source: source.isEmpty ? 'Walk-in' : source,
                            concern: _selectedConcern,
                            doctor: _selectedDoctor,
                          );
                        }
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                      ),
                      child: Text(
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_view_model.dart';
import '../../../core/state/clinic_view_model.dart';
import '../../../shared/widgets/app_confirmation_dialog.dart';
import 'treatment_plans_panel.dart';

class SettingsView extends StatefulWidget {
  final AppViewModel viewModel;
  final ClinicViewModel clinic;

  const SettingsView({super.key, required this.viewModel, required this.clinic});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  // 0 = Doctor Management, 1 = Clinic Profile, 2 = Treatment Plans
  int _selectedSettingsTab = 0;

  final List<Map<String, dynamic>> _doctors = [
    {
      'name': 'Dr. Anjali Nair',
      'specialization': 'Senior Dermatologist & Aesthetician',
      'slots': 'Mon - Fri: 09:30 AM - 01:30 PM, 04:00 PM - 07:00 PM',
      'patientsCount': 142,
    },
    {
      'name': 'Dr. Rohit Kumar',
      'specialization': 'Cosmetologist & Laser Specialist',
      'slots': 'Mon - Sat: 10:00 AM - 02:00 PM, 03:00 PM - 06:00 PM',
      'patientsCount': 98,
    },
    {
      'name': 'Dr. Karthik Iyer',
      'specialization': 'Trichologist & Hair Restoration Surgeon',
      'slots': 'Tue, Thu, Sat: 09:00 AM - 02:00 PM',
      'patientsCount': 64,
    },
    {
      'name': 'Dr. Meera Thomas',
      'specialization': 'Aesthetic Physician',
      'slots': 'Mon - Fri: 02:00 PM - 08:00 PM',
      'patientsCount': 88,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          Text('Clinic Settings', style: AppTypography.headingDisplay),
          const SizedBox(height: 4),
          Text(
            'Configure doctors, slot timings, and general clinic parameters.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Sub tabs (Doctor Management, Clinic Profile)
          Row(
            children: [
              _buildTabButton(0, 'Doctor Management', Icons.medical_services_outlined),
              const SizedBox(width: 12),
              _buildTabButton(1, 'Clinic Profile & Branding', Icons.business_outlined),
              const SizedBox(width: 12),
              _buildTabButton(2, 'Treatment Plans', Icons.spa_outlined),
            ],
          ),
          const SizedBox(height: 24),

          // Content
          switch (_selectedSettingsTab) {
            0 => _buildDoctorManagement(),
            1 => _buildClinicProfile(),
            _ => TreatmentPlansPanel(clinic: widget.clinic),
          },
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isSelected = _selectedSettingsTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedSettingsTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF4B5563)),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorManagement() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Doctors & Consultations',
                    style: AppTypography.headingSmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Doctors are managed by the administrator and assigned to patient consultations.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add Doctor dialog (Visual Mode)')),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Doctor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Doctors List
          ..._doctors.map((doc) => Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.sidebarBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFDCFCE7),
                      child: const Icon(Icons.person, color: Color(0xFF16A34A), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                doc['name'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${doc['patientsCount']} Assigned Patients',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF0284C7)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            doc['specialization'] as String,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF4B5563)),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 14, color: Color(0xFF6B7280)),
                              const SizedBox(width: 6),
                              Text(
                                doc['slots'] as String,
                                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF374151), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Configuring slot timings for ${doc['name']}')),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text('Edit Timings', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            AppConfirmationDialog.show(
                              context: context,
                              title: 'Remove Doctor?',
                              message: 'Are you sure you want to remove ${doc['name']}?\nActive patients must be reassigned first.',
                              confirmText: 'Remove',
                              confirmColor: const Color(0xFFDC2626),
                              icon: Icons.delete_outline,
                              onConfirm: () {},
                            );
                          },
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildClinicProfile() {
    return Container(
      width: 600,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Clinic Identity & Invoicing Defaults', style: AppTypography.headingSmall.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _field('Clinic Name', 'Veebros Clinic (Veebros Infosolutions)'),
          const SizedBox(height: 12),
          _field('Address', '28/4, Green View Plaza, Kadavanthra, Kochi, Kerala - 682020'),
          const SizedBox(height: 12),
          _field('Contact Phone', '+91 484 220 5678'),
          const SizedBox(height: 12),
          _field('Email Address', 'info@veebros.com'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _field('Bill Prefix', 'BILL')),
              const SizedBox(width: 12),
              Expanded(child: _field('Patient ID Prefix', 'PMS / #PT')),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved successfully.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String initialValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_view_model.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/app_confirmation_dialog.dart';
import '../../sessions/presentation/schedule_session_dialog.dart';
import '../../billing/presentation/half_a4_bill_dialog.dart';

class PatientDetailView extends StatelessWidget {
  final AppViewModel viewModel;

  const PatientDetailView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final patient = viewModel.selectedPatient;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Action Bar: "Back to Patients" & "+ Schedule Session"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => viewModel.navigateTo(AppNavSection.patients),
                icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF374151)),
                label: Text(
                  'Back to Patients',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => ScheduleSessionDialog.show(context, viewModel),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Schedule Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Patient Summary Header Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Initials Circle
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.avatarPurpleBg,
                  child: Text(
                    patient.initials,
                    style: GoogleFonts.ebGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name, ID & Badges
                      Row(
                        children: [
                          Text(
                            patient.name,
                            style: AppTypography.patientNameHeader,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            patient.patientId,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const StatusBadge(
                            label: 'Active Treatment',
                            type: StatusBadgeType.activeTreatment,
                          ),
                          const SizedBox(width: 8),
                          const StatusBadge(
                            label: 'Regular Patient',
                            type: StatusBadgeType.regularPatient,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Meta details row with icons
                      Row(
                        children: [
                          _buildHeaderMetaItem(
                            Icons.calendar_today_outlined,
                            '${patient.age} years (${patient.dob})',
                          ),
                          const SizedBox(width: 20),
                          _buildHeaderMetaItem(
                            Icons.female_rounded,
                            patient.gender,
                          ),
                          const SizedBox(width: 20),
                          _buildHeaderMetaItem(
                            Icons.phone_outlined,
                            patient.phone,
                          ),
                          const SizedBox(width: 20),
                          _buildHeaderMetaItem(
                            Icons.location_on_outlined,
                            'Kochi, Kerala',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Edit Profile & Delete Profile Buttons
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opening Edit Profile for ${patient.name}')),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                      label: Text(
                        'Edit Profile',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF0FDF4),
                        side: const BorderSide(color: Color(0xFFBBF7D0)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        AppConfirmationDialog.show(
                          context: context,
                          title: 'Permanently Delete Patient?',
                          message:
                              'Are you sure you want to delete ${patient.name} (${patient.patientId})?\nThis action cannot be undone. All consultation records, treatment sessions, progress photos, and billing history will be permanently deleted.',
                          confirmText: 'Delete Permanently',
                          confirmColor: const Color(0xFFDC2626),
                          icon: Icons.delete_forever_rounded,
                          onConfirm: () {
                            viewModel.navigateTo(AppNavSection.patients);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${patient.name} was permanently deleted.')),
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.delete_outline, size: 14, color: Color(0xFFDC2626)),
                      label: Text(
                        'Delete Profile',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF2F2),
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Horizontal Navigation Tabs
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
            ),
            child: Row(
              children: [
                _buildTab('Overview', PatientDetailTab.overview),
                _buildTab('Consultations', PatientDetailTab.consultations),
                _buildTab('Treatments & Sessions', PatientDetailTab.treatmentsSessions),
                _buildTab('Progress Photos', PatientDetailTab.progressPhotos),
                _buildTab('Billing', PatientDetailTab.billing),
                _buildTab('History', PatientDetailTab.history),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 4. Tab Body
          _buildTabContent(context, patient),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, PatientRecord patient) {
    switch (viewModel.currentPatientTab) {
      case PatientDetailTab.overview:
        return _buildOverviewTab(context, patient);
      case PatientDetailTab.consultations:
        return _buildConsultationsTab();
      case PatientDetailTab.treatmentsSessions:
        return _buildTreatmentsSessionsTab(context);
      case PatientDetailTab.progressPhotos:
        return _buildPhotosGalleryTab();
      case PatientDetailTab.billing:
        return _buildBillingTab(context, patient);
      case PatientDetailTab.history:
        return _buildHistoryTab(patient);
    }
  }

  // OVERVIEW TAB: 3 Columns matching reference UI
  Widget _buildOverviewTab(BuildContext context, PatientRecord patient) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column 1: Patient Info & Notes
        Expanded(
          flex: 3,
          child: Column(
            children: [
              // Patient Information Card
              Container(
                padding: const EdgeInsets.all(20),
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
                        Text(
                          'Patient Information',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        InkWell(
                          onTap: () {},
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 13, color: Color(0xFF4B5563)),
                              const SizedBox(width: 4),
                              Text('Edit', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4B5563))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _infoRow('Full Name', patient.name),
                    _infoRow('Patient ID', patient.patientId),
                    _infoRow('Age / DOB', '${patient.age} years (${patient.dob})'),
                    _infoRow('Gender', patient.gender),
                    _infoRow('Mobile Number', patient.phone),
                    _infoRow('Address', patient.address),
                    _infoRow('Source', patient.source),
                    _infoCustomRow(
                      'Primary Concern',
                      Row(
                        children: patient.concerns
                            .map((c) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: c == 'Skin' ? const Color(0xFFDCFCE7) : const Color(0xFFF3E8FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      c,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: c == 'Skin' ? const Color(0xFF16A34A) : const Color(0xFF9333EA),
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    _infoRow('Assigned Doctor', patient.assignedDoctor),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Notes Card
              Container(
                padding: const EdgeInsets.all(20),
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
                        Text(
                          'Notes',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Note editor opened (Visual Mode)')),
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.edit_note, size: 16, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text('Add Note', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.sidebarBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prefers morning appointments.\nSensitive skin. Avoid harsh laser settings.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: const Color(0xFF374151),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Added on 10 Apr 2025 by Admin',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Column 2: Current Treatment, Upcoming Session, Recent Sessions
        Expanded(
          flex: 4,
          child: Column(
            children: [
              // Current Treatment Card
              Container(
                padding: const EdgeInsets.all(20),
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
                        Text(
                          'Current Treatment',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        InkWell(
                          onTap: () => viewModel.setPatientTab(PatientDetailTab.treatmentsSessions),
                          child: Text(
                            'View All',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE4E6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.spa_outlined, color: Color(0xFFE11D48), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Laser Hair Reduction',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                'Underarm',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const StatusBadge(label: 'Ongoing', type: StatusBadgeType.ongoing),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Progress bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('4 of 6 sessions completed', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF6B7280))),
                        Text('66%', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: 0.66,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 14),
                    _treatmentMetaRow('Assigned Doctor', 'Dr. Anjali Nair'),
                    _treatmentMetaRow('Treatment Start Date', '10 Mar 2025'),
                    _treatmentMetaRow('Expected Completion', '20 Aug 2025'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Upcoming Session Card (Interactive state machine!)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming Session',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBgLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.event_available, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Session 5 of 6',
                                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Laser Hair Reduction',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ),
                        _buildSessionStatusBadge(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF6B7280)),
                        const SizedBox(width: 6),
                        Text('15 Apr 2025', style: GoogleFonts.plusJakartaSans(fontSize: 12.5)),
                        const SizedBox(width: 16),
                        const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF6B7280)),
                        const SizedBox(width: 6),
                        Text('10:00 AM', style: GoogleFonts.plusJakartaSans(fontSize: 12.5)),
                        const SizedBox(width: 16),
                        const Icon(Icons.person_outline, size: 14, color: Color(0xFF6B7280)),
                        const SizedBox(width: 6),
                        Text('Dr. Anjali Nair', style: GoogleFonts.plusJakartaSans(fontSize: 12.5)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Dynamic Workflow Buttons
                    _buildSessionWorkflowButtons(context, patient),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Recent Sessions Table Card
              Container(
                padding: const EdgeInsets.all(20),
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
                        Text(
                          'Recent Sessions',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        InkWell(
                          onTap: () => viewModel.setPatientTab(PatientDetailTab.treatmentsSessions),
                          child: Text(
                            'View All',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMiniSessionsTable(),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Column 3: Progress Photos & Billing History
        Expanded(
          flex: 4,
          child: Column(
            children: [
              // Progress Photos Card
              Container(
                padding: const EdgeInsets.all(20),
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
                        Text(
                          'Progress Photos',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        InkWell(
                          onTap: () => viewModel.setPatientTab(PatientDetailTab.progressPhotos),
                          child: Text(
                            'View All',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Dropdowns row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Laser Hair Reduction', style: GoogleFonts.plusJakartaSans(fontSize: 11)),
                                const Icon(Icons.keyboard_arrow_down, size: 14),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('All Sessions', style: GoogleFonts.plusJakartaSans(fontSize: 11)),
                                const Icon(Icons.keyboard_arrow_down, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Photos Row (Session 1, Session 2, Session 3)
                    Row(
                      children: [
                        Expanded(child: _photoSessionCard('Session 1', '17 Feb 2025')),
                        const SizedBox(width: 8),
                        Expanded(child: _photoSessionCard('Session 2', '24 Feb 2025')),
                        const SizedBox(width: 8),
                        Expanded(child: _photoSessionCard('Session 3', '03 Mar 2025')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Billing History Card
              Container(
                padding: const EdgeInsets.all(20),
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
                        Text(
                          'Billing History',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        InkWell(
                          onTap: () => viewModel.setPatientTab(PatientDetailTab.billing),
                          child: Text(
                            'View All',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildBillingHistoryTable(context, patient),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Session Dynamic Buttons
  Widget _buildSessionWorkflowButtons(BuildContext context, PatientRecord patient) {
    switch (viewModel.sessionState) {
      case SessionState.scheduled:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  AppConfirmationDialog.show(
                    context: context,
                    title: 'Confirm Patient Arrival?',
                    message:
                        'Confirm that ${patient.name} has arrived at the clinic.\nThis will record the exact arrival timestamp in the clinic log.',
                    confirmText: 'Confirm Arrival',
                    icon: Icons.check_circle_outline,
                    onConfirm: () {
                      viewModel.recordPatientArrival();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${patient.name} marked as Arrived at ${viewModel.arrivalTime}')),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Patient Arrived'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => ScheduleSessionDialog.show(context, viewModel),
              icon: const Icon(Icons.schedule, size: 14),
              label: const Text('Reschedule'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () {
                AppConfirmationDialog.show(
                  context: context,
                  title: 'Cancel This Session?',
                  message: 'Are you sure you want to cancel Session 5 for ${patient.name}?',
                  confirmText: 'Cancel Session',
                  confirmColor: const Color(0xFFDC2626),
                  icon: Icons.cancel_outlined,
                  onConfirm: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Session cancelled.')),
                    );
                  },
                );
              },
              icon: const Icon(Icons.close, size: 14, color: Color(0xFF6B7280)),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
            ),
          ],
        );

      case SessionState.arrived:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  AppConfirmationDialog.show(
                    context: context,
                    title: 'Start Session?',
                    message:
                        'Session 5 with ${patient.assignedDoctor} will begin now. Start timestamp will be saved.',
                    confirmText: 'Start Session',
                    icon: Icons.play_arrow_rounded,
                    onConfirm: () {
                      viewModel.startSession();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Session started at ${viewModel.startTime}')),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Start Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF15803D),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Arrived: ${viewModel.arrivalTime}',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF15803D)),
            ),
          ],
        );

      case SessionState.inProgress:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  AppConfirmationDialog.show(
                    context: context,
                    title: 'End Session?',
                    message:
                        'Are you sure you want to end Session 5? This will mark it as completed and proceed to billing.',
                    confirmText: 'End Session',
                    icon: Icons.stop_rounded,
                    onConfirm: () {
                      viewModel.endSession();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Session completed at ${viewModel.endTime}')),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.stop_rounded, size: 18),
                label: const Text('Session Ended'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB91C1C),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Started: ${viewModel.startTime}',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFD97706)),
            ),
          ],
        );

      case SessionState.completed:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  HalfA4BillDialog.show(
                    context,
                    patientName: patient.name,
                    patientId: patient.patientId,
                    treatmentName: 'Laser Hair Reduction',
                    sessionInfo: 'Session 5 of 6',
                    amount: 4500,
                  );
                },
                icon: const Icon(Icons.receipt_long, size: 16),
                label: const Text('Generate Bill (Half-A4)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () => viewModel.resetSession(),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
              child: const Text('Reset Demo'),
            ),
          ],
        );
    }
  }

  Widget _buildSessionStatusBadge() {
    switch (viewModel.sessionState) {
      case SessionState.scheduled:
        return const StatusBadge(label: 'Scheduled', type: StatusBadgeType.scheduled);
      case SessionState.arrived:
        return const StatusBadge(label: 'Arrived', type: StatusBadgeType.dueSoon);
      case SessionState.inProgress:
        return const StatusBadge(label: 'In Progress', type: StatusBadgeType.urgent);
      case SessionState.completed:
        return const StatusBadge(label: 'Completed', type: StatusBadgeType.completed);
    }
  }

  Widget _photoSessionCard(String sessionTitle, String date) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCC8B3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
                child: Center(
                  child: Text('Before', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(width: 1),
            Expanded(
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E2CF),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: Center(
                  child: Text('After', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF8C7F72))),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(sessionTitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600)),
        Text(date, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF9CA3AF))),
      ],
    );
  }

  Widget _buildMiniSessionsTable() {
    final rows = [
      {'#': '4', 'date': '10 Mar 2025', 'doctor': 'Dr. Anjali Nair', 'status': 'Completed'},
      {'#': '3', 'date': '03 Mar 2025', 'doctor': 'Dr. Anjali Nair', 'status': 'Completed'},
      {'#': '2', 'date': '24 Feb 2025', 'doctor': 'Dr. Anjali Nair', 'status': 'Completed'},
      {'#': '1', 'date': '17 Feb 2025', 'doctor': 'Dr. Anjali Nair', 'status': 'Completed'},
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(0.8),
        1: FlexColumnWidth(2.2),
        2: FlexColumnWidth(2.5),
        3: FlexColumnWidth(2.0),
        4: FlexColumnWidth(1.2),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
          children: [
            _tableHeader('#'),
            _tableHeader('Date'),
            _tableHeader('Doctor'),
            _tableHeader('Status'),
            _tableHeader('Action'),
          ],
        ),
        ...rows.map((r) => TableRow(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
              children: [
                Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(r['#']!, style: GoogleFonts.plusJakartaSans(fontSize: 12))),
                Text(r['date']!, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                Text(r['doctor']!, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                const StatusBadge(label: 'Completed', type: StatusBadgeType.completed),
                TextButton(
                  onPressed: () {},
                  child: Text('View', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600)),
                ),
              ],
            )),
      ],
    );
  }

  Widget _buildBillingHistoryTable(BuildContext context, PatientRecord patient) {
    final bills = [
      {'date': '10 Mar 2025', 'desc': 'Session 4', 'amount': '₹4,500', 'mode': 'Online'},
      {'date': '03 Mar 2025', 'desc': 'Session 3', 'amount': '₹4,500', 'mode': 'Cash'},
      {'date': '24 Feb 2025', 'desc': 'Session 2', 'amount': '₹4,500', 'mode': 'Online'},
      {'date': '17 Feb 2025', 'desc': 'Session 1', 'amount': '₹4,500', 'mode': 'Cash'},
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.2),
        1: FlexColumnWidth(2.0),
        2: FlexColumnWidth(1.6),
        3: FlexColumnWidth(1.6),
        4: FlexColumnWidth(1.4),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
          children: [
            _tableHeader('Date'),
            _tableHeader('Description'),
            _tableHeader('Amount'),
            _tableHeader('Payment Mode'),
            _tableHeader('Status'),
          ],
        ),
        ...bills.map((b) => TableRow(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    onTap: () {
                      HalfA4BillDialog.show(
                        context,
                        patientName: patient.name,
                        patientId: patient.patientId,
                        treatmentName: 'Laser Hair Reduction',
                        sessionInfo: b['desc']!,
                        paymentMode: b['mode']!,
                      );
                    },
                    child: Text(
                      b['date']!,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
                Text(b['desc']!, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                Text(b['amount']!, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(b['mode']!, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                const StatusBadge(label: 'Paid', type: StatusBadgeType.paid),
              ],
            )),
      ],
    );
  }

  // OTHER TABS
  Widget _buildConsultationsTab() {
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
              Text('Consultation History', style: AppTypography.headingSmall),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Consultation'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.sidebarBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Initial Consultation — Dr. Anjali Nair', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text('05 Mar 2025, 11:30 AM', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF6B7280))),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Primary Concern: Unwanted hair growth underarm and upper lip. Evaluated skin Fitzpatrick scale Type III.', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('Decision: ', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                      child: Text('Opted for Treatment (6 Sessions Package)', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF15803D))),
                    ),
                    const SizedBox(width: 14),
                    Text('Consultation Fee: N/A (Included in Package)', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF6B7280))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentsSessionsTab(BuildContext context) {
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
              Text('Treatments & Planned Sessions', style: AppTypography.headingSmall),
              ElevatedButton.icon(
                onPressed: () => ScheduleSessionDialog.show(context, viewModel),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Schedule Next Session'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Package: Laser Hair Reduction (Underarm - 6 Sessions)', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _buildMiniSessionsTable(),
        ],
      ),
    );
  }

  Widget _buildPhotosGalleryTab() {
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
              Text('Progress Photographs Gallery', style: AppTypography.headingSmall),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                label: const Text('Upload New Photos'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _photoSessionCard('Session 1', '17 Feb 2025')),
              const SizedBox(width: 16),
              Expanded(child: _photoSessionCard('Session 2', '24 Feb 2025')),
              const SizedBox(width: 16),
              Expanded(child: _photoSessionCard('Session 3', '03 Mar 2025')),
              const SizedBox(width: 16),
              Expanded(child: _photoSessionCard('Session 4', '10 Mar 2025')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillingTab(BuildContext context, PatientRecord patient) {
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
              Text('All Invoices & Receipts', style: AppTypography.headingSmall),
              ElevatedButton.icon(
                onPressed: () {
                  HalfA4BillDialog.show(
                    context,
                    patientName: patient.name,
                    patientId: patient.patientId,
                    treatmentName: 'Laser Hair Reduction',
                    sessionInfo: 'Session 5 of 6',
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Generate New Invoice'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBillingHistoryTable(context, patient),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(PatientRecord patient) {
    final timeline = [
      {'time': '10 Apr 2025, 04:15 PM', 'title': 'Admin Note Added', 'desc': 'Prefers morning appointments. Sensitive skin.'},
      {'time': '10 Mar 2025, 11:15 AM', 'title': 'Session 4 Completed & Billed', 'desc': 'End time 11:15 AM. Bill #BILL-2025-0042 paid online.'},
      {'time': '10 Mar 2025, 10:10 AM', 'title': 'Patient Arrived for Session 4', 'desc': 'Arrival recorded. Waiting time 10 mins.'},
      {'time': '03 Mar 2025, 10:45 AM', 'title': 'Session 3 Completed & Billed', 'desc': 'Bill #BILL-2025-0031 paid via Cash.'},
      {'time': '10 Mar 2025, 10:00 AM', 'title': 'Treatment Started', 'desc': 'Package Laser Hair Reduction activated.'},
      {'time': '05 Mar 2025, 11:30 AM', 'title': 'Consultation Completed', 'desc': 'Patient opted for treatment with Dr. Anjali Nair.'},
      {'time': '05 Mar 2025, 11:00 AM', 'title': 'Patient Registered', 'desc': 'Registered via Instagram inquiry by Admin.'},
    ];

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
          Text('Complete Patient Chronological History', style: AppTypography.headingSmall),
          const SizedBox(height: 20),
          ...timeline.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title']!, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700)),
                        Text(item['time']!, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF6B7280))),
                        const SizedBox(height: 2),
                        Text(item['desc']!, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF374151))),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // Helpers
  Widget _buildTab(String label, PatientDetailTab tab) {
    final isSelected = viewModel.currentPatientTab == tab;
    return GestureDetector(
      onTap: () => viewModel.setPatientTab(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderMetaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF4B5563))),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF6B7280))),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCustomRow(String label, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF6B7280))),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _treatmentMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF6B7280))),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
    );
  }
}

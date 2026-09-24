import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/state/app_view_model.dart';
import '../../../core/state/clinic_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../shared/widgets/app_confirmation_dialog.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../billing/models/bill.dart';
import '../../billing/presentation/bill_dialogs.dart';
import '../../consultations/models/consultation.dart';
import '../../consultations/presentation/consultation_form_dialog.dart';
import '../../sessions/models/session.dart';
import '../../sessions/presentation/schedule_session_dialog.dart';
import '../../sessions/presentation/session_form_dialog.dart';
import '../../treatments/models/treatment.dart';
import '../models/patient.dart';
import 'edit_patient_dialog.dart';

/// The patient profile — the same six-tab template, on real records.
///
/// A patient who has just been registered has no clinical history yet, so
/// the Overview shows only their information and registration notes until
/// a doctor has seen them.
class PatientDetailView extends StatelessWidget {
  final AppViewModel viewModel;
  final ClinicViewModel clinic;

  const PatientDetailView({super.key, required this.viewModel, required this.clinic});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: clinic,
      builder: (context, _) {
        final profile = clinic.profile;
        if (profile == null) {
          return Center(
            child: clinic.isProfileLoading
                ? const CircularProgressIndicator()
                : Text(
                    'Select a patient to see their profile.',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: AppColors.textMuted),
                  ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(context, profile),
              const SizedBox(height: 16),
              _summaryCard(context, profile.patient),
              const SizedBox(height: 20),
              _tabBar(),
              const SizedBox(height: 20),
              _tabContent(context, profile),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------- header

  Widget _topBar(BuildContext context, PatientProfile profile) {
    // Sessions can only be scheduled against a treatment a doctor has
    // already recommended.
    final canSchedule = profile.treatments.any((t) => t.isActive);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: () {
            clinic.closePatient();
            viewModel.navigateTo(AppNavSection.patients);
          },
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
        Row(
          children: [
            if (!profile.consultations.any((c) => c.isCompleted))
              ElevatedButton.icon(
                key: const Key('start_consultation_button'),
                onPressed: () => ConsultationFormDialog.show(context, clinic, profile.patient),
                icon: const Icon(Icons.assignment_outlined, size: 18),
                label: const Text('Start Consultation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            if (canSchedule) ...[
              const SizedBox(width: 10),
              ElevatedButton.icon(
                key: const Key('schedule_session_button'),
                onPressed: () => ScheduleSessionDialog.show(context, clinic, profile),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Schedule Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
            // Correcting or removing a patient record is the Admin's call,
            // not a doctor's.
            if (!clinic.isDoctor) ...[
              const SizedBox(width: 10),
              OutlinedButton.icon(
                key: const Key('edit_patient_button'),
                onPressed: () => EditPatientDialog.show(context, clinic, profile.patient),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                key: const Key('delete_patient_button'),
                onPressed: () => _confirmDelete(context, profile.patient),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Deleting archives the patient — their consultations, sessions, photos
  /// and bills are all kept, so the wording says so plainly.
  void _confirmDelete(BuildContext context, Patient patient) {
    AppConfirmationDialog.show(
      context: context,
      title: 'Delete this patient?',
      message: '${patient.name} (#${patient.patientCode}) will be archived and removed '
          'from the patient list. Their consultations, sessions and bills are kept '
          'on record and nothing is permanently deleted.',
      confirmText: 'Delete Profile',
      confirmColor: const Color(0xFFDC2626),
      icon: Icons.delete_outline,
      onConfirm: () async {
        await clinic.archivePatient(patient.id);
        viewModel.navigateTo(AppNavSection.patients);
      },
    );
  }

  Widget _summaryCard(BuildContext context, Patient patient) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.avatarPurpleBg,
            child: Text(
              patient.initials,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(patient.name, style: AppTypography.patientNameHeader),
                    const SizedBox(width: 12),
                    Text(
                      '#${patient.patientCode}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 14),
                    StatusBadge(
                      label: patient.status.isEmpty ? 'Joined' : patient.status,
                      type: patient.status == 'Not Joined'
                          ? StatusBadgeType.upcoming
                          : StatusBadgeType.activeTreatment,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 20,
                  runSpacing: 6,
                  children: [
                    if (patient.age != null)
                      _metaItem(Icons.calendar_today_outlined, '${patient.age} years'),
                    if (patient.gender.isNotEmpty)
                      _metaItem(Icons.person_outline, patient.gender),
                    _metaItem(Icons.phone_outlined, PhoneUtils.display(patient.phone)),
                    if (patient.address.isNotEmpty)
                      _metaItem(Icons.location_on_outlined, patient.address),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: const Color(0xFF4B5563),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------- tabs

  Widget _tabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _tab('Overview', PatientDetailTab.overview),
          _tab('Consultations', PatientDetailTab.consultations),
          _tab('Treatments & Sessions', PatientDetailTab.treatmentsSessions),
          _tab('Progress Photos', PatientDetailTab.progressPhotos),
          _tab('Billing', PatientDetailTab.billing),
          _tab('History', PatientDetailTab.history),
        ],
      ),
    );
  }

  Widget _tab(String label, PatientDetailTab tab) {
    final isSelected = viewModel.currentPatientTab == tab;
    return InkWell(
      onTap: () => viewModel.setPatientTab(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _tabContent(BuildContext context, PatientProfile profile) {
    switch (viewModel.currentPatientTab) {
      case PatientDetailTab.overview:
        return _overviewTab(context, profile);
      case PatientDetailTab.consultations:
        return _consultationsTab(context, profile);
      case PatientDetailTab.treatmentsSessions:
        return _treatmentsTab(context, profile);
      case PatientDetailTab.progressPhotos:
        return _photosTab(context, profile);
      case PatientDetailTab.billing:
        return _billingTab(context, profile);
      case PatientDetailTab.history:
        return _historyTab(profile);
    }
  }

  // ----------------------------------------------------------------- overview

  Widget _overviewTab(BuildContext context, PatientProfile profile) {
    final patient = profile.patient;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          key: const Key('patient_information_card'),
          title: 'Patient Information',
          child: Column(
            children: [
              _infoRow('Patient ID', '#${patient.patientCode}'),
              _infoRow('Full Name', patient.name),
              _infoRow('Age', patient.age == null ? '—' : '${patient.age}'),
              _infoRow('Gender', patient.gender.isEmpty ? '—' : patient.gender),
              _infoRow('Mobile Number', PhoneUtils.display(patient.phone)),
              _infoRow('Address', patient.address.isEmpty ? '—' : patient.address),
              _infoRow('Source', patient.source.isEmpty ? '—' : patient.source),
              if (patient.referralName.isNotEmpty)
                _infoRow('Referred By', patient.referralName),
              if (patient.isFromTelecallerLead)
                _infoRow('Telecaller', patient.telecallerName ?? 'Telecaller lead'),
              _infoRow('Registered On', DateFormat('d MMM yyyy').format(patient.created)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _card(
          key: const Key('patient_notes_card'),
          title: 'Notes',
          child: Text(
            patient.concern.isEmpty
                ? 'No notes were recorded at registration.'
                : patient.concern,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.6,
              color: const Color(0xFF374151),
            ),
          ),
        ),

        // Everything below only exists once a doctor has seen the patient.
        if (profile.hasClinicalHistory) ...[
          const SizedBox(height: 20),
          _card(
            title: 'Treatment Progress',
            child: Column(
              children: [
                for (final treatment in profile.treatments) _progressBlock(profile, treatment),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _progressBlock(PatientProfile profile, Treatment treatment) {
    final progress = profile.progressFor(treatment);
    final sessions = profile.sessionsFor(treatment.id);
    final completed = sessions.where((s) => s.status == SessionStatus.completed).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${treatment.packageName} (${treatment.category})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${progress.percent}% paid',
                key: Key('progress_percent_${treatment.id}'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              // The bar itself cannot exceed full width, but the figure
              // above it is the true, uncapped percentage.
              value: progress.fraction.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_money(progress.paidAmount)} paid of ${_money(progress.packageCost)}'
            '${treatment.sessionsTotal == null ? '' : ' • $completed of ${treatment.sessionsTotal} sessions done'}',
            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ consultations

  Widget _consultationsTab(BuildContext context, PatientProfile profile) {
    if (profile.consultations.isEmpty) {
      return _emptyCard('No consultations recorded yet.');
    }
    return Column(
      children: [
        for (final consultation in profile.consultations)
          _consultationCard(context, profile, consultation),
      ],
    );
  }

  Widget _consultationCard(
      BuildContext context, PatientProfile profile, Consultation consultation) {
    final bill = profile.bills.firstWhereOrNull((b) => b.consultationId == consultation.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _card(
        title: consultation.isCompleted
            ? 'Consultation — ${DateFormat('d MMM yyyy').format(consultation.completedAt ?? consultation.created)}'
            : 'Consultation (draft)',
        trailing: consultation.isCompleted
            ? null
            : TextButton(
                onPressed: () => ConsultationFormDialog.show(
                  context,
                  clinic,
                  profile.patient,
                  existing: consultation,
                ),
                child: const Text('Continue'),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Doctor', consultation.doctorName ?? '—'),
            _infoRow(
              'Reason for Visit',
              consultation.reasonForVisit.isEmpty ? '—' : consultation.reasonForVisit,
            ),
            _infoRow('Doctor’s Notes', consultation.notes.isEmpty ? '—' : consultation.notes),
            _infoRow(
              'Recommendation',
              consultation.recommendation?.label ?? '—',
            ),
            if (consultation.suggestedProduct.isNotEmpty)
              _infoRow('Suggested Product', consultation.suggestedProduct),
            if (consultation.consultationFee != null)
              _infoRow('Consultation Fee', _money(consultation.consultationFee!)),
            if (consultation.imageFilenames.isNotEmpty) ...[
              const SizedBox(height: 10),
              _imageStrip([
                for (final f in consultation.imageFilenames)
                  clinic.consultations.imageUrl(consultation, f),
              ]),
            ],
            if (consultation.isCompleted && (consultation.consultationFee ?? 0) > 0) ...[
              const SizedBox(height: 14),
              _billActions(context, bill, onGenerate: () async {
                await clinic.bills.createConsultationBill(
                  patientId: profile.patient.id,
                  consultationId: consultation.id,
                  consultationFee: consultation.consultationFee!,
                  paymentMethod: PaymentMethod.cash,
                );
                await clinic.reloadProfile();
              }),
            ],
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------- treatments

  Widget _treatmentsTab(BuildContext context, PatientProfile profile) {
    if (profile.treatments.isEmpty) {
      return _emptyCard('No treatment has been recommended yet.');
    }

    return Column(
      children: [
        for (final treatment in profile.treatments)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _card(
              title: '${treatment.packageName} — ${treatment.category}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Package Cost', _money(treatment.packageCost)),
                  if (treatment.sessionsTotal != null)
                    _infoRow('Total Sessions', '${treatment.sessionsTotal}'),
                  _infoRow('Status', treatment.status),
                  const SizedBox(height: 14),
                  _sessionsTable(context, profile, profile.sessionsFor(treatment.id)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _sessionsTable(BuildContext context, PatientProfile profile, List<Session> sessions) {
    if (sessions.isEmpty) {
      return Text(
        'No sessions scheduled yet.',
        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textMuted),
      );
    }

    return Column(
      children: [
        for (final session in sessions)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    DateFormat('d MMM yyyy').format(session.scheduledDate),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    // Unassigned is normal — whoever treats the patient
                    // becomes this session's doctor on completion.
                    session.doctorName ?? 'Any available doctor',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5, color: const Color(0xFF4B5563)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _sessionStatusPill(session),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (session.status == SessionStatus.scheduled ||
                          session.status == SessionStatus.noShow)
                        OutlinedButton(
                          onPressed: () => _markArrived(context, session.id),
                          style: _smallButtonStyle,
                          child: const Text('Patient Arrived'),
                        ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        onPressed: () =>
                            SessionFormDialog.show(context, clinic, profile.patient, session),
                        style: _smallButtonStyle,
                        child: Text(
                          session.status == SessionStatus.completed ? 'View' : 'Open Session',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  ButtonStyle get _smallButtonStyle => OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
        side: const BorderSide(color: Color(0xFFD1D5DB)),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
        foregroundColor: const Color(0xFF374151),
      );

  Widget _sessionStatusPill(Session session) {
    final (background, foreground) = switch (session.status) {
      SessionStatus.completed => (const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
      SessionStatus.noShow => (const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
      _ => (const Color(0xFFDCFCE7), const Color(0xFF15803D)),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          session.status.label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ photos

  Widget _photosTab(BuildContext context, PatientProfile profile) {
    final images = <(String label, Uri url)>[
      for (final consultation in profile.consultations)
        for (final filename in consultation.imageFilenames)
          (
            'Consultation • ${DateFormat('d MMM yyyy').format(consultation.created)}',
            clinic.consultations.imageUrl(consultation, filename),
          ),
      for (final session in profile.sessions)
        for (final filename in session.imageFilenames)
          (
            'Session • ${DateFormat('d MMM yyyy').format(session.scheduledDate)}',
            clinic.sessions.imageUrl(session, filename),
          ),
    ];

    if (images.isEmpty) {
      return _emptyCard('No progress photos have been added yet.');
    }

    return _card(
      title: 'Progress Photos',
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final (label, url) in images)
            SizedBox(
              width: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url.toString(),
                      height: 160,
                      width: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 160,
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(Icons.broken_image_outlined,
                            color: Color(0xFF9CA3AF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _imageStrip(List<Uri> urls) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            urls[index].toString(),
            width: 92,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 92,
              color: const Color(0xFFF3F4F6),
              child: const Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF)),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- billing

  Widget _billingTab(BuildContext context, PatientProfile profile) {
    // Consultation billing and session billing are kept apart — they are
    // different charges and are settled separately.
    final consultationBills = profile.bills.where((b) => b.isConsultationBill).toList();
    final sessionBills = profile.bills.where((b) => b.isSessionBill).toList();

    if (profile.bills.isEmpty) {
      return _emptyCard('No bills have been generated yet.');
    }

    return Column(
      children: [
        if (consultationBills.isNotEmpty)
          _card(
            key: const Key('consultation_billing_card'),
            title: 'Consultation Billing',
            child: Column(children: [for (final b in consultationBills) _billRow(context, b)]),
          ),
        if (consultationBills.isNotEmpty && sessionBills.isNotEmpty) const SizedBox(height: 20),
        if (sessionBills.isNotEmpty)
          _card(
            key: const Key('session_billing_card'),
            title: 'Session Billing',
            child: Column(children: [for (final b in sessionBills) _billRow(context, b)]),
          ),
      ],
    );
  }

  Widget _billRow(BuildContext context, Bill bill) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.billNumber,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  DateFormat('d MMM yyyy').format(bill.created),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _money(bill.totalAmount),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: StatusBadge(
              label: bill.isPaid ? 'Paid' : 'Payment Pending',
              type: bill.isPaid ? StatusBadgeType.paid : StatusBadgeType.upcoming,
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!bill.isPaid)
                  ElevatedButton(
                    key: Key('patient_paid_${bill.id}'),
                    onPressed: () => _collectPayment(context, bill),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      elevation: 0,
                      textStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Patient Paid'),
                  ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: () => BillPreviewDialog.show(context, clinic, bill),
                  style: _smallButtonStyle,
                  child: const Text('View Bill'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Generate Bill is not a payment — it only produces the bill. Settling
  /// it is the separate "Patient Paid" action.
  Widget _billActions(BuildContext context, Bill? bill, {required Future<void> Function() onGenerate}) {
    if (bill == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: ElevatedButton.icon(
          key: const Key('generate_bill_button'),
          onPressed: () => _generate(context, onGenerate),
          icon: const Icon(Icons.receipt_long_outlined, size: 16),
          label: const Text('Generate Bill'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            elevation: 0,
            textStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
    return _billRow(context, bill);
  }

  Future<void> _generate(BuildContext context, Future<void> Function() onGenerate) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await onGenerate();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not generate the bill. Please try again.')),
      );
    }
  }

  Future<void> _collectPayment(BuildContext context, Bill bill) async {
    await CollectPaymentDialog.show(context, clinic, bill);
  }

  Future<void> _markArrived(BuildContext context, String sessionId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await clinic.markArrived(sessionId);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not record the arrival. Please try again.')),
      );
    }
  }

  // ----------------------------------------------------------------- history

  Widget _historyTab(PatientProfile profile) {
    final events = <(DateTime at, String what)>[
      (profile.patient.created, 'Registered as #${profile.patient.patientCode}'),
      for (final c in profile.consultations)
        if (c.isCompleted)
          (
            c.completedAt ?? c.created,
            'Consultation by ${c.doctorName ?? 'a doctor'} — ${c.recommendation?.label ?? 'recorded'}'
          ),
      for (final s in profile.sessions)
        if (s.status == SessionStatus.completed)
          (s.endedAt ?? s.scheduledDate, 'Session completed by ${s.doctorName ?? 'a doctor'}')
        else if (s.status == SessionStatus.noShow)
          (s.scheduledDate, 'Missed a scheduled session')
        else
          (s.scheduledDate, 'Session scheduled'),
      for (final b in profile.bills)
        if (b.isPaid && b.paidAt != null) (b.paidAt!, 'Paid ${b.billNumber} — ${_money(b.totalAmount)}'),
    ]..sort((a, b) => b.$1.compareTo(a.$1));

    return _card(
      title: 'History',
      child: Column(
        children: [
          for (final (at, what) in events)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      DateFormat('d MMM yyyy').format(at),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: const Color(0xFF9CA3AF)),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      what,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, color: const Color(0xFF374151)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- shared

  Widget _card({Key? key, required String title, required Widget child, Widget? trailing}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
                title,
                style: AppTypography.headingSmall
                    .copyWith(fontSize: 15.5, fontWeight: FontWeight.w700),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textMuted),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _money(double amount) =>
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount);

extension _FirstWhereOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

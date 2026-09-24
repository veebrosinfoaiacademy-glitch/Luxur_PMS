import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/state/app_view_model.dart';
import '../../../core/state/clinic_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// The Doctor's day: who is waiting to be seen, and which treatment
/// sessions are booked. It reads the same clinic data the Admin dashboard
/// does — the Doctor simply works from the two clinical queues.
class DoctorDashboardView extends StatefulWidget {
  final AppViewModel viewModel;
  final ClinicViewModel clinic;

  const DoctorDashboardView({
    super.key,
    required this.viewModel,
    required this.clinic,
  });

  @override
  State<DoctorDashboardView> createState() => _DoctorDashboardViewState();
}

class _DoctorDashboardViewState extends State<DoctorDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.clinic.refreshDashboard());
  }

  static String _greetingFor(DateTime now) {
    if (now.hour < 12) return 'Good Morning';
    if (now.hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _open(String patientId) {
    widget.clinic.openPatient(patientId);
    widget.viewModel.navigateTo(AppNavSection.patientDetail);
  }

  @override
  Widget build(BuildContext context) {
    final clinic = widget.clinic;
    final now = DateTime.now();

    return ListenableBuilder(
      listenable: clinic,
      builder: (context, _) => RefreshIndicator(
        onRefresh: clinic.refreshDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_greetingFor(now)}, ${clinic.displayName}',
                        key: const Key('doctor_dashboard_greeting'),
                        style: AppTypography.headingDisplay,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Here are the patients waiting for you today.',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('EEE, d MMM yyyy').format(now),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              _queueCard(
                key: const Key('doctors_today_patients'),
                icon: Icons.person_outline_rounded,
                title: "Today's Patients",
                entries: clinic.awaitingConsultation,
                emptyMessage: 'No one is waiting for a consultation right now.',
                loading: clinic.isLoading,
              ),
              const SizedBox(height: 24),
              _queueCard(
                key: const Key('doctors_today_sessions'),
                icon: Icons.event_available_outlined,
                title: "Today's Sessions",
                entries: clinic.awaitingSession,
                emptyMessage: 'No treatment sessions are booked for today.',
                loading: clinic.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _queueCard({
    required Key key,
    required IconData icon,
    required String title,
    required List<ScheduleEntry> entries,
    required String emptyMessage,
    required bool loading,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTypography.headingSmall
                    .copyWith(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  entries.length == 1 ? '1 Patient' : '${entries.length} Patients',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (loading && entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  emptyMessage,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          else
            ...entries.map(_row),
        ],
      ),
    );
  }

  Widget _row(ScheduleEntry entry) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.avatarPurpleBg,
            child: Text(
              entry.patient.initials,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.patient.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if (entry.patient.patientCode.isNotEmpty)
                  Text(
                    '#${entry.patient.patientCode}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  // Green means "this patient is ready for you".
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  entry.statusLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _open(entry.patient.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: Text(
              entry.isConsultation ? 'Start Consultation' : 'Open Session',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

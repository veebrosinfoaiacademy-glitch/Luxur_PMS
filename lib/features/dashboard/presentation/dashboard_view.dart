import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_view_model.dart';
import '../../../core/state/clinic_view_model.dart';
import '../../patients/presentation/add_patient_dialog.dart';
import '../../sessions/models/session.dart';

/// The Admin dashboard. Everything on it is live clinic data; the visual
/// template (metric cards, search row, table card) is unchanged.
class DashboardView extends StatefulWidget {
  final AppViewModel viewModel;
  final ClinicViewModel clinic;

  const DashboardView({super.key, required this.viewModel, required this.clinic});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.clinic.refreshDashboard();
    });
  }

  static String _greetingFor(DateTime now) {
    if (now.hour < 12) return 'Good Morning';
    if (now.hour < 17) return 'Good Afternoon';
    return 'Good Evening';
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
              // 1. Header Greeting & Quote Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_greetingFor(now)}, ${clinic.displayName}',
                        key: const Key('admin_dashboard_greeting'),
                        style: AppTypography.headingDisplay,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Here's what's happening at your clinic today.",
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Quote & Date Box
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                          ),
                        ),
                        child: Text(
                          '“Healthy skin is a reflection\nof overall wellness.”',
                          style: AppTypography.quote,
                        ),
                      ),
                      const SizedBox(width: 24),
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
                ],
              ),
              const SizedBox(height: 28),

              // 2. Metrics Row (4 Cards)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildMetricCard(
                      icon: Icons.people_alt_outlined,
                      iconBg: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF16A34A),
                      label: 'Total Patients',
                      value: '${clinic.totalPatients}',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: _buildMetricCard(
                      icon: Icons.check_circle_outline_rounded,
                      iconBg: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF16A34A),
                      label: 'Joined Patients',
                      value: '${clinic.joinedPatients}',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: _buildMetricCard(
                      icon: Icons.person_outline_rounded,
                      iconBg: const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFDC2626),
                      label: 'Not Joined Patients',
                      value: '${clinic.notJoinedPatients}',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _buildMonthSelectorCard(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Search Bar + "+ Add New Patient" Button Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              onChanged: widget.viewModel.setSearchQuery,
                              onSubmitted: (_) =>
                                  widget.viewModel.navigateTo(AppNavSection.patients),
                              decoration: InputDecoration(
                                hintText: 'Search by patient ID or phone number...',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    key: const Key('dashboard_add_patient_button'),
                    onPressed: () => AddPatientDialog.show(context, widget.viewModel, clinic),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add New Patient'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Today's Schedule
              _buildScheduleCard(context, clinic),

              // 5. Missed appointments — only when there are any.
              if (clinic.noShows.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildNoShowCard(context, clinic),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(value, style: AppTypography.metricValue),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _buildMonthSelectorCard() {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 16, color: Color(0xFF4B5563)),
                  const SizedBox(width: 6),
                  Text(
                    'Patient Overview by Month',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.chevron_left, size: 18, color: Color(0xFF6B7280)),
                  Text(
                    '${widget.viewModel.selectedYear}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: Color(0xFF6B7280)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: months.sublist(0, 6).map(_buildMonthPill).toList(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: months.sublist(6, 12).map(_buildMonthPill).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthPill(String month) {
    final isSelected = widget.viewModel.selectedMonth == month;
    return GestureDetector(
      onTap: () => widget.viewModel.selectMonth(month),
      child: Container(
        width: 38,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            month,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF4B5563),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- the schedule

  Widget _buildScheduleCard(BuildContext context, ClinicViewModel clinic) {
    final consultation = clinic.awaitingConsultation;
    final session = clinic.awaitingSession;
    final completed = clinic.completedToday;
    final total = consultation.length + session.length + completed.length;

    return Container(
      key: const Key('todays_schedule'),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    "Today's Schedule",
                    style: AppTypography.headingSmall.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      total == 1 ? '1 Patient' : '$total Patients',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => widget.viewModel.navigateTo(AppNavSection.patients),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (clinic.isLoading && total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (total == 0)
            _emptyState('Nothing scheduled yet today.')
          else ...[
            if (consultation.isNotEmpty)
              _scheduleGroup(context, 'Consultation', consultation,
                  key: const Key('schedule_group_consultation')),
            if (session.isNotEmpty)
              _scheduleGroup(context, 'Waiting for Session', session,
                  key: const Key('schedule_group_session')),
            if (completed.isNotEmpty)
              _scheduleGroup(context, 'Completed', completed,
                  key: const Key('schedule_group_completed')),
          ],
        ],
      ),
    );
  }

  Widget _scheduleGroup(BuildContext context, String title, List<ScheduleEntry> entries,
      {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title (${entries.length})',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          ...entries.map((e) => _scheduleRow(context, e)),
        ],
      ),
    );
  }

  Widget _scheduleRow(BuildContext context, ScheduleEntry entry) {
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
            flex: 2,
            child: Text(
              entry.session?.doctorName ?? '—',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF374151),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _statusPill(entry.statusLabel, done: entry.isDone),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Front desk marks arrival for a scheduled session; the
                // time is stamped by the server, not this device.
                if (entry.session?.status == SessionStatus.scheduled)
                  OutlinedButton(
                    onPressed: () => _markArrived(context, entry.session!.id),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(
                      'Patient Arrived',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: () => _openPatient(entry.patient.id),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    minimumSize: const Size(60, 32),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(
                    'View',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- no-shows

  Widget _buildNoShowCard(BuildContext context, ClinicViewModel clinic) {
    return Container(
      key: const Key('no_show_section'),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, size: 20, color: Color(0xFFDC2626)),
              const SizedBox(width: 10),
              Text(
                'Missed Appointments',
                style: AppTypography.headingSmall.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF991B1B),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${clinic.noShows.length} No-Show',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB91C1C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...clinic.noShows.map((session) => _noShowRow(context, session)),
        ],
      ),
    );
  }

  Widget _noShowRow(BuildContext context, Session session) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFFECACA))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.patientName ?? 'Patient',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7F1D1D),
                  ),
                ),
                Text(
                  session.patientPhone ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF9F1239),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Missed ${DateFormat('d MMM yyyy').format(session.scheduledDate)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF991B1B),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _call(context, session.patientPhone),
            icon: const Icon(Icons.phone, size: 15),
            label: const Text('Call'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- helpers

  Widget _statusPill(String label, {required bool done}) {
    // Waiting patients are green — the clinic reads green as "ready for
    // you", not as "finished".
    final color = done ? const Color(0xFF6B7280) : const Color(0xFF15803D);
    final background = done ? const Color(0xFFF3F4F6) : const Color(0xFFDCFCE7);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  void _openPatient(String patientId) {
    widget.clinic.openPatient(patientId);
    widget.viewModel.navigateTo(AppNavSection.patientDetail);
  }

  Future<void> _markArrived(BuildContext context, String sessionId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.clinic.markArrived(sessionId);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not record the arrival. Please try again.')),
      );
    }
  }

  Future<void> _call(BuildContext context, String? phone) async {
    final messenger = ScaffoldMessenger.of(context);
    if (phone == null || phone.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No phone number on file for this patient.')),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      messenger.showSnackBar(SnackBar(content: Text('Could not start a call to $phone.')));
    }
  }
}

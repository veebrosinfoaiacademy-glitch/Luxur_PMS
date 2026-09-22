import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_view_model.dart';
import '../../patients/presentation/add_patient_dialog.dart';

class DashboardView extends StatelessWidget {
  final AppViewModel viewModel;

  const DashboardView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                    'Good Morning, Admin',
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
                    'Tue, 15 Apr 2025',
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
              // Metric 1: Total Patients
              Expanded(
                flex: 3,
                child: _buildMetricCard(
                  icon: Icons.people_alt_outlined,
                  iconBg: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF16A34A),
                  label: 'Total Patients',
                  value: '432',
                  trendText: '↑ 12%',
                  trendColor: const Color(0xFF16A34A),
                  subtext: 'vs. last month',
                ),
              ),
              const SizedBox(width: 16),

              // Metric 2: Joined Patients
              Expanded(
                flex: 3,
                child: _buildMetricCard(
                  icon: Icons.check_circle_outline_rounded,
                  iconBg: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF16A34A),
                  label: 'Joined Patients',
                  value: '298',
                  trendText: '↑ 8%',
                  trendColor: const Color(0xFF16A34A),
                  subtext: 'vs. last month',
                ),
              ),
              const SizedBox(width: 16),

              // Metric 3: Not Joined Patients
              Expanded(
                flex: 3,
                child: _buildMetricCard(
                  icon: Icons.person_outline_rounded,
                  iconBg: const Color(0xFFFEE2E2),
                  iconColor: const Color(0xFFDC2626),
                  label: 'Not Joined Patients',
                  value: '134',
                  trendText: '↑ 4%',
                  trendColor: const Color(0xFFDC2626),
                  subtext: 'vs. last month',
                ),
              ),
              const SizedBox(width: 16),

              // Metric 4: Patient Overview by Month
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
                          onChanged: viewModel.setSearchQuery,
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
                onPressed: () => AddPatientDialog.show(context, viewModel),
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

          // 4. "Today's Follow Ups" Table Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Today's Follow Ups",
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
                            '12 Patients',
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
                      onPressed: () => viewModel.navigateTo(AppNavSection.patients),
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

                // Table
                _buildFollowUpsTable(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required String trendText,
    required Color trendColor,
    required String subtext,
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
            child: Text(
              value,
              style: AppTypography.metricValue,
            ),
          ),
          Row(
            children: [
              Text(
                trendText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: trendColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                subtext,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
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
                    '${viewModel.selectedYear}',
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
          // Months 2 rows
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: months.sublist(0, 6).map((m) => _buildMonthPill(m)).toList(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: months.sublist(6, 12).map((m) => _buildMonthPill(m)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthPill(String month) {
    final isSelected = viewModel.selectedMonth == month;
    return GestureDetector(
      onTap: () => viewModel.selectMonth(month),
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

  Widget _buildFollowUpsTable(BuildContext context) {
    final patients = viewModel.patients;

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.6),
        1: FlexColumnWidth(2.0),
        2: FlexColumnWidth(2.0),
        3: FlexColumnWidth(2.2),
        4: FlexColumnWidth(1.4),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // Header Row
        TableRow(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.borderLight, width: 1),
            ),
          ),
          children: [
            _tableHeaderCell('Patient Name'),
            _tableHeaderCell('Phone Number'),
            _tableHeaderCell('Doctor Assigned'),
            _tableHeaderCell('Treatment'),
            _tableHeaderCell('Action'),
          ],
        ),
        // Data Rows
        ...patients.map((p) {
          return TableRow(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
              ),
            ),
            children: [
              // Patient Name & Initials & ID
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: p.avatarColor,
                      child: Text(
                        p.initials,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          p.patientId,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Phone
              Text(
                p.phone,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF374151)),
              ),
              // Doctor
              Text(
                p.assignedDoctor,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF374151)),
              ),
              // Treatment
              Text(
                p.treatment,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF374151)),
              ),
              // Action Buttons
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => viewModel.selectPatient(p),
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
                  const SizedBox(width: 6),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF9CA3AF)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'view', child: Text('Open Full Profile')),
                      const PopupMenuItem(value: 'schedule', child: Text('Schedule Next Session')),
                      const PopupMenuItem(value: 'call', child: Text('Call Patient')),
                    ],
                    onSelected: (val) {
                      if (val == 'view') {
                        viewModel.selectPatient(p);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Action: $val for ${p.name}')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _tableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }
}

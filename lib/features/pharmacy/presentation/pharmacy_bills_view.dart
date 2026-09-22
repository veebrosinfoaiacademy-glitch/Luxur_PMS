import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_view_model.dart';
import '../../../shared/widgets/status_badge.dart';
import 'add_pharmacy_bill_dialog.dart';

class PharmacyBillsView extends StatefulWidget {
  final AppViewModel viewModel;

  const PharmacyBillsView({super.key, required this.viewModel});

  @override
  State<PharmacyBillsView> createState() => _PharmacyBillsViewState();
}

class _PharmacyBillsViewState extends State<PharmacyBillsView> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final bills = widget.viewModel.pharmacyBills.where((b) {
      if (_filter.isEmpty) return true;
      return b.name.toLowerCase().contains(_filter.toLowerCase());
    }).toList();

    final reminders = widget.viewModel.activeReminders;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Page Header: Title, Subtitle, and "+ Add Pharmacy Bill"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pharmacy Bills',
                    style: AppTypography.headingDisplay,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage pharmacy invoices and track payments.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => AddPharmacyBillDialog.show(context, widget.viewModel),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Pharmacy Bill'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 2. Main Two-Column Layout (Left: All Pharmacy Bills Table, Right: Bill Reminders)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Section: All Pharmacy Bills Table
              Expanded(
                flex: 7,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with count badge & search input
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'All Pharmacy Bills',
                                style: AppTypography.headingSmall.copyWith(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${bills.length} Bills',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Search pharma name
                          SizedBox(
                            width: 220,
                            height: 38,
                            child: TextField(
                              onChanged: (val) => setState(() => _filter = val),
                              decoration: InputDecoration(
                                hintText: 'Search pharma name...',
                                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF9CA3AF)),
                                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                isDense: true,
                              ),
                              style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Table
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(0.6),
                          1: FlexColumnWidth(2.6),
                          2: FlexColumnWidth(2.0),
                          3: FlexColumnWidth(2.2),
                          4: FlexColumnWidth(1.6),
                          5: FlexColumnWidth(0.8),
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                            ),
                            children: [
                              _tableHeader('#'),
                              _tableHeader('Pharma Name'),
                              _tableHeader('Payment Amount'),
                              _tableHeader('Payment Last Date'),
                              _tableHeader('Status'),
                              _tableHeader('Action'),
                            ],
                          ),
                          ...bills.map((b) => TableRow(
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    child: Text(
                                      '${b.id}',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF6B7280)),
                                    ),
                                  ),
                                  Text(
                                    b.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    '₹${b.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: const Color(0xFF374151),
                                    ),
                                  ),
                                  Text(
                                    b.lastDate,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: const Color(0xFF374151),
                                    ),
                                  ),
                                  StatusBadge.fromStatusString(b.status),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF9CA3AF)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'view', child: Text('View Details')),
                                      const PopupMenuItem(value: 'settle', child: Text('Mark as Settled')),
                                      const PopupMenuItem(value: 'download', child: Text('Download Bill File')),
                                    ],
                                    onSelected: (val) {
                                      if (val == 'settle') {
                                        widget.viewModel.markReminderAsPaid(b.name);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Action: $val on ${b.name}')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Right Section: Bill Reminders Card
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.alarm_on_rounded, size: 20, color: Color(0xFFDC2626)),
                              const SizedBox(width: 8),
                              Text(
                                'Bill Reminders',
                                style: AppTypography.headingSmall.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${reminders.length} Reminders',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Reminders list
                      if (reminders.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'All bill reminders settled!',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textMuted),
                            ),
                          ),
                        )
                      else
                        ...reminders.map((r) => _buildReminderCard(r)),

                      const SizedBox(height: 14),
                      // View All Reminders link
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Showing all reminder logs.')),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF6B7280)),
                                const SizedBox(width: 8),
                                Text(
                                  'View All Reminders',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF6B7280)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(BillReminderItem r) {
    Color remainingColor;
    if (r.daysRemaining <= 5) {
      remainingColor = const Color(0xFFDC2626); // Red
    } else if (r.daysRemaining <= 25) {
      remainingColor = const Color(0xFFD97706); // Orange
    } else {
      remainingColor = const Color(0xFF16A34A); // Green
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFECEFE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                r.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              StatusBadge.fromStatusString(r.badge),
            ],
          ),
          const SizedBox(height: 4),

          // Days remaining with color urgency scale
          Text(
            '${r.daysRemaining} days remaining',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: remainingColor,
            ),
          ),
          const SizedBox(height: 2),

          // Due date and amount
          Text(
            'Due on ${r.dueDate}  |  ₹${r.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons: Mark as Paid & Close Reminder
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.viewModel.markReminderAsPaid(r.name);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${r.name} marked as Paid & settled.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(
                    'Mark as Paid',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.viewModel.closeReminder(r.name);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Reminder for ${r.name} closed.')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(
                    'Close Reminder',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
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

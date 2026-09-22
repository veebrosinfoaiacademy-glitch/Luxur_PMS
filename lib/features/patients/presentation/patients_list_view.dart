import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_view_model.dart';
import '../../../shared/widgets/status_badge.dart';
import 'add_patient_dialog.dart';

class PatientsListView extends StatefulWidget {
  final AppViewModel viewModel;

  const PatientsListView({super.key, required this.viewModel});

  @override
  State<PatientsListView> createState() => _PatientsListViewState();
}

class _PatientsListViewState extends State<PatientsListView> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Hair',
    'Skin',
    'Laser',
    'Body Aesthetics',
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = widget.viewModel.patients.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.patientId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.phone.contains(_searchQuery);

      final matchesCategory = _selectedCategory == 'All' ||
          p.concerns.any((c) => c.toLowerCase() == _selectedCategory.toLowerCase());

      return matchesSearch && matchesCategory;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patients',
                    style: AppTypography.headingDisplay,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage patient registrations, medical concerns, and treatment programs.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => AddPatientDialog.show(context, widget.viewModel),
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
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

          // Filters & Search Row
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Search Input
                Expanded(
                  flex: 4,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAF8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8E0)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: 'Search by patient name, ID (#PT-XXXX), or mobile...',
                              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF9CA3AF)),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: GoogleFonts.plusJakartaSans(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),

                // Category Filter Pills
                Expanded(
                  flex: 6,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF4B5563),
                          ),
                          selectedColor: AppColors.primary,
                          backgroundColor: const Color(0xFFF3F4F6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          side: BorderSide(color: isSelected ? AppColors.primary : Colors.transparent),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Patients Table
          Container(
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
                    Text(
                      'All Patients (${filtered.length})',
                      style: AppTypography.headingSmall.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Showing active clinic records',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2.6),
                    1: FlexColumnWidth(1.4),
                    2: FlexColumnWidth(1.8),
                    3: FlexColumnWidth(1.8),
                    4: FlexColumnWidth(1.8),
                    5: FlexColumnWidth(1.6),
                    6: FlexColumnWidth(1.2),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                      ),
                      children: [
                        _tableHeader('Patient Name & ID'),
                        _tableHeader('Age / Gender'),
                        _tableHeader('Mobile Number'),
                        _tableHeader('Primary Concern'),
                        _tableHeader('Assigned Doctor'),
                        _tableHeader('Status'),
                        _tableHeader('Action'),
                      ],
                    ),
                    ...filtered.map((p) => TableRow(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                          ),
                          children: [
                            // Patient Info Cell
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: InkWell(
                                onTap: () => widget.viewModel.selectPatient(p),
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
                                          color: const Color(0xFF1E4D3B),
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
                                            color: AppColors.primary,
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
                            ),
                            // Age/Gender
                            Text(
                              '${p.age} yrs • ${p.gender}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF374151)),
                            ),
                            // Phone
                            Text(
                              p.phone,
                              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF374151)),
                            ),
                            // Concerns
                            Wrap(
                              spacing: 4,
                              children: p.concerns.map((c) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    c,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            // Doctor
                            Text(
                              p.assignedDoctor,
                              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF374151)),
                            ),
                            // Status
                            const StatusBadge(label: 'Active', type: StatusBadgeType.activeTreatment),
                            // Action
                            ElevatedButton(
                              onPressed: () => widget.viewModel.selectPatient(p),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                minimumSize: const Size(60, 32),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: Text(
                                'View',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )),
                  ],
                ),
              ],
            ),
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

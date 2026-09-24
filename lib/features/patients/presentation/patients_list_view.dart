import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_view_model.dart';
import '../../../core/state/clinic_view_model.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/patient.dart';
import 'add_patient_dialog.dart';

class PatientsListView extends StatefulWidget {
  final AppViewModel viewModel;
  final ClinicViewModel clinic;

  const PatientsListView({super.key, required this.viewModel, required this.clinic});

  @override
  State<PatientsListView> createState() => _PatientsListViewState();
}

class _PatientsListViewState extends State<PatientsListView> {
  String _selectedCategory = 'All';
  late String _searchQuery = widget.viewModel.searchQuery;

  final List<String> _categories = [
    'All',
    'Hair',
    'Skin',
    'Laser',
    'Body Aesthetics',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.clinic.loadPatients());
  }

  List<Patient> _filter(List<Patient> patients) {
    final query = _searchQuery.trim().toLowerCase();
    return patients.where((p) {
      final matchesSearch = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.patientCode.toLowerCase().contains(query) ||
          p.phone.contains(query);

      final matchesCategory = _selectedCategory == 'All' ||
          p.concern.toLowerCase().contains(_selectedCategory.toLowerCase());

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _open(Patient patient) {
    widget.clinic.openPatient(patient.id);
    widget.viewModel.navigateTo(AppNavSection.patientDetail);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.clinic,
      builder: (context, _) {
        final filtered = _filter(widget.clinic.allPatients);

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
                      Text('Patients', style: AppTypography.headingDisplay),
                      const SizedBox(height: 4),
                      Text(
                        'Manage patient registrations, medical concerns, and treatment programs.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        AddPatientDialog.show(context, widget.viewModel, widget.clinic),
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
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.sidebarBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: TextEditingController(text: _searchQuery)
                                  ..selection = TextSelection.collapsed(offset: _searchQuery.length),
                                onChanged: (val) => setState(() => _searchQuery = val),
                                decoration: InputDecoration(
                                  hintText: 'Search by patient name, ID (PT-XXXX), or mobile...',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5, color: const Color(0xFF9CA3AF)),
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
                              shape:
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              side: BorderSide(
                                  color: isSelected ? AppColors.primary : Colors.transparent),
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
                          style: AppTypography.headingSmall
                              .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Showing active clinic records',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, color: const Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (widget.clinic.isPatientsLoading && filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No patients match this search.',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, color: AppColors.textMuted),
                          ),
                        ),
                      )
                    else
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
                              // No Assigned Doctor column: a patient is
                              // never tied to one doctor.
                              _tableHeader('Source'),
                              _tableHeader('Status'),
                              _tableHeader('Action'),
                            ],
                          ),
                          ...filtered.map((p) => TableRow(
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: InkWell(
                                      onTap: () => _open(p),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: AppColors.avatarPurpleBg,
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
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  p.name,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                                Text(
                                                  '#${p.patientCode}',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 11,
                                                    color: const Color(0xFF6B7280),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Text(
                                    p.age == null ? p.gender : '${p.age} yrs • ${p.gender}',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5, color: const Color(0xFF374151)),
                                  ),
                                  Text(
                                    PhoneUtils.display(p.phone),
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5, color: const Color(0xFF374151)),
                                  ),
                                  Text(
                                    p.concern.isEmpty ? '—' : p.concern,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5, color: const Color(0xFF374151)),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.source.isEmpty ? '—' : p.source,
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12.5, color: const Color(0xFF374151)),
                                      ),
                                      Text(
                                        DateFormat('d MMM yyyy').format(p.created),
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11, color: const Color(0xFF9CA3AF)),
                                      ),
                                    ],
                                  ),
                                  StatusBadge(
                                    label: p.status.isEmpty ? 'Joined' : p.status,
                                    type: p.status == 'Not Joined'
                                        ? StatusBadgeType.upcoming
                                        : StatusBadgeType.activeTreatment,
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _open(p),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      minimumSize: const Size(60, 32),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6)),
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
      },
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

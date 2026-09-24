import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/telecaller_lead.dart';
import '../state/telecaller_view_model.dart';
import '../utils/lead_search.dart';
import '../widgets/telecaller_profile_menu.dart';
import 'add_lead_view.dart';

final _dateFormat = DateFormat('d/M/yyyy, hh:mm a');
final _expectedArrivalDateFormat = DateFormat('d/M/yyyy');

enum _PatientFilter { all, pending, converted }

class LeadListView extends StatefulWidget {
  final TelecallerViewModel viewModel;
  final String initialQuery;
  final VoidCallback? onAddLead;
  final AuthService? authService;

  const LeadListView({
    super.key,
    required this.viewModel,
    this.initialQuery = '',
    this.onAddLead,
    this.authService,
  });

  @override
  State<LeadListView> createState() => _LeadListViewState();
}

class _LeadListViewState extends State<LeadListView> {
  late String _query = widget.initialQuery;
  late final _searchController = TextEditingController(text: widget.initialQuery);
  _PatientFilter _filter = _PatientFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String _toTitleCase(String text) {
    if (text.trim().isEmpty) return text;
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.length > 1 ? word.substring(1).toLowerCase() : ''}')
        .join(' ');
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'P';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static Color _getAvatarBg(String name) {
    const colors = [
      Color(0xFFEDE9FE), // Lavender
      Color(0xFFE0F2FE), // Sky
      Color(0xFFDCFCE7), // Mint
      Color(0xFFFEF3C7), // Amber
      Color(0xFFFCE7F3), // Rose
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  static Color _getAvatarFg(String name) {
    const colors = [
      Color(0xFF5E35B1),
      Color(0xFF0284C7),
      Color(0xFF16A34A),
      Color(0xFFD97706),
      Color(0xFFDB2777),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  void _showLeadDetails(TelecallerLead lead) {
    showDialog(
      context: context,
      builder: (_) => _LeadDetailsDialog(lead: lead),
    );
  }

  void _openEditDialog(TelecallerLead lead) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Material(
              color: Colors.transparent,
              child: AddLeadView(
                viewModel: widget.viewModel,
                isDialog: true,
                existingLead: lead,
                onClose: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patients', style: AppTypography.headingDisplay),
                    const SizedBox(height: 4),
                    Text(
                      'Converted leads and patient registrations.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onAddLead != null) ...[
                ElevatedButton.icon(
                  key: const Key('lead_list_add_button'),
                  onPressed: widget.onAddLead,
                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                  label: const Text('Add Patient'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              IconButton(
                key: const Key('lead_list_refresh_button'),
                onPressed: widget.viewModel.loadLeads,
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                tooltip: 'Refresh',
              ),
              if (widget.authService != null) ...[
                const SizedBox(width: 14),
                TelecallerProfileMenu(authService: widget.authService!),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Main Table Area with Integrated Search Header
          ListenableBuilder(
            listenable: widget.viewModel,
            builder: (context, _) => _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (widget.viewModel.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.viewModel.loadError != null) {
      return Padding(
        key: const Key('lead_list_error_state'),
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.statusUrgent,
                size: 32,
              ),
              const SizedBox(height: 10),
              Text(
                widget.viewModel.loadError!,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: widget.viewModel.loadLeads,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final allLeads = widget.viewModel.leads;
    final byStatus = switch (_filter) {
      _PatientFilter.all => allLeads,
      _PatientFilter.pending => allLeads.where((l) => !l.converted).toList(),
      _PatientFilter.converted => allLeads.where((l) => l.converted).toList(),
    };
    final filtered = filterLeads(byStatus, _query);

    return Container(
      key: const Key('lead_list_table'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Integrated Card Header with Filter Tabs & Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                // Left: Title, Total Count & Filter Chips
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.people_alt_rounded,
                        color: AppColors.primary,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'All Patients',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${filtered.length}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Quick Status Filter
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _filterButton('All', _PatientFilter.all),
                          _filterButton('Pending', _PatientFilter.pending),
                          _filterButton('Converted', _PatientFilter.converted),
                        ],
                      ),
                    ),
                  ],
                ),

                // Right: Integrated Search Box
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: TextField(
                      key: const Key('lead_search_field'),
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      textAlignVertical: TextAlignVertical.center,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Search by name or phone...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 15,
                                  color: Color(0xFF94A3B8),
                                ),
                                splashRadius: 14,
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Table Content or Empty State
          if (allLeads.isEmpty)
            _emptyState(
              key: const Key('lead_list_empty_state'),
              message: 'No leads yet. Add one manually or import a spreadsheet.',
            )
          else if (filtered.isEmpty)
            _emptyState(
              key: const Key('lead_list_no_results'),
              message: 'No leads match your search.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth < 1040 ? 1040.0 : constraints.maxWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(0.35),
                        1: FlexColumnWidth(2.0),
                        2: FlexColumnWidth(1.5),
                        3: FlexColumnWidth(1.3),
                        4: FlexColumnWidth(1.7),
                        5: FlexColumnWidth(1.7),
                        6: FlexColumnWidth(1.4),
                        7: FlexColumnWidth(0.8),
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        // Table Header with #F8FAFC tint
                        TableRow(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            border: Border(
                              top: BorderSide(color: Color(0xFFE2E8F0)),
                              bottom: BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          children: [
                            _header('#'),
                            _header('NAME'),
                            _header('PHONE NUMBER'),
                            _header('EXPECTED ARRIVAL'),
                            _header('CONCERN'),
                            _header('REGISTERED ON'),
                            _header('STATUS'),
                            _header('ACTION'),
                          ],
                        ),
                        for (var i = 0; i < filtered.length; i++)
                          _leadRow(i + 1, filtered[i]),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _filterButton(String label, _PatientFilter filter) {
    final isSelected = _filter == filter;
    return InkWell(
      onTap: () => setState(() => _filter = filter),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.primary : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  TableRow _leadRow(int index, TelecallerLead lead) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      children: [
        // Index
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(
            '$index',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280)),
          ),
        ),

        // Patient Name with Initials Avatar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _showLeadDetails(lead),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _getAvatarBg(lead.name),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(lead.name),
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _getAvatarFg(lead.name),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Text(
                      _toTitleCase(lead.name),
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Phone Number
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(
            PhoneUtils.display(lead.phone),
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF374151),
            ),
          ),
        ),

        // Expected Arrival
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(
            lead.expectedArrivalDate == null
                ? '—'
                : _expectedArrivalDateFormat.format(lead.expectedArrivalDate!),
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF374151),
            ),
          ),
        ),

        // Concern
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(
            lead.concern.isEmpty ? '—' : lead.concern,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF374151),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Registered On
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(
            _dateFormat.format(lead.created),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),

        // Standardized Status Badge (Consistent with Dashboard)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: lead.converted
                ? const StatusBadge(
                    label: 'Converted',
                    type: StatusBadgeType.completed,
                  )
                : const StatusBadge(
                    label: 'Pending',
                    type: StatusBadgeType.urgent,
                  ),
          ),
        ),

        // Actions Column — Follow Up lives only on the Dashboard; here a
        // patient just needs to be editable.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              key: Key('edit_lead_${lead.id}'),
              tooltip: 'Edit patient details',
              onPressed: () => _openEditDialog(lead),
              icon: const Icon(
                Icons.edit_outlined,
                size: 17,
                color: AppColors.primary,
              ),
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ),
      ],
    );
  }


  Widget _header(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _emptyState({required Key key, required String message}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 36, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LeadDetailsDialog extends StatelessWidget {
  final TelecallerLead lead;

  const _LeadDetailsDialog({required this.lead});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F3FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Patient Details', style: AppTypography.headingSmall),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 16),
            _row('Patient Name', lead.name),
            _row('Phone Number', '+91 ${lead.phone}'),
            _row('Address', lead.address.isEmpty ? '—' : lead.address),
            _row('Concern', lead.concern.isEmpty ? '—' : lead.concern),
            _row(
              'Expected Arrival',
              lead.expectedArrivalDate == null
                  ? '—'
                  : _expectedArrivalDateFormat.format(lead.expectedArrivalDate!),
            ),
            _row('Registered On', _dateFormat.format(lead.created)),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(
                  width: 110,
                  child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                lead.converted
                    ? const StatusBadge(
                        label: 'Converted',
                        type: StatusBadgeType.completed,
                      )
                    : const StatusBadge(
                        label: 'Pending',
                        type: StatusBadgeType.urgent,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

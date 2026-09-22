import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/telecaller_lead.dart';
import '../state/telecaller_view_model.dart';
import '../utils/lead_search.dart';

class LeadListView extends StatefulWidget {
  final TelecallerViewModel viewModel;
  final String initialQuery;
  final VoidCallback? onAddLead;

  const LeadListView({
    super.key,
    required this.viewModel,
    this.initialQuery = '',
    this.onAddLead,
  });

  @override
  State<LeadListView> createState() => _LeadListViewState();
}

class _LeadListViewState extends State<LeadListView> {
  late String _query = widget.initialQuery;
  late final _searchController = TextEditingController(text: widget.initialQuery);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      'Converted leads you have added. Only visible to you.',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
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
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
            ],
          ),
          const SizedBox(height: 20),

          Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
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
                    key: const Key('lead_search_field'),
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone number...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF9CA3AF)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

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
              const Icon(Icons.error_outline, color: AppColors.statusUrgent, size: 32),
              const SizedBox(height: 10),
              Text(widget.viewModel.loadError!, style: AppTypography.bodyMedium),
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

    final filtered = filterLeads(widget.viewModel.leads, _query);

    if (widget.viewModel.leads.isEmpty) {
      return _emptyState(
        key: const Key('lead_list_empty_state'),
        message: 'No leads yet. Add one manually or import a spreadsheet.',
      );
    }

    if (filtered.isEmpty) {
      return _emptyState(
        key: const Key('lead_list_no_results'),
        message: 'No leads match your search.',
      );
    }

    return Container(
      key: const Key('lead_list_table'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.4),
          1: FlexColumnWidth(1.6),
          2: FlexColumnWidth(2.2),
          3: FlexColumnWidth(2.0),
          4: FlexColumnWidth(1.4),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            children: [
              _header('Name'),
              _header('Phone'),
              _header('Concern'),
              _header('Added'),
              _header('Status'),
            ],
          ),
          ...filtered.map((lead) => _leadRow(lead)),
        ],
      ),
    );
  }

  TableRow _leadRow(TelecallerLead lead) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            lead.name,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ),
        Text(
          PhoneUtils.display(lead.phone),
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF374151)),
        ),
        Text(
          lead.concern.isEmpty ? '—' : lead.concern,
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF374151)),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${lead.created.day}/${lead.created.month}/${lead.created.year}',
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF6B7280)),
        ),
        lead.converted
            ? const StatusBadge(label: 'Converted', type: StatusBadgeType.completed)
            : const StatusBadge(label: 'Pending', type: StatusBadgeType.scheduled),
      ],
    );
  }

  Widget _header(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: AppTypography.tableHeader),
    );
  }

  Widget _emptyState({required Key key, required String message}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 32, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 10),
          Text(message, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/telecaller_lead.dart';
import '../services/excel_import_service.dart';
import '../state/telecaller_view_model.dart';
import '../utils/lead_search.dart';
import '../utils/pagination.dart';

/// Caps content width on very wide monitors so the table/cards don't
/// stretch edge-to-edge; a no-op on laptop/desktop widths below this.
const double _maxContentWidth = 1280;
const int _pageSize = 5;
final _addedDateFormat = DateFormat('d/M/yyyy, hh:mm a');

enum _FollowUpFilter { all, pending, converted }

/// "Follow-Up Required" here means leads you've added that haven't been
/// converted into a clinic patient yet — i.e. the ones worth calling back.
/// The original design framing ("patients expected today but not arrived")
/// is session/arrival data, which Telecallers don't have access to
/// (verified: telecaller_leads is the only collection a telecaller can
/// read — see pocketbase/pb_migrations and
/// telecaller_lead_repository_test.dart). This view only ever reads that
/// same lead data the rest of the Telecaller module already uses.
class TelecallerDashboardView extends StatefulWidget {
  final TelecallerViewModel viewModel;
  final VoidCallback onAddLead;
  final VoidCallback onImport;

  const TelecallerDashboardView({
    super.key,
    required this.viewModel,
    required this.onAddLead,
    required this.onImport,
  });

  @override
  State<TelecallerDashboardView> createState() =>
      _TelecallerDashboardViewState();
}

class _TelecallerDashboardViewState extends State<TelecallerDashboardView> {
  _FollowUpFilter _filter = _FollowUpFilter.all;
  String _tableSearchQuery = '';
  int _currentPage = 1;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  Future<void> _callLead(TelecallerLead lead) async {
    final uri = Uri(scheme: 'tel', path: lead.phone);
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open dialer for ${lead.phone}.')),
      );
    }
  }

  void _copyPhone(TelecallerLead lead) {
    Clipboard.setData(ClipboardData(text: '+91 ${lead.phone}'));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Phone number copied.')));
  }

  void _showLeadDetails(TelecallerLead lead) {
    showDialog(
      context: context,
      builder: (_) => _LeadDetailsDialog(lead: lead),
    );
  }

  Future<void> _downloadTemplate() async {
    try {
      final bytes = ExcelImportService().buildTemplateBytes();
      final uri = await FilePicker.saveFile(
        fileName: 'lead_import_template.xlsx',
        bytes: bytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (uri != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Template saved.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the template.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final leads = widget.viewModel.leads;
        final byStatus = switch (_filter) {
          _FollowUpFilter.all => leads,
          _FollowUpFilter.pending => leads.where((l) => !l.converted).toList(),
          _FollowUpFilter.converted => leads.where((l) => l.converted).toList(),
        };
        final filtered = filterLeads(byStatus, _tableSearchQuery);
        final page = paginate(
          filtered,
          requestedPage: _currentPage,
          pageSize: _pageSize,
        );
        final safePage = page.currentPage;
        final totalPages = page.totalPages;
        final pageStart = page.startIndex;
        final pageItems = page.items;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxxl,
                vertical: AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _greeting,
                              style: AppTypography.headingDisplay,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Manage patient enquiries and registrations.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 280),
                        padding: const EdgeInsets.only(left: AppSpacing.lg),
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: Color(0xFFE5E7EB),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Text(
                          '"Every new connection\nbrings a healthier tomorrow."',
                          style: AppTypography.quote,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _ActionCard(
                            key: const Key('action_add_lead'),
                            icon: Icons.person_add_alt_1_outlined,
                            iconBg: AppColors.primaryBgLight,
                            iconColor: AppColors.primary,
                            title: 'Add Patient',
                            subtitleLines: const [
                              'Register a new patient manually.',
                              'Capture basic details and save as a converted lead.',
                            ],
                            cornerIcon: Icons.groups_rounded,
                            cornerIconColor: AppColors.primary,
                            buttonLabel: 'Add Patient',
                            buttonIcon: Icons.add,
                            filled: true,
                            onTap: widget.onAddLead,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(
                          child: _ActionCard(
                            key: const Key('action_import'),
                            icon: Icons.description_outlined,
                            iconBg: AppColors.accentBlueBg,
                            iconColor: AppColors.accentBlue,
                            title: 'Import Patients',
                            subtitleLines: const [
                              'Bulk upload patient data from Excel or CSV file.',
                              'Use our template for best results.',
                            ],
                            cornerIcon: Icons.article_rounded,
                            cornerIconColor: AppColors.accentBlue,
                            buttonLabel: 'Import from Excel / CSV',
                            buttonIcon: Icons.upload_outlined,
                            filled: false,
                            onTap: widget.onImport,
                            topRight: TextButton.icon(
                              key: const Key('download_template_button'),
                              onPressed: _downloadTemplate,
                              icon: const Icon(
                                Icons.download_outlined,
                                size: 15,
                              ),
                              label: const Text(
                                'Download Template',
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                textStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.event_available_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Follow-Up Required',
                                    style: AppTypography.headingSmall,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Leads you\'ve added that haven\'t been converted yet — follow up to bring them in.',
                                    style: AppTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Flexible(
                              child: Wrap(
                                alignment: WrapAlignment.end,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  _FilterDropdown(
                                    value: _filter,
                                    onChanged: (v) => setState(() {
                                      _filter = v;
                                      _currentPage = 1;
                                    }),
                                  ),
                                  _TableSearchField(
                                    onChanged: (q) => setState(() {
                                      _tableSearchQuery = q;
                                      _currentPage = 1;
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (widget.viewModel.isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.xxxl,
                            ),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (filtered.isEmpty)
                          Padding(
                            key: const Key('follow_up_empty_state'),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xxxl,
                            ),
                            child: Center(
                              child: Text(
                                leads.isEmpty
                                    ? 'No leads yet. Add one manually or import a spreadsheet.'
                                    : 'Nothing to follow up on right now.',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        else ...[
                          _FollowUpTable(
                            leads: pageItems,
                            startIndex: pageStart,
                            onCall: _callLead,
                            onViewDetails: _showLeadDetails,
                            onCopyPhone: _copyPhone,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _PaginationFooter(
                            totalItems: filtered.length,
                            pageStart: pageStart,
                            pageItemCount: pageItems.length,
                            currentPage: safePage,
                            totalPages: totalPages,
                            onPageChanged: (p) =>
                                setState(() => _currentPage = p),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final _FollowUpFilter value;
  final ValueChanged<_FollowUpFilter> onChanged;

  const _FilterDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('follow_up_filter_dropdown'),
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_FollowUpFilter>(
          value: value,
          onChanged: (v) => v != null ? onChanged(v) : null,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: AppColors.textPrimary,
          ),
          items: const [
            DropdownMenuItem(
              value: _FollowUpFilter.all,
              child: Text('All Status'),
            ),
            DropdownMenuItem(
              value: _FollowUpFilter.pending,
              child: Text('Pending'),
            ),
            DropdownMenuItem(
              value: _FollowUpFilter.converted,
              child: Text('Converted'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _TableSearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('follow_up_search_field'),
      width: 200,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: Color(0xFF9CA3AF)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search leads...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: const Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowUpTable extends StatelessWidget {
  final List<TelecallerLead> leads;
  final int startIndex;
  final void Function(TelecallerLead) onCall;
  final void Function(TelecallerLead) onViewDetails;
  final void Function(TelecallerLead) onCopyPhone;

  const _FollowUpTable({
    required this.leads,
    required this.startIndex,
    required this.onCall,
    required this.onViewDetails,
    required this.onCopyPhone,
  });

  // Table gives each cell a *tight* width constraint equal to its column
  // width, so any child without its own intrinsic sizing (a badge's colored
  // background, a button's ink surface) stretches to fill it. Align resets
  // that to the child's natural size.
  static const _cellPadding = EdgeInsets.symmetric(
    vertical: AppSpacing.md,
    horizontal: AppSpacing.sm,
  );

  @override
  Widget build(BuildContext context) {
    return Table(
      key: const Key('follow_up_table'),
      columnWidths: const {
        0: FlexColumnWidth(0.4),
        1: FlexColumnWidth(2.2),
        2: FlexColumnWidth(1.7),
        3: FlexColumnWidth(1.7),
        4: FlexColumnWidth(1.1),
        5: FlexColumnWidth(1.3),
        6: FlexColumnWidth(0.4),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          children: [
            _header('#'),
            _header('Name'),
            _header('Phone Number'),
            _header('Added'),
            _header('Status'),
            _header('Action'),
            _header(''),
          ],
        ),
        for (var i = 0; i < leads.length; i++)
          _row(startIndex + i + 1, leads[i]),
      ],
    );
  }

  TableRow _row(int index, TelecallerLead lead) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      children: [
        Padding(
          padding: _cellPadding,
          child: Text(
            '$index',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        Padding(
          padding: _cellPadding,
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => onViewDetails(lead),
              child: Text(
                lead.name,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: _cellPadding,
          child: Text(
            '+91 ${lead.phone}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: const Color(0xFF374151),
            ),
          ),
        ),
        Padding(
          padding: _cellPadding,
          child: Text(
            _addedDateFormat.format(lead.created),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        Padding(
          padding: _cellPadding,
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
        Padding(
          padding: _cellPadding,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 30,
              child: lead.converted
                  ? TextButton.icon(
                      key: Key('view_details_${lead.id}'),
                      onPressed: () => onViewDetails(lead),
                      icon: const Icon(Icons.visibility_outlined, size: 14),
                      label: const Text('View Details'),
                      style: _actionButtonStyle(),
                    )
                  : TextButton.icon(
                      key: Key('follow_up_call_${lead.id}'),
                      onPressed: () => onCall(lead),
                      icon: const Icon(Icons.call_outlined, size: 14),
                      label: const Text('Follow Up'),
                      style: _actionButtonStyle(),
                    ),
            ),
          ),
        ),
        Padding(
          padding: _cellPadding,
          child: Align(
            alignment: Alignment.centerLeft,
            child: PopupMenuButton<String>(
              key: Key('lead_more_options_${lead.id}'),
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.more_vert,
                size: 18,
                color: Color(0xFF9CA3AF),
              ),
              onSelected: (value) {
                if (value == 'copy') onCopyPhone(lead);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      const Icon(Icons.copy_outlined, size: 16),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Copy phone number',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  ButtonStyle _actionButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      backgroundColor: AppColors.primaryBgLight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      textStyle: GoogleFonts.plusJakartaSans(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _header(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm)
          .copyWith(bottom: AppSpacing.md),
      child: Text(text, style: AppTypography.tableHeader),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  final int totalItems;
  final int pageStart;
  final int pageItemCount;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _PaginationFooter({
    required this.totalItems,
    required this.pageStart,
    required this.pageItemCount,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing ${pageStart + 1} to ${pageStart + pageItemCount} of $totalItems leads',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: const Color(0xFF6B7280),
          ),
        ),
        if (totalPages > 1)
          Row(
            children: [
              _pageButton(
                child: const Icon(Icons.chevron_left, size: 16),
                onTap: currentPage > 1
                    ? () => onPageChanged(currentPage - 1)
                    : null,
              ),
              const SizedBox(width: AppSpacing.xs),
              for (var page = 1; page <= totalPages; page++) ...[
                _pageButton(
                  child: Text('$page'),
                  selected: page == currentPage,
                  onTap: () => onPageChanged(page),
                ),
                if (page != totalPages) const SizedBox(width: AppSpacing.xs),
              ],
              const SizedBox(width: AppSpacing.xs),
              _pageButton(
                child: const Icon(Icons.chevron_right, size: 16),
                onTap: currentPage < totalPages
                    ? () => onPageChanged(currentPage + 1)
                    : null,
              ),
            ],
          ),
      ],
    );
  }

  Widget _pageButton({
    required Widget child,
    VoidCallback? onTap,
    bool selected = false,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: selected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            alignment: Alignment.center,
            child: DefaultTextStyle(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : (onTap == null
                          ? const Color(0xFFD1D5DB)
                          : AppColors.textPrimary),
              ),
              child: IconTheme(
                data: IconThemeData(
                  size: 16,
                  color: selected
                      ? Colors.white
                      : (onTap == null
                            ? const Color(0xFFD1D5DB)
                            : const Color(0xFF6B7280)),
                ),
                child: child,
              ),
            ),
          ),
        ),
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
        width: 420,
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lead Details', style: AppTypography.headingSmall),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _row('Name', lead.name),
            _row('Phone', '+91 ${lead.phone}'),
            _row('Address', lead.address.isEmpty ? '—' : lead.address),
            _row('Concern', lead.concern.isEmpty ? '—' : lead.concern),
            _row('Added', _addedDateFormat.format(lead.created)),
            const SizedBox(height: AppSpacing.xs),
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
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: AppTypography.labelBold),
          ),
          Expanded(child: Text(value, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final List<String> subtitleLines;
  final IconData cornerIcon;
  final Color cornerIconColor;
  final String buttonLabel;
  final IconData buttonIcon;
  final bool filled;
  final VoidCallback onTap;
  final Widget? topRight;

  const _ActionCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitleLines,
    required this.cornerIcon,
    required this.cornerIconColor,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.filled,
    required this.onTap,
    this.topRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: iconBg.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Subtle corner decoration, matching the reference — low-opacity,
          // purely decorative, never overlapping interactive content.
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              cornerIcon,
              size: 96,
              color: cornerIconColor.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(23),
                      ),
                      child: Icon(icon, color: iconColor, size: 22),
                    ),
                    const Spacer(),
                    if (topRight != null) Flexible(child: topRight!),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: AppTypography.headingSmall.copyWith(fontSize: 16),
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final line in subtitleLines)
                  Text(line, style: AppTypography.bodySmall),
                const SizedBox(height: AppSpacing.lg),
                filled
                    ? ElevatedButton.icon(
                        onPressed: onTap,
                        icon: Icon(buttonIcon, size: 17),
                        label: Text(buttonLabel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          textStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          elevation: 0,
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: onTap,
                        icon: Icon(buttonIcon, size: 17),
                        label: Text(buttonLabel),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          textStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/telecaller_lead.dart';
import '../services/excel_import_service.dart';
import '../state/telecaller_view_model.dart';
import '../utils/follow_up.dart';
import '../utils/lead_search.dart';
import '../utils/pagination.dart';
import '../widgets/telecaller_profile_menu.dart';

/// Caps content width on very wide monitors so the table/cards don't
/// stretch edge-to-edge; a no-op on laptop/desktop widths below this.
const double _maxContentWidth = 1280;
const int _pageSize = 5;
final _addedDateFormat = DateFormat('d/M/yyyy, hh:mm a');
final _expectedArrivalDateFormat = DateFormat('d/M/yyyy');

/// "Follow-Up Required" is every lead whose expected clinic arrival date has
/// passed without them converting — i.e. the ones worth calling back. Adding
/// a lead does NOT by itself put it here (see [isFollowUpDue]); it only
/// appears once its expected arrival date is in the past and it's still not
/// converted.
class TelecallerDashboardView extends StatefulWidget {
  final TelecallerViewModel viewModel;
  final VoidCallback onAddLead;
  final VoidCallback onImport;
  final AuthService? authService;

  const TelecallerDashboardView({
    super.key,
    required this.viewModel,
    required this.onAddLead,
    required this.onImport,
    this.authService,
  });

  @override
  State<TelecallerDashboardView> createState() =>
      _TelecallerDashboardViewState();
}

class _TelecallerDashboardViewState extends State<TelecallerDashboardView> {
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
        final overdue = leads.where(isFollowUpDue).toList();
        final filtered = filterLeads(overdue, _tableSearchQuery);
        final page = paginate(
          filtered,
          requestedPage: _currentPage,
          pageSize: _pageSize,
        );
        final safePage = page.currentPage;
        final totalPages = page.totalPages;
        final pageStart = page.startIndex;
        final pageItems = page.items;

        // topCenter, not Center: Center also centres vertically, which made
        // the page float down when the Follow-Up table had few rows and rise
        // as it grew.
        return Align(
          alignment: Alignment.topCenter,
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final showQuote = constraints.maxWidth >= 650;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _greeting,
                                  key: const Key('dashboard_greeting'),
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
                          if (showQuote)
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
                          if (widget.authService != null)
                            Padding(
                              padding: const EdgeInsets.only(left: AppSpacing.lg),
                              child: TelecallerProfileMenu(
                                authService: widget.authService!,
                              ),
                            ),
                        ],
                      );
                    },
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
                                textStyle: GoogleFonts.inter(
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
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 680;
                            final titleWidget = Row(
                              children: [
                                const Icon(
                                  Icons.event_available_outlined,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Follow-Up Required',
                                        style: AppTypography.headingSmall
                                            .copyWith(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Leads whose expected arrival date has passed without converting — follow up to bring them in.',
                                        style: AppTypography.bodySmall
                                            .copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );

                            final controlsWidget = Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _TableSearchField(
                                  onChanged: (q) => setState(() {
                                    _tableSearchQuery = q;
                                    _currentPage = 1;
                                  }),
                                ),
                              ],
                            );

                            if (isCompact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  titleWidget,
                                  const SizedBox(height: AppSpacing.md),
                                  controlsWidget,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: titleWidget),
                                const SizedBox(width: AppSpacing.md),
                                controlsWidget,
                              ],
                            );
                          },
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

class _TableSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _TableSearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('follow_up_search_field'),
      width: 190,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.search_rounded, size: 16, color: Color(0xFF9CA3AF)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search leads...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textPrimary,
              ),
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

  // Table gives each cell a tight width constraint equal to its column width.
  static const _cellPadding = EdgeInsets.symmetric(
    vertical: AppSpacing.md,
    horizontal: AppSpacing.sm,
  );

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

  @override
  Widget build(BuildContext context) {
    return Table(
      key: const Key('follow_up_table'),
      columnWidths: const {
        0: FlexColumnWidth(0.35),
        1: FlexColumnWidth(1.8),
        2: FlexColumnWidth(1.4),
        3: FlexColumnWidth(1.3),
        4: FlexColumnWidth(1.3),
        5: FlexColumnWidth(2.1),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
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
            _header('STATUS'),
            _header('ACTION'),
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
            style: GoogleFonts.inter(
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
              borderRadius: BorderRadius.circular(6),
              onTap: () => onViewDetails(lead),
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
        Padding(
          padding: _cellPadding,
          child: Text(
            '+91 ${lead.phone}',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF374151),
            ),
          ),
        ),
        Padding(
          padding: _cellPadding,
          child: Text(
            lead.expectedArrivalDate == null
                ? '—'
                : _expectedArrivalDateFormat.format(lead.expectedArrivalDate!),
            style: GoogleFonts.inter(
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
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
                const SizedBox(width: AppSpacing.xs),
                PopupMenuButton<String>(
                  key: Key('lead_more_options_${lead.id}'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
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
      textStyle: GoogleFonts.inter(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _header(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 10,
      ),
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
          style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
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
            _row(
              'Expected Arrival',
              lead.expectedArrivalDate == null
                  ? '—'
                  : _expectedArrivalDateFormat.format(lead.expectedArrivalDate!),
            ),
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
        color: filled
            ? const Color(0xFFF7F5FC)
            : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: filled
              ? const Color(0xFFEFE8F7)
              : const Color(0xFFE1EDFB),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background decorative graphic matching Image 2
          if (filled) ...[
            // Soft lavender wave at bottom right
            Positioned(
              right: -25,
              bottom: -25,
              child: Container(
                width: 150,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE5F7).withValues(alpha: 0.65),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(85),
                    bottomLeft: Radius.circular(55),
                  ),
                ),
              ),
            ),
            // Subtle silhouettes
            Positioned(
              right: 18,
              bottom: 12,
              child: Icon(
                Icons.groups_rounded,
                size: 52,
                color: const Color(0xFF7C52B3).withValues(alpha: 0.22),
              ),
            ),
          ] else ...[
            // Clean document illustration at bottom right
            Positioned(
              right: 18,
              bottom: 12,
              child: Icon(
                Icons.article_rounded,
                size: 56,
                color: const Color(0xFF0284C7).withValues(alpha: 0.2),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          right: topRight != null ? 145 : 0,
                        ),
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headingSmall.copyWith(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final line in subtitleLines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            line,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      filled
                          ? ElevatedButton.icon(
                              onPressed: onTap,
                              icon: Icon(buttonIcon, size: 16),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(buttonLabel),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : OutlinedButton.icon(
                              onPressed: onTap,
                              icon: Icon(buttonIcon, size: 16),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(buttonLabel),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: Color(0xFFD8D0E3),
                                  width: 1,
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (topRight != null)
            Positioned(
              top: 14,
              right: 14,
              child: topRight!,
            ),
        ],
      ),
    );
  }
}

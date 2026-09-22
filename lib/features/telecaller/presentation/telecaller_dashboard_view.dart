import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/telecaller_lead.dart';
import '../state/telecaller_view_model.dart';

/// Caps content width on very wide monitors so the table/cards don't
/// stretch edge-to-edge; a no-op on laptop/desktop widths below this.
const double _maxContentWidth = 1280;

enum _FollowUpFilter { all, pending, converted }

/// "Follow-Up Required" here means leads you've added that haven't been
/// converted into a clinic patient yet — i.e. the ones worth calling back.
/// The reference design's original framing ("patients expected today but
/// not arrived") is session/arrival data, which Telecallers don't have
/// access to (verified: telecaller_leads is the only collection a
/// telecaller can read — see pocketbase/pb_migrations and
/// telecaller_lead_repository_test.dart). This view only ever reads that
/// same lead data the rest of the Telecaller module already uses.
class TelecallerDashboardView extends StatefulWidget {
  final TelecallerViewModel viewModel;
  final VoidCallback onAddLead;
  final VoidCallback onImport;
  final void Function(TelecallerLead lead)? onOpenLead;

  const TelecallerDashboardView({
    super.key,
    required this.viewModel,
    required this.onAddLead,
    required this.onImport,
    this.onOpenLead,
  });

  @override
  State<TelecallerDashboardView> createState() =>
      _TelecallerDashboardViewState();
}

class _TelecallerDashboardViewState extends State<TelecallerDashboardView> {
  _FollowUpFilter _filter = _FollowUpFilter.all;

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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final leads = widget.viewModel.leads;
        final filtered = switch (_filter) {
          _FollowUpFilter.all => leads,
          _FollowUpFilter.pending => leads.where((l) => !l.converted).toList(),
          _FollowUpFilter.converted => leads.where((l) => l.converted).toList(),
        };

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
                            subtitle: 'Register a new patient manually.',
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
                            subtitle: 'Bulk upload patient data from Excel or CSV file.',
                            buttonLabel: 'Import from Excel / CSV',
                            buttonIcon: Icons.upload_outlined,
                            filled: false,
                            onTap: widget.onImport,
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
                            _FilterDropdown(
                              value: _filter,
                              onChanged: (v) => setState(() => _filter = v),
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
                        else
                          _FollowUpTable(
                            leads: filtered,
                            onCall: _callLead,
                            onOpen: widget.onOpenLead,
                          ),
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
            DropdownMenuItem(value: _FollowUpFilter.all, child: Text('All')),
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

class _FollowUpTable extends StatelessWidget {
  final List<TelecallerLead> leads;
  final void Function(TelecallerLead) onCall;
  final void Function(TelecallerLead)? onOpen;

  const _FollowUpTable({
    required this.leads,
    required this.onCall,
    this.onOpen,
  });

  // Table gives each cell a *tight* width constraint equal to its column
  // width, so any child without its own intrinsic sizing (a badge's colored
  // background, a button's ink surface) stretches to fill it. Align resets
  // that to the child's natural size — this is what was making the status
  // pill and Follow Up button look stretched across their columns.
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
        1: FlexColumnWidth(2.4),
        2: FlexColumnWidth(1.8),
        3: FlexColumnWidth(1.3),
        4: FlexColumnWidth(1.1),
        5: FlexColumnWidth(1.3),
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
          ],
        ),
        for (var i = 0; i < leads.length; i++) _row(i + 1, leads[i]),
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
              onTap: onOpen != null ? () => onOpen!(lead) : null,
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
            '${lead.created.day}/${lead.created.month}/${lead.created.year}',
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
              child: TextButton.icon(
                key: Key('follow_up_call_${lead.id}'),
                onPressed: () => onCall(lead),
                icon: const Icon(Icons.call_outlined, size: 14),
                label: const Text('Follow Up'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.primaryBgLight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData buttonIcon;
  final bool filled;
  final VoidCallback onTap;

  const _ActionCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: iconBg.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.headingSmall.copyWith(fontSize: 16)),
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle, style: AppTypography.bodySmall),
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
    );
  }
}

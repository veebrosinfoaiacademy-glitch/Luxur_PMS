import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../state/telecaller_view_model.dart';

/// Dashboard is intentionally simple: two real counts derived from the
/// telecaller's own data (no invented trend %, no fabricated comparisons —
/// there's no historical baseline to compare against honestly) plus the
/// three primary actions the requirements call for.
class TelecallerDashboardView extends StatelessWidget {
  final TelecallerViewModel viewModel;
  final VoidCallback onAddLead;
  final VoidCallback onImport;
  final VoidCallback onViewLeads;

  const TelecallerDashboardView({
    super.key,
    required this.viewModel,
    required this.onAddLead,
    required this.onImport,
    required this.onViewLeads,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Telecaller Dashboard', style: AppTypography.headingDisplay),
          const SizedBox(height: 4),
          Text(
            'Add and track the converted leads you bring in.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  key: const Key('stat_total_leads'),
                  icon: Icons.groups_outlined,
                  label: 'Total Leads Added',
                  value: viewModel.isLoading ? '—' : '${viewModel.totalLeadsCount}',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  key: const Key('stat_leads_today'),
                  icon: Icons.today_outlined,
                  label: 'Leads Added Today',
                  value: viewModel.isLoading ? '—' : '${viewModel.leadsAddedTodayCount}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          Text('Actions', style: AppTypography.headingSmall),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _ActionCard(
                key: const Key('action_add_lead'),
                icon: Icons.person_add_alt_1_outlined,
                title: 'Add Converted Lead',
                subtitle: 'Manually enter a single lead.',
                onTap: onAddLead,
              ),
              _ActionCard(
                key: const Key('action_import'),
                icon: Icons.upload_file_outlined,
                title: 'Import Excel',
                subtitle: 'Bulk-add leads from a spreadsheet.',
                onTap: onImport,
              ),
              _ActionCard(
                key: const Key('action_view_leads'),
                icon: Icons.list_alt_outlined,
                title: 'View Leads',
                subtitle: 'Search and review your lead list.',
                onTap: onViewLeads,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryBgLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.metricValue.copyWith(fontSize: 24),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 12),
            Text(title, style: AppTypography.labelBold),
            const SizedBox(height: 4),
            Text(subtitle, style: AppTypography.bodySmall),
          ],
        ),
      ),
    );
  }
}

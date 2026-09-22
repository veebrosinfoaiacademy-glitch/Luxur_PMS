import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../repositories/telecaller_lead_repository.dart';
import '../state/telecaller_view_model.dart';
import '../widgets/telecaller_sidebar_nav.dart';
import 'telecaller_dashboard_view.dart';
import 'add_lead_view.dart';
import 'import_leads_view.dart';
import 'lead_list_view.dart';

enum TelecallerSection { dashboard, addLead, import, leadList }

/// Root of the Telecaller-only area. This is the only widget subtree a
/// Telecaller account ever reaches — there is no navigation path from here
/// into Admin/Doctor/HR/Chairman UI, satisfying "prevent access to
/// unauthorized routes" at the Flutter layer. The real enforcement is
/// server-side (PocketBase collection rules); this is defense in depth,
/// not the security boundary itself.
class TelecallerShell extends StatefulWidget {
  final AuthService authService;
  final PocketBase pb;

  const TelecallerShell({super.key, required this.authService, required this.pb});

  @override
  State<TelecallerShell> createState() => _TelecallerShellState();
}

class _TelecallerShellState extends State<TelecallerShell> {
  TelecallerSection _section = TelecallerSection.dashboard;
  late final TelecallerLeadRepository _repository;
  late final TelecallerViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _repository = TelecallerLeadRepository(widget.pb);
    _viewModel = TelecallerViewModel(_repository)..loadLeads();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _navigateTo(TelecallerSection section) {
    setState(() => _section = section);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          TelecallerSidebarNav(
            currentSection: _section,
            onSectionSelected: _navigateTo,
            authService: widget.authService,
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) => _buildCurrentView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_section) {
      case TelecallerSection.dashboard:
        return TelecallerDashboardView(
          viewModel: _viewModel,
          onAddLead: () => _navigateTo(TelecallerSection.addLead),
          onImport: () => _navigateTo(TelecallerSection.import),
          onViewLeads: () => _navigateTo(TelecallerSection.leadList),
        );
      case TelecallerSection.addLead:
        return AddLeadView(viewModel: _viewModel);
      case TelecallerSection.import:
        return ImportLeadsView(viewModel: _viewModel);
      case TelecallerSection.leadList:
        return LeadListView(viewModel: _viewModel);
    }
  }
}

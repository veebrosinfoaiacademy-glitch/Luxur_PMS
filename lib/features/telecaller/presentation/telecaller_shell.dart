import 'dart:ui';
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
import 'telecaller_settings_view.dart';

enum TelecallerSection { dashboard, addLead, import, leadList, settings }

/// Root of the Telecaller-only area. This is the only widget subtree a
/// Telecaller account ever reaches — there is no navigation path from here
/// into Admin/Doctor/HR/Chairman UI, satisfying "prevent access to
/// unauthorized routes" at the Flutter layer. The real enforcement is
/// server-side (PocketBase collection rules); this is defense in depth,
/// not the security boundary itself.
class TelecallerShell extends StatefulWidget {
  final AuthService authService;
  final PocketBase pb;

  const TelecallerShell({
    super.key,
    required this.authService,
    required this.pb,
  });

  @override
  State<TelecallerShell> createState() => _TelecallerShellState();
}

class _TelecallerShellState extends State<TelecallerShell> {
  TelecallerSection _section = TelecallerSection.dashboard;
  final String _leadListInitialQuery = '';
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

  int get _sectionIndex {
    switch (_section) {
      case TelecallerSection.dashboard:
        return 0;
      case TelecallerSection.leadList:
        return 1;
      case TelecallerSection.settings:
        return 2;
      case TelecallerSection.import:
        return 3;
      case TelecallerSection.addLead:
        return 4;
    }
  }

  void _navigateTo(TelecallerSection section) {
    if (_section == section) return;
    setState(() => _section = section);
  }

  void _openAddPatientDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Material(
                  color: Colors.transparent,
                  child: AddLeadView(
                    viewModel: _viewModel,
                    isDialog: true,
                    onClose: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, secAnim, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TelecallerSidebarNav(
            currentSection: _section,
            onSectionSelected: _navigateTo,
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                return IndexedStack(
                  index: _sectionIndex,
                  children: [
                    TelecallerDashboardView(
                      viewModel: _viewModel,
                      authService: widget.authService,
                      onAddLead: () => _openAddPatientDialog(context),
                      onImport: () => _navigateTo(TelecallerSection.import),
                    ),
                    LeadListView(
                      key: ValueKey(_leadListInitialQuery),
                      viewModel: _viewModel,
                      authService: widget.authService,
                      initialQuery: _leadListInitialQuery,
                      onAddLead: () => _openAddPatientDialog(context),
                    ),
                    TelecallerSettingsView(authService: widget.authService),
                    ImportLeadsView(
                      viewModel: _viewModel,
                      authService: widget.authService,
                    ),
                    AddLeadView(
                      viewModel: _viewModel,
                      authService: widget.authService,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

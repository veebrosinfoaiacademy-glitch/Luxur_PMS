import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../core/auth/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/state/app_view_model.dart';
import '../../core/state/clinic_view_model.dart';
import 'sidebar_nav.dart';
import '../../features/dashboard/presentation/dashboard_view.dart';
import '../../features/dashboard/presentation/doctor_dashboard_view.dart';
import '../../features/patients/presentation/patients_list_view.dart';
import '../../features/patients/presentation/patient_detail_view.dart';
import '../../features/pharmacy/presentation/pharmacy_bills_view.dart';
import '../../features/settings/presentation/settings_view.dart';

/// The clinic shell, shared by the Admin and the Doctor. The two differ in
/// which dashboard they land on and which nav entries they get — the
/// patient records underneath are the same records, and the real access
/// limits are enforced by PocketBase, not by what this hides.
class AppShell extends StatefulWidget {
  final AppViewModel viewModel;
  final AuthService authService;
  final PocketBase pb;

  const AppShell({
    super.key,
    required this.viewModel,
    required this.authService,
    required this.pb,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final ClinicViewModel _clinic;

  @override
  void initState() {
    super.initState();
    _clinic = ClinicViewModel(
      pb: widget.pb,
      role: widget.authService.role ?? '',
      displayName: widget.authService.displayName,
    );
  }

  @override
  void dispose() {
    _clinic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Row(
            children: [
              SidebarNav(
                viewModel: widget.viewModel,
                authService: widget.authService,
                isDoctor: _clinic.isDoctor,
              ),
              Expanded(child: _buildCurrentView()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentView() {
    switch (widget.viewModel.currentSection) {
      case AppNavSection.dashboard:
        return _clinic.isDoctor
            ? DoctorDashboardView(viewModel: widget.viewModel, clinic: _clinic)
            : DashboardView(viewModel: widget.viewModel, clinic: _clinic);
      case AppNavSection.patients:
        return PatientsListView(viewModel: widget.viewModel, clinic: _clinic);
      case AppNavSection.patientDetail:
        return PatientDetailView(viewModel: widget.viewModel, clinic: _clinic);
      case AppNavSection.pharmacyBills:
        return PharmacyBillsView(viewModel: widget.viewModel);
      case AppNavSection.settings:
        return SettingsView(viewModel: widget.viewModel, clinic: _clinic);
    }
  }
}

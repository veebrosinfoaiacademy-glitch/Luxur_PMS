import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/state/app_view_model.dart';
import 'sidebar_nav.dart';
import '../../features/dashboard/presentation/dashboard_view.dart';
import '../../features/patients/presentation/patients_list_view.dart';
import '../../features/patients/presentation/patient_detail_view.dart';
import '../../features/pharmacy/presentation/pharmacy_bills_view.dart';
import '../../features/settings/presentation/settings_view.dart';

class AppShell extends StatelessWidget {
  final AppViewModel viewModel;

  const AppShell({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Row(
            children: [
              // 1. Permanent Desktop Sidebar Navigation
              SidebarNav(viewModel: viewModel),

              // 2. Main Content Area
              Expanded(
                child: _buildCurrentView(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentView() {
    switch (viewModel.currentSection) {
      case AppNavSection.dashboard:
        return DashboardView(viewModel: viewModel);
      case AppNavSection.patients:
        return PatientsListView(viewModel: viewModel);
      case AppNavSection.patientDetail:
        return PatientDetailView(viewModel: viewModel);
      case AppNavSection.pharmacyBills:
        return PharmacyBillsView(viewModel: viewModel);
      case AppNavSection.settings:
        return SettingsView(viewModel: viewModel);
    }
  }
}

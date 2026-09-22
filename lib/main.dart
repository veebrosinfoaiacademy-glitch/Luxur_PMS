import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/state/app_view_model.dart';
import 'shared/widgets/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PMSApp());
}

class PMSApp extends StatefulWidget {
  const PMSApp({super.key});

  @override
  State<PMSApp> createState() => _PMSAppState();
}

class _PMSAppState extends State<PMSApp> {
  late final AppViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AppViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veebros Clinic — Practice Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AppShell(viewModel: _viewModel),
    );
  }
}

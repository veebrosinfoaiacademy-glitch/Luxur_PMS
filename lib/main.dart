import 'package:flutter/material.dart';
import 'core/auth/auth_service.dart';
import 'core/network/pocketbase_client.dart';
import 'core/theme/app_theme.dart';
import 'core/state/app_view_model.dart';
import 'shared/widgets/app_shell.dart';
import 'features/auth/presentation/login_view.dart';
import 'features/telecaller/presentation/telecaller_shell.dart';

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
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(PocketBaseClient.instance);
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veebros Clinic — Practice Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: ListenableBuilder(
        listenable: _authService,
        builder: (context, _) => _buildHome(),
      ),
    );
  }

  Widget _buildHome() {
    if (!_authService.isAuthenticated) {
      return LoginView(authService: _authService);
    }

    // Telecaller reaches its own restricted area and nothing else. Admin
    // and Doctor share the clinic shell, which picks the right dashboard
    // and navigation for the role; HR/Chairman fall through to it too for
    // now. Real access control for every role is enforced server-side by
    // PocketBase collection rules regardless of what the Flutter UI shows.
    if (_authService.role == 'telecaller') {
      return TelecallerShell(authService: _authService, pb: PocketBaseClient.instance);
    }

    return AppShell(
      viewModel: AppViewModel(),
      authService: _authService,
      pb: PocketBaseClient.instance,
    );
  }
}

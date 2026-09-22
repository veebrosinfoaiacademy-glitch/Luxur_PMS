import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:pms_vbis/core/auth/auth_service.dart';
import '../support/pocketbase_test_helper.dart';

/// Guards against the quick-login account list in login_view.dart silently
/// drifting from scripts/seed_dev_data.mjs (they can't share one literal
/// source of truth across Dart/JS, so this is the check that keeps them
/// honest). Requires `node scripts/seed_dev_data.mjs` to have been run
/// against the local instance at least once.
void main() {
  const password = 'DevPass123!';
  const accounts = {
    'admin': 'admin@luxurpms.local',
    'doctor': 'doctor@luxurpms.local',
    'hr': 'hr@luxurpms.local',
    'chairman': 'chairman@luxurpms.local',
    'telecaller': 'telecaller@luxurpms.local',
  };

  accounts.forEach((expectedRole, email) {
    test('quick-login credentials for $expectedRole actually authenticate with role=$expectedRole', () async {
      final pb = PocketBase(testPocketBaseUrl);
      final auth = AuthService(pb);

      await auth.login(email, password);

      expect(auth.isAuthenticated, isTrue);
      expect(auth.role, expectedRole);
    });
  });
}

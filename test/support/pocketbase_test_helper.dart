import 'package:pocketbase/pocketbase.dart';

/// Test-only helpers for running against the LOCAL dev PocketBase instance
/// (pocketbase/pb_migrations applied, `pocketbase serve` running on
/// 127.0.0.1:8090). Never point this at DEV/PROD — see AGENTS/pms-project
/// skill: tests must not run against real clinic data.
const testPocketBaseUrl = 'http://127.0.0.1:8090';

const testSuperuserEmail = 'dev@local.test';
const testSuperuserPassword = 'DevPass123!';

/// Dedicated accounts for automated tests, kept separate from the
/// scripts/seed_dev_data.mjs demo accounts so test runs don't clutter what
/// a developer is looking at in the seeded dashboard.
const testTelecallerAEmail = 'test.telecaller.a@luxurpms.local';
const testTelecallerBEmail = 'test.telecaller.b@luxurpms.local';
const testAccountPassword = 'TestPass123!';

/// Creates the given test `users` account (role=telecaller) if it doesn't
/// already exist, using the local superuser. Idempotent — safe to call at
/// the start of every test file.
Future<void> ensureTestTelecaller(PocketBase superuserPb, String email) async {
  final existing = await superuserPb.collection('users').getList(
        page: 1,
        perPage: 1,
        filter: 'email = "$email"',
      );
  if (existing.totalItems > 0) return;

  await superuserPb.collection('users').create(body: {
    'email': email,
    'password': testAccountPassword,
    'passwordConfirm': testAccountPassword,
    'name': email.split('@').first,
    'role': 'telecaller',
    'active': true,
    'verified': true,
  });
}

Future<PocketBase> authenticatedSuperuserClient() async {
  final pb = PocketBase(testPocketBaseUrl);
  await pb.collection('_superusers').authWithPassword(
        testSuperuserEmail,
        testSuperuserPassword,
      );
  return pb;
}

Future<PocketBase> authenticatedTelecallerClient(String email) async {
  final pb = PocketBase(testPocketBaseUrl);
  await pb.collection('users').authWithPassword(email, testAccountPassword);
  return pb;
}

/// A phone-safe unique suffix so repeated test runs never collide with
/// earlier runs' data (telecaller_leads has no delete rule by design — see
/// pocketbase/pb_migrations — so old test rows are never cleaned up
/// automatically; using a fresh number each run keeps tests independent of
/// that leftover data instead of trying to delete it).
String uniqueTestPhone() {
  final ms = DateTime.now().millisecondsSinceEpoch;
  // Keep it to 10 digits, starting with a valid Indian mobile prefix (9).
  final tail = (ms % 1000000000).toString().padLeft(9, '0');
  return '9$tail';
}

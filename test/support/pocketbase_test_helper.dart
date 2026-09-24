import 'package:pocketbase/pocketbase.dart';

/// Test-only helpers for the LOCAL dev PocketBase instance
/// (pocketbase/pb_migrations applied, `pocketbase serve` running on
/// 127.0.0.1:8090). Never point this at DEV/PROD — tests must not run
/// against real clinic data.
const testPocketBaseUrl = 'http://127.0.0.1:8090';

const testSuperuserEmail = 'dev@local.test';
const testSuperuserPassword = 'DevPass123!';

/// Dedicated accounts for automated tests, kept separate from the
/// scripts/seed_dev_data.mjs demo accounts so test runs don't clutter what
/// a developer is looking at in the seeded dashboard.
const testTelecallerAEmail = 'test.telecaller.a@luxurpms.local';
const testTelecallerBEmail = 'test.telecaller.b@luxurpms.local';
const testAdminEmail = 'test.admin.a@luxurpms.local';
const testDoctorAEmail = 'test.doctor.a@luxurpms.local';
const testDoctorBEmail = 'test.doctor.b@luxurpms.local';
const testAccountPassword = 'TestPass123!';

/// Creates the given test `users` account (role=telecaller) if missing.
Future<void> ensureTestTelecaller(PocketBase superuserPb, String email) async {
  await ensureTestUser(superuserPb, email, role: 'telecaller');
}

/// Idempotent test-account creation for any role.
///
/// `flutter test` runs test files concurrently and several share the same
/// well-known account emails, so the check-then-create below is inherently
/// racy across files' `setUpAll`s. Rather than trying to prevent that race,
/// this treats "someone else created it a moment ago" as success.
Future<void> ensureTestUser(
  PocketBase superuserPb,
  String email, {
  required String role,
}) async {
  final existing = await superuserPb.collection('users').getList(
        page: 1,
        perPage: 1,
        filter: 'email = "$email"',
      );
  if (existing.totalItems > 0) return;

  try {
    await superuserPb.collection('users').create(body: {
      'email': email,
      'password': testAccountPassword,
      'passwordConfirm': testAccountPassword,
      'name': email.split('@').first,
      'role': role,
      'active': true,
      'verified': true,
    });
  } on ClientException catch (e) {
    final data = e.response['data'];
    final isDuplicateEmail = data is Map &&
        data['email'] is Map &&
        (data['email'] as Map)['code'] == 'validation_not_unique';
    if (!isDuplicateEmail) rethrow;
  }
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

/// Same thing, for any role's test account.
Future<PocketBase> authenticatedClientAs(String email) =>
    authenticatedTelecallerClient(email);

/// A phone-safe unique suffix so repeated test runs never collide with
/// earlier runs' data (telecaller_leads has no delete rule by design, so
/// old test rows are never cleaned up automatically).
String uniqueTestPhone() {
  final ms = DateTime.now().millisecondsSinceEpoch;
  final tail = (ms % 1000000000).toString().padLeft(9, '0');
  return '9$tail';
}

/// Minimal valid 1x1 transparent PNG — real bytes, so the server's
/// mimeTypes validation on image fields genuinely passes.
final testPngBytes = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x62, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:pms_vbis/features/telecaller/repositories/telecaller_lead_repository.dart';
import '../support/pocketbase_test_helper.dart';

/// Runs against the real LOCAL PocketBase (127.0.0.1:8090) with
/// pocketbase/pb_migrations applied — start it before running this file:
///   cd pocketbase && ./pocketbase.exe serve
/// These exercise the actual collection API rules, not a mock, since the
/// task requires server-side authorization to be verified, not assumed.
void main() {
  late final PocketBase superuserPb;

  setUpAll(() async {
    superuserPb = await authenticatedSuperuserClient();
    await ensureTestTelecaller(superuserPb, testTelecallerAEmail);
    await ensureTestTelecaller(superuserPb, testTelecallerBEmail);
  });

  test('create() attributes the lead to the authenticated telecaller', () async {
    final pbA = await authenticatedTelecallerClient(testTelecallerAEmail);
    final repo = TelecallerLeadRepository(pbA);
    final myId = pbA.authStore.record!.id;
    final phone = uniqueTestPhone();

    final lead = await repo.create(name: 'Attribution Test', normalizedPhone: phone);

    expect(lead.telecallerId, myId);
  });

  test('create() rejects a second lead with the same phone for the same telecaller', () async {
    final pbA = await authenticatedTelecallerClient(testTelecallerAEmail);
    final repo = TelecallerLeadRepository(pbA);
    final phone = uniqueTestPhone();

    await repo.create(name: 'First Entry', normalizedPhone: phone);

    expect(
      () => repo.create(name: 'Duplicate Entry', normalizedPhone: phone),
      throwsA(isA<DuplicateLeadException>()),
    );
  });

  test('listMine() only returns the authenticated telecaller\'s own leads, never another\'s', () async {
    final pbA = await authenticatedTelecallerClient(testTelecallerAEmail);
    final pbB = await authenticatedTelecallerClient(testTelecallerBEmail);
    final repoA = TelecallerLeadRepository(pbA);
    final repoB = TelecallerLeadRepository(pbB);

    final phoneA = uniqueTestPhone();
    await repoA.create(name: 'Only A should see this', normalizedPhone: phoneA);

    final bList = await repoB.listMine();
    expect(bList.any((l) => l.phone == phoneA), isFalse);

    final aList = await repoA.listMine();
    expect(aList.any((l) => l.phone == phoneA), isTrue);
  });

  test(
    'the server rejects an attempt to attribute a lead to a different telecaller '
    '(bypassing the repository, straight at the API — impersonation guard)',
    () async {
      final pbA = await authenticatedTelecallerClient(testTelecallerAEmail);
      final pbB = await authenticatedTelecallerClient(testTelecallerBEmail);
      final otherTelecallerId = pbB.authStore.record!.id;

      await expectLater(
        pbA.collection('telecaller_leads').create(body: {
          'name': 'Impersonation attempt',
          'phone': uniqueTestPhone(),
          'telecaller': otherTelecallerId, // trying to attribute to B while authenticated as A
          'converted': false,
        }),
        throwsA(anything), // PocketBase ClientException (403) — createRule fails
      );
    },
  );

  test('a telecaller cannot read the main patients collection at all', () async {
    final pbA = await authenticatedTelecallerClient(testTelecallerAEmail);
    final patients = await pbA.collection('patients').getList(page: 1, perPage: 10);
    // listRule filters rather than 403s — but it must filter to nothing.
    expect(patients.totalItems, 0);
  });

  test('a telecaller cannot create a record in the main patients collection', () async {
    final pbA = await authenticatedTelecallerClient(testTelecallerAEmail);
    await expectLater(
      pbA.collection('patients').create(body: {
        'patient_code': 'HACK-${uniqueTestPhone()}',
        'name': 'Should not be allowed',
        'phone': uniqueTestPhone(),
        'status': 'Joined',
      }),
      throwsA(anything),
    );
  });

  test('findExistingPhones only reports phones that exist among the caller\'s own leads', () async {
    final pbA = await authenticatedTelecallerClient(testTelecallerAEmail);
    final repoA = TelecallerLeadRepository(pbA);
    final existingPhone = uniqueTestPhone();
    final neverUsedPhone = uniqueTestPhone();

    await repoA.create(name: 'Existing Lead', normalizedPhone: existingPhone);

    final result = await repoA.findExistingPhones({existingPhone, neverUsedPhone});

    expect(result, {existingPhone});
  });
}

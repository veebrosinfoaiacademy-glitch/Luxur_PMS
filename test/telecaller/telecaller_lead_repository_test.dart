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

  test('create() stores and round-trips expected_arrival_date as a calendar date', () async {
    final pbA = await authenticatedTelecallerClient(testTelecallerAEmail);
    final repo = TelecallerLeadRepository(pbA);
    final phone = uniqueTestPhone();

    final created = await repo.create(
      name: 'Expected Arrival Test',
      normalizedPhone: phone,
      expectedArrivalDate: DateTime(2026, 9, 28),
    );
    expect(created.expectedArrivalDate, isNotNull);
    expect(created.expectedArrivalDate!.year, 2026);
    expect(created.expectedArrivalDate!.month, 9);
    expect(created.expectedArrivalDate!.day, 28);

    final reloaded = await repo.listMine();
    final match = reloaded.firstWhere((l) => l.phone == phone);
    expect(match.expectedArrivalDate!.year, 2026);
    expect(match.expectedArrivalDate!.month, 9);
    expect(match.expectedArrivalDate!.day, 28);
  });

  test('create() leaves expected_arrival_date unset when omitted (e.g. bulk import path)', () async {
    final pbA = await authenticatedTelecallerClient(testTelecallerAEmail);
    final repo = TelecallerLeadRepository(pbA);

    final created = await repo.create(name: 'No Arrival Date', normalizedPhone: uniqueTestPhone());

    expect(created.expectedArrivalDate, isNull);
  });

  test('update() edits a telecaller\'s own lead fields', () async {
    final pbA = await authenticatedTelecallerClient(testTelecallerAEmail);
    final repo = TelecallerLeadRepository(pbA);
    final phone = uniqueTestPhone();
    final created = await repo.create(name: 'Before Edit', normalizedPhone: phone);

    final newPhone = uniqueTestPhone();
    final updated = await repo.update(
      id: created.id,
      name: 'After Edit',
      normalizedPhone: newPhone,
      address: 'New Address',
      concern: 'New Concern',
      expectedArrivalDate: DateTime(2026, 11, 5),
    );

    expect(updated.name, 'After Edit');
    expect(updated.phone, newPhone);
    expect(updated.address, 'New Address');
    expect(updated.concern, 'New Concern');
    expect(updated.expectedArrivalDate!.day, 5);
  });

  test('update() rejects changing the phone to one that collides with another of the caller\'s own leads', () async {
    final pbA = await authenticatedTelecallerClient(testTelecallerAEmail);
    final repo = TelecallerLeadRepository(pbA);
    final phoneOne = uniqueTestPhone();
    // uniqueTestPhone() is millisecond-based — deriving phoneTwo from it
    // (rather than calling it again immediately) guarantees distinctness
    // even when both calls land in the same millisecond.
    final phoneTwo = (int.parse(phoneOne) + 1).toString();
    await repo.create(name: 'Lead One', normalizedPhone: phoneOne);
    final leadTwo = await repo.create(name: 'Lead Two', normalizedPhone: phoneTwo);

    expect(
      () => repo.update(id: leadTwo.id, name: 'Lead Two', normalizedPhone: phoneOne),
      throwsA(isA<DuplicateLeadException>()),
    );
  });

  test('update() does not flag a no-op phone change as a duplicate of itself', () async {
    final pbA = await authenticatedTelecallerClient(testTelecallerAEmail);
    final repo = TelecallerLeadRepository(pbA);
    final phone = uniqueTestPhone();
    final created = await repo.create(name: 'Same Phone', normalizedPhone: phone);

    final updated = await repo.update(id: created.id, name: 'Same Phone Renamed', normalizedPhone: phone);

    expect(updated.name, 'Same Phone Renamed');
  });

  test(
    'a telecaller cannot self-convert their own lead via a direct API update '
    '(bypassing the app UI — pb_hooks/telecaller_leads_protect_fields.pb.js)',
    () async {
      final pbA = await authenticatedTelecallerClient(testTelecallerAEmail);
      final repo = TelecallerLeadRepository(pbA);
      final lead = await repo.create(name: 'Self Convert Attempt', normalizedPhone: uniqueTestPhone());

      await expectLater(
        pbA.collection('telecaller_leads').update(lead.id, body: {'converted': true}),
        throwsA(anything),
      );
    },
  );

  test('a superuser (stand-in for the admin conversion workflow) can still convert a lead directly', () async {
    final superuserPb = await authenticatedSuperuserClient();
    final repo = TelecallerLeadRepository(await authenticatedTelecallerClient(testTelecallerAEmail));
    final lead = await repo.create(name: 'Admin Converts This', normalizedPhone: uniqueTestPhone());

    final updated = await superuserPb.collection('telecaller_leads').update(lead.id, body: {'converted': true});
    expect(updated.getBoolValue('converted'), isTrue);
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

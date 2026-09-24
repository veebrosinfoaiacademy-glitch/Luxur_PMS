import 'dart:typed_data';
import 'package:excel/excel.dart' as xl;
import 'package:flutter_test/flutter_test.dart';
import 'package:pms_vbis/features/telecaller/repositories/telecaller_lead_repository.dart';
import 'package:pms_vbis/features/telecaller/state/telecaller_view_model.dart';
import '../support/pocketbase_test_helper.dart';

Uint8List _sheet(List<String> headers, List<List<String>> rows) {
  final excel = xl.Excel.createExcel();
  final name = excel.getDefaultSheet()!;
  excel.appendRow(name, headers.map((h) => xl.TextCellValue(h)).toList());
  for (final r in rows) {
    excel.appendRow(name, r.map((c) => xl.TextCellValue(c)).toList());
  }
  return Uint8List.fromList(excel.encode()!);
}

void main() {
  setUpAll(() async {
    final superuserPb = await authenticatedSuperuserClient();
    await ensureTestTelecaller(superuserPb, testTelecallerAEmail);
  });

  test('addLead() rejects empty name before hitting the network', () async {
    final pb = await authenticatedTelecallerClient(testTelecallerAEmail);
    final vm = TelecallerViewModel(TelecallerLeadRepository(pb));

    final result = await vm.addLead(name: '   ', rawPhone: uniqueTestPhone());

    expect(result.success, isFalse);
    expect(result.errorMessage, contains('Name'));
  });

  test('addLead() rejects an invalid phone number', () async {
    final pb = await authenticatedTelecallerClient(testTelecallerAEmail);
    final vm = TelecallerViewModel(TelecallerLeadRepository(pb));

    final result = await vm.addLead(name: 'Valid Name', rawPhone: '123');

    expect(result.success, isFalse);
    expect(result.errorMessage, contains('valid'));
  });

  test('addLead() succeeds and the new lead is immediately in .leads', () async {
    final pb = await authenticatedTelecallerClient(testTelecallerAEmail);
    final vm = TelecallerViewModel(TelecallerLeadRepository(pb));
    final phone = uniqueTestPhone();

    final result = await vm.addLead(name: 'New Lead', rawPhone: phone);

    expect(result.success, isTrue);
    expect(vm.leads.any((l) => l.phone == phone), isTrue);
  });

  test('addLead() stores the expected arrival date passed from the form', () async {
    final pb = await authenticatedTelecallerClient(testTelecallerAEmail);
    final vm = TelecallerViewModel(TelecallerLeadRepository(pb));
    final phone = uniqueTestPhone();

    final result = await vm.addLead(
      name: 'Dated Lead',
      rawPhone: phone,
      expectedArrivalDate: DateTime(2026, 10, 1),
    );

    expect(result.success, isTrue);
    final saved = vm.leads.firstWhere((l) => l.phone == phone);
    expect(saved.expectedArrivalDate!.year, 2026);
    expect(saved.expectedArrivalDate!.month, 10);
    expect(saved.expectedArrivalDate!.day, 1);
  });

  test('updateLead() edits an existing lead in place within .leads', () async {
    final pb = await authenticatedTelecallerClient(testTelecallerAEmail);
    final vm = TelecallerViewModel(TelecallerLeadRepository(pb));
    final phone = uniqueTestPhone();
    await vm.addLead(name: 'Original Name', rawPhone: phone);
    final id = vm.leads.firstWhere((l) => l.phone == phone).id;

    final newPhone = uniqueTestPhone();
    final result = await vm.updateLead(
      id: id,
      name: 'Updated Name',
      rawPhone: newPhone,
      expectedArrivalDate: DateTime(2026, 12, 25),
    );

    expect(result.success, isTrue);
    expect(vm.leads.any((l) => l.phone == phone), isFalse);
    final updated = vm.leads.firstWhere((l) => l.id == id);
    expect(updated.name, 'Updated Name');
    expect(updated.phone, newPhone);
    expect(updated.expectedArrivalDate!.day, 25);
    expect(vm.leads.length, vm.leads.map((l) => l.id).toSet().length,
        reason: 'updateLead() must replace the existing entry, not duplicate it');
  });

  test('updateLead() rejects an invalid phone number without touching the stored lead', () async {
    final pb = await authenticatedTelecallerClient(testTelecallerAEmail);
    final vm = TelecallerViewModel(TelecallerLeadRepository(pb));
    final phone = uniqueTestPhone();
    await vm.addLead(name: 'Keep Me', rawPhone: phone);
    final id = vm.leads.firstWhere((l) => l.phone == phone).id;

    final result = await vm.updateLead(id: id, name: 'Keep Me', rawPhone: '123');

    expect(result.success, isFalse);
    expect(vm.leads.firstWhere((l) => l.id == id).phone, phone);
  });

  test('addLead() surfaces a clear duplicate error on the second attempt', () async {
    final pb = await authenticatedTelecallerClient(testTelecallerAEmail);
    final vm = TelecallerViewModel(TelecallerLeadRepository(pb));
    final phone = uniqueTestPhone();

    await vm.addLead(name: 'First', rawPhone: phone);
    final second = await vm.addLead(name: 'Second', rawPhone: phone);

    expect(second.success, isFalse);
    expect(second.errorMessage, contains('already exists'));
  });

  test('importLeads() attributes every imported row to the authenticated telecaller', () async {
    final pb = await authenticatedTelecallerClient(testTelecallerAEmail);
    final myId = pb.authStore.record!.id;
    final vm = TelecallerViewModel(TelecallerLeadRepository(pb));

    final p1 = uniqueTestPhone();
    final p2 = (int.parse(uniqueTestPhone()) + 1).toString();
    final bytes = _sheet(
      ['Name', 'Phone', 'Telecaller'],
      [
        ['Import One', p1, 'Someone Else Entirely'],
        ['Import Two', p2, 'Someone Else Entirely'],
      ],
    );

    final summary = await vm.importLeads(bytes);

    expect(summary.imported, 2);
    expect(summary.totalRows, 2);
    expect(summary.duplicates, isEmpty);
    expect(summary.invalid, isEmpty);
    for (final lead in vm.leads.where((l) => l.phone == p1 || l.phone == p2)) {
      expect(lead.telecallerId, myId);
    }
  });

  test('importLeads() reports total/imported/duplicates/invalid correctly for a mixed file', () async {
    final pb = await authenticatedTelecallerClient(testTelecallerAEmail);
    final vm = TelecallerViewModel(TelecallerLeadRepository(pb));

    final alreadyExists = uniqueTestPhone();
    await vm.addLead(name: 'Pre-existing', rawPhone: alreadyExists);

    final freshPhone = (int.parse(uniqueTestPhone()) + 2).toString();
    final bytes = _sheet(
      ['Name', 'Phone'],
      [
        ['Fresh Valid Row', freshPhone],
        ['Already In DB', alreadyExists], // duplicate against existing DB record
        ['', '9999999999'], // invalid: missing name
        ['Bad Phone Row', '123'], // invalid: bad phone
      ],
    );

    final summary = await vm.importLeads(bytes);

    expect(summary.totalRows, 4);
    expect(summary.imported, 1);
    expect(summary.duplicates, hasLength(1));
    expect(summary.duplicates.first.rawPhone, alreadyExists);
    expect(summary.invalid, hasLength(2));
  });

  group('import review (preview → confirm) against the real backend', () {
    test('previewImport() saves nothing — not in the view model and not in the database', () async {
      final pb = await authenticatedTelecallerClient(testTelecallerAEmail);
      final repo = TelecallerLeadRepository(pb);
      final vm = TelecallerViewModel(repo);
      final phone = uniqueTestPhone();
      final leadsBefore = (await repo.listMine()).length;

      final preview = await vm.previewImport(_sheet(
        ['Name', 'Phone', 'Expected Arrival Date'],
        [
          ['Preview Only', phone, '25/09/2030'],
        ],
      ));

      expect(preview.toCreate, hasLength(1));
      expect(preview.toCreate.first.row.expectedArrivalDate, DateTime(2030, 9, 25));
      expect(vm.leads.any((l) => l.phone == phone), isFalse);
      expect((await repo.listMine()).length, leadsBefore);
      expect((await repo.listMine()).any((l) => l.phone == phone), isFalse);
    });

    test('previewImport() flags a lead that already exists in the database as a duplicate to skip', () async {
      final pb = await authenticatedTelecallerClient(testTelecallerAEmail);
      final vm = TelecallerViewModel(TelecallerLeadRepository(pb));
      final existing = uniqueTestPhone();
      await vm.addLead(name: 'Already Saved', rawPhone: existing);

      final preview = await vm.previewImport(_sheet(
        ['Name', 'Phone'],
        [
          ['Already Saved Again', existing],
        ],
      ));

      expect(preview.toCreate, isEmpty);
      expect(preview.duplicates, hasLength(1));
    });

    test('confirmImport() saves the previewed rows with their expected arrival dates', () async {
      final pb = await authenticatedTelecallerClient(testTelecallerAEmail);
      final repo = TelecallerLeadRepository(pb);
      final vm = TelecallerViewModel(repo);
      final phoneWithDate = uniqueTestPhone();
      final phoneWithoutDate = (int.parse(phoneWithDate) + 1).toString();

      final preview = await vm.previewImport(_sheet(
        ['Name', 'Phone', 'Expected Arrival Date'],
        [
          ['Has A Date', phoneWithDate, '25/09/2030'],
          ['Has No Date', phoneWithoutDate, ''],
        ],
      ));
      expect(preview.withoutExpectedArrivalCount, 1);

      final summary = await vm.confirmImport(preview);

      expect(summary.imported, 2);
      final saved = await repo.listMine();
      final withDate = saved.firstWhere((l) => l.phone == phoneWithDate);
      final withoutDate = saved.firstWhere((l) => l.phone == phoneWithoutDate);
      expect(withDate.expectedArrivalDate, isNotNull);
      expect(withDate.expectedArrivalDate!.year, 2030);
      expect(withDate.expectedArrivalDate!.month, 9);
      expect(withDate.expectedArrivalDate!.day, 25);
      expect(withoutDate.expectedArrivalDate, isNull);
    });

    test('importLeads() (preview + confirm together) still works and keeps the date', () async {
      final pb = await authenticatedTelecallerClient(testTelecallerAEmail);
      final repo = TelecallerLeadRepository(pb);
      final vm = TelecallerViewModel(repo);
      final phone = uniqueTestPhone();

      final summary = await vm.importLeads(_sheet(
        ['Name', 'Phone', 'Expected Arrival Date'],
        [
          ['One Shot', phone, '2030-10-05'],
        ],
      ));

      expect(summary.imported, 1);
      final saved = (await repo.listMine()).firstWhere((l) => l.phone == phone);
      expect(saved.expectedArrivalDate!.day, 5);
      expect(saved.expectedArrivalDate!.month, 10);
    });
  });
}

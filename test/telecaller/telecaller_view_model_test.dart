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
}

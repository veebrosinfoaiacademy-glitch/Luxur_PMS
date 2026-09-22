import 'dart:typed_data';
import 'package:excel/excel.dart' as xl;
import 'package:flutter_test/flutter_test.dart';
import 'package:pms_vbis/features/telecaller/services/excel_import_service.dart';

Uint8List _buildSheet(List<String> headers, List<List<String>> rows) {
  final excel = xl.Excel.createExcel();
  final sheetName = excel.getDefaultSheet()!;
  excel.appendRow(sheetName, headers.map((h) => xl.TextCellValue(h)).toList());
  for (final row in rows) {
    excel.appendRow(sheetName, row.map((c) => xl.TextCellValue(c)).toList());
  }
  return Uint8List.fromList(excel.encode()!);
}

void main() {
  final service = ExcelImportService();

  test('imports well-formed rows as valid', () {
    final bytes = _buildSheet(
      ['Name', 'Phone', 'Address', 'Concern'],
      [
        ['Priya Menon', '9876543001', 'Kochi', 'Laser'],
        ['Arjun Nair', '+91 98765 43002', 'Ernakulam', 'Acne'],
      ],
    );

    final result = service.parse(bytes);

    expect(result.totalDataRows, 2);
    expect(result.valid, hasLength(2));
    expect(result.invalid, isEmpty);
    expect(result.duplicatesInFile, isEmpty);
    expect(result.valid[0].normalizedPhone, '9876543001');
    expect(result.valid[1].normalizedPhone, '9876543002');
  });

  test('recognizes Mobile/Patient Name header aliases', () {
    final bytes = _buildSheet(
      ['Patient Name', 'Mobile'],
      [
        ['Sneha Varghese', '9876543003'],
      ],
    );

    final result = service.parse(bytes);

    expect(result.valid, hasLength(1));
    expect(result.valid.first.row.rawName, 'Sneha Varghese');
  });

  test('rejects rows missing a name', () {
    final bytes = _buildSheet(
      ['Name', 'Phone'],
      [
        ['', '9876543004'],
      ],
    );

    final result = service.parse(bytes);

    expect(result.valid, isEmpty);
    expect(result.invalid, hasLength(1));
    expect(result.invalid.first.issue, RowIssue.missingName);
  });

  test('rejects rows with an invalid phone number', () {
    final bytes = _buildSheet(
      ['Name', 'Phone'],
      [
        ['Rohan Mathew', '12345'],
      ],
    );

    final result = service.parse(bytes);

    expect(result.valid, isEmpty);
    expect(result.invalid, hasLength(1));
    expect(result.invalid.first.issue, RowIssue.invalidPhone);
  });

  test('flags a repeated phone number within the same file as a duplicate, not invalid', () {
    final bytes = _buildSheet(
      ['Name', 'Phone'],
      [
        ['Anjali Suresh', '9876543005'],
        ['Anjali S (typo re-entry)', '9876543005'],
      ],
    );

    final result = service.parse(bytes);

    expect(result.valid, hasLength(1));
    expect(result.invalid, isEmpty);
    expect(result.duplicatesInFile, hasLength(1));
    expect(result.duplicatesInFile.first.duplicateOfRowNumber, 2); // header is row 1
  });

  test('ignores a Telecaller/Agent column entirely (not read into any field)', () {
    final bytes = _buildSheet(
      ['Name', 'Phone', 'Telecaller'],
      [
        ['Karthik Iyer', '9876543006', 'Someone Else'],
      ],
    );

    final result = service.parse(bytes);

    expect(result.valid, hasLength(1));
    // No field on ImportRow/ValidRow carries the sheet's "Telecaller" value —
    // attribution is decided solely by TelecallerLeadRepository from the
    // authenticated session (verified in telecaller_lead_repository_test.dart).
  });

  test('throws HeaderMappingException when required columns are missing', () {
    final bytes = _buildSheet(
      ['Full Name Only'],
      [
        ['Someone'],
      ],
    );

    expect(() => service.parse(bytes), throwsA(isA<HeaderMappingException>()));
  });

  test('skips fully blank rows without counting them', () {
    final bytes = _buildSheet(
      ['Name', 'Phone'],
      [
        ['Meera Thomas', '9876543007'],
        ['', ''],
      ],
    );

    final result = service.parse(bytes);

    expect(result.totalDataRows, 1);
    expect(result.valid, hasLength(1));
  });
}

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

  test('parseCsv imports well-formed CSV rows as valid', () {
    final service = ExcelImportService();
    const csv = 'Name,Phone,Address,Concern\r\nPriya Menon,9876543001,Kochi,Laser\r\nArjun Nair,9876543002,Ernakulam,Acne\r\n';

    final result = service.parseCsv(csv);

    expect(result.totalDataRows, 2);
    expect(result.valid, hasLength(2));
    expect(result.valid[0].row.rawName, 'Priya Menon');
    expect(result.valid[0].normalizedPhone, '9876543001');
  });

  test('parseCsv rejects rows with invalid phone numbers the same way as Excel', () {
    final service = ExcelImportService();
    const csv = 'Name,Phone\r\nBad Row,123\r\n';

    final result = service.parseCsv(csv);

    expect(result.valid, isEmpty);
    expect(result.invalid, hasLength(1));
    expect(result.invalid.first.issue, RowIssue.invalidPhone);
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

  group('Expected Arrival Date column', () {
    Uint8List sheetWithCells(List<String> headers, List<List<xl.CellValue>> rows) {
      final excel = xl.Excel.createExcel();
      final name = excel.getDefaultSheet()!;
      excel.appendRow(name, headers.map((h) => xl.TextCellValue(h)).toList());
      for (final row in rows) {
        excel.appendRow(name, row);
      }
      return Uint8List.fromList(excel.encode()!);
    }

    test('the downloadable template now has an Expected Arrival Date column', () {
      final excel = xl.Excel.decodeBytes(service.buildTemplateBytes());
      final sheet = excel.tables[excel.tables.keys.first]!;
      final header = sheet.rows.first.map((c) => c?.value.toString()).toList();

      expect(header, ['Name', 'Phone', 'Expected Arrival Date', 'Address', 'Concern']);
    });

    test('the template round-trips: its example row imports with a future date', () {
      final now = DateTime(2026, 9, 24);

      final result = service.parse(service.buildTemplateBytes(now: now));

      expect(result.invalid, isEmpty);
      expect(result.valid, hasLength(1));
      // Example date is a week out, so importing the template untouched
      // never creates an already-overdue lead.
      expect(result.valid.first.row.expectedArrivalDate, DateTime(2026, 10, 1));
    });

    test('reads a real Excel date cell (not just text)', () {
      final bytes = sheetWithCells(
        ['Name', 'Phone', 'Expected Arrival Date'],
        [
          [
            xl.TextCellValue('Priya Menon'),
            xl.TextCellValue('9876543001'),
            xl.DateCellValue(year: 2026, month: 9, day: 25),
          ],
        ],
      );

      final result = service.parse(bytes);

      expect(result.valid, hasLength(1));
      expect(result.valid.first.row.expectedArrivalDate, DateTime(2026, 9, 25));
    });

    test('accepts the common text date formats, read day-first', () {
      final formats = {
        '25/09/2026': DateTime(2026, 9, 25),
        '5/9/2026': DateTime(2026, 9, 5), // 5 September, not 9 May
        '25-09-2026': DateTime(2026, 9, 25),
        '25.09.2026': DateTime(2026, 9, 25),
        '2026-09-25': DateTime(2026, 9, 25),
        '2026-09-25T00:00:00.000Z': DateTime(2026, 9, 25),
        '25 Sep 2026': DateTime(2026, 9, 25),
        '25 September 2026': DateTime(2026, 9, 25),
        '25-Sep-2026': DateTime(2026, 9, 25),
        '46290': DateTime(2026, 9, 25), // Excel serial number
      };
      for (final entry in formats.entries) {
        expect(
          ExcelImportService.parseExpectedArrivalDate(entry.key),
          entry.value,
          reason: '"${entry.key}" should parse',
        );
      }
    });

    test('rejects text that is not a real date', () {
      for (final bad in ['tomorrow', '31/02/2026', '32/01/2026', '13/13/2026', '25/09/26', '01/01/1999', '2026-13-01']) {
        expect(
          ExcelImportService.parseExpectedArrivalDate(bad),
          isNull,
          reason: '"$bad" should not parse',
        );
      }
    });

    test('a filled-in but unreadable date rejects that row instead of dropping the date', () {
      final bytes = _buildSheet(
        ['Name', 'Phone', 'Expected Arrival Date'],
        [
          ['Good Row', '9876543011', '25/09/2026'],
          ['Bad Date Row', '9876543012', 'next week'],
        ],
      );

      final result = service.parse(bytes);

      expect(result.valid, hasLength(1));
      expect(result.invalid, hasLength(1));
      expect(result.invalid.first.issue, RowIssue.invalidExpectedArrivalDate);
      expect(result.invalid.first.reason, contains('next week'));
    });

    test('a blank date cell is allowed and imports without a date', () {
      final bytes = _buildSheet(
        ['Name', 'Phone', 'Expected Arrival Date'],
        [
          ['No Date Yet', '9876543013', ''],
        ],
      );

      final result = service.parse(bytes);

      expect(result.valid, hasLength(1));
      expect(result.valid.first.row.expectedArrivalDate, isNull);
    });

    test('a file with no date column at all still imports exactly as before', () {
      final bytes = _buildSheet(
        ['Name', 'Phone'],
        [
          ['Legacy File Row', '9876543014'],
        ],
      );

      final result = service.parse(bytes);

      expect(result.valid, hasLength(1));
      expect(result.invalid, isEmpty);
      expect(result.valid.first.row.expectedArrivalDate, isNull);
    });

    test('recognises the alternative header "Expected Clinic Arrival Date"', () {
      final bytes = _buildSheet(
        ['Name', 'Phone', 'Expected Clinic Arrival Date'],
        [
          ['Alias Header', '9876543015', '01/10/2026'],
        ],
      );

      final result = service.parse(bytes);

      expect(result.valid.first.row.expectedArrivalDate, DateTime(2026, 10, 1));
    });

    test('CSV files carry the date column through too', () {
      const csv = 'Name,Phone,Expected Arrival Date\r\nCsv Lead,9876543016,25/09/2026\r\nBad Csv,9876543017,soon\r\n';

      final result = service.parseCsv(csv);

      expect(result.valid, hasLength(1));
      expect(result.valid.first.row.expectedArrivalDate, DateTime(2026, 9, 25));
      expect(result.invalid.single.issue, RowIssue.invalidExpectedArrivalDate);
    });
  });
}

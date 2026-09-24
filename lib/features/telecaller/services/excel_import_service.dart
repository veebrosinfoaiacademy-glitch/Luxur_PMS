import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

import '../../../core/utils/phone_utils.dart';

/// One row read from the uploaded file, before it's checked against the
/// database. `rowNumber` is 1-based and counts the header row as row 1,
/// matching what a user sees if they open the file themselves.
class ImportRow {
  final int rowNumber;
  final String rawName;
  final String rawPhone;
  final String address;
  final String concern;
  /// What the cell actually contained (for error messages) and the date it
  /// parsed to. Both are empty/null for a file with no such column, or a
  /// blank cell — such leads import without a date, exactly as before.
  final String rawExpectedArrival;
  final DateTime? expectedArrivalDate;

  ImportRow({
    required this.rowNumber,
    required this.rawName,
    required this.rawPhone,
    required this.address,
    required this.concern,
    this.rawExpectedArrival = '',
    this.expectedArrivalDate,
  });
}

enum RowIssue { missingName, invalidPhone, invalidExpectedArrivalDate }

class InvalidRow {
  final ImportRow row;
  final RowIssue issue;
  InvalidRow(this.row, this.issue);

  String get reason => switch (issue) {
    RowIssue.missingName => 'Missing name',
    RowIssue.invalidPhone => 'Invalid phone number: "${row.rawPhone}"',
    RowIssue.invalidExpectedArrivalDate =>
      'Invalid expected arrival date: "${row.rawExpectedArrival}" (use DD/MM/YYYY)',
  };
}

class ValidRow {
  final ImportRow row;
  final String normalizedPhone;
  ValidRow(this.row, this.normalizedPhone);
}

/// A structurally fine row (valid name + phone) whose phone number repeats
/// an earlier row in the same file. Kept separate from [InvalidRow] so the
/// import summary can report "Duplicates" distinctly from "Invalid".
class DuplicateRow {
  final ImportRow row;
  final String normalizedPhone;
  final int duplicateOfRowNumber;
  DuplicateRow(this.row, this.normalizedPhone, this.duplicateOfRowNumber);
}

/// Result of reading + locally validating a file, before any database
/// duplicate check happens (that check needs network access, so it's done
/// separately per [ValidRow] — see TelecallerViewModel.previewImport).
class ParsedImport {
  final List<ValidRow> valid;
  final List<DuplicateRow> duplicatesInFile;
  final List<InvalidRow> invalid;
  final int totalDataRows;

  ParsedImport({
    required this.valid,
    required this.duplicatesInFile,
    required this.invalid,
    required this.totalDataRows,
  });
}

class HeaderMappingException implements Exception {
  final String message;
  HeaderMappingException(this.message);
}

/// Reads converted-lead rows from an uploaded .xlsx or .csv file.
///
/// No import-template convention existed in the project, so this accepts a
/// small set of case-insensitive header aliases rather than one rigid
/// layout — "Name"/"Lead Name"/"Patient Name" for the name column, etc.
/// Only Name and Phone are mandatory, matching the fields the requirements
/// actually call out for a converted lead. An "Expected Arrival Date" column
/// is optional: when present, a filled cell must hold a real date (a bad one
/// rejects that row rather than silently dropping the date), and a blank cell
/// just imports the lead without one. A "Telecaller"/"Agent" column,
/// if present, is read but deliberately ignored for attribution — see
/// TelecallerLeadRepository.
class ExcelImportService {
  static const _nameAliases = ['name', 'lead name', 'patient name'];
  static const _phoneAliases = [
    'phone',
    'mobile',
    'phone number',
    'mobile number',
  ];
  static const _addressAliases = ['address'];
  static const _concernAliases = ['concern', 'concerns', 'notes'];
  static const _expectedArrivalAliases = [
    'expected arrival date',
    'expected clinic arrival date',
    'expected arrival',
    'expected clinic arrival',
    'arrival date',
    'expected_arrival_date',
  ];

  static const _monthNames = [
    'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december',
  ];

  /// Reads the date formats a clinic spreadsheet realistically contains
  /// into a date-only value, or null if [raw] isn't a recognisable date:
  ///  - `25/09/2026`, `25-09-2026`, `25.09.2026`, `5/9/2026` — day first
  ///    (this is an Indian clinic; `5/9/2026` is 5 September)
  ///  - `2026-09-25` (also with a trailing time, which is ignored)
  ///  - `25 Sep 2026`, `25 September 2026`, `25-Sep-2026`
  ///  - an Excel serial number such as `46290` (a date cell that lost its
  ///    date formatting, e.g. through a paste or a CSV round trip)
  /// Impossible dates (31/02/2026) and years outside 2000–2100 (almost
  /// certainly typos) are rejected.
  static DateTime? parseExpectedArrivalDate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final ymd = _isoParts(text) ??
        _dayFirstNumericParts(text) ??
        _dayMonthNameParts(text) ??
        _excelSerialParts(text);
    if (ymd == null) return null;

    final (year, month, day) = ymd;
    if (year < 2000 || year > 2100 || month < 1 || month > 12 || day < 1) {
      return null;
    }
    final date = DateTime(year, month, day);
    // DateTime silently rolls 31 Feb over into March — reject that instead.
    if (date.year != year || date.month != month || date.day != day) return null;
    return date;
  }

  static (int, int, int)? _isoParts(String text) {
    final m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})(?:[T ].*)?$').firstMatch(text);
    if (m == null) return null;
    return (int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  }

  static (int, int, int)? _dayFirstNumericParts(String text) {
    final m = RegExp(r'^(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})$').firstMatch(text);
    if (m == null) return null;
    return (int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
  }

  static (int, int, int)? _dayMonthNameParts(String text) {
    final m = RegExp(r'^(\d{1,2})[\s\-/.,]*([A-Za-z]{3,9})\.?[\s\-/.,]*(\d{4})$')
        .firstMatch(text);
    if (m == null) return null;
    final word = m[2]!.toLowerCase();
    final monthIndex = _monthNames.indexWhere((name) => name.startsWith(word));
    if (monthIndex == -1) return null;
    return (int.parse(m[3]!), monthIndex + 1, int.parse(m[1]!));
  }

  static (int, int, int)? _excelSerialParts(String text) {
    if (!RegExp(r'^\d{5}$').hasMatch(text)) return null;
    final serial = int.parse(text);
    if (serial < 36526 || serial > 73415) return null; // 2000-01-01 .. 2100-01-01
    // Excel's day 1 is 1900-01-01, with its well-known phantom 1900-02-29,
    // so for any date after Feb 1900 the epoch is 1899-12-30.
    final date = DateTime.utc(1899, 12, 30).add(Duration(days: serial));
    return (date.year, date.month, date.day);
  }

  /// A real Excel date cell arrives as a DateCellValue/DateTimeCellValue,
  /// not text — turn it into the ISO date the shared row classifier reads,
  /// using the cell's own calendar date (no timezone conversion).
  static String _excelCellText(CellValue? value) {
    String ymd(int y, int m, int d) =>
        '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    return switch (value) {
      null => '',
      DateCellValue(:final year, :final month, :final day) => ymd(year, month, day),
      DateTimeCellValue(:final year, :final month, :final day) => ymd(year, month, day),
      _ => value.toString().trim(),
    };
  }

  ParsedImport parse(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      throw HeaderMappingException('The file has no sheets.');
    }
    final sheet = excel.tables[excel.tables.keys.first]!;
    if (sheet.maxRows == 0) {
      throw HeaderMappingException('The sheet is empty.');
    }

    final rows = sheet.rows
        .map((cells) => cells.map((c) => _excelCellText(c?.value)).toList())
        .toList();
    return _classify(rows);
  }

  ParsedImport parseCsv(String content) {
    final decoded = Csv().decode(content);
    final rows = decoded
        .map((row) => row.map((c) => c?.toString().trim() ?? '').toList())
        .toList();
    if (rows.isEmpty) {
      throw HeaderMappingException('The file is empty.');
    }
    return _classify(rows);
  }

  ParsedImport _classify(List<List<String>> rows) {
    final headerRow = rows.first;
    final headerIndex = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final value = headerRow[i].trim().toLowerCase();
      if (value.isNotEmpty) headerIndex[value] = i;
    }

    final nameCol = _findColumn(headerIndex, _nameAliases);
    final phoneCol = _findColumn(headerIndex, _phoneAliases);
    if (nameCol == null || phoneCol == null) {
      throw HeaderMappingException(
        'Could not find required columns. The file needs a Name column '
        '(e.g. "Name") and a Phone column (e.g. "Phone" or "Mobile").',
      );
    }
    final addressCol = _findColumn(headerIndex, _addressAliases);
    final concernCol = _findColumn(headerIndex, _concernAliases);
    final expectedArrivalCol = _findColumn(headerIndex, _expectedArrivalAliases);

    final valid = <ValidRow>[];
    final duplicatesInFile = <DuplicateRow>[];
    final invalid = <InvalidRow>[];
    var totalDataRows = 0;
    final seenPhonesInFile =
        <String, int>{}; // normalized phone -> first row number

    for (var r = 1; r < rows.length; r++) {
      final cells = rows[r];
      final isBlank = cells.every((c) => c.isEmpty);
      if (isBlank) continue;

      totalDataRows++;
      final rawExpectedArrival =
          expectedArrivalCol != null ? _cell(cells, expectedArrivalCol) : '';
      final row = ImportRow(
        rowNumber: r + 1,
        rawName: _cell(cells, nameCol),
        rawPhone: _cell(cells, phoneCol),
        address: addressCol != null ? _cell(cells, addressCol) : '',
        concern: concernCol != null ? _cell(cells, concernCol) : '',
        rawExpectedArrival: rawExpectedArrival,
        expectedArrivalDate: rawExpectedArrival.isEmpty
            ? null
            : parseExpectedArrivalDate(rawExpectedArrival),
      );

      if (row.rawName.isEmpty) {
        invalid.add(InvalidRow(row, RowIssue.missingName));
        continue;
      }
      final normalized = PhoneUtils.normalizeIndianMobile(row.rawPhone);
      if (normalized == null) {
        invalid.add(InvalidRow(row, RowIssue.invalidPhone));
        continue;
      }
      // A filled-in date that can't be read is rejected, not dropped: the
      // expected arrival date drives Follow-Up, so losing it silently would
      // quietly hide the lead. A blank cell is fine (imports without one).
      if (rawExpectedArrival.isNotEmpty && row.expectedArrivalDate == null) {
        invalid.add(InvalidRow(row, RowIssue.invalidExpectedArrivalDate));
        continue;
      }

      final firstSeenAt = seenPhonesInFile[normalized];
      if (firstSeenAt != null) {
        duplicatesInFile.add(DuplicateRow(row, normalized, firstSeenAt));
        continue;
      }
      seenPhonesInFile[normalized] = row.rowNumber;
      valid.add(ValidRow(row, normalized));
    }

    return ParsedImport(
      valid: valid,
      duplicatesInFile: duplicatesInFile,
      invalid: invalid,
      totalDataRows: totalDataRows,
    );
  }

  int? _findColumn(Map<String, int> headerIndex, List<String> aliases) {
    for (final alias in aliases) {
      final idx = headerIndex[alias];
      if (idx != null) return idx;
    }
    return null;
  }

  String _cell(List<String> cells, int index) {
    if (index >= cells.length) return '';
    return cells[index].trim();
  }

  /// Builds a minimal, real .xlsx template — the exact header row this
  /// parser expects, plus one filled example row — for the "Download
  /// Template" action. Not a static asset: generated here so it can never
  /// drift out of sync with the columns [_classify] actually reads.
  Uint8List buildTemplateBytes({DateTime? now}) {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet()!;
    excel.appendRow(sheetName, [
      TextCellValue('Name'),
      TextCellValue('Phone'),
      TextCellValue('Expected Arrival Date'),
      TextCellValue('Address'),
      TextCellValue('Concern'),
    ]);
    // The example date is a week from "today" (in DD/MM/YYYY, the format
    // this parser is documented to read), so importing the template as-is
    // never produces an already-overdue lead.
    final example = (now ?? DateTime.now()).add(const Duration(days: 7));
    final exampleDate = '${example.day.toString().padLeft(2, '0')}/'
        '${example.month.toString().padLeft(2, '0')}/${example.year}';
    excel.appendRow(sheetName, [
      TextCellValue('Priya Menon'),
      TextCellValue('9876543210'),
      TextCellValue(exampleDate),
      TextCellValue('Kochi'),
      TextCellValue('Laser hair reduction enquiry'),
    ]);
    return Uint8List.fromList(excel.encode()!);
  }
}

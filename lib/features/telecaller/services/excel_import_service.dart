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

  ImportRow({
    required this.rowNumber,
    required this.rawName,
    required this.rawPhone,
    required this.address,
    required this.concern,
  });
}

enum RowIssue { missingName, invalidPhone }

class InvalidRow {
  final ImportRow row;
  final RowIssue issue;
  InvalidRow(this.row, this.issue);

  String get reason => switch (issue) {
    RowIssue.missingName => 'Missing name',
    RowIssue.invalidPhone => 'Invalid phone number: "${row.rawPhone}"',
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
/// separately per [ValidRow] — see TelecallerViewModel.importLeads).
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
/// actually call out for a converted lead. A "Telecaller"/"Agent" column,
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
        .map(
          (cells) =>
              cells.map((c) => c?.value?.toString().trim() ?? '').toList(),
        )
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
      final row = ImportRow(
        rowNumber: r + 1,
        rawName: _cell(cells, nameCol),
        rawPhone: _cell(cells, phoneCol),
        address: addressCol != null ? _cell(cells, addressCol) : '',
        concern: concernCol != null ? _cell(cells, concernCol) : '',
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
  Uint8List buildTemplateBytes() {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet()!;
    excel.appendRow(sheetName, [
      TextCellValue('Name'),
      TextCellValue('Phone'),
      TextCellValue('Address'),
      TextCellValue('Concern'),
    ]);
    excel.appendRow(sheetName, [
      TextCellValue('Priya Menon'),
      TextCellValue('9876543210'),
      TextCellValue('Kochi'),
      TextCellValue('Laser hair reduction enquiry'),
    ]);
    return Uint8List.fromList(excel.encode()!);
  }
}

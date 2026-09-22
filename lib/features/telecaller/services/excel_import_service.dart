import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../../../core/utils/phone_utils.dart';

/// One row read from the uploaded sheet, before it's checked against the
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

/// Result of reading + locally validating a sheet, before any database
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

/// Reads converted-lead rows from an uploaded .xlsx file.
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
  static const _phoneAliases = ['phone', 'mobile', 'phone number', 'mobile number'];
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

    final headerRow = sheet.rows.first;
    final headerIndex = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final value = headerRow[i]?.value?.toString().trim().toLowerCase();
      if (value != null && value.isNotEmpty) headerIndex[value] = i;
    }

    final nameCol = _findColumn(headerIndex, _nameAliases);
    final phoneCol = _findColumn(headerIndex, _phoneAliases);
    if (nameCol == null || phoneCol == null) {
      throw HeaderMappingException(
        'Could not find required columns. The sheet needs a Name column '
        '(e.g. "Name") and a Phone column (e.g. "Phone" or "Mobile").',
      );
    }
    final addressCol = _findColumn(headerIndex, _addressAliases);
    final concernCol = _findColumn(headerIndex, _concernAliases);

    final valid = <ValidRow>[];
    final duplicatesInFile = <DuplicateRow>[];
    final invalid = <InvalidRow>[];
    var totalDataRows = 0;
    final seenPhonesInFile = <String, int>{}; // normalized phone -> first row number

    for (var r = 1; r < sheet.rows.length; r++) {
      final cells = sheet.rows[r];
      final isBlank = cells.every((c) => (c?.value?.toString().trim() ?? '').isEmpty);
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

  String _cell(List<Data?> cells, int index) {
    if (index >= cells.length) return '';
    return cells[index]?.value?.toString().trim() ?? '';
  }
}

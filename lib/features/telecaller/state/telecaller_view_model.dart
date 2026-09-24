import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/utils/phone_utils.dart';
import '../models/telecaller_lead.dart';
import '../repositories/telecaller_lead_repository.dart';
import '../services/excel_import_service.dart';

class AddLeadResult {
  final bool success;
  final String? errorMessage;
  const AddLeadResult._(this.success, this.errorMessage);
  const AddLeadResult.ok() : this._(true, null);
  const AddLeadResult.error(String message) : this._(false, message);
}

class RejectedImportRow {
  final int rowNumber;
  final String name;
  final String rawPhone;
  final String reason;
  RejectedImportRow(this.rowNumber, this.name, this.rawPhone, this.reason);
}

class ImportSummary {
  final int totalRows;
  final int imported;
  final List<RejectedImportRow> duplicates;
  final List<RejectedImportRow> invalid;

  ImportSummary({
    required this.totalRows,
    required this.imported,
    required this.duplicates,
    required this.invalid,
  });
}

/// A file that has been read, validated and duplicate-checked but NOT yet
/// saved — what the user reviews and confirms before anything is written.
class ImportPreview {
  final int totalRows;
  /// The rows that will be created if the user confirms.
  final List<ValidRow> toCreate;
  /// Rows that will be skipped because the lead already exists (in the file
  /// or in the database).
  final List<RejectedImportRow> duplicates;
  /// Rows that will be skipped because they aren't valid.
  final List<RejectedImportRow> invalid;

  ImportPreview({
    required this.totalRows,
    required this.toCreate,
    required this.duplicates,
    required this.invalid,
  });

  /// Leads that will import without an expected arrival date — they won't
  /// appear in Follow-Up until one is set, so the review step calls them out.
  int get withoutExpectedArrivalCount =>
      toCreate.where((v) => v.row.expectedArrivalDate == null).length;
}

/// State for the Telecaller module only — deliberately not the shared
/// Admin AppViewModel, so this feature stays isolated from Admin/Doctor/HR
/// code as required by this task's scope.
class TelecallerViewModel extends ChangeNotifier {
  TelecallerViewModel(this._repo);

  final TelecallerLeadRepository _repo;

  List<TelecallerLead> _leads = [];
  bool _isLoading = false;
  String? _loadError;

  List<TelecallerLead> get leads => _leads;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;

  int get totalLeadsCount => _leads.length;

  int get leadsAddedTodayCount {
    final now = DateTime.now();
    return _leads.where((l) {
      final c = l.created;
      return c.year == now.year && c.month == now.month && c.day == now.day;
    }).length;
  }

  Future<void> loadLeads() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      _leads = await _repo.listMine();
    } catch (e) {
      _loadError = 'Could not load leads. Check your connection and try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AddLeadResult> addLead({
    required String name,
    required String rawPhone,
    String address = '',
    String concern = '',
    DateTime? expectedArrivalDate,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const AddLeadResult.error('Name is required.');
    }

    final normalizedPhone = PhoneUtils.normalizeIndianMobile(rawPhone);
    if (normalizedPhone == null) {
      return const AddLeadResult.error(
        'Enter a valid 10-digit Indian mobile number.',
      );
    }

    try {
      final lead = await _repo.create(
        name: trimmedName,
        normalizedPhone: normalizedPhone,
        address: address.trim(),
        concern: concern.trim(),
        expectedArrivalDate: expectedArrivalDate,
      );
      _leads = [lead, ..._leads];
      notifyListeners();
      return const AddLeadResult.ok();
    } on DuplicateLeadException {
      return const AddLeadResult.error(
        'A lead with this phone number already exists in your list.',
      );
    } catch (e) {
      return const AddLeadResult.error('Could not save the lead. Please try again.');
    }
  }

  /// Edits an existing lead's own details (name/phone/address/concern/
  /// expected arrival date). Never touches conversion status or
  /// attribution — that's Admin's conversion workflow, not this form.
  Future<AddLeadResult> updateLead({
    required String id,
    required String name,
    required String rawPhone,
    String address = '',
    String concern = '',
    DateTime? expectedArrivalDate,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const AddLeadResult.error('Name is required.');
    }

    final normalizedPhone = PhoneUtils.normalizeIndianMobile(rawPhone);
    if (normalizedPhone == null) {
      return const AddLeadResult.error(
        'Enter a valid 10-digit Indian mobile number.',
      );
    }

    try {
      final updated = await _repo.update(
        id: id,
        name: trimmedName,
        normalizedPhone: normalizedPhone,
        address: address.trim(),
        concern: concern.trim(),
        expectedArrivalDate: expectedArrivalDate,
      );
      _leads = [for (final l in _leads) if (l.id == updated.id) updated else l];
      notifyListeners();
      return const AddLeadResult.ok();
    } on DuplicateLeadException {
      return const AddLeadResult.error(
        'A lead with this phone number already exists in your list.',
      );
    } catch (e) {
      return const AddLeadResult.error('Could not update the lead. Please try again.');
    }
  }

  /// Step 1 of an import: reads [bytes] as either an .xlsx or .csv file (per
  /// [isCsv]), validates every row and checks for duplicates already in the
  /// database — and saves NOTHING. The result is what the user reviews
  /// before confirming; only [confirmImport] writes anything. Throws
  /// [HeaderMappingException] if the columns can't be understood at all
  /// (caller should show that as a blocking error before any row-level
  /// preview makes sense).
  Future<ImportPreview> previewImport(Uint8List bytes, {bool isCsv = false}) async {
    final parsed = isCsv
        ? ExcelImportService().parseCsv(utf8.decode(bytes, allowMalformed: true))
        : ExcelImportService().parse(bytes);

    final candidatePhones = parsed.valid.map((v) => v.normalizedPhone).toSet();
    final alreadyInDb = await _repo.findExistingPhones(candidatePhones);

    final toCreate = <ValidRow>[];
    final duplicates = <RejectedImportRow>[
      for (final d in parsed.duplicatesInFile)
        RejectedImportRow(
          d.row.rowNumber,
          d.row.rawName,
          d.row.rawPhone,
          'Duplicate of row ${d.duplicateOfRowNumber} in this file',
        ),
    ];

    for (final v in parsed.valid) {
      if (alreadyInDb.contains(v.normalizedPhone)) {
        duplicates.add(RejectedImportRow(
          v.row.rowNumber,
          v.row.rawName,
          v.row.rawPhone,
          'Already exists in your lead list',
        ));
      } else {
        toCreate.add(v);
      }
    }

    final invalid = <RejectedImportRow>[
      for (final inv in parsed.invalid)
        RejectedImportRow(inv.row.rowNumber, inv.row.rawName, inv.row.rawPhone, inv.reason),
    ];

    return ImportPreview(
      totalRows: parsed.totalDataRows,
      toCreate: toCreate,
      duplicates: duplicates,
      invalid: invalid,
    );
  }

  /// Step 2 of an import: actually saves the rows the user confirmed in a
  /// [previewImport] result.
  Future<ImportSummary> confirmImport(ImportPreview preview) async {
    final duplicates = [...preview.duplicates];
    final invalid = [...preview.invalid];

    var importedCount = 0;
    final newlyCreated = <TelecallerLead>[];
    for (final v in preview.toCreate) {
      try {
        final lead = await _repo.create(
          name: v.row.rawName,
          normalizedPhone: v.normalizedPhone,
          address: v.row.address,
          concern: v.row.concern,
          expectedArrivalDate: v.row.expectedArrivalDate,
        );
        newlyCreated.add(lead);
        importedCount++;
      } on DuplicateLeadException {
        // Race: created by another request between our batch check and now.
        duplicates.add(RejectedImportRow(
          v.row.rowNumber,
          v.row.rawName,
          v.row.rawPhone,
          'Already exists in your lead list',
        ));
      } catch (e) {
        invalid.add(RejectedImportRow(
          v.row.rowNumber,
          v.row.rawName,
          v.row.rawPhone,
          'Could not be saved',
        ));
      }
    }

    if (newlyCreated.isNotEmpty) {
      _leads = [...newlyCreated, ..._leads];
      notifyListeners();
    }

    return ImportSummary(
      totalRows: preview.totalRows,
      imported: importedCount,
      duplicates: duplicates,
      invalid: invalid,
    );
  }

  /// Preview + confirm in one go, with no review step in between.
  Future<ImportSummary> importLeads(Uint8List bytes, {bool isCsv = false}) async {
    return confirmImport(await previewImport(bytes, isCsv: isCsv));
  }
}

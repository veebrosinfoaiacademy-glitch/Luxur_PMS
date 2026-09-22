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

  /// Parses [bytes] as either an .xlsx or .csv file (per [isCsv]) and
  /// imports the valid, non-duplicate rows. Throws [HeaderMappingException]
  /// if the columns can't be understood at all (caller should show that as
  /// a blocking error before any row-level summary makes sense).
  Future<ImportSummary> importLeads(Uint8List bytes, {bool isCsv = false}) async {
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

    var importedCount = 0;
    final newlyCreated = <TelecallerLead>[];
    for (final v in toCreate) {
      try {
        final lead = await _repo.create(
          name: v.row.rawName,
          normalizedPhone: v.normalizedPhone,
          address: v.row.address,
          concern: v.row.concern,
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
      totalRows: parsed.totalDataRows,
      imported: importedCount,
      duplicates: duplicates,
      invalid: invalid,
    );
  }
}

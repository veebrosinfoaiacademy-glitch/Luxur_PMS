import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/phone_utils.dart';
import '../services/excel_import_service.dart';
import '../state/telecaller_view_model.dart';
import '../widgets/telecaller_profile_menu.dart';

/// A file the user chose, already read into memory.
class ImportFileSelection {
  final String name;
  final Uint8List bytes;
  final bool isCsv;
  const ImportFileSelection({
    required this.name,
    required this.bytes,
    required this.isCsv,
  });
}

typedef ImportFilePicker = Future<ImportFileSelection?> Function();

/// Month spelled out on purpose: the review step is where a wrongly-read
/// date (e.g. 5/9 read as 5 Sep vs 9 May) should be spotted, so it must
/// never itself be ambiguous.
final _previewDateFormat = DateFormat('d MMM yyyy');

const double _previewRowHeight = 40;
const double _previewMaxHeight = 320;

class ImportLeadsView extends StatefulWidget {
  final TelecallerViewModel viewModel;
  final AuthService? authService;

  /// Stands in for the native file dialog, which a widget test can't drive.
  /// Null in the real app, which then uses the platform file picker.
  @visibleForTesting
  final ImportFilePicker? pickFile;

  const ImportLeadsView({
    super.key,
    required this.viewModel,
    this.authService,
    this.pickFile,
  });

  @override
  State<ImportLeadsView> createState() => _ImportLeadsViewState();
}

/// idle → reading (file chosen, being parsed + checked) → preview (nothing
/// saved yet; the user reviews) → importing (they confirmed) → done.
enum _ImportStage { idle, reading, preview, importing, done }

class _ImportLeadsViewState extends State<ImportLeadsView> {
  _ImportStage _stage = _ImportStage.idle;
  String? _pickedFileName;
  String? _blockingError;
  ImportPreview? _preview;
  ImportSummary? _summary;

  static Future<ImportFileSelection?> _pickWithFilePicker() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
    );
    if (result.isEmpty) return null;

    final file = result.first;
    return ImportFileSelection(
      name: file.name,
      bytes: await file.readAsBytes(),
      isCsv: file.extension?.toLowerCase() == 'csv',
    );
  }

  Future<void> _pickAndPreview() async {
    setState(() {
      _blockingError = null;
      _summary = null;
      _preview = null;
    });

    final selection = await (widget.pickFile ?? _pickWithFilePicker)();
    if (selection == null || !mounted) return;

    setState(() {
      _pickedFileName = selection.name;
      _stage = _ImportStage.reading;
    });

    try {
      // Reads and validates the file and checks for existing leads — but
      // saves nothing. Saving only happens in _confirmImport.
      final preview = await widget.viewModel.previewImport(
        selection.bytes,
        isCsv: selection.isCsv,
      );
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _stage = _ImportStage.preview;
      });
    } on HeaderMappingException catch (e) {
      if (!mounted) return;
      setState(() {
        _blockingError = e.message;
        _stage = _ImportStage.idle;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _blockingError = 'Could not read this file. Make sure it is a valid .xlsx or .csv file.';
        _stage = _ImportStage.idle;
      });
    }
  }

  Future<void> _confirmImport() async {
    final preview = _preview;
    if (preview == null) return;

    setState(() {
      _blockingError = null;
      _stage = _ImportStage.importing;
    });
    try {
      final summary = await widget.viewModel.confirmImport(preview);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _preview = null;
        _stage = _ImportStage.done;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _blockingError = 'Could not complete the import. Please try again.';
        _stage = _ImportStage.preview;
      });
    }
  }

  void _reset() {
    setState(() {
      _stage = _ImportStage.idle;
      _pickedFileName = null;
      _blockingError = null;
      _preview = null;
      _summary = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Import Patients', style: AppTypography.headingDisplay),
                        const SizedBox(height: 6),
                        Text(
                          'Upload an Excel (.xlsx) or CSV file with your converted leads. '
                          'Required columns: Name and Phone. Expected Arrival Date '
                          '(DD/MM/YYYY), Address and Concern are optional. '
                          "You'll review everything before it is saved. "
                          'A Telecaller/Agent column, if present, is ignored — imported leads '
                          'are always attributed to your account.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.authService != null) ...[
                    const SizedBox(width: 16),
                    TelecallerProfileMenu(authService: widget.authService!),
                  ],
                ],
              ),
              const SizedBox(height: 28),

              // Upload Card — only until a file has been read; from then on the
              // review (and later the summary) takes its place.
              if (_stage == _ImportStage.idle || _stage == _ImportStage.reading)
                _buildUploadCard(),

              // Review before importing (nothing is saved yet)
              if (_preview != null) _buildPreview(_preview!),

              // Blocking Error Banner
              if (_blockingError != null) ...[
                const SizedBox(height: 18),
                Container(
                  key: const Key('import_blocking_error'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFEE2E2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _blockingError!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Import Summary
              if (_summary != null) ...[
                const SizedBox(height: 24),
                _buildSummary(_summary!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return Container(
      key: const Key('import_upload_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF5FF).withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFDDD6FE),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cloud Upload Icon Container
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDDD6FE), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5E35B1).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.cloud_upload_outlined,
                  size: 28,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // File Name / Status
            if (_pickedFileName != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD8B4FE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _pickedFileName!,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Text(
                    'No file selected',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose an Excel (.xlsx) or CSV (.csv) file to import',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 22),

            // Action Button
            ElevatedButton.icon(
              key: const Key('import_pick_file_button'),
              onPressed: _stage == _ImportStage.reading ? null : _pickAndPreview,
              icon: _stage == _ImportStage.reading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.folder_open_outlined, size: 18),
              label: Text(
                _stage == _ImportStage.reading
                    ? 'Reading file...'
                    : 'Choose Excel / CSV File',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The confirmation step: what was read from the file, what will and
  /// won't be imported and why — with nothing saved until the user confirms.
  Widget _buildPreview(ImportPreview preview) {
    final isImporting = _stage == _ImportStage.importing;
    final count = preview.toCreate.length;
    final withoutDate = preview.withoutExpectedArrivalCount;

    return Container(
      key: const Key('import_preview'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Review before importing',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 12),
              if (_pickedFileName != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD8B4FE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _pickedFileName!,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Nothing has been saved yet. Check the leads below, then confirm to import them.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              _summaryCard(
                'Total rows',
                '${preview.totalRows}',
                const Color(0xFFF8FAFC),
                const Color(0xFF334155),
                const Color(0xFFE2E8F0),
              ),
              const SizedBox(width: 12),
              _summaryCard(
                'Ready to import',
                '$count',
                const Color(0xFFECFDF5),
                const Color(0xFF059669),
                const Color(0xFFA7F3D0),
              ),
              const SizedBox(width: 12),
              _summaryCard(
                'Duplicates (skipped)',
                '${preview.duplicates.length}',
                const Color(0xFFFEF3C7),
                const Color(0xFFD97706),
                const Color(0xFFFDE68A),
              ),
              const SizedBox(width: 12),
              _summaryCard(
                'Invalid (skipped)',
                '${preview.invalid.length}',
                const Color(0xFFFEF2F2),
                const Color(0xFFDC2626),
                const Color(0xFFFECACA),
              ),
            ],
          ),

          const SizedBox(height: 22),
          if (count > 0) ...[
            Text(
              'Leads to import',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            _previewRowsTable(preview),
            if (withoutDate > 0) ...[
              const SizedBox(height: 10),
              Container(
                key: const Key('import_preview_no_date_note'),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        withoutDate == 1
                            ? '1 lead has no expected arrival date, so it won\'t appear in '
                                'Follow-Up Required until one is added.'
                            : '$withoutDate leads have no expected arrival date, so they won\'t '
                                'appear in Follow-Up Required until one is added.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else
            Container(
              key: const Key('import_preview_nothing_to_import'),
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'There are no new, valid leads to import from this file.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

          if (preview.duplicates.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              'Duplicates — will be skipped',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFB45309),
              ),
            ),
            const SizedBox(height: 8),
            ..._rejectedRows(preview.duplicates, key: 'import_preview_duplicate_rows'),
          ],

          if (preview.invalid.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              'Invalid rows — will be skipped',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFB91C1C),
              ),
            ),
            const SizedBox(height: 8),
            ..._rejectedRows(preview.invalid, key: 'import_preview_invalid_rows'),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              OutlinedButton(
                key: const Key('import_cancel_button'),
                onPressed: isImporting ? null : _reset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: Color(0xFFDDD6FE)),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                key: const Key('import_confirm_button'),
                onPressed: (count == 0 || isImporting) ? null : _confirmImport,
                icon: isImporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  isImporting
                      ? 'Importing...'
                      : 'Confirm & Import $count Lead${count == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A read-only table of every lead that will be created. Lazily built and
  /// height-capped (scrolls inside itself) so a file with hundreds of rows
  /// neither stretches the page nor builds every row up front.
  Widget _previewRowsTable(ImportPreview preview) {
    final rows = preview.toCreate;
    final listHeight = math.min(rows.length * _previewRowHeight, _previewMaxHeight);

    Widget headerCell(String text, int flex) => Expanded(
          flex: flex,
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: const Color(0xFF64748B),
            ),
          ),
        );

    Widget cell(String text, int flex, {bool muted = false}) => Expanded(
          flex: flex,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: muted ? const Color(0xFF94A3B8) : const Color(0xFF334155),
              ),
            ),
          ),
        );

    return Container(
      key: const Key('import_preview_rows'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                headerCell('ROW', 1),
                headerCell('NAME', 3),
                headerCell('PHONE', 3),
                headerCell('EXPECTED ARRIVAL', 3),
                headerCell('ADDRESS', 3),
                headerCell('CONCERN', 3),
              ],
            ),
          ),
          SizedBox(
            height: listHeight,
            child: ListView.builder(
              itemCount: rows.length,
              itemExtent: _previewRowHeight,
              itemBuilder: (context, i) {
                final v = rows[i];
                final date = v.row.expectedArrivalDate;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    children: [
                      cell('${v.row.rowNumber}', 1, muted: true),
                      cell(v.row.rawName, 3),
                      cell(PhoneUtils.display(v.normalizedPhone), 3),
                      cell(
                        date == null ? '—' : _previewDateFormat.format(date),
                        3,
                        muted: date == null,
                      ),
                      cell(v.row.address.isEmpty ? '—' : v.row.address, 3, muted: v.row.address.isEmpty),
                      cell(v.row.concern.isEmpty ? '—' : v.row.concern, 3, muted: v.row.concern.isEmpty),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(ImportSummary summary) {
    return Container(
      key: const Key('import_summary'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF059669),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Import Summary',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4 Metric cards
          Row(
            children: [
              _summaryCard(
                'Total rows',
                '${summary.totalRows}',
                const Color(0xFFF8FAFC),
                const Color(0xFF334155),
                const Color(0xFFE2E8F0),
              ),
              const SizedBox(width: 12),
              _summaryCard(
                'Imported',
                '${summary.imported}',
                const Color(0xFFECFDF5),
                const Color(0xFF059669),
                const Color(0xFFA7F3D0),
              ),
              const SizedBox(width: 12),
              _summaryCard(
                'Duplicates',
                '${summary.duplicates.length}',
                const Color(0xFFFEF3C7),
                const Color(0xFFD97706),
                const Color(0xFFFDE68A),
              ),
              const SizedBox(width: 12),
              _summaryCard(
                'Invalid',
                '${summary.invalid.length}',
                const Color(0xFFFEF2F2),
                const Color(0xFFDC2626),
                const Color(0xFFFECACA),
              ),
            ],
          ),

          if (summary.duplicates.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              'Duplicates',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFB45309),
              ),
            ),
            const SizedBox(height: 8),
            ..._rejectedRows(summary.duplicates, key: 'import_duplicate_rows'),
          ],

          if (summary.invalid.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              'Invalid rows',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFB91C1C),
              ),
            ),
            const SizedBox(height: 8),
            ..._rejectedRows(summary.invalid, key: 'import_invalid_rows'),
          ],

          const SizedBox(height: 24),
          OutlinedButton.icon(
            key: const Key('import_another_file_button'),
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Import another file'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: Color(0xFFDDD6FE)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    String label,
    String value,
    Color bg,
    Color textCol,
    Color borderCol,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderCol),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textCol,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: textCol.withValues(alpha: 0.85),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _rejectedRows(List<RejectedImportRow> rows, {required String key}) {
    return [
      Container(
        key: Key(key),
        constraints: const BoxConstraints(maxHeight: 180),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows
                .map((r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Row ${r.rowNumber}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${r.name.isEmpty ? '(no name)' : r.name}: ${r.reason}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    ];
  }
}

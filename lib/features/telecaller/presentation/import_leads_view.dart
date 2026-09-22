import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../services/excel_import_service.dart';
import '../state/telecaller_view_model.dart';

class ImportLeadsView extends StatefulWidget {
  final TelecallerViewModel viewModel;

  const ImportLeadsView({super.key, required this.viewModel});

  @override
  State<ImportLeadsView> createState() => _ImportLeadsViewState();
}

enum _ImportStage { idle, importing, done }

class _ImportLeadsViewState extends State<ImportLeadsView> {
  _ImportStage _stage = _ImportStage.idle;
  String? _pickedFileName;
  String? _blockingError;
  ImportSummary? _summary;

  Future<void> _pickAndImport() async {
    setState(() {
      _blockingError = null;
      _summary = null;
    });

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result.isEmpty) return;

    final file = result.first;
    setState(() {
      _pickedFileName = file.name;
      _stage = _ImportStage.importing;
    });

    try {
      final bytes = await file.readAsBytes();
      final summary = await widget.viewModel.importLeads(bytes);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _stage = _ImportStage.done;
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
        _blockingError = 'Could not read this file. Make sure it is a valid .xlsx spreadsheet.';
        _stage = _ImportStage.idle;
      });
    }
  }

  void _reset() {
    setState(() {
      _stage = _ImportStage.idle;
      _pickedFileName = null;
      _blockingError = null;
      _summary = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Import Converted Leads', style: AppTypography.headingDisplay),
            const SizedBox(height: 4),
            Text(
              'Upload an .xlsx file with your converted leads. Required columns: '
              'Name and Phone. Address and Concern are optional. A Telecaller/Agent '
              'column, if present, is ignored — imported leads are always attributed '
              'to your account.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            if (_stage != _ImportStage.done) _buildUploadCard(),
            if (_blockingError != null) ...[
              const SizedBox(height: 16),
              Container(
                key: const Key('import_blocking_error'),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.statusUrgentBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _blockingError!,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.statusUrgent),
                ),
              ),
            ],
            if (_summary != null) ...[
              const SizedBox(height: 24),
              _buildSummary(_summary!),
            ],
          ],
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(Icons.upload_file_outlined, size: 36, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            _pickedFileName ?? 'No file selected',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            key: const Key('import_pick_file_button'),
            onPressed: _stage == _ImportStage.importing ? null : _pickAndImport,
            icon: _stage == _ImportStage.importing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.folder_open_outlined, size: 18),
            label: Text(_stage == _ImportStage.importing ? 'Importing...' : 'Choose .xlsx File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Import Summary', style: AppTypography.headingSmall),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryTile('Total rows', '${summary.totalRows}', AppColors.textPrimary),
              _summaryTile('Imported', '${summary.imported}', AppColors.statusUpcoming),
              _summaryTile('Duplicates', '${summary.duplicates.length}', AppColors.statusDueSoon),
              _summaryTile('Invalid', '${summary.invalid.length}', AppColors.statusUrgent),
            ],
          ),
          if (summary.duplicates.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Duplicates', style: AppTypography.labelBold),
            const SizedBox(height: 8),
            ..._rejectedRows(summary.duplicates, key: 'import_duplicate_rows'),
          ],
          if (summary.invalid.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Invalid rows', style: AppTypography.labelBold),
            const SizedBox(height: 8),
            ..._rejectedRows(summary.invalid, key: 'import_invalid_rows'),
          ],
          const SizedBox(height: 20),
          OutlinedButton(
            key: const Key('import_another_file_button'),
            onPressed: _reset,
            child: const Text('Import another file'),
          ),
        ],
      ),
    );
  }

  List<Widget> _rejectedRows(List<RejectedImportRow> rows, {required String key}) {
    return [
      Container(
        key: Key(key),
        constraints: const BoxConstraints(maxHeight: 200),
        child: SingleChildScrollView(
          child: Column(
            children: rows
                .map((r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Row ${r.rowNumber} — ${r.name.isEmpty ? '(no name)' : r.name}: ${r.reason}',
                        style: AppTypography.bodySmall,
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    ];
  }

  Widget _summaryTile(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTypography.metricValue.copyWith(fontSize: 26, color: color)),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

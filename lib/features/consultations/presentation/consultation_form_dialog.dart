import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/state/clinic_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../patients/models/patient.dart';
import '../../treatments/models/treatment_plan.dart';
import '../models/consultation.dart';

/// The consultation form. The doctor records what they saw, then chooses
/// one of two conclusions:
///
///  * Recommend Treatment — which also captures the plan, its package cost,
///    an optional session count and the first session's date; or
///  * No Treatment Required.
///
/// A consultation fee is optional on BOTH paths. The suggested product is
/// advice only and is deliberately never carried into session billing.
class ConsultationFormDialog extends StatefulWidget {
  const ConsultationFormDialog({
    super.key,
    required this.clinic,
    required this.patient,
    this.existing,
  });

  final ClinicViewModel clinic;
  final Patient patient;
  final Consultation? existing;

  static Future<void> show(
    BuildContext context,
    ClinicViewModel clinic,
    Patient patient, {
    Consultation? existing,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => ConsultationFormDialog(
        clinic: clinic,
        patient: patient,
        existing: existing,
      ),
    );
  }

  @override
  State<ConsultationFormDialog> createState() => _ConsultationFormDialogState();
}

class _ConsultationFormDialogState extends State<ConsultationFormDialog> {
  late final _reasonController =
      TextEditingController(text: widget.existing?.reasonForVisit ?? '');
  late final _notesController = TextEditingController(text: widget.existing?.notes ?? '');
  late final _productController =
      TextEditingController(text: widget.existing?.suggestedProduct ?? '');
  final _feeController = TextEditingController();
  final _packageCostController = TextEditingController();
  final _sessionsController = TextEditingController();

  ConsultationRecommendation? _recommendation;
  bool _chargeConsultationFee = false;

  String _category = TreatmentCategory.hair;
  List<TreatmentPlan> _plans = const [];
  String? _planName;
  bool _plansLoading = false;
  DateTime? _firstSessionDate;

  final List<(String filename, List<int> bytes)> _pendingImages = [];

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    _productController.dispose();
    _feeController.dispose();
    _packageCostController.dispose();
    _sessionsController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() => _plansLoading = true);
    try {
      final plans = await widget.clinic.treatmentPlans.listActiveForCategory(_category);
      if (!mounted) return;
      setState(() {
        _plans = plans;
        // Keep the selection only if it is still offered in this category.
        _planName = plans.any((p) => p.name == _planName) ? _planName : null;
        _plansLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _plans = const [];
        _plansLoading = false;
      });
    }
  }

  Future<void> _pickImages() async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    for (final file in files) {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _pendingImages.add((file.name, bytes)));
    }
  }

  Future<void> _pickFirstSessionDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstSessionDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _firstSessionDate = picked);
  }

  /// Creates the draft if this is the first save, then keeps updating it.
  Future<Consultation> _ensureDraft() async {
    final existing = widget.existing;
    if (existing != null) {
      return widget.clinic.consultations.updateDraft(
        existing.id,
        reasonForVisit: _reasonController.text.trim(),
        notes: _notesController.text.trim(),
      );
    }
    return widget.clinic.consultations.saveDraft(
      patientId: widget.patient.id,
      reasonForVisit: _reasonController.text.trim(),
      notes: _notesController.text.trim(),
    );
  }

  Future<void> _saveNotes() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final draft = await _ensureDraft();
      await _uploadPending(draft.id);
      await widget.clinic.reloadProfile();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not save these notes. Please try again.';
      });
    }
  }

  Future<void> _uploadPending(String consultationId) async {
    if (_pendingImages.isEmpty) return;
    await widget.clinic.consultations.uploadImages(consultationId, _pendingImages);
  }

  Future<void> _complete() async {
    final recommendation = _recommendation;
    if (recommendation == null) {
      setState(() => _error = 'Choose a recommendation before completing.');
      return;
    }

    final fee = _chargeConsultationFee ? double.tryParse(_feeController.text.trim()) : null;
    if (_chargeConsultationFee && (fee == null || fee <= 0)) {
      setState(() => _error = 'Enter the consultation fee amount.');
      return;
    }

    double? packageCost;
    if (recommendation == ConsultationRecommendation.recommendTreatment) {
      if (_planName == null) {
        setState(() => _error = 'Choose a treatment plan.');
        return;
      }
      packageCost = double.tryParse(_packageCostController.text.trim());
      if (packageCost == null || packageCost <= 0) {
        setState(() => _error = 'Enter the treatment package cost.');
        return;
      }
      if (_firstSessionDate == null) {
        setState(() => _error = 'Choose the first session date.');
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final draft = await _ensureDraft();
      await _uploadPending(draft.id);

      String? treatmentId;
      if (recommendation == ConsultationRecommendation.recommendTreatment) {
        // Total sessions is optional — a package may be sold without one.
        final totalSessions = int.tryParse(_sessionsController.text.trim());
        final treatment = await widget.clinic.treatments.create(
          patientId: widget.patient.id,
          category: _category,
          packageName: _planName!,
          packageCost: packageCost!,
          sessionsTotal: totalSessions,
          consultationId: draft.id,
        );
        treatmentId = treatment.id;

        // The first session is booked by DATE only — no time slot, and no
        // doctor, so any doctor can take it.
        await widget.clinic.sessions.schedule(
          patientId: widget.patient.id,
          treatmentId: treatment.id,
          scheduledDate: _firstSessionDate!,
        );
      }

      await widget.clinic.consultations.complete(
        draft.id,
        recommendation: recommendation,
        reasonForVisit: _reasonController.text.trim(),
        notes: _notesController.text.trim(),
        consultationFee: fee,
        suggestedProduct: _productController.text.trim(),
        treatmentId: treatmentId,
      );

      await widget.clinic.reloadProfile();
      await widget.clinic.refreshDashboard();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not complete the consultation. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendsTreatment =
        _recommendation == ConsultationRecommendation.recommendTreatment;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 620,
        constraints: const BoxConstraints(maxHeight: 720),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consultation',
                      style: AppTypography.headingSmall
                          .copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${widget.patient.name} · #${widget.patient.patientCode}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5, color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Reason for Visit'),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('consultation_reason'),
                      controller: _reasonController,
                      decoration: _decoration('Why has the patient come in?'),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                    ),
                    const SizedBox(height: 14),

                    _label('Doctor’s Notes'),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('consultation_notes'),
                      controller: _notesController,
                      maxLines: 4,
                      decoration: _decoration('Examination findings and advice'),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                    ),
                    const SizedBox(height: 14),

                    _label('Images'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _pickImages,
                          icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                          label: const Text('Add Image'),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _pendingImages.isEmpty
                              ? 'No new images'
                              : '${_pendingImages.length} image(s) ready to upload',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5, color: const Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    _label('Recommendation'),
                    const SizedBox(height: 6),
                    RadioGroup<ConsultationRecommendation>(
                      groupValue: _recommendation,
                      onChanged: (v) => setState(() => _recommendation = v),
                      child: Column(
                        children: [
                          RadioListTile<ConsultationRecommendation>(
                            key: const Key('recommend_treatment'),
                            value: ConsultationRecommendation.recommendTreatment,
                            title: Text(
                              'Recommend Treatment',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                            ),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                          RadioListTile<ConsultationRecommendation>(
                            key: const Key('no_treatment_required'),
                            value: ConsultationRecommendation.noTreatmentRequired,
                            title: Text(
                              'No Treatment Required',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                            ),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ],
                      ),
                    ),

                    if (recommendsTreatment) ...[
                      const Divider(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Treatment Category'),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _category,
                                  decoration: _decoration(''),
                                  items: TreatmentCategory.all
                                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => _category = v);
                                    _loadPlans();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Treatment Plan'),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  key: const Key('treatment_plan_select'),
                                  initialValue: _planName,
                                  decoration: _decoration(
                                    _plansLoading
                                        ? 'Loading…'
                                        : _plans.isEmpty
                                            ? 'No active plans in this category'
                                            : 'Choose a plan',
                                  ),
                                  items: _plans
                                      .map((p) =>
                                          DropdownMenuItem(value: p.name, child: Text(p.name)))
                                      .toList(),
                                  onChanged: (v) => setState(() => _planName = v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Treatment Package Cost'),
                                const SizedBox(height: 6),
                                TextField(
                                  key: const Key('package_cost'),
                                  controller: _packageCostController,
                                  keyboardType: TextInputType.number,
                                  decoration: _decoration('e.g. 50000').copyWith(prefixText: '₹ '),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Total Sessions (optional)'),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _sessionsController,
                                  keyboardType: TextInputType.number,
                                  decoration: _decoration('Leave blank if open-ended'),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _label('First Session Starting Date'),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        key: const Key('first_session_date'),
                        onPressed: _busy ? null : _pickFirstSessionDate,
                        icon: const Icon(Icons.calendar_today_outlined, size: 16),
                        label: Text(
                          _firstSessionDate == null
                              ? 'Choose a date'
                              : DateFormat('d MMM yyyy').format(_firstSessionDate!),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          alignment: Alignment.centerLeft,
                          minimumSize: const Size(double.infinity, 0),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _label('Suggested Product'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _productController,
                        decoration: _decoration('Advice only — not added to any bill'),
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                      ),
                    ],

                    const Divider(height: 28),
                    // A consultation fee may be charged whether or not a
                    // treatment was recommended.
                    CheckboxListTile(
                      key: const Key('charge_consultation_fee'),
                      value: _chargeConsultationFee,
                      onChanged: (v) => setState(() => _chargeConsultationFee = v ?? false),
                      title: Text(
                        'Consultation Fees',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    if (_chargeConsultationFee) ...[
                      const SizedBox(height: 6),
                      TextField(
                        key: const Key('consultation_fee_amount'),
                        controller: _feeController,
                        keyboardType: TextInputType.number,
                        decoration: _decoration('Amount').copyWith(prefixText: '₹ '),
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                      ),
                    ],

                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        key: const Key('consultation_error'),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5, color: const Color(0xFFDC2626)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('save_notes_button'),
                    onPressed: _busy ? null : _saveNotes,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    child: Text(
                      'Save Notes',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('complete_consultation_button'),
                    onPressed: _busy ? null : _complete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Complete Consultation',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF374151),
        ),
      );

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF9CA3AF)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );
}

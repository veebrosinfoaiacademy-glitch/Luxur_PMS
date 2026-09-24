import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/state/clinic_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../billing/models/bill.dart';
import '../../patients/models/patient.dart';
import '../models/session.dart';
import '../repositories/session_repository.dart';

/// The session form.
///
/// There is no Start Session and no End Session — the patient arrives, the
/// doctor does the work, and the single closing action is "Session
/// Completed". The arrival time shown here was stamped by the server, not
/// by this device.
class SessionFormDialog extends StatefulWidget {
  const SessionFormDialog({
    super.key,
    required this.clinic,
    required this.patient,
    required this.session,
  });

  final ClinicViewModel clinic;
  final Patient patient;
  final Session session;

  static Future<void> show(
    BuildContext context,
    ClinicViewModel clinic,
    Patient patient,
    Session session,
  ) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) =>
          SessionFormDialog(clinic: clinic, patient: patient, session: session),
    );
  }

  @override
  State<SessionFormDialog> createState() => _SessionFormDialogState();
}

class _SessionFormDialogState extends State<SessionFormDialog> {
  late final _notesController = TextEditingController(text: widget.session.notes);
  final _feeController = TextEditingController();
  final _productNameController = TextEditingController();
  final _productCostController = TextEditingController();

  bool _addFees = false;
  String _paymentMethod = PaymentMethod.cash;
  final List<(String filename, List<int> bytes)> _pendingImages = [];

  bool _busy = false;
  String? _error;

  Session get _session => widget.session;
  bool get _isCompleted => _session.status == SessionStatus.completed;

  @override
  void dispose() {
    _notesController.dispose();
    _feeController.dispose();
    _productNameController.dispose();
    _productCostController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    for (final file in files) {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _pendingImages.add((file.name, bytes)));
    }
  }

  Future<void> _uploadPending() async {
    if (_pendingImages.isEmpty) return;
    await widget.clinic.sessions.uploadImages(_session.id, _pendingImages);
    _pendingImages.clear();
  }

  Future<void> _saveNotes() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _uploadPending();
      await widget.clinic.sessions
          .saveNotes(_session.id, notes: _notesController.text.trim());
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

  Future<void> _markArrived() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.clinic.markArrived(_session.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not record the arrival. Please try again.';
      });
    }
  }

  Future<void> _complete() async {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) {
      setState(() => _error = 'Record what was done before completing the session.');
      return;
    }
    if (_pendingImages.isEmpty && _session.imageFilenames.isEmpty) {
      setState(() => _error = 'Add at least one session image before completing.');
      return;
    }

    double? fee;
    if (_addFees) {
      fee = double.tryParse(_feeController.text.trim());
      if (fee == null || fee <= 0) {
        setState(() => _error = 'Enter the session fee amount.');
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _uploadPending();
      await widget.clinic.sessions.complete(_session.id, notes: notes);

      if (fee != null) {
        // Generating the bill is not taking payment — it stays unpaid
        // until Admin records "Patient Paid".
        await widget.clinic.bills.createSessionBill(
          patientId: widget.patient.id,
          sessionId: _session.id,
          treatmentId: _session.treatmentId,
          sessionFee: fee,
          productName: _productNameController.text.trim(),
          productCost: double.tryParse(_productCostController.text.trim()) ?? 0,
          paymentMethod: _paymentMethod,
        );
      }

      await widget.clinic.reloadProfile();
      await widget.clinic.refreshDashboard();
      if (!mounted) return;
      Navigator.of(context).pop();
    } on SessionCompletionRejected catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not complete the session. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 620,
        constraints: const BoxConstraints(maxHeight: 700),
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
                      'Session Form',
                      style: AppTypography.headingSmall
                          .copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${widget.patient.name} · ${DateFormat('d MMM yyyy').format(_session.scheduledDate)}',
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
                    _statusStrip(),
                    const SizedBox(height: 18),

                    _label('Session Notes'),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('session_notes'),
                      controller: _notesController,
                      maxLines: 5,
                      readOnly: _isCompleted,
                      decoration: _decoration('What was done in this session?'),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                    ),
                    const SizedBox(height: 14),

                    _label('Session Images'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Admin and Doctor may both add session images.
                        OutlinedButton.icon(
                          key: const Key('add_session_image'),
                          onPressed: _busy ? null : _pickImages,
                          icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                          label: const Text('Add Image'),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _summariseImages(),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5, color: const Color(0xFF6B7280)),
                        ),
                      ],
                    ),

                    if (!_isCompleted) ...[
                      const Divider(height: 28),
                      CheckboxListTile(
                        key: const Key('add_session_fees'),
                        value: _addFees,
                        onChanged: (v) => setState(() => _addFees = v ?? false),
                        title: Text(
                          'Add Fees',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                        ),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      ),
                      if (_addFees) ...[
                        const SizedBox(height: 6),
                        TextField(
                          key: const Key('session_fee_amount'),
                          controller: _feeController,
                          keyboardType: TextInputType.number,
                          decoration: _decoration('Session fee').copyWith(prefixText: '₹ '),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _productNameController,
                                decoration: _decoration('Product sold (optional)'),
                                style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _productCostController,
                                keyboardType: TextInputType.number,
                                decoration:
                                    _decoration('Product cost').copyWith(prefixText: '₹ '),
                                style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _paymentMethod,
                          decoration: _decoration(''),
                          items: PaymentMethod.all
                              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _paymentMethod = v);
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'The product amount is billed but never counts toward treatment progress.',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5, color: const Color(0xFF6B7280)),
                        ),
                      ],
                    ],

                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        key: const Key('session_error'),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5, color: const Color(0xFFDC2626)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _actions(),
          ],
        ),
      ),
    );
  }

  String _summariseImages() {
    final existing = _session.imageFilenames.length;
    final pending = _pendingImages.length;
    if (existing == 0 && pending == 0) return 'No images yet';
    final parts = <String>[
      if (existing > 0) '$existing saved',
      if (pending > 0) '$pending ready to upload',
    ];
    return parts.join(' · ');
  }

  Widget _statusStrip() {
    final arrivedAt = _session.arrivedAt;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statusItem('Status', _session.status.label),
          ),
          Expanded(
            child: _statusItem(
              'Patient Arrived',
              arrivedAt == null
                  ? 'Not yet'
                  : DateFormat('d MMM yyyy, h:mm a').format(arrivedAt.toLocal()),
            ),
          ),
          Expanded(
            child: _statusItem(
              'Doctor',
              _session.doctorName ?? 'Any available doctor',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF6B7280)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _actions() {
    if (_isCompleted) {
      return Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          ),
          child: const Text('Close'),
        ),
      );
    }

    // Until the patient has physically arrived, the only thing to do is
    // record that they have.
    if (_session.status != SessionStatus.arrived) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
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
              key: const Key('patient_arrived_button'),
              onPressed: _busy ? null : _markArrived,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
              ),
              child: Text(
                'Patient Arrived',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
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
            key: const Key('session_completed_button'),
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Session Completed',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
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

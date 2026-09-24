import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/directory/doctor_directory.dart';
import '../../../core/state/clinic_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../treatments/models/treatment.dart';

/// Scheduling a session.
///
/// Sessions are booked by DATE only — the clinic does not run appointment
/// time slots, and a patient may arrive at any time on the day. Choosing a
/// doctor is optional and applies to this one session: leaving it blank
/// means whichever doctor treats the patient becomes that session's doctor.
class ScheduleSessionDialog extends StatefulWidget {
  const ScheduleSessionDialog({
    super.key,
    required this.clinic,
    required this.profile,
  });

  final ClinicViewModel clinic;
  final PatientProfile profile;

  static Future<void> show(
    BuildContext context,
    ClinicViewModel clinic,
    PatientProfile profile,
  ) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => ScheduleSessionDialog(clinic: clinic, profile: profile),
    );
  }

  @override
  State<ScheduleSessionDialog> createState() => _ScheduleSessionDialogState();
}

class _ScheduleSessionDialogState extends State<ScheduleSessionDialog> {
  late final List<Treatment> _treatments =
      widget.profile.treatments.where((t) => t.isActive).toList();
  late String? _treatmentId = _treatments.isEmpty ? null : _treatments.first.id;

  DateTime? _date;
  String? _doctorId;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.clinic.loadDoctors();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _schedule() async {
    if (_treatmentId == null) {
      setState(() => _error = 'Choose the treatment this session belongs to.');
      return;
    }
    if (_date == null) {
      setState(() => _error = 'Choose the session date.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await widget.clinic.sessions.schedule(
        patientId: widget.profile.patient.id,
        treatmentId: _treatmentId!,
        scheduledDate: _date!,
        doctorId: _doctorId,
      );
      await widget.clinic.reloadProfile();
      await widget.clinic.refreshDashboard();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not schedule the session. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.clinic,
      builder: (context, _) => AlertDialog(
        title: Text(
          'Schedule Session',
          style: AppTypography.headingSmall.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.profile.patient.name} · #${widget.profile.patient.patientCode}',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5, color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('schedule_treatment'),
                initialValue: _treatmentId,
                decoration: const InputDecoration(labelText: 'Treatment'),
                items: _treatments
                    .map((t) => DropdownMenuItem(
                          value: t.id,
                          child: Text('${t.packageName} (${t.category})'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _treatmentId = v),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('schedule_date'),
                onPressed: _busy ? null : _pickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(
                  _date == null ? 'Choose a date' : DateFormat('d MMM yyyy').format(_date!),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size(double.infinity, 0),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                key: const Key('schedule_doctor'),
                initialValue: _doctorId,
                decoration: const InputDecoration(labelText: 'Doctor (optional)'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem(value: null, child: Text('Any available doctor')),
                  ...widget.clinic.doctors.map<DropdownMenuItem<String?>>(
                    (DoctorOption d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                  ),
                ],
                onChanged: (v) => setState(() => _doctorId = v),
              ),
              const SizedBox(height: 8),
              Text(
                'Sessions are booked by date — the clinic does not use time slots.',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5, color: const Color(0xFF6B7280)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  key: const Key('schedule_error'),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5, color: const Color(0xFFDC2626)),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirm_schedule_session'),
            onPressed: _busy ? null : _schedule,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Schedule'),
          ),
        ],
      ),
    );
  }
}

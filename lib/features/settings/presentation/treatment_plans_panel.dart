import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/state/clinic_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../treatments/models/treatment_plan.dart';
import '../../treatments/repositories/treatment_plan_repository.dart';

/// Admin configuration for the treatment plans a Doctor may recommend.
///
/// Plans are deactivated rather than deleted: an inactive plan vanishes
/// from new treatment selection while every past treatment that used it
/// keeps the name it was sold under.
class TreatmentPlansPanel extends StatefulWidget {
  const TreatmentPlansPanel({super.key, required this.clinic});

  final ClinicViewModel clinic;

  @override
  State<TreatmentPlansPanel> createState() => _TreatmentPlansPanelState();
}

class _TreatmentPlansPanelState extends State<TreatmentPlansPanel> {
  late final TreatmentPlanRepository _repository = widget.clinic.treatmentPlans;

  List<TreatmentPlan> _plans = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plans = await _repository.listAll();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load the treatment plans.';
        _loading = false;
      });
    }
  }

  Future<void> _addOrEdit({TreatmentPlan? existing}) async {
    final result = await showDialog<({String category, String name})>(
      context: context,
      builder: (context) => _PlanDialog(existing: existing),
    );
    if (result == null) return;

    try {
      if (existing == null) {
        await _repository.create(category: result.category, name: result.name);
      } else {
        await _repository.update(existing.id, category: result.category, name: result.name);
      }
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the treatment plan.')),
      );
    }
  }

  Future<void> _setActive(TreatmentPlan plan, bool active) async {
    try {
      await _repository.setActive(plan.id, active);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update the treatment plan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('treatment_plans_panel'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Treatment Plans',
                    style: AppTypography.headingSmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'These are the plans a doctor can choose from when recommending a treatment. '
                    'Deactivating a plan hides it from new treatments but leaves past records untouched.',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                key: const Key('add_treatment_plan'),
                onPressed: () => _addOrEdit(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  _error!,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: const Color(0xFFDC2626)),
                ),
              ),
            )
          else
            for (final category in TreatmentCategory.all)
              _categorySection(category, _plans.where((p) => p.category == category).toList()),
        ],
      ),
    );
  }

  Widget _categorySection(String category, List<TreatmentPlan> plans) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          if (plans.isEmpty)
            Text(
              'No plans configured yet.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textMuted),
            )
          else
            ...plans.map(_planRow),
        ],
      ),
    );
  }

  Widget _planRow(TreatmentPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              plan.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: plan.active ? AppColors.textDark : const Color(0xFF9CA3AF),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: plan.active ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              plan.active ? 'Active' : 'Inactive',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: plan.active ? const Color(0xFF15803D) : const Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => _addOrEdit(existing: plan),
            child: Text(
              'Edit',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          Switch(
            value: plan.active,
            onChanged: (value) => _setActive(plan, value),
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _PlanDialog extends StatefulWidget {
  const _PlanDialog({this.existing});

  final TreatmentPlan? existing;

  @override
  State<_PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends State<_PlanDialog> {
  late final _nameController = TextEditingController(text: widget.existing?.name ?? '');
  late String _category = widget.existing?.category ?? TreatmentCategory.hair;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a plan name.');
      return;
    }
    Navigator.of(context).pop((category: _category, name: name));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add Treatment Plan' : 'Edit Treatment Plan',
        style: AppTypography.headingSmall.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: TreatmentCategory.all
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('treatment_plan_name'),
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Plan name',
                hintText: 'e.g. Hair PRP — 6 sessions',
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5, color: const Color(0xFFDC2626)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('treatment_plan_save'),
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

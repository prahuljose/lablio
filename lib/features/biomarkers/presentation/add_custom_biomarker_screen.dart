import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../data/biomarker_model.dart';
import '../providers/custom_biomarkers_provider.dart';

class AddCustomBiomarkerScreen extends ConsumerStatefulWidget {
  const AddCustomBiomarkerScreen({super.key});

  @override
  ConsumerState<AddCustomBiomarkerScreen> createState() =>
      _AddCustomBiomarkerScreenState();
}

class _AddCustomBiomarkerScreenState
    extends ConsumerState<AddCustomBiomarkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _shortName = TextEditingController();
  final _category = TextEditingController(text: 'Custom');
  final _unit = TextEditingController();
  final _refLow = TextEditingController();
  final _refHigh = TextEditingController();
  final _description = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _shortName,
      _category,
      _unit,
      _refLow,
      _refHigh,
      _description,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final model = BiomarkerModel(
        id: 'custom_${const Uuid().v4()}',
        name: _name.text.trim(),
        shortName: _shortName.text.trim().isEmpty
            ? _name.text.trim()
            : _shortName.text.trim(),
        category: _category.text.trim().isEmpty
            ? 'Custom'
            : _category.text.trim(),
        unit: _unit.text.trim(),
        refRangeLow: double.tryParse(_refLow.text.trim()),
        refRangeHigh: double.tryParse(_refHigh.text.trim()),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
      );
      await ref.read(customBiomarkersProvider.notifier).add(model);
      if (!mounted) return;
      // Go straight to logging the first value — this also makes the biomarker
      // appear on the Biomarkers page (which only shows tracked/logged markers).
      context.go(AppRoutes.biomarkers);
      context.push(
        AppRoutes.addEntry,
        extra: {
          'biomarkerId': model.id,
          'biomarkerName': model.name,
          'biomarker': model,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context).customBiomarkerSaveError('$e')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.high,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.customBiomarkerTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: t.customBiomarkerName,
                hintText: t.customBiomarkerNameHint,
                prefixIcon: const Icon(Icons.biotech_outlined),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? t.customBiomarkerEnterName
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _shortName,
              decoration: InputDecoration(
                labelText: t.customBiomarkerShortName,
                hintText: t.customBiomarkerShortNameHint,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _category,
              decoration: InputDecoration(
                labelText: t.customBiomarkerCategory,
                hintText: t.customBiomarkerCategoryHint,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _unit,
              decoration: InputDecoration(
                labelText: t.customBiomarkerUnit,
                hintText: t.customBiomarkerUnitHint,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _refLow,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration:
                        InputDecoration(labelText: t.customBiomarkerRefLow),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _refHigh,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration:
                        InputDecoration(labelText: t.customBiomarkerRefHigh),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: t.customBiomarkerDescription,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(t.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}

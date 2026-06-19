import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../biomarkers/data/biomarker_entry_model.dart';
import '../../biomarkers/providers/biomarkers_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/lab_report_parser.dart';

class ReviewExtractionScreen extends ConsumerStatefulWidget {
  final List<ExtractedCandidate> candidates;
  final String? rawText;
  final String? reportId;
  const ReviewExtractionScreen(
      {super.key, required this.candidates, this.rawText, this.reportId});

  @override
  ConsumerState<ReviewExtractionScreen> createState() =>
      _ReviewExtractionScreenState();
}

class _ReviewExtractionScreenState
    extends ConsumerState<ReviewExtractionScreen> {
  late final List<bool> _selected;
  late final List<TextEditingController> _controllers;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = List.filled(widget.candidates.length, true);
    _controllers = widget.candidates
        .map((c) => TextEditingController(
            text: c.value.toString().replaceAll(RegExp(r'\.0$'), '')))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  int get _selectedCount => _selected.where((s) => s).length;

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    setState(() => _saving = true);
    final sex = ref.read(profileProvider).valueOrNull?.sex;
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final notifier = ref.read(biomarkerEntriesProvider.notifier);
    var saved = 0;

    try {
      for (var i = 0; i < widget.candidates.length; i++) {
        if (!_selected[i]) continue;
        final value = double.tryParse(_controllers[i].text.trim());
        if (value == null) continue;
        final b = widget.candidates[i].biomarker;
        final range = b.rangeForSex(sex);
        await notifier.add(BiomarkerEntryModel(
          id: const Uuid().v4(),
          userId: userId,
          reportId: widget.reportId,
          biomarkerId: b.id,
          biomarkerName: b.name,
          biomarkerCategory: b.category,
          value: value,
          unit: b.unit,
          date: _date,
          refRangeLow: range.low,
          refRangeHigh: range.high,
          createdAt: DateTime.now(),
        ));
        saved++;
      }
      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t.reviewSaved(saved)),
          backgroundColor: AppColors.normal,
          behavior: SnackBarBehavior.floating,
        ));
        context.go(AppRoutes.biomarkers);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t.commonCouldNotSave(e.toString())),
          backgroundColor: AppColors.high,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.reviewTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    t.reviewHeader(widget.candidates.length),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          // Test date selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          t.reviewTestDate(
                              DateFormat('MMM d, yyyy').format(_date)),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Icon(Icons.chevron_right,
                        color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: widget.candidates.length,
              itemBuilder: (_, i) {
                final c = widget.candidates[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _selected[i],
                          activeColor: AppColors.primary,
                          onChanged: (v) =>
                              setState(() => _selected[i] = v ?? false),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.biomarker.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text(c.biomarker.category,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontSize: 12)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 84,
                          child: TextField(
                            controller: _controllers[i],
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 44,
                          child: Text(c.biomarker.unit,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.rawText != null && widget.rawText!.isNotEmpty)
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.text_snippet_outlined, size: 20),
                title: Text(t.reviewShowText,
                    style: const TextStyle(fontSize: 14)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        widget.rawText!,
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: ElevatedButton(
              onPressed: (_saving || _selectedCount == 0) ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(t.reviewSaveCount(_selectedCount)),
            ),
          ),
        ],
      ),
    );
  }
}

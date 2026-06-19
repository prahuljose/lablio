import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../biomarkers/data/biomarker_entry_model.dart';

/// What the user chose to include in the doctor PDF.
class ExportSelection {
  final Set<String> biomarkerIds;
  final bool includeMedical;
  const ExportSelection({
    required this.biomarkerIds,
    required this.includeMedical,
  });

  /// Nothing to generate when no biomarkers and no medical section are chosen.
  bool get isEmpty => biomarkerIds.isEmpty && !includeMedical;
}

/// Bottom sheet that lets the user pick which biomarkers (and whether the
/// medical-record section) to include in the "Share with doctor" PDF.
/// Returns the selection, or `null` if dismissed without generating.
Future<ExportSelection?> showExportSelectionSheet(
  BuildContext context,
  List<BiomarkerEntryModel> tracked, {
  int medicalCount = 0,
}) {
  return showModalBottomSheet<ExportSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        _ExportSelectionSheet(tracked: tracked, medicalCount: medicalCount),
  );
}

class _ExportSelectionSheet extends StatefulWidget {
  final List<BiomarkerEntryModel> tracked;
  final int medicalCount;
  const _ExportSelectionSheet({
    required this.tracked,
    required this.medicalCount,
  });

  @override
  State<_ExportSelectionSheet> createState() => _ExportSelectionSheetState();
}

class _ExportSelectionSheetState extends State<_ExportSelectionSheet> {
  // Latest entry per biomarker (the screen passes already-deduped data, but we
  // guard against duplicates), grouped by category for display.
  late final Map<String, List<BiomarkerEntryModel>> _byCategory;
  late final List<String> _categories;

  // Selected biomarker IDs — everything starts selected.
  late final Set<String> _selected;

  late bool _includeMedical;

  @override
  void initState() {
    super.initState();
    _includeMedical = widget.medicalCount > 0;
    final latest = <String, BiomarkerEntryModel>{};
    for (final e in widget.tracked) {
      final cur = latest[e.biomarkerId];
      if (cur == null || cur.date.isBefore(e.date)) latest[e.biomarkerId] = e;
    }
    _byCategory = {};
    for (final e in latest.values) {
      final cat = e.biomarkerCategory.isEmpty ? 'Other' : e.biomarkerCategory;
      _byCategory.putIfAbsent(cat, () => []).add(e);
    }
    for (final list in _byCategory.values) {
      list.sort((a, b) => a.biomarkerName.compareTo(b.biomarkerName));
    }
    _categories = _byCategory.keys.toList()..sort();
    _selected = latest.keys.toSet();
  }

  int get _total => _byCategory.values.fold(0, (a, l) => a + l.length);

  bool get _canGenerate => _selected.isNotEmpty || _includeMedical;

  Iterable<String> _idsIn(String cat) =>
      _byCategory[cat]!.map((e) => e.biomarkerId);

  /// Tri-state for a category header: true = all, false = none, null = some.
  bool? _categoryState(String cat) {
    final ids = _idsIn(cat).toList();
    final sel = ids.where(_selected.contains).length;
    if (sel == 0) return false;
    if (sel == ids.length) return true;
    return null;
  }

  void _toggleCategory(String cat) {
    final ids = _idsIn(cat).toSet();
    final allSelected = ids.every(_selected.contains);
    setState(() {
      if (allSelected) {
        _selected.removeAll(ids);
      } else {
        _selected.addAll(ids);
      }
    });
  }

  void _toggleAll() {
    setState(() {
      if (_selected.length == _total) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(_byCategory.values.expand((l) => l.map((e) => e.biomarkerId)));
      }
    });
  }

  (Color, String) _status(AppLocalizations t, BiomarkerEntryModel e) {
    if (e.isHigh) return (AppColors.high, t.biomarkersStatusHigh);
    if (e.isLow) return (AppColors.low, t.biomarkersStatusLow);
    if (e.isNormal) return (AppColors.normal, t.biomarkersStatusNormal);
    return (AppColors.textTertiary, '—');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final allSelected = _selected.length == _total && _total > 0;
    final mq = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mq.size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.exportSelectTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(t.exportSelectSubtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _total == 0 ? null : _toggleAll,
                    child: Text(allSelected ? t.exportClearAll : t.exportSelectAll),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // ── List ────────────────────────────────────────────────
            Flexible(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  if (widget.medicalCount > 0) _medicalToggle(t),
                  for (final cat in _categories) ...[
                    _categoryHeader(cat),
                    for (final e in _byCategory[cat]!) _row(t, e),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            // ── Footer ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + mq.padding.bottom),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _summaryLabel(t),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _canGenerate
                        ? () => Navigator.pop(
                              context,
                              ExportSelection(
                                biomarkerIds: _selected,
                                includeMedical: _includeMedical,
                              ),
                            )
                        : null,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: Text(t.exportGeneratePdf),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _summaryLabel(AppLocalizations t) {
    final parts = <String>[t.exportSummaryMarkers(_selected.length, _total)];
    if (widget.medicalCount > 0 && _includeMedical) {
      parts.add(t.exportSummaryMedical);
    }
    return parts.join('  ·  ');
  }

  // ── Medical-record include/exclude toggle ─────────────────────────
  Widget _medicalToggle(AppLocalizations t) {
    return Column(
      children: [
        SwitchListTile(
          value: _includeMedical,
          onChanged: (v) => setState(() => _includeMedical = v),
          contentPadding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
          secondary: Icon(Icons.medical_information_outlined,
              color: AppColors.textSecondary),
          title: Text(t.profileMedicalRecord),
          subtitle: Text(
            t.exportMedicalSub(widget.medicalCount),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  // ── Category header with tri-state bulk toggle ────────────────────
  Widget _categoryHeader(String cat) {
    final ids = _idsIn(cat).toList();
    final sel = ids.where(_selected.contains).length;
    return InkWell(
      onTap: () => _toggleCategory(cat),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 20, 2),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Checkbox(
                tristate: true,
                value: _categoryState(cat),
                onChanged: (_) => _toggleCategory(cat),
              ),
            ),
            Expanded(
              child: Text(
                cat.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text(
              '$sel/${ids.length}',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(AppLocalizations t, BiomarkerEntryModel e) {
    final (color, label) = _status(t, e);
    final selected = _selected.contains(e.biomarkerId);
    return InkWell(
      onTap: () => setState(() {
        if (selected) {
          _selected.remove(e.biomarkerId);
        } else {
          _selected.add(e.biomarkerId);
        }
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selected.add(e.biomarkerId);
                } else {
                  _selected.remove(e.biomarkerId);
                }
              }),
            ),
            Expanded(
              child: Text(e.biomarkerName,
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
            const SizedBox(width: 8),
            Text(
              '${_fmt(e.value)} ${e.unit}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 10),
            // Status dot + label so a doctor-facing selection shows what's flagged.
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 48,
              child: Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: color, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }
}

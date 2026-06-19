import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../biomarkers/data/biomarker_entry_model.dart';

/// Bottom sheet that lets the user pick which biomarkers to include in the
/// "Share with doctor" PDF. Returns the set of selected biomarker IDs, or
/// `null` if the user dismissed it without generating.
Future<Set<String>?> showExportSelectionSheet(
  BuildContext context,
  List<BiomarkerEntryModel> tracked,
) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ExportSelectionSheet(tracked: tracked),
  );
}

class _ExportSelectionSheet extends StatefulWidget {
  final List<BiomarkerEntryModel> tracked;
  const _ExportSelectionSheet({required this.tracked});

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

  @override
  void initState() {
    super.initState();
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

  (Color, String) _status(BiomarkerEntryModel e) {
    if (e.isHigh) return (AppColors.high, 'High');
    if (e.isLow) return (AppColors.low, 'Low');
    if (e.isNormal) return (AppColors.normal, 'Normal');
    return (AppColors.textTertiary, '—');
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _selected.length == _total;
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
                        Text('Select biomarkers',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('Choose what goes into the PDF summary',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _toggleAll,
                    child: Text(allSelected ? 'Clear all' : 'Select all'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // ── List ────────────────────────────────────────────────
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: _categories.length,
                itemBuilder: (_, ci) {
                  final cat = _categories[ci];
                  final rows = _byCategory[cat]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                        child: Text(
                          cat.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: AppColors.textTertiary,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      for (final e in rows) _row(e),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1),
            // ── Footer ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, 12 + mq.padding.bottom),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_selected.length} of $_total selected',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => Navigator.pop(context, _selected),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: Text('Generate PDF (${_selected.length})'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BiomarkerEntryModel e) {
    final (color, label) = _status(e);
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../data/biomarker_model.dart';
import '../providers/custom_biomarkers_provider.dart';

/// Half-sheet biomarker picker — faster alternative to the full "Select
/// Biomarker" route for the common "log a value now" flow.
Future<void> showQuickLogSheet(BuildContext context, {String? reportId}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuickLogSheet(reportId: reportId),
  );
}

class _QuickLogSheet extends ConsumerStatefulWidget {
  final String? reportId;
  const _QuickLogSheet({this.reportId});

  @override
  ConsumerState<_QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends ConsumerState<_QuickLogSheet> {
  String _q = '';
  String? _category; // null = all categories

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final all = ref.watch(allBiomarkersProvider).valueOrNull ??
        const <BiomarkerModel>[];

    // Sorted unique categories across all reference biomarkers.
    final categories = all
        .map((b) => b.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final q = _q.trim().toLowerCase();
    var results = _category != null
        ? all.where((b) => b.category == _category).toList()
        : all.toList();
    if (q.isNotEmpty) {
      results = results
          .where((b) =>
              b.name.toLowerCase().contains(q) ||
              b.shortName.toLowerCase().contains(q) ||
              b.category.toLowerCase().contains(q))
          .toList();
    }

    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollCtl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Handle ──────────────────────────────────────────
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // ── Header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(t.reportDetailLogResult,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: t.customBiomarkerTitle,
                      onPressed: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.addCustomBiomarker);
                      },
                    ),
                  ],
                ),
              ),
              // ── Search ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  autofocus: false,
                  onChanged: (v) => setState(() => _q = v),
                  decoration: InputDecoration(
                    hintText: t.biomarkersSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppColors.divider, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // ── Category chips ───────────────────────────────────
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  itemCount: categories.length,
                  itemBuilder: (_, i) {
                    final cat = categories[i];
                    final isSel = cat == _category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSel
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        selectedColor: AppColors.primaryDark,
                        backgroundColor: AppColors.surface,
                        shape: const StadiumBorder(),
                        side: BorderSide(
                            color: isSel
                                ? AppColors.primaryDark
                                : AppColors.divider),
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() =>
                              _category = isSel ? null : cat);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              // ── Results ─────────────────────────────────────────
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Text(t.biomarkersNoneFound,
                            style:
                                Theme.of(context).textTheme.bodyMedium),
                      )
                    : ListView.builder(
                        controller: scrollCtl,
                        itemCount: results.length,
                        itemBuilder: (_, i) {
                          final b = results[i];
                          return ListTile(
                            leading: const Icon(Icons.biotech_outlined,
                                color: AppColors.primary),
                            title: Text(b.name),
                            subtitle: Text(b.category),
                            trailing: Icon(Icons.chevron_right,
                                color: AppColors.textTertiary),
                            onTap: () {
                              Navigator.pop(context);
                              context.push(
                                AppRoutes.addEntry,
                                extra: {
                                  'biomarkerId': b.id,
                                  'biomarkerName': b.name,
                                  'biomarker': b,
                                  if (widget.reportId != null)
                                    'reportId': widget.reportId,
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

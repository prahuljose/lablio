import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../biomarkers/data/biomarker_entry_model.dart';
import '../../biomarkers/data/biomarker_model.dart';
import '../../biomarkers/providers/biomarkers_provider.dart';
import '../../biomarkers/providers/custom_biomarkers_provider.dart';
import '../../reports/data/report_model.dart';
import '../../reports/providers/reports_provider.dart';
import '../../../l10n/app_localizations.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final q = _query.trim().toLowerCase();
    final biomarkers =
        ref.watch(allBiomarkersProvider).valueOrNull ?? const <BiomarkerModel>[];
    final reports =
        ref.watch(reportsProvider).valueOrNull ?? const <ReportModel>[];
    final entries = ref.watch(biomarkerEntriesProvider).valueOrNull ??
        const <BiomarkerEntryModel>[];

    final bmHits = q.isEmpty
        ? const <BiomarkerModel>[]
        : biomarkers
            .where((b) =>
                b.name.toLowerCase().contains(q) ||
                b.shortName.toLowerCase().contains(q) ||
                b.category.toLowerCase().contains(q))
            .take(12)
            .toList();

    final reportHits = q.isEmpty
        ? const <ReportModel>[]
        : reports
            .where((r) =>
                r.title.toLowerCase().contains(q) ||
                (r.notes ?? '').toLowerCase().contains(q))
            .take(12)
            .toList();

    final entryHits = q.isEmpty
        ? const <BiomarkerEntryModel>[]
        : entries
            .where((e) =>
                (e.notes ?? '').toLowerCase().contains(q) ||
                e.tags.any((t) => t.toLowerCase().contains(q)))
            .take(12)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).searchHint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: q.isEmpty
          ? _buildPrompt(context)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (bmHits.isEmpty &&
                    reportHits.isEmpty &&
                    entryHits.isEmpty)
                  _empty(),
                if (bmHits.isNotEmpty) ...[
                  _header(AppLocalizations.of(context).navBiomarkers),
                  ...bmHits
                      .map((b) => _BiomarkerHit(biomarker: b, query: q)),
                  const SizedBox(height: 12),
                ],
                if (reportHits.isNotEmpty) ...[
                  _header(AppLocalizations.of(context).navReports),
                  ...reportHits
                      .map((r) => _ReportHit(report: r, query: q)),
                  const SizedBox(height: 12),
                ],
                if (entryHits.isNotEmpty) ...[
                  _header(AppLocalizations.of(context).searchSectionEntries),
                  ...entryHits.map((e) => _EntryHit(entry: e, query: q)),
                ],
              ],
            ),
    );
  }

  Widget _buildPrompt(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            AppLocalizations.of(context).searchPrompt,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );

  Widget _empty() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(AppLocalizations.of(context).searchNoMatches,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      );

  Widget _header(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
        child: Text(t.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppColors.textSecondary,
            )),
      );
}

/// Returns a RichText that highlights occurrences of [query] inside [text].
/// The highlight stays legible in both light and dark themes.
Widget _highlight(String text, String query, BuildContext context,
    {TextStyle? base, bool oneLine = true}) {
  final baseStyle = base ?? DefaultTextStyle.of(context).style;
  if (query.isEmpty) {
    return Text(text,
        style: baseStyle,
        maxLines: oneLine ? 1 : null,
        overflow: oneLine ? TextOverflow.ellipsis : TextOverflow.clip);
  }
  final lower = text.toLowerCase();
  final q = query.toLowerCase();
  final spans = <TextSpan>[];
  var i = 0;
  while (i < text.length) {
    final hit = lower.indexOf(q, i);
    if (hit < 0) {
      spans.add(TextSpan(text: text.substring(i)));
      break;
    }
    if (hit > i) {
      spans.add(TextSpan(text: text.substring(i, hit)));
    }
    spans.add(TextSpan(
      text: text.substring(hit, hit + q.length),
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        backgroundColor: AppColors.primary.withValues(alpha: 0.16),
      ),
    ));
    i = hit + q.length;
  }
  return RichText(
    text: TextSpan(style: baseStyle, children: spans),
    maxLines: oneLine ? 1 : null,
    overflow: oneLine ? TextOverflow.ellipsis : TextOverflow.clip,
  );
}

class _BiomarkerHit extends StatelessWidget {
  final BiomarkerModel biomarker;
  final String query;
  const _BiomarkerHit({required this.biomarker, required this.query});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.biotech_outlined, color: AppColors.primary),
        title: _highlight(biomarker.name, query, context,
            base: Theme.of(context).textTheme.titleMedium),
        subtitle: _highlight(biomarker.category, query, context,
            base: Theme.of(context).textTheme.bodyMedium),
        trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary),
        onTap: () => context.push(
          AppRoutes.biomarkerDetail,
          extra: {
            'biomarkerId': biomarker.id,
            'biomarkerName': biomarker.name,
          },
        ),
      ),
    );
  }
}

class _ReportHit extends StatelessWidget {
  final ReportModel report;
  final String query;
  const _ReportHit({required this.report, required this.query});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.description_outlined,
            color: AppColors.primary),
        title: _highlight(report.title, query, context,
            base: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(DateFormat('MMM d, yyyy').format(report.date)),
        trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary),
        onTap: () => context.push(AppRoutes.reportDetail, extra: report),
      ),
    );
  }
}

class _EntryHit extends StatelessWidget {
  final BiomarkerEntryModel entry;
  final String query;
  const _EntryHit({required this.entry, required this.query});

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      DateFormat('MMM d, yyyy').format(entry.date),
      if (entry.tags.isNotEmpty) entry.tags.join(', '),
      if (entry.notes != null && entry.notes!.isNotEmpty) entry.notes!,
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading:
            const Icon(Icons.science_outlined, color: AppColors.primary),
        title: Text(
            '${entry.biomarkerName} · ${entry.value} ${entry.unit}'),
        subtitle: _highlight(subtitle, query, context,
            base: Theme.of(context).textTheme.bodyMedium, oneLine: false),
        trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary),
        onTap: () => context.push(
          AppRoutes.biomarkerDetail,
          extra: {
            'biomarkerId': entry.biomarkerId,
            'biomarkerName': entry.biomarkerName,
          },
        ),
      ),
    );
  }
}

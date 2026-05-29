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

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
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
          decoration: const InputDecoration(
            hintText: 'Search biomarkers, reports, notes, tags…',
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
                  _header('Biomarkers'),
                  ...bmHits.map((b) => _BiomarkerHit(biomarker: b)),
                  const SizedBox(height: 12),
                ],
                if (reportHits.isNotEmpty) ...[
                  _header('Reports'),
                  ...reportHits.map((r) => _ReportHit(report: r)),
                  const SizedBox(height: 12),
                ],
                if (entryHits.isNotEmpty) ...[
                  _header('Results matching notes / tags'),
                  ...entryHits.map((e) => _EntryHit(entry: e)),
                ],
              ],
            ),
    );
  }

  Widget _buildPrompt(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Start typing to search across your biomarkers, reports, and result notes / tags.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );

  Widget _empty() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text('No matches',
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

class _BiomarkerHit extends StatelessWidget {
  final BiomarkerModel biomarker;
  const _BiomarkerHit({required this.biomarker});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.biotech_outlined, color: AppColors.primary),
        title: Text(biomarker.name),
        subtitle: Text(biomarker.category),
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
  const _ReportHit({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.description_outlined,
            color: AppColors.primary),
        title: Text(report.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(DateFormat('MMM d, yyyy').format(report.date)),
        trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary),
        onTap: () => context.push(AppRoutes.reportDetail, extra: report),
      ),
    );
  }
}

class _EntryHit extends StatelessWidget {
  final BiomarkerEntryModel entry;
  const _EntryHit({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading:
            const Icon(Icons.science_outlined, color: AppColors.primary),
        title: Text(
            '${entry.biomarkerName} · ${entry.value} ${entry.unit}'),
        subtitle: Text(
          [
            DateFormat('MMM d, yyyy').format(entry.date),
            if (entry.tags.isNotEmpty) entry.tags.join(', '),
            if (entry.notes != null && entry.notes!.isNotEmpty) entry.notes!,
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
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

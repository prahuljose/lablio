import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../biomarkers/data/biomarker_entry_model.dart';
import '../../biomarkers/providers/biomarkers_provider.dart';
import '../data/report_model.dart';
import '../providers/reports_provider.dart';

class ReportDetailScreen extends ConsumerWidget {
  final ReportModel report;
  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Entries linked to this report, derived from the in-memory list
    final linkedEntries = ref.watch(biomarkerEntriesProvider).whenData(
          (entries) => entries
              .where((e) => e.reportId == report.id)
              .toList()
            ..sort((a, b) => a.biomarkerName.compareTo(b.biomarkerName)),
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.high),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          AppRoutes.browseBiomarkers,
          extra: {'reportId': report.id},
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Result'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Header card ────────────────────────────────────────────
          _HeaderCard(report: report),

          // ── PDF button ─────────────────────────────────────────────
          if (report.pdfUrl != null) ...[
            const SizedBox(height: 16),
            _PdfButton(url: report.pdfUrl!),
          ],

          // ── Biomarker entries ──────────────────────────────────────
          const SizedBox(height: 28),
          const _SectionLabel('Biomarker Results'),
          const SizedBox(height: 12),
          linkedEntries.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (entries) => entries.isEmpty
                ? _EmptyEntries(report: report)
                : Column(
                    children: entries
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _EntryRow(entry: e),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Report'),
        content: Text('Delete "${report.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(reportsProvider.notifier).remove(
                    report.id,
                    pdfPath: report.pdfPath,
                  );
              context.pop();
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.high)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.4,
        ),
      );
}

class _HeaderCard extends StatelessWidget {
  final ReportModel report;
  const _HeaderCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description_outlined,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 13, color: AppColors.textTertiary),
                        const SizedBox(width: 5),
                        Text(
                          DateFormat('MMMM d, yyyy').format(report.date),
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (report.notes != null && report.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_outlined,
                    size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(report.notes!,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PdfButton extends StatelessWidget {
  final String url;
  const _PdfButton({required this.url});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final uri = Uri.parse(url);
        // Try the external browser/viewer first, then fall back to the
        // in-app webview. Don't gate on canLaunchUrl — it can report false
        // negatives on Android even when the URL is perfectly launchable.
        bool launched = false;
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } catch (_) {
          launched = false;
        }
        if (!launched) {
          try {
            launched = await launchUrl(
              uri,
              mode: LaunchMode.inAppBrowserView,
            );
          } catch (_) {
            launched = false;
          }
        }
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open PDF'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: AppColors.primary),
        foregroundColor: AppColors.primary,
      ),
      icon: const Icon(Icons.picture_as_pdf_outlined),
      label: const Text('View PDF',
          style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyEntries extends StatelessWidget {
  final ReportModel report;
  const _EmptyEntries({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Icon(Icons.science_outlined,
              size: 40, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          const Text('No results logged for this report',
              style: TextStyle(
                  fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => context.push(
              AppRoutes.browseBiomarkers,
              extra: {'reportId': report.id},
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Log a biomarker result'),
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final BiomarkerEntryModel entry;
  const _EntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final statusColor = entry.isNormal
        ? AppColors.normal
        : entry.isHigh
            ? AppColors.high
            : entry.isLow
                ? AppColors.low
                : AppColors.textTertiary;

    final statusBg = entry.isNormal
        ? AppColors.normalBg
        : entry.isHigh
            ? AppColors.highBg
            : entry.isLow
                ? AppColors.lowBg
                : AppColors.surfaceVariant;

    final statusLabel = entry.isNormal
        ? 'Normal'
        : entry.isHigh
            ? 'High'
            : entry.isLow
                ? 'Low'
                : '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
                color: statusColor, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.biomarkerName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  entry.refRangeLow != null && entry.refRangeHigh != null
                      ? 'Ref: ${entry.refRangeLow} – ${entry.refRangeHigh} ${entry.unit}'
                      : entry.unit,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.value} ${entry.unit}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

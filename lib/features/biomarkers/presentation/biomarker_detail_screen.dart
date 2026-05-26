import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../data/biomarker_entry_model.dart';
import '../data/biomarker_model.dart';
import '../providers/biomarkers_provider.dart';

class BiomarkerDetailScreen extends ConsumerWidget {
  final String biomarkerId;
  final String biomarkerName;

  const BiomarkerDetailScreen({
    super.key,
    required this.biomarkerId,
    required this.biomarkerName,
  });

  void _goToAddEntry(BuildContext context, BiomarkerModel? biomarker) {
    context.push(
      AppRoutes.addEntry,
      extra: {
        'biomarkerId': biomarkerId,
        'biomarkerName': biomarkerName,
        'biomarker': biomarker,
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(biomarkerHistoryProvider(biomarkerId));

    // Watch (not read) so the biomarker is guaranteed resolved before use
    final biomarker = ref.watch(referenceBiomarkersProvider).whenData(
          (list) => list.firstWhere(
            (b) => b.id == biomarkerId,
            orElse: () => BiomarkerModel(
              id: biomarkerId,
              name: biomarkerName,
              shortName: biomarkerName,
              category: 'Other',
              unit: '',
            ),
          ),
        ).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(biomarkerName),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            // null while ref biomarkers still loading → button is disabled
            onPressed: biomarker == null
                ? null
                : () => _goToAddEntry(context, biomarker),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) => entries.isEmpty
            ? _buildEmpty(context, biomarker)
            : _buildContent(context, ref, entries),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, BiomarkerModel? biomarker) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('No entries yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: biomarker == null
                ? null
                : () => _goToAddEntry(context, biomarker),
            icon: const Icon(Icons.add),
            label: const Text('Log First Result'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, List<BiomarkerEntryModel> entries) {
    final latest = entries.last;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _LatestValueCard(entry: latest),
        const SizedBox(height: 16),
        if (entries.length >= 2) ...[
          _TrendChart(entries: entries),
          const SizedBox(height: 16),
        ],
        Text('History', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...entries.reversed.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _EntryRow(entry: e, ref: ref),
          ),
        ),
      ],
    );
  }
}

class _LatestValueCard extends StatelessWidget {
  final BiomarkerEntryModel entry;
  const _LatestValueCard({required this.entry});

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
                : 'No range';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Latest result',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        entry.value.toStringAsFixed(
                            entry.value.truncateToDouble() == entry.value
                                ? 0
                                : 2),
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(entry.unit,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                  if (entry.refRangeLow != null && entry.refRangeHigh != null)
                    Text(
                      'Reference: ${entry.refRangeLow} – ${entry.refRangeHigh} ${entry.unit}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<BiomarkerEntryModel> entries;
  const _TrendChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final spots = entries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    final refLow = entries.first.refRangeLow;
    final refHigh = entries.first.refRangeHigh;
    final values = entries.map((e) => e.value).toList();
    final minY = (refLow != null
            ? [refLow, ...values].reduce((a, b) => a < b ? a : b)
            : values.reduce((a, b) => a < b ? a : b)) *
        0.9;
    final maxY = (refHigh != null
            ? [refHigh, ...values].reduce((a, b) => a > b ? a : b)
            : values.reduce((a, b) => a > b ? a : b)) *
        1.1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 12),
              child: Text('Trend',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.divider,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, _) => Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textTertiary),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= entries.length) {
                            return const SizedBox();
                          }
                          return Text(
                            DateFormat('MMM yy').format(entries[idx].date),
                            style: const TextStyle(
                                fontSize: 9, color: AppColors.textTertiary),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      if (refLow != null)
                        HorizontalLine(
                          y: refLow,
                          color: AppColors.low.withOpacity(0.5),
                          strokeWidth: 1.5,
                          dashArray: [4, 4],
                        ),
                      if (refHigh != null)
                        HorizontalLine(
                          y: refHigh,
                          color: AppColors.high.withOpacity(0.5),
                          strokeWidth: 1.5,
                          dashArray: [4, 4],
                        ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: AppColors.primary,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final BiomarkerEntryModel entry;
  final WidgetRef ref;
  const _EntryRow({required this.entry, required this.ref});

  @override
  Widget build(BuildContext context) {
    final statusColor = entry.isNormal
        ? AppColors.normal
        : entry.isHigh
            ? AppColors.high
            : entry.isLow
                ? AppColors.low
                : AppColors.textTertiary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('MMM d, yyyy').format(entry.date),
                      style: Theme.of(context).textTheme.bodyMedium),
                  if (entry.notes != null && entry.notes!.isNotEmpty)
                    Text(entry.notes!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 12)),
                ],
              ),
            ),
            Text(
              '${entry.value} ${entry.unit}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _confirmDelete(context),
              child: const Icon(Icons.delete_outline,
                  color: AppColors.textTertiary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Remove this result? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(biomarkerEntriesProvider.notifier).remove(entry.id);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.high)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../data/biomarker_entry_model.dart';
import '../providers/biomarkers_provider.dart';

class BiomarkersScreen extends ConsumerWidget {
  const BiomarkersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackedAsync = ref.watch(trackedBiomarkersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Biomarkers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.browseBiomarkers),
        icon: const Icon(Icons.add),
        label: const Text('Log Result'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: trackedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tracked) => tracked.isEmpty
            ? _buildEmpty(context)
            : _buildList(context, tracked),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('No biomarkers tracked',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Log your first lab result to start tracking',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<BiomarkerEntryModel> tracked) {
    // Group by category
    final grouped = <String, List<BiomarkerEntryModel>>{};
    for (final entry in tracked) {
      grouped.putIfAbsent(entry.biomarkerCategory, () => []).add(entry);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final category in grouped.keys) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Text(category,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    )),
          ),
          ...grouped[category]!.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BiomarkerTile(entry: entry),
            ),
          ),
        ],
      ],
    );
  }
}

class _BiomarkerTile extends ConsumerWidget {
  final BiomarkerEntryModel entry;
  const _BiomarkerTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
          AppRoutes.biomarkerDetail,
          extra: {
            'biomarkerId': entry.biomarkerId,
            'biomarkerName': entry.biomarkerName,
          },
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.biomarkerName,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Latest: ${entry.value} ${entry.unit}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    if (entry.refRangeLow != null &&
                        entry.refRangeHigh != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Ref: ${entry.refRangeLow} – ${entry.refRangeHigh} ${entry.unit}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textTertiary, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

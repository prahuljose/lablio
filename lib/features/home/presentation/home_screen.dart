import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../biomarkers/data/biomarker_entry_model.dart';
import '../../biomarkers/presentation/quick_log_sheet.dart';
import '../../biomarkers/providers/biomarkers_provider.dart';
import '../../biomarkers/providers/insights_provider.dart';
import '../../biomarkers/providers/pinned_biomarkers_provider.dart';
import '../../reports/providers/reports_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final firstName = (user?.userMetadata?['full_name'] as String? ?? 'there')
        .split(' ')
        .first;

    final reportsAsync = ref.watch(reportsProvider);
    final entriesAsync = ref.watch(biomarkerEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $firstName 👋',
                style: Theme.of(context).textTheme.titleLarge),
            Text(DateFormat('EEEE, MMM d').format(DateTime.now()),
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        toolbarHeight: 64,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => context.push(AppRoutes.search),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(reportsProvider.notifier).refresh();
          ref.read(biomarkerEntriesProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatsRow(
              reportsAsync: reportsAsync,
              entriesAsync: entriesAsync,
              onReports: () => context.go(AppRoutes.reports),
              onResults: () {
                ref.read(biomarkerInitialFilterProvider.notifier).state =
                    BiomarkerFilter.all;
                context.go(AppRoutes.biomarkers);
              },
              onOutOfRange: () {
                ref.read(biomarkerInitialFilterProvider.notifier).state =
                    BiomarkerFilter.outOfRange;
                context.go(AppRoutes.biomarkers);
              },
            ),
            const SizedBox(height: 24),
            _QuickActions(),
            const SizedBox(height: 24),
            _InsightsCard(
              insightsAsync: ref.watch(healthInsightsProvider),
              onViewAll: () {
                ref.read(biomarkerInitialFilterProvider.notifier).state =
                    BiomarkerFilter.outOfRange;
                context.go(AppRoutes.biomarkers);
              },
              onTapMarker: (i) => context.push(
                AppRoutes.biomarkerDetail,
                extra: {
                  'biomarkerId': i.biomarkerId,
                  'biomarkerName': i.name,
                },
              ),
            ),
            // Pinned biomarkers section (only shown if user has pinned any).
            _PinnedSection(
              pinnedIds: ref.watch(pinnedBiomarkersProvider),
              entries:
                  entriesAsync.valueOrNull ?? const <BiomarkerEntryModel>[],
            ),
            Text('Recent Results',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (entries) => entries.isEmpty
                  ? _buildEmptyResults(context)
                  : Column(
                      children: ([...entries]
                            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
                          .take(5)
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _RecentResultTile(entry: e),
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyResults(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.science_outlined,
              size: 40, color: AppColors.textTertiary),
          const SizedBox(height: 8),
          Text('No results yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Start by logging your first lab result',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  final AsyncValue<HealthInsights> insightsAsync;
  final VoidCallback onViewAll;
  final void Function(BiomarkerInsight) onTapMarker;

  const _InsightsCard({
    required this.insightsAsync,
    required this.onViewAll,
    required this.onTapMarker,
  });

  @override
  Widget build(BuildContext context) {
    final data = insightsAsync.valueOrNull;
    if (data == null || data.tracked == 0) return const SizedBox.shrink();

    final inRange = data.tracked - data.outOfRange;
    final highlights = data.highlights.take(4).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Card(
        child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Health Insights',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                if (data.outOfRange > 0)
                  GestureDetector(
                    onTap: onViewAll,
                    child: const Text('View all',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Headline summary
            Text(
              data.outOfRange == 0
                  ? 'All ${data.tracked} markers in range 🎉'
                  : '${data.outOfRange} of ${data.tracked} markers out of range',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: data.outOfRange == 0
                    ? AppColors.normal
                    : AppColors.textPrimary,
              ),
            ),
            if (data.improving > 0 || data.worsening > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (data.improving > 0) ...[
                    const Icon(Icons.trending_down,
                        size: 14, color: AppColors.normal),
                    const SizedBox(width: 4),
                    Text('${data.improving} improving',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.normal)),
                    const SizedBox(width: 12),
                  ],
                  if (data.worsening > 0) ...[
                    const Icon(Icons.trending_up,
                        size: 14, color: AppColors.high),
                    const SizedBox(width: 4),
                    Text('${data.worsening} worsening',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.high)),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 4),
            ...highlights.map((i) => _InsightRow(
                  insight: i,
                  onTap: () => onTapMarker(i),
                )),
            if (data.outOfRange == 0 && inRange > 0) const SizedBox(height: 4),
          ],
        ),
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final BiomarkerInsight insight;
  final VoidCallback onTap;
  const _InsightRow({required this.insight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = insight.latest.isNormal
        ? AppColors.normal
        : insight.latest.isHigh
            ? AppColors.high
            : insight.latest.isLow
                ? AppColors.low
                : AppColors.textTertiary;

    final (arrow, arrowColor) = switch (insight.direction) {
      TrendDirection.up => (
          Icons.north_east,
          insight.improving ? AppColors.normal : AppColors.high
        ),
      TrendDirection.down => (
          Icons.south_east,
          insight.improving ? AppColors.normal : AppColors.high
        ),
      TrendDirection.flat => (Icons.east, AppColors.textTertiary),
      TrendDirection.none => (Icons.fiber_manual_record, AppColors.textTertiary),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(insight.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Text('${insight.latest.value} ${insight.unit}',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Icon(
                insight.direction == TrendDirection.none
                    ? Icons.remove
                    : arrow,
                size: 16,
                color: arrowColor),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AsyncValue reportsAsync;
  final AsyncValue entriesAsync;
  final VoidCallback onReports;
  final VoidCallback onResults;
  final VoidCallback onOutOfRange;

  const _StatsRow({
    required this.reportsAsync,
    required this.entriesAsync,
    required this.onReports,
    required this.onResults,
    required this.onOutOfRange,
  });

  @override
  Widget build(BuildContext context) {
    final reportCount = reportsAsync.valueOrNull?.length ?? 0;
    final entryCount = entriesAsync.valueOrNull?.length ?? 0;

    // Count out-of-range entries (latest per biomarker)
    final entries = entriesAsync.valueOrNull ?? [];
    final outOfRange = entries.where((e) => e.isHigh || e.isLow).length;

    return Row(
      children: [
        Expanded(
            child: _StatCard(
                label: 'Reports',
                value: '$reportCount',
                icon: Icons.folder_outlined,
                onTap: onReports)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                label: 'Results',
                value: '$entryCount',
                icon: Icons.science_outlined,
                onTap: onResults)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                label: 'Out of Range',
                value: '$outOfRange',
                icon: Icons.warning_amber_outlined,
                valueColor: outOfRange > 0 ? AppColors.high : null,
                onTap: onOutOfRange)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 20),
                  const Spacer(),
                  if (onTap != null)
                    Icon(Icons.chevron_right,
                        color: AppColors.textTertiary, size: 16),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: valueColor ?? AppColors.textPrimary,
                    ),
              ),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.add_circle_outline,
                label: 'Log Result',
                color: AppColors.primary,
                onTap: () => showQuickLogSheet(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.upload_file_outlined,
                label: 'Upload Report',
                color: AppColors.primaryLight,
                onTap: () => context.push(AppRoutes.addReport),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Scan Report is not ready yet — disabled with a "Coming soon" badge.
        const _ActionCard(
          icon: Icons.document_scanner_outlined,
          label: 'Scan Report (auto-extract values)',
          color: AppColors.primaryDark,
          comingSoon: true,
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool comingSoon;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = comingSoon ? AppColors.textTertiary : color;
    return InkWell(
      onTap: comingSoon
          ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Scan Report is coming soon'),
                behavior: SnackBarBehavior.floating,
              ))
          : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: comingSoon ? 0.65 : 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tint.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: tint, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: tint)),
              ),
              if (comingSoon)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('SOON',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      )),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentResultTile extends StatelessWidget {
  final dynamic entry;
  const _RecentResultTile({required this.entry});

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
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: statusColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(entry.biomarkerName,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Text('${entry.value} ${entry.unit}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            Text(
              DateFormat('MMM d').format(entry.date),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PinnedSection extends StatelessWidget {
  final Set<String> pinnedIds;
  final List<BiomarkerEntryModel> entries;
  const _PinnedSection({required this.pinnedIds, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (pinnedIds.isEmpty) return const SizedBox.shrink();
    // Latest entry per pinned biomarker.
    final byId = <String, BiomarkerEntryModel>{};
    for (final e in entries) {
      if (!pinnedIds.contains(e.biomarkerId)) continue;
      final cur = byId[e.biomarkerId];
      if (cur == null || cur.date.isBefore(e.date)) {
        byId[e.biomarkerId] = e;
      }
    }
    if (byId.isEmpty) return const SizedBox.shrink();
    final tiles = byId.values.toList()
      ..sort((a, b) => a.biomarkerName.compareTo(b.biomarkerName));

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.push_pin, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Pinned',
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: tiles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _PinnedCard(entry: tiles[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedCard extends StatelessWidget {
  final BiomarkerEntryModel entry;
  const _PinnedCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = entry.isHigh
        ? AppColors.high
        : entry.isLow
            ? AppColors.low
            : entry.isNormal
                ? AppColors.normal
                : AppColors.textTertiary;
    return SizedBox(
      width: 160,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(
            AppRoutes.biomarkerDetail,
            extra: {
              'biomarkerId': entry.biomarkerId,
              'biomarkerName': entry.biomarkerName,
            },
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(entry.biomarkerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${entry.value}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(entry.unit,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

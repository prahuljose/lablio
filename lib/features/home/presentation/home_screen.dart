import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/network/network_error.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/animated_lablio_logo.dart';
import '../../../core/widgets/lablio_refresh.dart';
import '../../../l10n/app_localizations.dart';
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
    final t = AppLocalizations.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final firstName = (user?.userMetadata?['full_name'] as String? ?? 'there')
        .split(' ')
        .first;

    final reportsAsync = ref.watch(reportsProvider);
    final entriesAsync = ref.watch(biomarkerEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 52,
        titleSpacing: 8,
        leading: const LablioAppBarLogo(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.homeGreeting(firstName),
                style: Theme.of(context).textTheme.titleLarge),
            Text(DateFormat('EEEE, MMM d').format(DateTime.now()),
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        toolbarHeight: 64,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: t.commonSearch,
            onPressed: () => context.push(AppRoutes.search),
          ),
        ],
      ),
      body: LablioRefresh(
        onRefresh: () async {
          try {
            await Future.wait([
              ref.read(reportsProvider.notifier).refresh(),
              ref.read(biomarkerEntriesProvider.notifier).refresh(),
            ]);
          } catch (e) {
            if (context.mounted) showOfflineAwareSnackBar(context, e);
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
            Text(t.homeRecentResults,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            entriesAsync.when(
              loading: () => const LablioLoader(),
              error: (e, _) => Text(
                  networkAwareMessage(e, AppLocalizations.of(context)),
                  style: Theme.of(context).textTheme.bodyMedium),
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
    final t = AppLocalizations.of(context);
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
          Text(t.homeNoResults,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(t.homeNoResultsSub,
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
    final t = AppLocalizations.of(context);
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
                Expanded(
                  child: Text(t.homeHealthInsights,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (data.outOfRange > 0)
                  GestureDetector(
                    onTap: onViewAll,
                    child: Text(t.homeViewAll,
                        style: const TextStyle(
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
                  ? t.homeAllInRange(data.tracked)
                  : t.homeOutOfRangeSummary(data.outOfRange, data.tracked),
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
                    const Icon(Icons.trending_up,
                        size: 14, color: AppColors.normal),
                    const SizedBox(width: 4),
                    Text(t.homeImproving(data.improving),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.normal)),
                    const SizedBox(width: 12),
                  ],
                  if (data.worsening > 0) ...[
                    const Icon(Icons.trending_down,
                        size: 14, color: AppColors.high),
                    const SizedBox(width: 4),
                    Text(t.homeWorsening(data.worsening),
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
    final statusIcon = insight.latest.isNormal
        ? Icons.check_rounded
        : insight.latest.isHigh
            ? Icons.arrow_upward_rounded
            : insight.latest.isLow
                ? Icons.arrow_downward_rounded
                : Icons.remove_rounded;

    // Arrow reflects health trend, not raw value direction:
    // green trending_up = improving, red trending_down = worsening.
    final (arrow, arrowColor) = insight.improving
        ? (Icons.trending_up, AppColors.normal)
        : insight.worsening
            ? (Icons.trending_down, AppColors.high)
            : insight.direction == TrendDirection.none
                ? (Icons.remove, AppColors.textTertiary)
                : (Icons.east, AppColors.textTertiary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(color: statusColor, shape: BoxShape.circle),
              child: Icon(statusIcon, size: 12, color: Colors.white),
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
    final t = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
            child: _StatCard(
                label: t.homeReportsStat,
                value: '$reportCount',
                icon: Icons.folder_outlined,
                onTap: onReports)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                label: t.homeResultsStat,
                value: '$entryCount',
                icon: Icons.science_outlined,
                onTap: onResults)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                label: t.homeOutOfRange,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            // Subtle translucent brand tint, echoing the frosted nav bar.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.09),
                AppColors.primaryLight.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 16),
                  ),
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
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.homeQuickActions,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.add_circle_outline,
                label: t.homeLogResult,
                color: AppColors.primary,
                onTap: () => showQuickLogSheet(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.upload_file_outlined,
                label: t.homeUploadReport,
                color: AppColors.primaryLight,
                onTap: () => context.push(AppRoutes.addReport),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.accessibility_new_outlined,
          label: t.homeBodyMap,
          color: AppColors.primaryDark,
          onTap: () => context.push(AppRoutes.bodyMap),
        ),
        const SizedBox(height: 12),
        // Scan Report is not ready yet — disabled with a "Coming soon" badge.
        _ActionCard(
          icon: Icons.document_scanner_outlined,
          label: t.homeScanReportAction,
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
    final t = AppLocalizations.of(context);
    final tint = comingSoon ? AppColors.textTertiary : color;
    return InkWell(
      onTap: comingSoon
          ? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(t.homeScanReportComingSoon),
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
                  child: Text(t.homeComingSoonBadge,
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
    final statusIcon = entry.isNormal
        ? Icons.check_rounded
        : entry.isHigh
            ? Icons.arrow_upward_rounded
            : entry.isLow
                ? Icons.arrow_downward_rounded
                : Icons.remove_rounded;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: statusColor, shape: BoxShape.circle),
              child: Icon(statusIcon, size: 12, color: Colors.white),
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
  final List<String> pinnedIds;
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
    // Render in the user's chosen order (not alphabetical).
    final tiles = [
      for (final id in pinnedIds)
        if (byId[id] != null) byId[id]!,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.push_pin, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(AppLocalizations.of(context).homePinned,
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              if (tiles.length > 1)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.tune_rounded,
                      size: 20, color: AppColors.textSecondary),
                  tooltip: AppLocalizations.of(context).pinnedManage,
                  onPressed: () => showManagePinnedSheet(context),
                ),
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

/// Bottom sheet to reorder (drag) and remove pinned biomarkers.
void showManagePinnedSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _ManagePinnedSheet(),
  );
}

class _ManagePinnedSheet extends ConsumerWidget {
  const _ManagePinnedSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final pinned = ref.watch(pinnedBiomarkersProvider);
    final tracked = ref.watch(trackedBiomarkersProvider).valueOrNull ??
        const <BiomarkerEntryModel>[];
    final nameById = {for (final e in tracked) e.biomarkerId: e.biomarkerName};
    final mq = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mq.padding.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mq.size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(t.pinnedManageTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: pinned.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(t.pinnedEmpty,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium),
                    )
                  : ReorderableListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: pinned.length,
                      onReorder: (oldIndex, newIndex) => ref
                          .read(pinnedBiomarkersProvider.notifier)
                          .reorder(oldIndex, newIndex),
                      itemBuilder: (_, i) {
                        final id = pinned[i];
                        return ListTile(
                          key: ValueKey(id),
                          leading: ReorderableDragStartListener(
                            index: i,
                            child: Icon(Icons.drag_handle,
                                color: AppColors.textTertiary),
                          ),
                          title: Text(nameById[id] ?? id),
                          trailing: IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: AppColors.textTertiary, size: 20),
                            onPressed: () => ref
                                .read(pinnedBiomarkersProvider.notifier)
                                .toggle(id),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
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
    final statusIcon = entry.isHigh
        ? Icons.arrow_upward_rounded
        : entry.isLow
            ? Icons.arrow_downward_rounded
            : entry.isNormal
                ? Icons.check_rounded
                : Icons.remove_rounded;
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
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                      child: Icon(statusIcon, size: 10, color: Colors.white),
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

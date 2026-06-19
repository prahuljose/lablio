import 'dart:ui' show lerpDouble;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/router/app_router.dart';
import '../../../core/units/unit_converter.dart';
import '../../../core/units/unit_system_provider.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/status_style.dart';
import '../../../l10n/app_localizations.dart';
import '../data/biomarker_entry_model.dart';
import '../data/biomarker_model.dart';
import '../data/nutrient_nudges.dart';
import '../providers/biomarker_notes_provider.dart';
import '../providers/biomarkers_provider.dart';
import '../providers/pinned_biomarkers_provider.dart';

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
    final t = AppLocalizations.of(context);
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

    final topPad = MediaQuery.of(context).padding.top;
    final isPinned =
        ref.watch(pinnedBiomarkersProvider).contains(biomarkerId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _BiomarkerHeaderDelegate(
              name: biomarkerName,
              category: biomarker?.category,
              topPadding: topPad,
              isPinned: isPinned,
              onPin: () => ref
                  .read(pinnedBiomarkersProvider.notifier)
                  .toggle(biomarkerId),
              canAdd: biomarker != null,
              onAdd: () {
                if (biomarker != null) _goToAddEntry(context, biomarker);
              },
            ),
          ),
          historyAsync.when(
            loading: () => const SliverToBoxAdapter(
                child: SkeletonList(itemCount: 4)),
            error: (e, _) => SliverFillRemaining(
                child: ErrorView(
                    error: e,
                    onRetry: () =>
                        ref.read(biomarkerEntriesProvider.notifier).refresh()),
              ),
            data: (entries) => entries.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmpty(context, biomarker),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        _buildContentChildren(context, ref, entries,
                            ref.watch(unitSystemProvider), biomarker),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, BiomarkerModel? biomarker) {
    final t = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(t.biomarkerDetailNoEntries,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: biomarker == null
                ? null
                : () => _goToAddEntry(context, biomarker),
            icon: const Icon(Icons.add),
            label: Text(t.biomarkerDetailLogFirst),
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContentChildren(BuildContext context, WidgetRef ref,
      List<BiomarkerEntryModel> entries, UnitSystem system,
      BiomarkerModel? biomarker) {
    final t = AppLocalizations.of(context);
    final latest = entries.last;
    return [
      _LatestValueCard(entry: latest, system: system),
      const SizedBox(height: 16),
      _TrendSection(entries: entries, system: system),
      const SizedBox(height: 16),
      if (biomarker != null) ...[
        _ExplainerCard(biomarker: biomarker, latest: latest),
        const SizedBox(height: 16),
      ],
      ...() {
        final nudge = nutrientNudgeFor(latest.biomarkerId,
            isHigh: latest.isHigh, isLow: latest.isLow);
        if (nudge == null) return const <Widget>[];
        return [
          _LeverCard(text: nudge),
          const SizedBox(height: 16),
        ];
      }(),
      _NotesCard(biomarkerId: biomarkerId),
      const SizedBox(height: 16),
      Text(t.biomarkerDetailHistory, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      ...entries.reversed.map(
        (e) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _EntryRow(entry: e, ref: ref, system: system),
        ),
      ),
    ];
  }
}

class _LatestValueCard extends StatelessWidget {
  final BiomarkerEntryModel entry;
  final UnitSystem system;
  const _LatestValueCard({required this.entry, required this.system});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final conv = UnitConverter.display(
      biomarkerId: entry.biomarkerId,
      value: entry.value,
      unit: entry.unit,
      low: entry.refRangeLow,
      high: entry.refRangeHigh,
      system: system,
    );
    final status = StatusStyle.from(
      isNormal: entry.isNormal,
      isHigh: entry.isHigh,
      isLow: entry.isLow,
    );
    final hasRange = conv.low != null && conv.high != null;
    final numColor = hasRange ? status.color : AppColors.primary;
    final decimals = conv.value.truncateToDouble() == conv.value ? 0 : 2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.biomarkerDetailLatestResult,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: conv.value),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text(
                    v.toStringAsFixed(decimals),
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: numColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(conv.unit,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.textTertiary)),
              ],
            ),
            if (hasRange) ...[
              const SizedBox(height: 4),
              Text(t.biomarkerDetailReference(
                      conv.low.toString(), conv.high.toString(), conv.unit),
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
            // Only show the status banner when there's an actual range result.
            if (status.label != '—') ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: status.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Filled disc with a glyph so status reads without colour.
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                        color: status.color, shape: BoxShape.circle),
                    child: Icon(status.icon, size: 12, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(status.label,
                      style: TextStyle(
                          color: status.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const Spacer(),
                  Text(DateFormat('MMM d, yyyy').format(entry.date),
                      style: TextStyle(
                          color: status.color.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            ], // end if (status.label != '—')
          ],
        ),
      ),
    );
  }
}

enum _TrendRange { m3, m6, y1, all }

extension on _TrendRange {
  String get label => switch (this) {
        _TrendRange.m3 => '3M',
        _TrendRange.m6 => '6M',
        _TrendRange.y1 => '1Y',
        _TrendRange.all => 'All',
      };

  Duration? get window => switch (this) {
        _TrendRange.m3 => const Duration(days: 90),
        _TrendRange.m6 => const Duration(days: 180),
        _TrendRange.y1 => const Duration(days: 365),
        _TrendRange.all => null,
      };
}

/// Trend chart plus a time-range selector. Entries are assumed sorted oldest→newest.
class _TrendSection extends StatefulWidget {
  final List<BiomarkerEntryModel> entries;
  final UnitSystem system;
  const _TrendSection({required this.entries, required this.system});

  @override
  State<_TrendSection> createState() => _TrendSectionState();
}

class _TrendSectionState extends State<_TrendSection> {
  _TrendRange _range = _TrendRange.all;

  @override
  Widget build(BuildContext context) {
    final cutoff = _range.window == null
        ? null
        : DateTime.now().subtract(_range.window!);
    var filtered = cutoff == null
        ? widget.entries
        : widget.entries.where((e) => e.date.isAfter(cutoff)).toList();
    // Always keep at least the most recent point so the chart isn't empty.
    if (filtered.isEmpty) filtered = [widget.entries.last];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 6,
            children: _TrendRange.values.map((r) {
              final sel = r == _range;
              return GestureDetector(
                onTap: () => setState(() => _range = r),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? AppColors.primary : AppColors.divider),
                  ),
                  child: Text(
                    r.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        _TrendChart(entries: filtered, system: widget.system),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<BiomarkerEntryModel> entries;
  final UnitSystem system;
  const _TrendChart({required this.entries, required this.system});

  static Color _dotColor(double y, double? low, double? high) {
    if (low != null && y < low) return AppColors.low;
    if (high != null && y > high) return AppColors.high;
    if (low != null || high != null) return AppColors.normal;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final id = entries.first.biomarkerId;
    double cv(double v) => UnitConverter.convertValue(id, v, system);

    final spots = entries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), cv(e.value.value));
    }).toList();

    final refLow =
        entries.first.refRangeLow == null ? null : cv(entries.first.refRangeLow!);
    final refHigh = entries.first.refRangeHigh == null
        ? null
        : cv(entries.first.refRangeHigh!);
    final values = entries.map((e) => cv(e.value)).toList();
    var minY = (refLow != null
            ? [refLow, ...values].reduce((a, b) => a < b ? a : b)
            : values.reduce((a, b) => a < b ? a : b)) *
        0.9;
    var maxY = (refHigh != null
            ? [refHigh, ...values].reduce((a, b) => a > b ? a : b)
            : values.reduce((a, b) => a > b ? a : b)) *
        1.1;
    // Guard against a flat/zero range (e.g. a single value of 0, or all-equal
    // values) which would collapse the chart's vertical axis.
    if (maxY <= minY) {
      final mid = maxY == 0 ? 1.0 : maxY;
      minY = mid * 0.8;
      maxY = mid * 1.2;
    }
    final single = entries.length == 1;
    // Pick an axis date format based on how much time the data spans.
    // Within ~18 months, day-level labels ("May 27") are clearer; for longer
    // histories switch to month+year ("May 26" = May 2026) to avoid clutter.
    final spanDays =
        entries.last.date.difference(entries.first.date).inDays.abs();
    final axisDateFormat = spanDays > 540 ? 'MMM yy' : 'MMM d';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 12),
              child: Text(AppLocalizations.of(context).biomarkerDetailTrend,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  minX: single ? -0.5 : null,
                  maxX: single ? 0.5 : null,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      // Fixed deep-blue background so white text stays legible
                      // in both light and dark themes (textPrimary inverts).
                      getTooltipColor: (_) => AppColors.primaryDark,
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      getTooltipItems: (spots) => spots.map((s) {
                        final idx = s.x.toInt();
                        final dateStr = (idx >= 0 && idx < entries.length)
                            ? DateFormat('MMM d, yyyy').format(entries[idx].date)
                            : '';
                        return LineTooltipItem(
                          '${s.y}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: dateStr,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w400,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    getTouchedSpotIndicator: (barData, indexes) => indexes
                        .map((i) => TouchedSpotIndicatorData(
                              const FlLine(
                                  color: AppColors.primary, strokeWidth: 1.5),
                              FlDotData(
                                getDotPainter: (spot, _, __, ___) =>
                                    FlDotCirclePainter(
                                  radius: 6,
                                  color: AppColors.primary,
                                  strokeWidth: 3,
                                  strokeColor: Colors.white,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
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
                          style: TextStyle(
                              fontSize: 10, color: AppColors.textTertiary),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        // One tick per data point only — prevents fractional
                        // ticks all flooring to the same index (which showed
                        // the same date repeated, e.g. for a single value).
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          // Skip non-integer tick positions.
                          if ((value - value.roundToDouble()).abs() > 0.01) {
                            return const SizedBox.shrink();
                          }
                          final idx = value.round();
                          if (idx < 0 || idx >= entries.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              DateFormat(axisDateFormat)
                                  .format(entries[idx].date),
                              style: TextStyle(
                                  fontSize: 9, color: AppColors.textTertiary),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  // Shade the healthy reference range as a soft green band so
                  // "in / out of range" is readable at a glance.
                  rangeAnnotations: RangeAnnotations(
                    horizontalRangeAnnotations: [
                      if (refLow != null && refHigh != null)
                        HorizontalRangeAnnotation(
                          y1: refLow,
                          y2: refHigh,
                          color: AppColors.normal.withValues(alpha: 0.10),
                        ),
                    ],
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      if (refLow != null)
                        HorizontalLine(
                          y: refLow,
                          color: AppColors.normal.withValues(alpha: 0.35),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      if (refHigh != null)
                        HorizontalLine(
                          y: refHigh,
                          color: AppColors.normal.withValues(alpha: 0.35),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                    ],
                  ),
                  // A single smooth "river" line in the brand gradient with a
                  // soft gradient fill flowing beneath it. Dots stay status-
                  // coloured (green/amber/red) so in/out-of-range reads at a
                  // glance, and out-of-range points get a larger ringed marker.
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.28,
                      preventCurveOverShooting: true,
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primaryDark,
                          AppColors.primary,
                          AppColors.primaryLight,
                        ],
                      ),
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) {
                          final c = _dotColor(spot.y, refLow, refHigh);
                          final outOfRange = (refLow != null &&
                                  spot.y < refLow) ||
                              (refHigh != null && spot.y > refHigh);
                          return FlDotCirclePainter(
                            radius: outOfRange ? 5 : 4,
                            color: c,
                            strokeWidth: outOfRange ? 2.5 : 2,
                            strokeColor: AppColors.surface,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.28),
                            AppColors.primaryLight.withValues(alpha: 0.02),
                          ],
                        ),
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
  final UnitSystem system;
  const _EntryRow(
      {required this.entry, required this.ref, required this.system});

  @override
  Widget build(BuildContext context) {
    final conv = UnitConverter.display(
      biomarkerId: entry.biomarkerId,
      value: entry.value,
      unit: entry.unit,
      system: system,
    );
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
                  if (entry.tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: entry.tags
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(t,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '${conv.value} ${conv.unit}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _confirmDelete(context),
              child: Icon(Icons.delete_outline,
                  color: AppColors.textTertiary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.biomarkerDetailDeleteTitle),
        content: Text(t.biomarkerDetailDeleteBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.commonCancel)),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              ref.read(biomarkerEntriesProvider.notifier).remove(entry.id);
            },
            child: Text(t.commonDelete,
                style: const TextStyle(color: AppColors.high)),
          ),
        ],
      ),
    );
  }
}


class _ExplainerCard extends StatelessWidget {
  final BiomarkerModel biomarker;
  final BiomarkerEntryModel latest;
  const _ExplainerCard({required this.biomarker, required this.latest});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isHigh = latest.isHigh;
    final isLow = latest.isLow;
    String? text;
    String? heading;
    Color? color;
    IconData icon = Icons.info_outline;
    if (isHigh && biomarker.explanationHigh != null) {
      text = biomarker.explanationHigh;
      heading = t.biomarkerDetailWhatHighMeans;
      color = AppColors.high;
      icon = Icons.warning_amber_outlined;
    } else if (isLow && biomarker.explanationLow != null) {
      text = biomarker.explanationLow;
      heading = t.biomarkerDetailWhatLowMeans;
      color = AppColors.low;
      icon = Icons.warning_amber_outlined;
    } else if (biomarker.description != null &&
        biomarker.description!.isNotEmpty) {
      text = biomarker.description;
      heading = t.biomarkerDetailAbout(biomarker.name);
      color = AppColors.primary;
      icon = Icons.menu_book_outlined;
    }
    if (text == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(heading!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(text, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(
              t.biomarkerDetailInfoDisclaimer,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diet & lifestyle "levers" for a marker that's currently out of range.
class _LeverCard extends StatelessWidget {
  final String text;
  const _LeverCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 18, color: AppColors.normal),
                const SizedBox(width: 8),
                Text(t.biomarkerDetailWhatMayHelp,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.normal)),
              ],
            ),
            const SizedBox(height: 8),
            Text(text, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(
              t.biomarkerDetailGuidanceDisclaimer,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesCard extends ConsumerStatefulWidget {
  final String biomarkerId;
  const _NotesCard({required this.biomarkerId});

  @override
  ConsumerState<_NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends ConsumerState<_NotesCard> {
  final _controller = TextEditingController();
  String _saved = '';
  bool _hydrated = false;
  bool _saving = false;

  void _hydrate(String body) {
    if (_hydrated) return;
    _hydrated = true;
    _saved = body;
    _controller.text = body;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(biomarkerNotesProvider.notifier)
          .save(widget.biomarkerId, _controller.text.trim());
      _saved = _controller.text.trim();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).biomarkerDetailNoteSaved),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.normal,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              AppLocalizations.of(context).commonCouldNotSave(e.toString())),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.high,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final notesAsync = ref.watch(biomarkerNotesProvider);
    final body = notesAsync.valueOrNull?[widget.biomarkerId]?.body ?? '';
    _hydrate(body);
    final dirty = _controller.text.trim() != _saved;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note,
                    size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(t.biomarkerDetailNotes,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (dirty)
                  TextButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : Text(t.commonSave),
                  ),
              ],
            ),
            TextField(
              controller: _controller,
              onChanged: (_) => setState(() {}),
              maxLines: null,
              minLines: 2,
              decoration: InputDecoration(
                hintText: t.biomarkerDetailNotesHint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A [SliverPersistentHeaderDelegate] that animates the biomarker name and
/// category label from no left-padding (fully expanded) to just-right-of-the-
/// back-button padding (fully collapsed). Uses [shrinkOffset] directly so the
/// transition tracks the user's scroll with no separate animation controller.
class _BiomarkerHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String name;
  final String? category;
  final double topPadding;
  final bool isPinned;
  final VoidCallback onPin;
  final bool canAdd;
  final VoidCallback onAdd;

  const _BiomarkerHeaderDelegate({
    required this.name,
    this.category,
    required this.topPadding,
    required this.isPinned,
    required this.onPin,
    required this.canAdd,
    required this.onAdd,
  });

  static const double _expandedExtra = 54.0; // extra height beyond the toolbar

  @override
  double get minExtent => kToolbarHeight + topPadding;

  @override
  double get maxExtent => kToolbarHeight + topPadding + _expandedExtra;

  @override
  bool shouldRebuild(covariant _BiomarkerHeaderDelegate old) =>
      old.name != name ||
      old.category != category ||
      old.isPinned != isPinned ||
      old.canAdd != canAdd ||
      old.topPadding != topPadding;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final totalDelta = maxExtent - minExtent; // == _expandedExtra
    // t = 0 fully expanded, t = 1 fully collapsed.
    final t = totalDelta > 0
        ? (shrinkOffset / totalDelta).clamp(0.0, 1.0)
        : 1.0;

    // Left padding: 16 when expanded → 72 when collapsed (clears 56px back btn).
    final titleLeft = lerpDouble(15.0, 45.0, t)!;
    // Category fades out quickly in the first 40% of collapse.
    final categoryOpacity = ((1.0 - t / 0.4)).clamp(0.0, 1.0);

    // maxLines: 2 when expanded, 1 when mostly collapsed.
    final titleMaxLines = t > 0.6 ? 1 : 2;
    // Bottom offset: 10 when expanded (breathing room), 18 when collapsed
    // (vertically centred in kToolbarHeight ≈ 56px for a ~20px line).
    final titleBottom = lerpDouble(10.0, 18.0, t)!;

    return ClipRect(
      child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
      ),
      child: Stack(
        children: [
          // ── Toolbar row: always fixed below status bar ─────────
          Positioned(
            top: topPadding,
            left: 0,
            right: 0,
            height: kToolbarHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: Colors.white,
                  ),
                  tooltip: AppLocalizations.of(context).biomarkerDetailPinTooltip,
                  onPressed: onPin,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: Colors.white),
                  onPressed: canAdd ? onAdd : null,
                ),
              ],
            ),
          ),

          // ── Animated title + category ──────────────────────────
          // No fixed height — content grows upward from the bottom.
          // ClipRect on the parent prevents overflow outside the header.
          // Switch to 1 line at 60% collapse so it fits when nearly collapsed.
          Positioned(
            bottom: titleBottom,
            left: 0,
            right: 0,
            child: Padding(
              // right: 96 = 2 action buttons (pin + add) × 48px each
              padding: EdgeInsets.only(left: titleLeft, right: 96),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category != null && categoryOpacity > 0)
                    Opacity(
                      opacity: categoryOpacity,
                      child: Text(
                        category!.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Text(
                    name,
                    maxLines: titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
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

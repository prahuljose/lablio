import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/router/app_router.dart';
import '../../../core/units/unit_converter.dart';
import '../../../core/widgets/animated_lablio_logo.dart';
import '../../../core/widgets/lablio_refresh.dart';
import '../../../core/units/unit_system_provider.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/status_style.dart';
import '../../../l10n/app_localizations.dart';
import '../data/biomarker_entry_model.dart';
import '../providers/biomarkers_provider.dart';
import 'quick_log_sheet.dart';

class BiomarkersScreen extends ConsumerStatefulWidget {
  const BiomarkersScreen({super.key});

  @override
  ConsumerState<BiomarkersScreen> createState() => _BiomarkersScreenState();
}

class _BiomarkersScreenState extends ConsumerState<BiomarkersScreen> {
  String _query = '';
  BiomarkerFilter _filter = BiomarkerFilter.all;
  BiomarkerSort _sort = BiomarkerSort.name;
  String? _categoryFilter;
  String? _tagFilter;

  @override
  void initState() {
    super.initState();
    // Pick up a filter requested by another screen (e.g. Home "Out of Range").
    _filter = ref.read(biomarkerInitialFilterProvider);
    // Reset so it doesn't stick on the next visit.
    Future.microtask(() => ref
        .read(biomarkerInitialFilterProvider.notifier)
        .state = BiomarkerFilter.all);
  }

  bool _matchesFilter(BiomarkerEntryModel e) {
    switch (_filter) {
      case BiomarkerFilter.all:
        return true;
      case BiomarkerFilter.normal:
        return e.isNormal;
      case BiomarkerFilter.high:
        return e.isHigh;
      case BiomarkerFilter.low:
        return e.isLow;
      case BiomarkerFilter.outOfRange:
        return e.isHigh || e.isLow;
    }
  }

  int _statusRank(BiomarkerEntryModel e) {
    if (e.isHigh) return 0;
    if (e.isLow) return 1;
    if (e.isNormal) return 2;
    return 3;
  }

  List<BiomarkerEntryModel> _process(List<BiomarkerEntryModel> tracked) {
    var list = tracked.where(_matchesFilter).toList();
    if (_categoryFilter != null) {
      list = list
          .where((e) => e.biomarkerCategory == _categoryFilter)
          .toList();
    }
    if (_tagFilter != null) {
      list = list.where((e) => e.tags.contains(_tagFilter)).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((e) => e.biomarkerName.toLowerCase().contains(q) ||
              e.biomarkerCategory.toLowerCase().contains(q))
          .toList();
    }
    switch (_sort) {
      case BiomarkerSort.name:
        list.sort((a, b) => a.biomarkerName.compareTo(b.biomarkerName));
      case BiomarkerSort.recent:
        list.sort((a, b) => b.date.compareTo(a.date));
      case BiomarkerSort.status:
        list.sort((a, b) {
          final c = _statusRank(a).compareTo(_statusRank(b));
          return c != 0 ? c : a.biomarkerName.compareTo(b.biomarkerName);
        });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final trackedAsync = ref.watch(trackedBiomarkersProvider);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 52,
        titleSpacing: 8 ,
        leading: const LablioAppBarLogo(),
        title: Text(t.navBiomarkers),
        actions: [
          PopupMenuButton<BiomarkerSort>(
            icon: const Icon(Icons.sort),
            tooltip: t.biomarkersSortTooltip,
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: BiomarkerSort.name, child: Text(t.biomarkersSortName)),
              PopupMenuItem(
                  value: BiomarkerSort.recent,
                  child: Text(t.biomarkersSortRecent)),
              PopupMenuItem(
                  value: BiomarkerSort.status, child: Text(t.biomarkersSortStatus)),
            ],
          ),
        ],
      ),
      floatingActionButton: Padding(
        // Lift above the floating nav bar (extendBody is on in the shell).
        padding: const EdgeInsets.only(bottom: 96),
        child: FloatingActionButton.extended(
          onPressed: () => showQuickLogSheet(context),
          icon: const Icon(Icons.add),
          label: Text(t.homeLogResult),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
      body: trackedAsync.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorView(
            error: e,
            onRetry: () =>
                ref.read(biomarkerEntriesProvider.notifier).refresh()),
        data: (tracked) {
          if (tracked.isEmpty) return _buildEmpty(context);
          final list = _process(tracked);
          // Unique categories from tracked biomarkers, sorted alphabetically.
          final categories = tracked
              .map((e) => e.biomarkerCategory)
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          return Column(
            children: [
              _SearchBar(onChanged: (v) => setState(() => _query = v)),
              _FilterChips(
                selected: _filter,
                onSelected: (f) {
                  HapticFeedback.selectionClick();
                  setState(() => _filter = f);
                },
              ),
              if (categories.length > 1)
                _CategoryChips(
                  categories: categories,
                  selected: _categoryFilter,
                  onSelected: (c) {
                    HapticFeedback.selectionClick();
                    setState(() =>
                        _categoryFilter = _categoryFilter == c ? null : c);
                  },
                ),
              // Tag filter — only shown when at least one entry has a tag.
              Builder(builder: (context) {
                final allTags = tracked
                    .expand((e) => e.tags)
                    .toSet()
                    .toList()
                  ..sort();
                if (allTags.isEmpty) return const SizedBox.shrink();
                return _TagChips(
                  tags: allTags,
                  selected: _tagFilter,
                  onSelected: (t) {
                    HapticFeedback.selectionClick();
                    setState(() =>
                        _tagFilter = _tagFilter == t ? null : t);
                  },
                );
              }),
              Expanded(
                child: LablioRefresh(
                  onRefresh: () async {
                    try {
                      await ref
                          .read(biomarkerEntriesProvider.notifier)
                          .refresh();
                    } catch (e) {
                      if (context.mounted) {
                        showOfflineAwareSnackBar(context, e);
                      }
                    }
                  },
                  child: list.isEmpty
                      // AlwaysScrollable so pull-to-refresh works even when empty.
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.5,
                              child: _buildNoMatches(context),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _BiomarkerTile(
                            entry: list[i],
                            system: ref.watch(unitSystemProvider),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoMatches(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_alt_off_outlined,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(t.biomarkersNoMatches,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(t.biomarkersEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(t.biomarkersEmptySubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    setState(() {}); // keep focus / keyboard open, just reset the text
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _controller,
        onChanged: (v) {
          widget.onChanged(v);
          setState(() {}); // toggle the clear button
        },
        decoration: InputDecoration(
          hintText: t.biomarkersSearchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: t.biomarkersClear,
                  onPressed: _clear,
                ),
          isDense: true,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.divider, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final BiomarkerFilter selected;
  final ValueChanged<BiomarkerFilter> onSelected;
  const _FilterChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final labels = {
      BiomarkerFilter.all: t.biomarkersFilterAll,
      BiomarkerFilter.outOfRange: t.biomarkersFilterOutOfRange,
      BiomarkerFilter.high: t.biomarkersStatusHigh,
      BiomarkerFilter.low: t.biomarkersStatusLow,
      BiomarkerFilter.normal: t.biomarkersStatusNormal,
    };
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: labels.entries.map((e) {
          final isSel = e.key == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.value),
              selected: isSel,
              showCheckmark: false,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSel ? Colors.white : AppColors.textSecondary,
              ),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              shape: const StadiumBorder(),
              side: BorderSide(
                  color: isSel ? AppColors.primary : AppColors.divider),
              onSelected: (_) => onSelected(e.key),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSel = cat == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSel,
              showCheckmark: false,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSel ? Colors.white : AppColors.textSecondary,
              ),
              selectedColor: AppColors.primaryDark,
              backgroundColor: AppColors.surface,
              shape: const StadiumBorder(),
              side: BorderSide(
                  color: isSel ? AppColors.primaryDark : AppColors.divider),
              onSelected: (_) => onSelected(cat),
            ),
          );
        },
      ),
    );
  }
}

class _TagChips extends StatelessWidget {
  final List<String> tags;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _TagChips({
    required this.tags,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        itemCount: tags.length,
        itemBuilder: (_, i) {
          final tag = tags[i];
          final isSel = tag == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.label_outline,
                      size: 13,
                      color: isSel ? Colors.white : AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(tag),
                ],
              ),
              selected: isSel,
              showCheckmark: false,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSel ? Colors.white : AppColors.textSecondary,
              ),
              selectedColor: AppColors.primaryLight,
              backgroundColor: AppColors.surface,
              shape: const StadiumBorder(),
              side: BorderSide(
                  color: isSel ? AppColors.primaryLight : AppColors.divider),
              onSelected: (_) => onSelected(tag),
            ),
          );
        },
      ),
    );
  }
}

class _BiomarkerTile extends ConsumerWidget {
  final BiomarkerEntryModel entry;
  final UnitSystem system;
  const _BiomarkerTile({required this.entry, required this.system});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final conv = UnitConverter.display(
      biomarkerId: entry.biomarkerId,
      value: entry.value,
      unit: entry.unit,
      system: system,
    );
    final status = StatusStyle.from(
        isNormal: entry.isNormal, isHigh: entry.isHigh, isLow: entry.isLow);

    // History for the sparkline (oldest → newest).
    final history = (ref.watch(biomarkerEntriesProvider).valueOrNull ?? [])
        .where((e) => e.biomarkerId == entry.biomarkerId)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final sparkValues = history.map((e) => e.value).toList();

    // Delta vs the previous reading (in display units), tinted by whether the
    // change moved the value toward (green) or away from (red) its range.
    final delta = history.length >= 2
        ? _DeltaInfo.compute(history[history.length - 2], entry, system)
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.biomarkerDetail,
          extra: {
            'biomarkerId': entry.biomarkerId,
            'biomarkerName': entry.biomarkerName,
          },
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Status accent bar.
              Container(width: 4, color: status.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.biomarkerName,
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text(entry.biomarkerCategory,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                      t.biomarkersLatest(
                                          conv.value.toString(), conv.unit),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                ),
                                if (delta != null) ...[
                                  const SizedBox(width: 8),
                                  _DeltaChip(info: delta),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (sparkValues.length >= 2) ...[
                        const SizedBox(width: 10),
                        _Sparkline(values: sparkValues, color: status.color),
                      ],
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Hide chip entirely when there's no reference range.
                          if (status.label != '—')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: status.bg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(status.icon,
                                      size: 13, color: status.color),
                                  const SizedBox(width: 3),
                                  Text(status.label,
                                      style: TextStyle(
                                        color: status.color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ],
                              ),
                            ),
                          const SizedBox(height: 4),
                          Icon(Icons.chevron_right,
                              color: AppColors.textTertiary, size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The change between the two most recent readings, with a colour that tells
/// the user whether the move was *healthy* (toward the range) or not.
class _DeltaInfo {
  final double amount; // signed, in display units
  final Color color;
  const _DeltaInfo({required this.amount, required this.color});

  static _DeltaInfo? compute(
      BiomarkerEntryModel prev, BiomarkerEntryModel curr, UnitSystem system) {
    final id = curr.biomarkerId;
    final currDisp = UnitConverter.convertValue(id, curr.value, system);
    final prevDisp = UnitConverter.convertValue(id, prev.value, system);
    final d = currDisp - prevDisp;
    if (d.abs() < 1e-9) return null;

    // Distance outside the reference range (0 when inside) — comparing the two
    // tells us if the value moved toward or away from the healthy band.
    final low = curr.refRangeLow;
    final high = curr.refRangeHigh;
    Color color = AppColors.textTertiary;
    if (low != null || high != null) {
      double out(double v) {
        if (low != null && v < low) return low - v;
        if (high != null && v > high) return v - high;
        return 0;
      }

      final outCurr = out(curr.value);
      final outPrev = out(prev.value);
      if (outCurr < outPrev - 1e-9) {
        color = AppColors.normal; // moved toward range — improving
      } else if (outCurr > outPrev + 1e-9) {
        color = AppColors.high; // moved away from range — worsening
      }
    }
    return _DeltaInfo(amount: d, color: color);
  }
}

class _DeltaChip extends StatelessWidget {
  final _DeltaInfo info;
  const _DeltaChip({required this.info});

  static String _fmt(double v) {
    if (v == v.roundToDouble() || v.abs() >= 10) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final up = info.amount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
              size: 11, color: info.color),
          const SizedBox(width: 2),
          Text(
            _fmt(info.amount.abs()),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: info.color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  const _Sparkline({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])
    ];
    return SizedBox(
      width: 56,
      height: 30,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

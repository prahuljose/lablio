import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../data/biomarker_entry_model.dart';
import '../providers/biomarkers_provider.dart';

class BiomarkersScreen extends ConsumerStatefulWidget {
  const BiomarkersScreen({super.key});

  @override
  ConsumerState<BiomarkersScreen> createState() => _BiomarkersScreenState();
}

class _BiomarkersScreenState extends ConsumerState<BiomarkersScreen> {
  String _query = '';
  BiomarkerFilter _filter = BiomarkerFilter.all;
  BiomarkerSort _sort = BiomarkerSort.name;

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
    final trackedAsync = ref.watch(trackedBiomarkersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biomarkers'),
        actions: [
          PopupMenuButton<BiomarkerSort>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: BiomarkerSort.name, child: Text('Sort: Name (A–Z)')),
              PopupMenuItem(
                  value: BiomarkerSort.recent,
                  child: Text('Sort: Most recent')),
              PopupMenuItem(
                  value: BiomarkerSort.status, child: Text('Sort: Status')),
            ],
          ),
        ],
      ),
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
        data: (tracked) {
          if (tracked.isEmpty) return _buildEmpty(context);
          final list = _process(tracked);
          return Column(
            children: [
              _SearchBar(onChanged: (v) => setState(() => _query = v)),
              _FilterChips(
                selected: _filter,
                onSelected: (f) => setState(() => _filter = f),
              ),
              Expanded(
                child: list.isEmpty
                    ? _buildNoMatches(context)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _BiomarkerTile(entry: list[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoMatches(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.filter_alt_off_outlined,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text('No biomarkers match your filters',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
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
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'Search biomarkers…',
          prefixIcon: Icon(Icons.search),
          isDense: true,
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final BiomarkerFilter selected;
  final ValueChanged<BiomarkerFilter> onSelected;
  const _FilterChips({required this.selected, required this.onSelected});

  static const _labels = {
    BiomarkerFilter.all: 'All',
    BiomarkerFilter.outOfRange: 'Out of Range',
    BiomarkerFilter.high: 'High',
    BiomarkerFilter.low: 'Low',
    BiomarkerFilter.normal: 'Normal',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _labels.entries.map((e) {
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

class _BiomarkerTile extends StatelessWidget {
  final BiomarkerEntryModel entry;
  const _BiomarkerTile({required this.entry});

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
                    const SizedBox(height: 2),
                    Text(entry.biomarkerCategory,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Latest: ${entry.value} ${entry.unit}',
                        style: Theme.of(context).textTheme.bodyMedium),
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

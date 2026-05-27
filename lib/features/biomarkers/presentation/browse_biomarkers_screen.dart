import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/biomarker_model.dart';
import '../providers/biomarkers_provider.dart';

class BrowseBiomarkersScreen extends ConsumerStatefulWidget {
  /// When launched from a report detail screen, entries will be linked to this report.
  final String? reportId;
  const BrowseBiomarkersScreen({super.key, this.reportId});

  @override
  ConsumerState<BrowseBiomarkersScreen> createState() =>
      _BrowseBiomarkersScreenState();
}

class _BrowseBiomarkersScreenState
    extends ConsumerState<BrowseBiomarkersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final biomarkersAsync = ref.watch(referenceBiomarkersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Biomarker')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search biomarkers...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: biomarkersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (biomarkers) {
                final filtered = _query.isEmpty
                    ? biomarkers
                    : biomarkers
                        .where((b) =>
                            b.name.toLowerCase().contains(_query) ||
                            b.shortName.toLowerCase().contains(_query) ||
                            b.category.toLowerCase().contains(_query))
                        .toList();

                final grouped = <String, List<BiomarkerModel>>{};
                for (final b in filtered) {
                  grouped.putIfAbsent(b.category, () => []).add(b);
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text('No biomarkers found',
                        style: Theme.of(context).textTheme.bodyMedium),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    for (final category in grouped.keys) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 6),
                        child: Text(
                          category,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5),
                        ),
                      ),
                      ...grouped[category]!.map(
                        (b) => _BiomarkerListTile(
                          biomarker: b,
                          reportId: widget.reportId,
                          sex: ref.watch(profileProvider).valueOrNull?.sex,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BiomarkerListTile extends StatelessWidget {
  final BiomarkerModel biomarker;
  final String? reportId;
  final String? sex;
  const _BiomarkerListTile({required this.biomarker, this.reportId, this.sex});

  @override
  Widget build(BuildContext context) {
    final range = biomarker.rangeForSex(sex);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(biomarker.name,
            style: Theme.of(context).textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(biomarker.shortName,
                style: Theme.of(context).textTheme.bodyMedium),
            if (range.low != null && range.high != null)
              Text(
                'Ref: ${range.low} – ${range.high} ${biomarker.unit}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 12, color: AppColors.textTertiary),
              ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary),
        onTap: () => context.push(
          AppRoutes.addEntry,
          extra: {
            'biomarkerId': biomarker.id,
            'biomarkerName': biomarker.name,
            'biomarker': biomarker,
            if (reportId != null) 'reportId': reportId,
          },
        ),
      ),
    );
  }
}

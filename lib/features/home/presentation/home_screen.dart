import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../biomarkers/providers/biomarkers_provider.dart';
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
            ),
            const SizedBox(height: 24),
            _QuickActions(),
            const SizedBox(height: 24),
            Text('Recent Results',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (entries) => entries.isEmpty
                  ? _buildEmptyResults(context)
                  : Column(
                      children: entries
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
          const Icon(Icons.science_outlined,
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

class _StatsRow extends StatelessWidget {
  final AsyncValue reportsAsync;
  final AsyncValue entriesAsync;

  const _StatsRow({required this.reportsAsync, required this.entriesAsync});

  @override
  Widget build(BuildContext context) {
    final reportCount =
        reportsAsync.valueOrNull?.length ?? 0;
    final entryCount =
        entriesAsync.valueOrNull?.length ?? 0;

    // Count out-of-range entries (latest per biomarker)
    final entries = entriesAsync.valueOrNull ?? [];
    final outOfRange = entries
        .where((e) => e.isHigh || e.isLow)
        .length;

    return Row(
      children: [
        Expanded(
            child: _StatCard(
                label: 'Reports', value: '$reportCount', icon: Icons.folder_outlined)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                label: 'Results', value: '$entryCount', icon: Icons.science_outlined)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                label: 'Out of Range',
                value: '$outOfRange',
                icon: Icons.warning_amber_outlined,
                valueColor: outOfRange > 0 ? AppColors.high : null)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
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
                onTap: () => context.push(AppRoutes.browseBiomarkers),
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
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: color)),
          ],
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

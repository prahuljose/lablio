import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/nav_scroll.dart';
import '../../../core/widgets/lablio_refresh.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/animated_lablio_logo.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../l10n/app_localizations.dart';
import '../data/report_model.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsProvider);
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 52,
        titleSpacing: 8,
        leading: const LablioAppBarLogo(),
        title: Text(t.navReports),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: t.commonRefresh,
            onPressed: () => ref.read(reportsProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: Padding(
        // Lift above the floating nav bar (extendBody is on in the shell).
        padding: const EdgeInsets.only(bottom: 96),
        child: FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.addReport),
          icon: const Icon(Icons.add),
          label: Text(t.reportsAddButton),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
      body: LablioRefresh(
        onRefresh: () async {
          try {
            await ref.read(reportsProvider.notifier).refresh();
          } catch (e) {
            if (context.mounted) showOfflineAwareSnackBar(context, e);
          }
        },
        child: reportsAsync.when(
          loading: () => const SkeletonList(),
          error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.read(reportsProvider.notifier).refresh()),
          data: (reports) => reports.isEmpty
              ? _buildEmpty(context)
              : _buildList(context, ref, reports),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final t = AppLocalizations.of(context);
    // Scrollable so pull-to-refresh works even when the list is empty.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined,
              size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(t.reportsEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(t.reportsEmptyBody,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
      ],
    );
  }

  Widget _buildList(
      BuildContext context, WidgetRef ref, List<ReportModel> reports) {
    return ListView.separated(
      controller: ref.watch(navScrollControllersProvider)[1],
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _ReportCard(report: reports[i]),
    );
  }
}

class _ReportCard extends ConsumerWidget {
  final ReportModel report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final dateStr = DateFormat('MMM d, yyyy').format(report.date);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.reportDetail, extra: report),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.description_outlined,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(dateStr,
                              style: Theme.of(context).textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (report.pdfUrl != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.picture_as_pdf,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(t.reportsPdfAttached,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.primary),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                    if (report.notes != null && report.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(report.notes!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDelete(context, ref);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: AppColors.high),
                        const SizedBox(width: 8),
                        Text(t.commonDelete,
                            style: const TextStyle(color: AppColors.high)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.reportsDeleteTitle),
        content: Text(t.reportsDeleteConfirm(report.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.commonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(reportsProvider.notifier)
                  .remove(report.id, pdfPath: report.pdfPath);
            },
            child: Text(t.commonDelete,
                style: const TextStyle(color: AppColors.high)),
          ),
        ],
      ),
    );
  }
}

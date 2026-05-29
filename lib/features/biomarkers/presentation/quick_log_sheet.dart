import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../data/biomarker_model.dart';
import '../providers/custom_biomarkers_provider.dart';

/// Half-sheet biomarker picker — faster alternative to the full "Select
/// Biomarker" route for the common "log a value now" flow.
Future<void> showQuickLogSheet(BuildContext context, {String? reportId}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuickLogSheet(reportId: reportId),
  );
}

class _QuickLogSheet extends ConsumerStatefulWidget {
  final String? reportId;
  const _QuickLogSheet({this.reportId});

  @override
  ConsumerState<_QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends ConsumerState<_QuickLogSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allBiomarkersProvider).valueOrNull ??
        const <BiomarkerModel>[];
    final q = _q.trim().toLowerCase();
    final results = q.isEmpty
        ? all.take(40).toList()
        : all
            .where((b) =>
                b.name.toLowerCase().contains(q) ||
                b.shortName.toLowerCase().contains(q) ||
                b.category.toLowerCase().contains(q))
            .take(40)
            .toList();

    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollCtl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Text('Log a result',
                        style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Add custom biomarker',
                      onPressed: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.addCustomBiomarker);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => _q = v),
                  decoration: const InputDecoration(
                    hintText: 'Search biomarkers…',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtl,
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final b = results[i];
                    return ListTile(
                      leading: const Icon(Icons.biotech_outlined,
                          color: AppColors.primary),
                      title: Text(b.name),
                      subtitle: Text(b.category),
                      trailing: Icon(Icons.chevron_right,
                          color: AppColors.textTertiary),
                      onTap: () {
                        Navigator.pop(context);
                        context.push(
                          AppRoutes.addEntry,
                          extra: {
                            'biomarkerId': b.id,
                            'biomarkerName': b.name,
                            'biomarker': b,
                            if (widget.reportId != null)
                              'reportId': widget.reportId,
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

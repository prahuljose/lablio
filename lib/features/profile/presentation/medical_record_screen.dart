import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/branded_date_picker.dart';
import '../../../core/widgets/animated_lablio_logo.dart';
import '../../../l10n/app_localizations.dart';
import '../data/medical_record_model.dart';
import '../providers/medical_record_provider.dart';

String _singularL(AppLocalizations t, MedicalRecordKind k) => switch (k) {
      MedicalRecordKind.vaccination => t.medicalSingularVaccination,
      MedicalRecordKind.allergy => t.medicalSingularAllergy,
      MedicalRecordKind.condition => t.medicalSingularCondition,
    };

String _pluralL(AppLocalizations t, MedicalRecordKind k) => switch (k) {
      MedicalRecordKind.vaccination => t.medicalTabVaccinations,
      MedicalRecordKind.allergy => t.medicalTabAllergies,
      MedicalRecordKind.condition => t.medicalTabConditions,
    };

class MedicalRecordScreen extends ConsumerWidget {
  const MedicalRecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.profileMedicalRecord),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: t.medicalTabVaccinations),
              Tab(text: t.medicalTabAllergies),
              Tab(text: t.medicalTabConditions),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RecordList(kind: MedicalRecordKind.vaccination),
            _RecordList(kind: MedicalRecordKind.allergy),
            _RecordList(kind: MedicalRecordKind.condition),
          ],
        ),
      ),
    );
  }
}

class _RecordList extends ConsumerWidget {
  final MedicalRecordKind kind;
  const _RecordList({required this.kind});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(medicalRecordProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref, kind),
        icon: const Icon(Icons.add),
        label: Text(t.medicalAddItem(_singularL(t, kind))),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: async.when(
        loading: () => const LablioLoader(),
        error: (e, _) => ErrorView(
            error: e,
            onRetry: () async => ref.invalidate(medicalRecordProvider)),
        data: (entries) {
          final filtered =
              entries.where((e) => e.kind == kind).toList();
          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(t.medicalNoneLogged(_pluralL(t, kind).toLowerCase()),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _Tile(
              entry: filtered[i],
              onDelete: () => ref
                  .read(medicalRecordProvider.notifier)
                  .remove(filtered[i].id),
            ),
          );
        },
      ),
    );
  }

}

class _Tile extends StatelessWidget {
  final MedicalRecordEntry entry;
  final VoidCallback onDelete;
  const _Tile({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        title: Text(entry.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([
          if (entry.occurredOn != null)
            DateFormat('MMM d, yyyy').format(entry.occurredOn!),
          if (entry.severity != null) t.medicalSeverityValue(entry.severity!),
          if (entry.status != null) t.medicalStatusValue(entry.status!),
          if (entry.notes != null && entry.notes!.isNotEmpty) entry.notes!,
        ].join('  ·  ')),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline,
              color: AppColors.textTertiary),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

Future<void> _showAddSheet(
    BuildContext context, WidgetRef ref, MedicalRecordKind kind) async {
  final t = AppLocalizations.of(context);
  final nameCtl = TextEditingController();
  final notesCtl = TextEditingController();
  DateTime? date;
  String? severity;
  String? status;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 4,
        ),
        child: StatefulBuilder(builder: (ctx, setLocal) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.medicalAddItem(_singularL(t, kind)),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: switch (kind) {
                    MedicalRecordKind.vaccination => t.medicalNameVaccine,
                    MedicalRecordKind.allergy => t.medicalNameAllergen,
                    MedicalRecordKind.condition => t.medicalNameCondition,
                  },
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showBrandedDatePicker(
                    context: ctx,
                    initialDate: date ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setLocal(() => date = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: kind == MedicalRecordKind.vaccination
                        ? t.medicalDateGiven
                        : kind == MedicalRecordKind.condition
                            ? t.medicalDiagnosedOn
                            : t.medicalFirstNoticed,
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(date == null
                      ? t.medicalSelectDate
                      : DateFormat('MMM d, yyyy').format(date!)),
                ),
              ),
              if (kind == MedicalRecordKind.allergy) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: severity,
                  decoration: InputDecoration(labelText: t.medicalSeverity),
                  items: [
                    DropdownMenuItem(
                        value: 'Mild', child: Text(t.medicalSeverityMild)),
                    DropdownMenuItem(
                        value: 'Moderate',
                        child: Text(t.medicalSeverityModerate)),
                    DropdownMenuItem(
                        value: 'Severe', child: Text(t.medicalSeveritySevere)),
                  ],
                  onChanged: (v) => setLocal(() => severity = v),
                ),
              ],
              if (kind == MedicalRecordKind.condition) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: InputDecoration(labelText: t.medicalStatus),
                  items: [
                    DropdownMenuItem(
                        value: 'Active', child: Text(t.medicalStatusActive)),
                    DropdownMenuItem(
                        value: 'Resolved',
                        child: Text(t.medicalStatusResolved)),
                  ],
                  onChanged: (v) => setLocal(() => status = v),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: notesCtl,
                maxLines: 2,
                decoration:
                    InputDecoration(labelText: t.addEntryNotes),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtl.text.trim().isEmpty) return;
                    final entry = MedicalRecordEntry(
                      id: const Uuid().v4(),
                      kind: kind,
                      name: nameCtl.text.trim(),
                      occurredOn: date,
                      severity: severity,
                      status: status,
                      notes: notesCtl.text.trim().isEmpty
                          ? null
                          : notesCtl.text.trim(),
                      createdAt: DateTime.now(),
                    );
                    try {
                      await ref
                          .read(medicalRecordProvider.notifier)
                          .add(entry);
                      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                    } catch (e) {
                      if (sheetCtx.mounted) {
                        ScaffoldMessenger.of(sheetCtx).showSnackBar(SnackBar(
                          content: Text(t.commonCouldNotSave(e.toString())),
                          backgroundColor: AppColors.high,
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    }
                  },
                  child: Text(t.commonSave),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }),
      );
    },
  );
}

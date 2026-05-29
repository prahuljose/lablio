import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../data/medical_record_model.dart';
import '../providers/medical_record_provider.dart';

class MedicalRecordScreen extends ConsumerWidget {
  const MedicalRecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Medical record'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Vaccinations'),
              Tab(text: 'Allergies'),
              Tab(text: 'Conditions'),
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
    final async = ref.watch(medicalRecordProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref, kind),
        icon: const Icon(Icons.add),
        label: Text('Add ${_singular(kind)}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          final filtered =
              entries.where((e) => e.kind == kind).toList();
          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('No ${kind.label.toLowerCase()} logged yet.',
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

  static String _singular(MedicalRecordKind k) => switch (k) {
        MedicalRecordKind.vaccination => 'vaccination',
        MedicalRecordKind.allergy => 'allergy',
        MedicalRecordKind.condition => 'condition',
      };
}

class _Tile extends StatelessWidget {
  final MedicalRecordEntry entry;
  final VoidCallback onDelete;
  const _Tile({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(entry.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([
          if (entry.occurredOn != null)
            DateFormat('MMM d, yyyy').format(entry.occurredOn!),
          if (entry.severity != null) 'Severity: ${entry.severity}',
          if (entry.status != null) 'Status: ${entry.status}',
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
              Text('Add ${_RecordList._singular(kind)}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: switch (kind) {
                    MedicalRecordKind.vaccination =>
                      'Vaccine (e.g. Tdap, Covishield)',
                    MedicalRecordKind.allergy =>
                      'Allergen (e.g. Penicillin, Peanuts)',
                    MedicalRecordKind.condition =>
                      'Condition (e.g. Asthma, Hypertension)',
                  },
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
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
                        ? 'Date given'
                        : kind == MedicalRecordKind.condition
                            ? 'Diagnosed on'
                            : 'First noticed',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(date == null
                      ? 'Select date (optional)'
                      : DateFormat('MMM d, yyyy').format(date!)),
                ),
              ),
              if (kind == MedicalRecordKind.allergy) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: severity,
                  decoration: const InputDecoration(labelText: 'Severity'),
                  items: const [
                    DropdownMenuItem(value: 'Mild', child: Text('Mild')),
                    DropdownMenuItem(
                        value: 'Moderate', child: Text('Moderate')),
                    DropdownMenuItem(value: 'Severe', child: Text('Severe')),
                  ],
                  onChanged: (v) => setLocal(() => severity = v),
                ),
              ],
              if (kind == MedicalRecordKind.condition) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(
                        value: 'Active', child: Text('Active')),
                    DropdownMenuItem(
                        value: 'Resolved', child: Text('Resolved')),
                  ],
                  onChanged: (v) => setLocal(() => status = v),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: notesCtl,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Notes (optional)'),
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
                          content: Text("Couldn't save: $e"),
                          backgroundColor: AppColors.high,
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    }
                  },
                  child: const Text('Save'),
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

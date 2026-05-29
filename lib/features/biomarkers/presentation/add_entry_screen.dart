import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/biomarker_entry_model.dart';
import '../data/biomarker_model.dart';
import '../providers/biomarkers_provider.dart';

class AddEntryScreen extends ConsumerStatefulWidget {
  final String biomarkerId;
  final String biomarkerName;
  final BiomarkerModel? biomarker;
  final String? reportId;

  const AddEntryScreen({
    super.key,
    required this.biomarkerId,
    required this.biomarkerName,
    this.biomarker,
    this.reportId,
  });

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagController = TextEditingController();
  final _valueFocus = FocusNode();
  final List<String> _tags = [];
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    _valueFocus.dispose();
    super.dispose();
  }

  void _addTag(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return;
    if (_tags.contains(t)) {
      _tagController.clear();
      return;
    }
    setState(() {
      _tags.add(t);
      _tagController.clear();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Prompts the user to replace an existing entry for this biomarker on the
  /// same day. Returns true if the user confirmed.
  Future<bool> _confirmReplace(BiomarkerEntryModel existing) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Replace existing result?'),
        content: Text(
          'You already logged ${widget.biomarkerName} for '
          '${DateFormat('MMM d, yyyy').format(existing.date)} '
          '(${existing.value} ${existing.unit}). '
          'Replace it with this new value?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Replace',
                style: TextStyle(color: AppColors.high)),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // If there's already an entry for this biomarker on the selected day,
    // ask before clobbering it.
    final existingSameDay = (ref.read(biomarkerEntriesProvider).valueOrNull ??
            const <BiomarkerEntryModel>[])
        .where((e) =>
            e.biomarkerId == widget.biomarkerId &&
            _sameDay(e.date, _selectedDate))
        .toList();
    if (existingSameDay.isNotEmpty) {
      final replace = await _confirmReplace(existingSameDay.first);
      if (!replace) return;
      if (!mounted) return;
    }

    setState(() => _loading = true);

    // Remove any same-day duplicates before adding the new entry.
    try {
      for (final dup in existingSameDay) {
        await ref.read(biomarkerEntriesProvider.notifier).remove(dup.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not replace existing entry: $e'),
            backgroundColor: AppColors.high,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final biomarker = widget.biomarker;
    final sex = ref.read(profileProvider).valueOrNull?.sex;
    final range = biomarker?.rangeForSex(sex);
    final entry = BiomarkerEntryModel(
      id: const Uuid().v4(),
      userId: Supabase.instance.client.auth.currentUser!.id,
      biomarkerId: widget.biomarkerId,
      biomarkerName: widget.biomarkerName,
      biomarkerCategory: biomarker?.category ?? 'Other',
      value: double.parse(_valueController.text),
      unit: biomarker?.unit ?? '',
      date: _selectedDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      refRangeLow: range?.low,
      refRangeHigh: range?.high,
      tags: List<String>.from(_tags),
      reportId: widget.reportId,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(biomarkerEntriesProvider.notifier).add(entry);
      HapticFeedback.lightImpact();
      if (!mounted) return;
      if (widget.reportId != null) {
        // Logging against a report — return to it (it shows linked results).
        context.pop();
      } else {
        // Open this biomarker's results page, with the Biomarkers tab beneath
        // it so Back returns to the list rather than the add/browse flow.
        context.go(AppRoutes.biomarkers);
        context.push(
          AppRoutes.biomarkerDetail,
          extra: {
            'biomarkerId': widget.biomarkerId,
            'biomarkerName': widget.biomarkerName,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't save that one — try again? ($e)"),
            backgroundColor: AppColors.high,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Determine status colour based on typed value + ref range
  Color? _statusColor(String? sex) {
    final biomarker = widget.biomarker;
    if (biomarker == null) return null;
    final val = double.tryParse(_valueController.text);
    if (val == null) return null;
    final status = biomarker.statusForValue(val, sex: sex);
    return switch (status) {
      RangeStatus.normal => AppColors.normal,
      RangeStatus.high => AppColors.high,
      RangeStatus.low => AppColors.low,
      RangeStatus.unknown => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final biomarker = widget.biomarker;
    final sex = ref.watch(profileProvider).valueOrNull?.sex;
    final range = biomarker?.rangeForSex(sex);
    final hasRange = range?.low != null && range?.high != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Log ${widget.biomarkerName}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                children: [
                  // ── Biomarker info card ─────────────────────────────
                  if (biomarker != null) ...[
                    _InfoCard(biomarker: biomarker),
                    const SizedBox(height: 24),
                  ],

                  // ── Value input ──────────────────────────────────────
                  _SectionLabel('Result'),
                  const SizedBox(height: 8),
                  _ValueField(
                    controller: _valueController,
                    focusNode: _valueFocus,
                    unit: biomarker?.unit,
                    statusColor: () => _statusColor(sex),
                    onChanged: (_) => setState(() {}),
                  ),

                  // ── Live range hint ──────────────────────────────────
                  if (hasRange) ...[
                    const SizedBox(height: 10),
                    _RangeHint(
                      low: range!.low!,
                      high: range.high!,
                      unit: biomarker!.unit,
                      sexSpecific: biomarker.hasSexSpecificRange && sex != null,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Date ────────────────────────────────────────────
                  _SectionLabel('Test date'),
                  const SizedBox(height: 8),
                  _DateTile(
                      selectedDate: _selectedDate, onTap: _pickDate),

                  const SizedBox(height: 24),

                  // ── Tags ────────────────────────────────────────────
                  _SectionLabel('Tags (optional)'),
                  const SizedBox(height: 8),
                  _TagInputField(
                    controller: _tagController,
                    tags: _tags,
                    onAdd: _addTag,
                    onRemove: (t) => setState(() => _tags.remove(t)),
                  ),
                  const SizedBox(height: 24),

                  // ── Notes ───────────────────────────────────────────
                  _SectionLabel('Notes (optional)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Any context about this result…',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: AppColors.divider, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: AppColors.divider, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),

            // ── Save button pinned to bottom ─────────────────────────
            _SaveButton(loading: _loading, onTap: _save),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.4,
        ),
      );
}

class _InfoCard extends StatelessWidget {
  final BiomarkerModel biomarker;
  const _InfoCard({required this.biomarker});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.biotech_outlined,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(biomarker.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(biomarker.category,
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          // Category chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              biomarker.shortName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? unit;
  final Color? Function() statusColor;
  final void Function(String) onChanged;

  const _ValueField({
    required this.controller,
    required this.focusNode,
    required this.unit,
    required this.statusColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusColor();
    final activeBorderColor = color ?? AppColors.primary;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: false,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
      decoration: InputDecoration(
        hintText: '0.0',
        hintStyle: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: -0.5,
        ),
        filled: true,
        fillColor: AppColors.surface,
        suffixIcon: unit != null && unit!.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  unit!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            : null,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.divider, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: activeBorderColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.high, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.high, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Enter a value';
        if (double.tryParse(v) == null) return 'Enter a valid number';
        return null;
      },
    );
  }
}

class _RangeHint extends StatelessWidget {
  final double low;
  final double high;
  final String unit;
  final bool sexSpecific;
  const _RangeHint({
    required this.low,
    required this.high,
    required this.unit,
    required this.sexSpecific,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            'Reference range: $low – $high $unit'
            '${sexSpecific ? ' (for your profile)' : ''}',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;
  const _DateTile({required this.selectedDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_today_outlined,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date of test',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMMM d, yyyy').format(selectedDate),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right,
                color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _SaveButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : const Text(
                'Save Result',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2),
              ),
      ),
    );
  }
}

class _TagInputField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> tags;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  const _TagInputField({
    required this.controller,
    required this.tags,
    required this.onAdd,
    required this.onRemove,
  });

  static const _suggestions = [
    'fasting',
    'post-meal',
    'morning',
    'post-workout',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.none,
          onSubmitted: onAdd,
          decoration: InputDecoration(
            hintText: 'Add a tag and press Enter…',
            prefixIcon: const Icon(Icons.label_outline),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => onAdd(controller.text),
            ),
          ),
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags
                .map((t) => Chip(
                      label: Text(t),
                      onDeleted: () => onRemove(t),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
        ] else ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _suggestions
                .map((t) => ActionChip(
                      label: Text(t),
                      avatar: const Icon(Icons.add, size: 16),
                      onPressed: () => onAdd(t),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

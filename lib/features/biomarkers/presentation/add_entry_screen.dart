import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/confirm_discard.dart';
import '../../../core/widgets/branded_date_picker.dart';
import '../../../core/units/unit_converter.dart';
import '../../../core/units/unit_system_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/data/profile_model.dart';
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
  // The unit the user is entering the value in (defaults to their display
  // system). Stored values are always converted back to the canonical unit.
  UnitOption? _unit;

  /// The typed value converted to the canonical (stored) unit.
  double? _canonicalValue() {
    final v = double.tryParse(_valueController.text);
    if (v == null) return null;
    final u = _unit;
    return u == null ? v : UnitConverter.toCanonical(v, u);
  }

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
    final picked = await showBrandedDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Prompts the user to replace an existing entry for this biomarker on the
  /// same day. Returns true if the user confirmed.
  Future<bool> _confirmReplace(BiomarkerEntryModel existing) async {
    final t = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.addEntryReplaceTitle),
        content: Text(
          t.addEntryReplaceBody(
            widget.biomarkerName,
            DateFormat('MMM d, yyyy').format(existing.date),
            '${existing.value} ${existing.unit}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t.addEntryReplace,
                style: const TextStyle(color: AppColors.high)),
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
            content:
                Text(AppLocalizations.of(context).addEntryReplaceError('$e')),
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
      // Always store in the canonical (conventional) unit, regardless of which
      // unit the user typed in.
      value: _canonicalValue() ?? double.parse(_valueController.text),
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
            content: Text(AppLocalizations.of(context).addEntrySaveError('$e')),
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

  bool get _dirty =>
      _valueController.text.trim().isNotEmpty ||
      _notesController.text.trim().isNotEmpty ||
      _tags.isNotEmpty;

  Future<void> _handleClose() async {
    if (!_dirty) {
      context.pop();
      return;
    }
    if (await confirmDiscard(context) && mounted) context.pop();
  }

  // Determine status colour based on typed value + ref range
  Color? _statusColor(String? sex) {
    final biomarker = widget.biomarker;
    if (biomarker == null) return null;
    final val = _canonicalValue();
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
    final t = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider).valueOrNull;
    final sex = profile?.sex;
    final biomarker = widget.biomarker;
    final range = biomarker?.rangeForSex(sex);
    final hasRange = range?.low != null && range?.high != null;

    // Unit options for entry, defaulting to the user's display system.
    final canonicalUnit = biomarker?.unit ?? '';
    final unitOptions =
        UnitConverter.optionsFor(widget.biomarkerId, canonicalUnit);
    _unit ??= UnitConverter.defaultOptionFor(
        widget.biomarkerId, canonicalUnit, ref.watch(unitSystemProvider));

    // Live status of the value being typed (converted to canonical first).
    final canonicalTyped = _canonicalValue();
    final liveStatus = (biomarker != null && canonicalTyped != null && hasRange)
        ? biomarker.statusForValue(canonicalTyped, sex: sex)
        : RangeStatus.unknown;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _handleClose();
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: t.commonClose,
          onPressed: _handleClose,
        ),
        title: Text(
          t.addEntryTitle(widget.biomarkerName),
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
                  _SectionLabel(t.addEntryResult),
                  const SizedBox(height: 8),
                  _ValueField(
                    controller: _valueController,
                    focusNode: _valueFocus,
                    units: unitOptions,
                    selectedUnit: _unit,
                    onUnitChanged: (u) => setState(() => _unit = u),
                    statusColor: () => _statusColor(sex),
                    onChanged: (_) => setState(() {}),
                  ),

                  // ── Live status chip (appears once a value is typed) ──
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: liveStatus == RangeStatus.unknown
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: _LiveStatusChip(status: liveStatus),
                          ),
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
                  _SectionLabel(t.addEntryTestDate),
                  const SizedBox(height: 8),
                  _DateTile(
                      selectedDate: _selectedDate, onTap: _pickDate),

                  const SizedBox(height: 24),

                  // ── Tags ────────────────────────────────────────────
                  _SectionLabel(t.addEntryTags),
                  const SizedBox(height: 8),
                  _TagInputField(
                    controller: _tagController,
                    tags: _tags,
                    suggestions: ref.watch(profileProvider).valueOrNull?.effectiveTags ?? kDefaultTags,
                    onAdd: _addTag,
                    onRemove: (t) => setState(() => _tags.remove(t)),
                  ),
                  const SizedBox(height: 24),

                  // ── Notes ───────────────────────────────────────────
                  _SectionLabel(t.addEntryNotes),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: t.addEntryNotesHint,
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
                        borderSide: BorderSide(
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Live "Normal / High / Low" preview chip shown as the user types a value.
class _LiveStatusChip extends StatelessWidget {
  final RangeStatus status;
  const _LiveStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final (color, label, icon) = switch (status) {
      RangeStatus.high => (
          AppColors.high,
          t.biomarkersStatusHigh,
          Icons.arrow_upward_rounded
        ),
      RangeStatus.low => (
          AppColors.low,
          t.biomarkersStatusLow,
          Icons.arrow_downward_rounded
        ),
      _ => (
          AppColors.normal,
          t.biomarkersStatusNormal,
          Icons.check_rounded
        ),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

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
            child: Icon(Icons.biotech_outlined,
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
              style: TextStyle(
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
  final List<UnitOption> units;
  final UnitOption? selectedUnit;
  final ValueChanged<UnitOption>? onUnitChanged;
  final Color? Function() statusColor;
  final void Function(String) onChanged;

  const _ValueField({
    required this.controller,
    required this.focusNode,
    required this.units,
    required this.selectedUnit,
    required this.onUnitChanged,
    required this.statusColor,
    required this.onChanged,
  });

  Widget? _buildUnitSuffix() {
    if (units.isEmpty) return null;
    final sel = selectedUnit ?? units.first;
    // Single unit → static label. Multiple → a picker so the user can enter
    // a value in the unit their lab used.
    if (units.length == 1) {
      if (sel.label.isEmpty) return null;
      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Text(sel.label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: DropdownButton<UnitOption>(
        value: sel,
        isDense: true,
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(12),
        style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primary),
        items: [
          for (final u in units)
            DropdownMenuItem(value: u, child: Text(u.label)),
        ],
        onChanged: (u) {
          if (u != null) onUnitChanged?.call(u);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final color = statusColor();
    final activeBorderColor = color ?? AppColors.primary;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
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
        suffixIcon: _buildUnitSuffix(),
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
        if (v == null || v.trim().isEmpty) return t.addEntryEnterValue;
        if (double.tryParse(v) == null) return t.addEntryEnterValidNumber;
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
    final t = AppLocalizations.of(context);
    final base = t.addEntryReferenceRange('$low', '$high', unit);
    return Row(
      children: [
        Icon(Icons.info_outline, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            sexSpecific ? '$base ${t.addEntryForYourProfile}' : base,
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
              child: Icon(Icons.calendar_today_outlined,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).addEntryDateOfTest,
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
            ),
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
            : Text(
                AppLocalizations.of(context).addEntrySaveResult,
                style: const TextStyle(
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
  final List<String> suggestions;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  const _TagInputField({
    required this.controller,
    required this.tags,
    required this.suggestions,
    required this.onAdd,
    required this.onRemove,
  });


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
            hintText: AppLocalizations.of(context).addEntryTagHint,
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
            children: suggestions
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

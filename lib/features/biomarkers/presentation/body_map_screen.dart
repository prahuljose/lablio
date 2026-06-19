import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/units/unit_converter.dart';
import '../../../core/units/unit_system_provider.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/status_style.dart';
import '../../../l10n/app_localizations.dart';
import '../data/biomarker_entry_model.dart';
import '../providers/biomarkers_provider.dart';

/// A body-silhouette "heatmap" that groups tracked biomarkers into organ
/// systems and lights each one green / amber / red based on the worst current
/// status among its markers. Tapping a region drills into that system.
class BodyMapScreen extends ConsumerWidget {
  const BodyMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackedAsync = ref.watch(trackedBiomarkersProvider);
    final system = ref.watch(unitSystemProvider);
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.homeBodyMap)),
      body: trackedAsync.when(
        loading: () => const SkeletonList(),
        error: (e, _) => Center(child: Text(t.commonError(e.toString()))),
        data: (tracked) {
          final summaries = _BodySystem.all
              .map((s) => _SystemSummary.from(s, tracked))
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                t.bodyMapIntro,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _Legend(),
              const SizedBox(height: 8),
              _BodyDiagram(
                summaries: summaries,
                onTap: (s) => _openSystem(context, ref, s, system),
              ),
              const SizedBox(height: 16),
              Text(t.bodyMapSystems,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...summaries.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SystemCard(
                      summary: s,
                      onTap: () => _openSystem(context, ref, s, system),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  void _openSystem(BuildContext context, WidgetRef ref, _SystemSummary s,
      UnitSystem system) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SystemSheet(summary: s, system: system),
    );
  }
}

// ── Status colour for a system ───────────────────────────────────────────────

enum _SysStatus { none, normal, low, high }

extension on _SysStatus {
  Color get color => switch (this) {
        _SysStatus.high => AppColors.high,
        _SysStatus.low => AppColors.low,
        _SysStatus.normal => AppColors.normal,
        _SysStatus.none => AppColors.textTertiary,
      };
}

// ── System model ─────────────────────────────────────────────────────────────

class _BodySystem {
  final String name;
  final List<String> categories;
  final IconData icon;

  /// Fractional position within the silhouette box (0..1).
  final Offset pos;

  const _BodySystem({
    required this.name,
    required this.categories,
    required this.icon,
    required this.pos,
  });

  static const all = <_BodySystem>[
    _BodySystem(
      name: 'Thyroid',
      categories: ['Thyroid'],
      icon: Icons.bolt_outlined,
      pos: Offset(0.50, 0.155),
    ),
    _BodySystem(
      name: 'Cardiovascular',
      categories: ['Cardiac', 'Lipid Panel'],
      icon: Icons.favorite_outline,
      pos: Offset(0.42, 0.30),
    ),
    _BodySystem(
      name: 'Blood & Immunity',
      categories: ['Complete Blood Count', 'Inflammation'],
      icon: Icons.water_drop_outlined,
      pos: Offset(0.60, 0.31),
    ),
    _BodySystem(
      name: 'Liver',
      categories: ['Liver Function'],
      icon: Icons.eco_outlined,
      pos: Offset(0.61, 0.45),
    ),
    _BodySystem(
      name: 'Metabolic',
      categories: ['Metabolic Panel', 'Diabetes'],
      icon: Icons.speed_outlined,
      pos: Offset(0.41, 0.47),
    ),
    _BodySystem(
      name: 'Vitamins & Minerals',
      categories: ['Vitamins & Minerals'],
      icon: Icons.medication_outlined,
      pos: Offset(0.255, 0.345),
    ),
    _BodySystem(
      name: 'Hormones',
      categories: ['Hormones'],
      icon: Icons.science_outlined,
      pos: Offset(0.50, 0.565),
    ),
    _BodySystem(
      name: 'Cancer Markers',
      categories: ['Cancer Markers'],
      icon: Icons.coronavirus_outlined,
      pos: Offset(0.745, 0.345),
    ),
    _BodySystem(
      name: 'Body Composition',
      categories: ['Body Composition'],
      icon: Icons.straighten_outlined,
      pos: Offset(0.50, 0.78),
    ),
  ];
}

class _SystemSummary {
  final _BodySystem system;
  final List<BiomarkerEntryModel> entries;
  final _SysStatus status;
  final int total;
  final int outOfRange;

  _SystemSummary({
    required this.system,
    required this.entries,
    required this.status,
    required this.total,
    required this.outOfRange,
  });

  factory _SystemSummary.from(
      _BodySystem system, List<BiomarkerEntryModel> tracked) {
    final entries = tracked
        .where((e) => system.categories.contains(e.biomarkerCategory))
        .toList()
      ..sort((a, b) => a.biomarkerName.compareTo(b.biomarkerName));

    _SysStatus status;
    if (entries.isEmpty) {
      status = _SysStatus.none;
    } else if (entries.any((e) => e.isHigh)) {
      status = _SysStatus.high;
    } else if (entries.any((e) => e.isLow)) {
      status = _SysStatus.low;
    } else if (entries.any((e) => e.isNormal)) {
      status = _SysStatus.normal;
    } else {
      status = _SysStatus.none; // tracked but no reference range
    }

    final out = entries.where((e) => e.isHigh || e.isLow).length;
    return _SystemSummary(
      system: system,
      entries: entries,
      status: status,
      total: entries.length,
      outOfRange: out,
    );
  }

  String subtitle(AppLocalizations t) {
    if (total == 0) return t.bodyMapNoDataYet;
    if (outOfRange == 0) return t.bodyMapAllInRange(total);
    return t.bodyMapOutOfRange(outOfRange, total);
  }
}

// ── Legend ───────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget dot(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 12)),
          ],
        );
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        dot(AppColors.normal, AppLocalizations.of(context).bodyMapInRange),
        dot(AppColors.low, AppLocalizations.of(context).biomarkersStatusLow),
        dot(AppColors.high, AppLocalizations.of(context).biomarkersStatusHigh),
        dot(AppColors.textTertiary, AppLocalizations.of(context).bodyMapNoData),
      ],
    );
  }
}

// ── Silhouette + markers ─────────────────────────────────────────────────────

class _BodyDiagram extends StatelessWidget {
  final List<_SystemSummary> summaries;
  final ValueChanged<_SystemSummary> onTap;
  const _BodyDiagram({required this.summaries, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final bodyW = (constraints.maxWidth * 0.66).clamp(180.0, 300.0);
      final bodyH = bodyW * 2.0;
      const markerR = 17.0;

      return Center(
        child: SizedBox(
          width: bodyW,
          height: bodyH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(bodyW, bodyH),
                painter: _BodyPainter(
                  fill: AppColors.primary.withValues(alpha: 0.07),
                  stroke: AppColors.primary.withValues(alpha: 0.28),
                ),
              ),
              for (final s in summaries)
                Positioned(
                  left: s.system.pos.dx * bodyW - markerR,
                  top: s.system.pos.dy * bodyH - markerR,
                  child: _Marker(
                    summary: s,
                    radius: markerR,
                    onTap: () => onTap(s),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _Marker extends StatelessWidget {
  final _SystemSummary summary;
  final double radius;
  final VoidCallback onTap;
  const _Marker({
    required this.summary,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = summary.status.color;
    final tracked = summary.total > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: tracked
              ? color.withValues(alpha: 0.18)
              : AppColors.surfaceVariant,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          boxShadow: tracked
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Icon(summary.system.icon, size: radius, color: color),
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  final Color fill;
  final Color stroke;
  _BodyPainter({required this.fill, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // Head
    path.addOval(
        Rect.fromCircle(center: Offset(w * 0.5, h * 0.075), radius: w * 0.115));
    // Neck
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.155), width: w * 0.12, height: h * 0.05),
      Radius.circular(w * 0.03),
    ));
    // Torso (shoulders → waist)
    final torso = Path()
      ..moveTo(w * 0.30, h * 0.205)
      ..quadraticBezierTo(w * 0.5, h * 0.175, w * 0.70, h * 0.205)
      ..lineTo(w * 0.645, h * 0.525)
      ..quadraticBezierTo(w * 0.5, h * 0.565, w * 0.355, h * 0.525)
      ..close();
    path.addPath(torso, Offset.zero);
    // Arms
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.175, h * 0.215, w * 0.10, h * 0.32),
      Radius.circular(w * 0.05),
    ));
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.725, h * 0.215, w * 0.10, h * 0.32),
      Radius.circular(w * 0.05),
    ));
    // Legs
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.37, h * 0.55, w * 0.11, h * 0.42),
      Radius.circular(w * 0.055),
    ));
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.52, h * 0.55, w * 0.11, h * 0.42),
      Radius.circular(w * 0.055),
    ));

    canvas.drawPath(
        path,
        Paint()
          ..color = fill
          ..style = PaintingStyle.fill);
    canvas.drawPath(
        path,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) =>
      old.fill != fill || old.stroke != stroke;
}

// ── System card ──────────────────────────────────────────────────────────────

class _SystemCard extends StatelessWidget {
  final _SystemSummary summary;
  final VoidCallback onTap;
  const _SystemCard({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = summary.status.color;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(summary.system.icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(summary.system.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(summary.subtitle(AppLocalizations.of(context)),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontSize: 12,
                              color: summary.outOfRange > 0
                                  ? color
                                  : AppColors.textSecondary,
                            )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppColors.textTertiary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── System detail bottom sheet ───────────────────────────────────────────────

class _SystemSheet extends StatelessWidget {
  final _SystemSummary summary;
  final UnitSystem system;
  const _SystemSheet({required this.summary, required this.system});

  @override
  Widget build(BuildContext context) {
    final color = summary.status.color;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(summary.system.icon, size: 22, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(summary.system.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(summary.subtitle(AppLocalizations.of(context)),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (summary.entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).bodyMapEmptyCategory,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: summary.entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      _SheetRow(entry: summary.entries[i], system: system),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final BiomarkerEntryModel entry;
  final UnitSystem system;
  const _SheetRow({required this.entry, required this.system});

  @override
  Widget build(BuildContext context) {
    final conv = UnitConverter.display(
      biomarkerId: entry.biomarkerId,
      value: entry.value,
      unit: entry.unit,
      system: system,
    );
    final status = StatusStyle.from(
        isNormal: entry.isNormal, isHigh: entry.isHigh, isLow: entry.isLow);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.pop(context);
        context.push(
          AppRoutes.biomarkerDetail,
          extra: {
            'biomarkerId': entry.biomarkerId,
            'biomarkerName': entry.biomarkerName,
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: status.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(entry.biomarkerName,
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
            Text(AppLocalizations.of(context).biomarkersLatest('${conv.value}', conv.unit),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

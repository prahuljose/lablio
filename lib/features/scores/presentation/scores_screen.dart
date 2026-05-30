import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/skeletons.dart';
import '../../biomarkers/data/biomarker_entry_model.dart';
import '../../biomarkers/presentation/quick_log_sheet.dart';
import '../../biomarkers/providers/biomarkers_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/metabolic_scores.dart';

class ScoresScreen extends ConsumerWidget {
  const ScoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackedAsync = ref.watch(trackedBiomarkersProvider);
    final profile = ref.watch(profileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Metabolic Scores')),
      body: trackedAsync.when(
        loading: () => const SkeletonList(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tracked) {
          final byId = <String, BiomarkerEntryModel>{
            for (final e in tracked) e.biomarkerId: e,
          };
          double? v(String id) => byId[id]?.value;

          final inputs = ScoreInputs(
            glucose: v('glucose'),
            insulin: v('fasting_insulin'),
            triglycerides: v('triglycerides'),
            hdl: v('hdl'),
            ast: v('ast'),
            alt: v('alt'),
            plateletsPerCmm: v('platelets'),
            waistCm: v('waist_circumference'),
            systolic: v('systolic_bp'),
            diastolic: v('diastolic_bp'),
            age: profile?.age,
            sex: profile?.sex,
          );

          final results = computeMetabolicScores(inputs);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () =>
                ref.read(biomarkerEntriesProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                _SummaryHeader(results: results),
                const SizedBox(height: 16),
                ...results.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ScoreCard(result: r),
                    )),
                const SizedBox(height: 8),
                Text(
                  'Scores are informational only — not medical advice. They '
                  'assume fasting samples and standard adult reference cutoffs. '
                  'Discuss results with a clinician.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Color _levelColor(ScoreLevel l) => switch (l) {
      ScoreLevel.good => AppColors.normal,
      ScoreLevel.warn => AppColors.low,
      ScoreLevel.bad => AppColors.high,
      ScoreLevel.unknown => AppColors.textTertiary,
    };

Color _levelBg(ScoreLevel l) => switch (l) {
      ScoreLevel.good => AppColors.normalBg,
      ScoreLevel.warn => AppColors.lowBg,
      ScoreLevel.bad => AppColors.highBg,
      ScoreLevel.unknown => AppColors.surfaceVariant,
    };

// ── Summary header ───────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  final List<ScoreResult> results;
  const _SummaryHeader({required this.results});

  @override
  Widget build(BuildContext context) {
    final computed = results.where((r) => r.computable).toList();
    final flags =
        computed.where((r) => r.level == ScoreLevel.bad).length;
    final watch =
        computed.where((r) => r.level == ScoreLevel.warn).length;

    final String headline;
    if (computed.isEmpty) {
      headline = 'Log glucose, lipids & insulin to unlock your scores';
    } else if (flags > 0) {
      headline = '$flags score${flags == 1 ? '' : 's'} flagged · '
          '${computed.length} computed';
    } else if (watch > 0) {
      headline = '$watch to watch · ${computed.length} computed';
    } else {
      headline = 'All ${computed.length} scores looking good 🎉';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart_outlined,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Metabolic Health',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Text(headline,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          if (computed.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _Pip(count: computed.where((r) => r.level == ScoreLevel.good).length, color: AppColors.normal, label: 'good'),
                const SizedBox(width: 14),
                _Pip(count: watch, color: AppColors.low, label: 'watch'),
                const SizedBox(width: 14),
                _Pip(count: flags, color: AppColors.high, label: 'flagged'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Pip extends StatelessWidget {
  final int count;
  final Color color;
  final String label;
  const _Pip({required this.count, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text('$count $label',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Score card ───────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final ScoreResult result;
  const _ScoreCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(result.level);
    final computable = result.computable;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: name + band chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(result.formula,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textTertiary)),
                    ],
                  ),
                ),
                if (computable)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _levelBg(result.level),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(result.bandLabel,
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (computable) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(result.valueText,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        color: color,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      )),
                ],
              ),
              const SizedBox(height: 8),
              Text(result.interpretation,
                  style: Theme.of(context).textTheme.bodyMedium),
              if (result.criteria != null) ...[
                const SizedBox(height: 12),
                ...result.criteria!.map((c) => _CriterionRow(c: c)),
              ],
              if (result.inputsUsed.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: result.inputsUsed
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(s,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ))
                      .toList(),
                ),
              ],
            ] else ...[
              // Not computable — show what's missing + a CTA.
              Text(result.about,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.lock_outline,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Needs: ${result.missing.join(', ')}',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => showQuickLogSheet(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Log a result'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CriterionRow extends StatelessWidget {
  final ScoreCriterion c;
  const _CriterionRow({required this.c});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = c.met == null
        ? (Icons.help_outline, AppColors.textTertiary)
        : c.met!
            ? (Icons.check_circle, AppColors.high) // "met" = a risk factor
            : (Icons.circle_outlined, AppColors.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(c.label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(c.detail,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

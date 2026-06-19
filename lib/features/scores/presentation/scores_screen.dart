import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/animated_lablio_logo.dart';
import '../../../core/widgets/lablio_refresh.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../l10n/app_localizations.dart';
import '../../biomarkers/data/biomarker_entry_model.dart';
import '../../biomarkers/presentation/quick_log_sheet.dart';
import '../../biomarkers/providers/biomarkers_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/metabolic_scores.dart';
import '../data/phenoage.dart';

class ScoresScreen extends ConsumerWidget {
  const ScoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackedAsync = ref.watch(trackedBiomarkersProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 52,
        titleSpacing: 8,
        leading: const LablioAppBarLogo(),
        title: Text(t.scoresTitle),
      ),
      body: trackedAsync.when(
        loading: () => const SkeletonList(),
        error: (e, _) => Center(child: Text(t.commonError(e.toString()))),
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
            creatinine: v('creatinine'),
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

          final pheno = computePhenoAge(PhenoAgeInputs(
            albuminGdl: v('albumin'),
            creatinineMgdl: v('creatinine'),
            glucoseMgdl: v('glucose'),
            crpMgl: v('crp'),
            lymphocytePct: v('lymphocytes_pct'),
            mcvFl: v('mcv'),
            rdwPct: v('rdw'),
            alpUl: v('alp'),
            wbcPerCmm: v('wbc'),
            age: profile?.age,
          ));

          return LablioRefresh(
            onRefresh: () =>
                ref.read(biomarkerEntriesProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                _PhenoAgeCard(result: pheno),
                const SizedBox(height: 16),
                _SummaryHeader(results: results),
                const SizedBox(height: 16),
                ...results.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ScoreCard(result: r),
                    )),
                const SizedBox(height: 8),
                Text(
                  t.scoresDisclaimer,
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

// ── Biological age (PhenoAge) hero ───────────────────────────────────────────

class _MetricChip extends StatelessWidget {
  final PhenoMetric metric;
  const _MetricChip({required this.metric});

  @override
  Widget build(BuildContext context) {
    final flagged = metric.flagged;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: flagged ? AppColors.highBg : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: flagged
            ? Border.all(color: AppColors.high.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (flagged) ...[
            const Icon(Icons.warning_amber_rounded,
                size: 12, color: AppColors.high),
            const SizedBox(width: 4),
          ],
          Text(metric.label,
              style: TextStyle(
                fontSize: 11,
                color: flagged ? AppColors.high : AppColors.textSecondary,
                fontWeight: flagged ? FontWeight.w700 : FontWeight.w400,
              )),
        ],
      ),
    );
  }
}

void _showPhenoAgeInfo(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _PhenoAgeInfoSheet(),
  );
}

class _PhenoAgeInfoSheet extends StatelessWidget {
  const _PhenoAgeInfoSheet();

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: AppColors.textSecondary, height: 1.4);

    Widget heading(String t) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 6),
          child: Text(t,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        );

    Widget mono(String t) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(t,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
              )),
        );

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.cake_outlined,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Text('Biological Age',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),

              heading('What it is'),
              Text(
                'Your chronological age counts birthdays. Your biological age '
                'estimates how old your body looks on the inside, based on '
                'routine blood markers. A biological age below your real age '
                'suggests healthier-than-average aging; above it suggests the '
                'opposite — and unlike your birthday, it can improve.',
                style: body,
              ),

              heading('Why we use PhenoAge'),
              Text(
                'This uses the "PhenoAge" model (Levine et al., 2018), which was '
                'built by finding the combination of 9 common blood markers + '
                'age that best predicts mortality and disease risk across tens '
                'of thousands of people. It needs no special test — just a '
                'standard CBC, metabolic panel, and hs-CRP.',
                style: body,
              ),

              heading('The exact math'),
              Text('1. A weighted score combines the markers (each in its '
                  'required unit) with published coefficients:', style: body),
              mono('xb = −19.907\n'
                  '   + 0.0804·age(yrs)\n'
                  '   − 0.0336·albumin(g/L)\n'
                  '   + 0.0095·creatinine(µmol/L)\n'
                  '   + 0.1953·glucose(mmol/L)\n'
                  '   + 0.0954·ln(CRP mg/dL)\n'
                  '   − 0.0120·lymphocyte(%)\n'
                  '   + 0.0268·MCV(fL)\n'
                  '   + 0.3306·RDW(%)\n'
                  '   + 0.00188·ALP(U/L)\n'
                  '   + 0.0554·WBC(10³/µL)'),
              const SizedBox(height: 12),
              Text('2. That score is turned into a 10-year mortality risk via '
                  'a Gompertz survival model:', style: body),
              mono('M = 1 − exp( −1.5171·e^xb ⁄ 0.007693 )'),
              const SizedBox(height: 12),
              Text('3. Finally, that risk is mapped back to the age at which '
                  'it would be average for the population — your PhenoAge:',
                  style: body),
              mono('PhenoAge = 141.50\n'
                  '   + ln( −0.00553·ln(1−M) ) ⁄ 0.09017'),

              heading('Units & conversions'),
              Text(
                'Lablio stores conventional units, so before computing it '
                'converts: albumin g/dL→g/L (×10), creatinine mg/dL→µmol/L '
                '(×88.4), glucose mg/dL→mmol/L (×0.0555), hs-CRP mg/L→mg/dL '
                '(÷10), WBC per-µL→10³/µL (÷1000). All 9 markers and your age '
                'must be present for a result.',
                style: body,
              ),

              heading('Important'),
              Text(
                'This is an informational estimate, not a diagnosis. It assumes '
                'fasting samples and standard adult ranges, and a single '
                'abnormal marker can skew it. Always discuss results with a '
                'clinician.',
                style: body,
              ),
              const SizedBox(height: 10),
              Text('Source: Levine ME et al., "An epigenetic biomarker of '
                  'aging for lifespan and healthspan", Aging (2018).',
                  style: body?.copyWith(
                      fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhenoAgeCard extends StatelessWidget {
  final PhenoAgeResult result;
  const _PhenoAgeCard({required this.result});

  @override
  Widget build(BuildContext context) {
    if (!result.computable) return _buildLocked(context);

    final bio = result.bioAge!;
    final delta = result.deltaYears; // negative = younger
    final younger = delta != null && delta < -0.5;
    final older = delta != null && delta > 0.5;
    final deltaColor = younger
        ? const Color(0xFF6EE7B7) // mint — reads on the gradient
        : older
            ? const Color(0xFFFCA5A5) // soft red
            : Colors.white;
    final deltaText = delta == null
        ? null
        : younger
            ? '${delta.abs().toStringAsFixed(1)} yrs younger'
            : older
                ? '${delta.toStringAsFixed(1)} yrs older'
                : 'about your age';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cake_outlined, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(AppLocalizations.of(context).scoresBiologicalAgeCaps,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    )),
              ),
              GestureDetector(
                onTap: () => _showPhenoAgeInfo(context),
                behavior: HitTestBehavior.opaque,
                child: Icon(Icons.info_outline,
                    size: 18, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: bio),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Text(
                  v.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 46,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(AppLocalizations.of(context).scoresYears,
                    style: const TextStyle(color: Colors.white70, fontSize: 16)),
              ),
              const Spacer(),
              if (deltaText != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        younger
                            ? Icons.trending_down
                            : older
                                ? Icons.trending_up
                                : Icons.remove,
                        size: 14,
                        color: deltaColor,
                      ),
                      const SizedBox(width: 4),
                      Text(deltaText,
                          style: TextStyle(
                              color: deltaColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
          if (result.chronoAge != null) ...[
            const SizedBox(height: 6),
            Text(AppLocalizations.of(context).scoresActualAge(result.chronoAge!),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
          ],
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context).scoresPhenoCaption,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildLocked(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cake_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(AppLocalizations.of(context).scoresBiologicalAge,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                GestureDetector(
                  onTap: () => _showPhenoAgeInfo(context),
                  behavior: HitTestBehavior.opaque,
                  child: Icon(Icons.info_outline,
                      size: 18, color: AppColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (result.note != null) ...[
              // Inputs are present but produced an out-of-range result.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 15, color: AppColors.low),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(result.note!,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
              if (result.metrics.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context).scoresValuesUsed,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textTertiary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: result.metrics
                      .map((m) => _MetricChip(metric: m))
                      .toList(),
                ),
                if (result.metrics.any((m) => m.flagged)) ...[
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context).scoresUnusualWarning,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 11, color: AppColors.high)),
                ],
              ],
            ] else ...[
              Text(
                AppLocalizations.of(context).scoresPhenoLockedBody,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.lock_outline,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        AppLocalizations.of(context)
                            .scoresNeeds(result.missing.join(', ')),
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
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
                  label: Text(AppLocalizations.of(context).reportDetailLogResult),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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

    final t = AppLocalizations.of(context);
    final String headline;
    if (computed.isEmpty) {
      headline = t.scoresUnlockHint;
    } else if (flags > 0) {
      headline = t.scoresHeadlineFlagged(flags, computed.length);
    } else if (watch > 0) {
      headline = t.scoresHeadlineWatch(watch, computed.length);
    } else {
      headline = t.scoresAllGood(computed.length);
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
              Text(t.scoresMetabolicHealth,
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
                _Pip(count: computed.where((r) => r.level == ScoreLevel.good).length, color: AppColors.normal, label: t.scoresLevelGood),
                const SizedBox(width: 14),
                _Pip(count: watch, color: AppColors.low, label: t.scoresLevelWatch),
                const SizedBox(width: 14),
                _Pip(count: flags, color: AppColors.high, label: t.scoresLevelFlagged),
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
                    child: Text(
                        AppLocalizations.of(context)
                            .scoresNeeds(result.missing.join(', ')),
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
                  label: Text(AppLocalizations.of(context).reportDetailLogResult),
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

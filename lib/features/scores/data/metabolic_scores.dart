import 'dart:math' as math;

/// Severity level for a computed score, mapped to colours in the UI layer.
enum ScoreLevel { good, warn, bad, unknown }

/// One sub-criterion of a checklist score (e.g. Metabolic Syndrome).
class ScoreCriterion {
  final String label;
  final bool? met; // null = can't evaluate (missing input)
  final String detail; // e.g. "TG 180 ≥ 150" or "needs Triglycerides"
  const ScoreCriterion(
      {required this.label, required this.met, required this.detail});
}

/// A single computed (or not-yet-computable) metabolic index.
class ScoreResult {
  final String id;
  final String name;
  final String formula; // short human-readable definition
  final String about; // one-line plain-English explanation
  final double? value; // null when not computable
  final String valueText; // formatted value or '—'
  final ScoreLevel level;
  final String bandLabel; // e.g. "Insulin sensitive"
  final String interpretation; // full sentence
  final List<String> inputsUsed; // ["Glucose 95 mg/dL", "Insulin 8 µIU/mL"]
  final List<String> missing; // ["Fasting Insulin"]
  final List<ScoreCriterion>? criteria; // checklist-style scores only

  const ScoreResult({
    required this.id,
    required this.name,
    required this.formula,
    required this.about,
    required this.value,
    required this.valueText,
    required this.level,
    required this.bandLabel,
    required this.interpretation,
    this.inputsUsed = const [],
    this.missing = const [],
    this.criteria,
  });

  bool get computable => missing.isEmpty;
}

/// Raw inputs for the scores, all in conventional units:
/// glucose/triglycerides/HDL in mg/dL, insulin in µIU/mL, AST/ALT in U/L,
/// platelets in /cmm (per µL), waist in cm, BP in mmHg.
class ScoreInputs {
  final double? glucose;
  final double? insulin;
  final double? triglycerides;
  final double? hdl;
  final double? creatinine;
  final double? ast;
  final double? alt;
  final double? plateletsPerCmm;
  final double? waistCm;
  final double? systolic;
  final double? diastolic;
  final int? age;
  final String? sex;

  const ScoreInputs({
    this.glucose,
    this.insulin,
    this.triglycerides,
    this.hdl,
    this.creatinine,
    this.ast,
    this.alt,
    this.plateletsPerCmm,
    this.waistCm,
    this.systolic,
    this.diastolic,
    this.age,
    this.sex,
  });

  bool get isFemale => (sex ?? '').toLowerCase().startsWith('f');
  bool get isMale => (sex ?? '').toLowerCase().startsWith('m');
  bool get sexKnown => isFemale || isMale;
}

String _fmt(double v, {int decimals = 1}) {
  if (v.isNaN || v.isInfinite) return '—';
  if (v == v.roundToDouble() && decimals == 0) return v.toStringAsFixed(0);
  return v.toStringAsFixed(decimals);
}

List<ScoreResult> computeMetabolicScores(ScoreInputs i) {
  return [
    _homaIr(i),
    _tyg(i),
    _tgHdl(i),
    _aip(i),
    _fib4(i),
    _egfr(i),
    _metabolicSyndrome(i),
  ];
}

// ── eGFR (kidney function, CKD-EPI 2021 race-free) ───────────────────────────

ScoreResult _egfr(ScoreInputs i) {
  const id = 'egfr';
  const name = 'eGFR (Kidney)';
  const formula = 'CKD-EPI 2021 · creatinine, age, sex';
  const about =
      'Estimated glomerular filtration rate — how well your kidneys filter, '
      'in mL/min/1.73m².';
  final missing = <String>[];
  if (i.creatinine == null) missing.add('Creatinine');
  if (i.age == null) missing.add('Age (in Profile)');
  if (!i.sexKnown) missing.add('Sex (in Profile)');
  if (missing.isNotEmpty) {
    return ScoreResult(
      id: id, name: name, formula: formula, about: about,
      value: null, valueText: '—', level: ScoreLevel.unknown,
      bandLabel: 'Not enough data', interpretation: '', missing: missing,
    );
  }

  final scr = i.creatinine!;
  final female = i.isFemale;
  final k = female ? 0.7 : 0.9;
  final a = female ? -0.241 : -0.302;
  final ratio = scr / k;
  final minR = math.min(ratio, 1.0);
  final maxR = math.max(ratio, 1.0);
  var egfr = 142 *
      math.pow(minR, a) *
      math.pow(maxR, -1.200) *
      math.pow(0.9938, i.age!);
  if (female) egfr *= 1.012;

  final (String stage, ScoreLevel level) = egfr >= 90
      ? ('G1 · Normal', ScoreLevel.good)
      : egfr >= 60
          ? ('G2 · Mildly low', ScoreLevel.good)
          : egfr >= 45
              ? ('G3a · Mild–moderate', ScoreLevel.warn)
              : egfr >= 30
                  ? ('G3b · Moderate–severe', ScoreLevel.warn)
                  : egfr >= 15
                      ? ('G4 · Severe', ScoreLevel.bad)
                      : ('G5 · Kidney failure', ScoreLevel.bad);

  return ScoreResult(
    id: id, name: name, formula: formula, about: about,
    value: egfr.toDouble(),
    valueText: '${egfr.round()}',
    level: level,
    bandLabel: stage,
    interpretation: level == ScoreLevel.good
        ? '≥60 mL/min/1.73m² indicates normal kidney filtration.'
        : level == ScoreLevel.warn
            ? '30–59 suggests reduced filtration (CKD stage 3) — worth a '
                'clinician review.'
            : 'Below 30 indicates severely reduced kidney function — seek '
                'medical advice.',
    inputsUsed: [
      'Creatinine ${scr.toStringAsFixed(2)} mg/dL',
      'Age ${i.age}',
      female ? 'Female' : 'Male',
    ],
  );
}

// ── HOMA-IR ──────────────────────────────────────────────────────────────────

ScoreResult _homaIr(ScoreInputs i) {
  const id = 'homa_ir';
  const name = 'HOMA-IR';
  const formula = 'Glucose × Insulin ÷ 405';
  const about = 'Estimates insulin resistance from fasting glucose and insulin.';
  final missing = <String>[];
  if (i.glucose == null) missing.add('Fasting Glucose');
  if (i.insulin == null) missing.add('Fasting Insulin');
  if (missing.isNotEmpty) {
    return ScoreResult(
      id: id, name: name, formula: formula, about: about,
      value: null, valueText: '—', level: ScoreLevel.unknown,
      bandLabel: 'Not enough data', interpretation: '',
      missing: missing,
    );
  }
  final v = i.glucose! * i.insulin! / 405;
  final (level, band) = v < 2.0
      ? (ScoreLevel.good, 'Insulin sensitive')
      : v < 2.9
          ? (ScoreLevel.warn, 'Early insulin resistance')
          : (ScoreLevel.bad, 'Insulin resistant');
  return ScoreResult(
    id: id, name: name, formula: formula, about: about,
    value: v, valueText: _fmt(v, decimals: 2), level: level, bandLabel: band,
    interpretation: level == ScoreLevel.good
        ? 'Below 2.0 suggests your cells respond well to insulin.'
        : level == ScoreLevel.warn
            ? '2.0–2.9 points to developing insulin resistance — worth watching.'
            : 'Above 2.9 indicates significant insulin resistance.',
    inputsUsed: [
      'Glucose ${_fmt(i.glucose!, decimals: 0)} mg/dL',
      'Insulin ${_fmt(i.insulin!)} µIU/mL',
    ],
  );
}

// ── TyG index ────────────────────────────────────────────────────────────────

ScoreResult _tyg(ScoreInputs i) {
  const id = 'tyg';
  const name = 'TyG Index';
  const formula = 'ln(Triglycerides × Glucose ÷ 2)';
  const about = 'A triglyceride–glucose proxy for insulin resistance.';
  final missing = <String>[];
  if (i.triglycerides == null) missing.add('Triglycerides');
  if (i.glucose == null) missing.add('Fasting Glucose');
  if (missing.isNotEmpty) {
    return ScoreResult(
      id: id, name: name, formula: formula, about: about,
      value: null, valueText: '—', level: ScoreLevel.unknown,
      bandLabel: 'Not enough data', interpretation: '', missing: missing,
    );
  }
  final v = math.log(i.triglycerides! * i.glucose! / 2);
  final (level, band) = v < 8.5
      ? (ScoreLevel.good, 'Low risk')
      : v < 9.0
          ? (ScoreLevel.warn, 'Borderline')
          : (ScoreLevel.bad, 'High risk');
  return ScoreResult(
    id: id, name: name, formula: formula, about: about,
    value: v, valueText: _fmt(v, decimals: 2), level: level, bandLabel: band,
    interpretation: level == ScoreLevel.good
        ? 'Below ~8.5 is associated with good insulin sensitivity.'
        : level == ScoreLevel.warn
            ? 'Around 8.5–9.0 sits in a borderline range.'
            : 'Above ~9.0 is linked to higher insulin-resistance risk.',
    inputsUsed: [
      'Triglycerides ${_fmt(i.triglycerides!, decimals: 0)} mg/dL',
      'Glucose ${_fmt(i.glucose!, decimals: 0)} mg/dL',
    ],
  );
}

// ── Triglyceride / HDL ratio ─────────────────────────────────────────────────

ScoreResult _tgHdl(ScoreInputs i) {
  const id = 'tg_hdl';
  const name = 'Triglyceride / HDL';
  const formula = 'Triglycerides ÷ HDL (mg/dL)';
  const about = 'A simple lipid ratio tied to insulin resistance and heart risk.';
  final missing = <String>[];
  if (i.triglycerides == null) missing.add('Triglycerides');
  if (i.hdl == null) missing.add('HDL Cholesterol');
  if (missing.isNotEmpty) {
    return ScoreResult(
      id: id, name: name, formula: formula, about: about,
      value: null, valueText: '—', level: ScoreLevel.unknown,
      bandLabel: 'Not enough data', interpretation: '', missing: missing,
    );
  }
  final v = i.triglycerides! / i.hdl!;
  final (level, band) = v < 2.0
      ? (ScoreLevel.good, 'Optimal')
      : v < 4.0
          ? (ScoreLevel.warn, 'Elevated')
          : (ScoreLevel.bad, 'High');
  return ScoreResult(
    id: id, name: name, formula: formula, about: about,
    value: v, valueText: _fmt(v, decimals: 1), level: level, bandLabel: band,
    interpretation: level == ScoreLevel.good
        ? 'Below 2.0 is considered optimal.'
        : level == ScoreLevel.warn
            ? '2.0–4.0 suggests elevated cardiometabolic risk.'
            : 'Above 4.0 is strongly linked to insulin resistance.',
    inputsUsed: [
      'Triglycerides ${_fmt(i.triglycerides!, decimals: 0)} mg/dL',
      'HDL ${_fmt(i.hdl!, decimals: 0)} mg/dL',
    ],
  );
}

// ── AIP (Atherogenic Index of Plasma) ────────────────────────────────────────

ScoreResult _aip(ScoreInputs i) {
  const id = 'aip';
  const name = 'Atherogenic Index (AIP)';
  const formula = 'log₁₀(Triglycerides ÷ HDL), molar';
  const about = 'Plasma atherogenicity — a cardiovascular-risk lipid marker.';
  final missing = <String>[];
  if (i.triglycerides == null) missing.add('Triglycerides');
  if (i.hdl == null) missing.add('HDL Cholesterol');
  if (missing.isNotEmpty) {
    return ScoreResult(
      id: id, name: name, formula: formula, about: about,
      value: null, valueText: '—', level: ScoreLevel.unknown,
      bandLabel: 'Not enough data', interpretation: '', missing: missing,
    );
  }
  // Convert mg/dL → mmol/L (TG ×0.0113, HDL ×0.0259) then log10 of the ratio.
  final tgMolar = i.triglycerides! * 0.0113;
  final hdlMolar = i.hdl! * 0.0259;
  final v = math.log(tgMolar / hdlMolar) / math.ln10;
  final (level, band) = v < 0.11
      ? (ScoreLevel.good, 'Low risk')
      : v <= 0.21
          ? (ScoreLevel.warn, 'Intermediate risk')
          : (ScoreLevel.bad, 'High risk');
  return ScoreResult(
    id: id, name: name, formula: formula, about: about,
    value: v, valueText: _fmt(v, decimals: 2), level: level, bandLabel: band,
    interpretation: level == ScoreLevel.good
        ? 'Below 0.11 corresponds to low cardiovascular risk.'
        : level == ScoreLevel.warn
            ? '0.11–0.21 is an intermediate-risk range.'
            : 'Above 0.21 corresponds to high cardiovascular risk.',
    inputsUsed: [
      'Triglycerides ${_fmt(i.triglycerides!, decimals: 0)} mg/dL',
      'HDL ${_fmt(i.hdl!, decimals: 0)} mg/dL',
    ],
  );
}

// ── FIB-4 (liver fibrosis) ───────────────────────────────────────────────────

ScoreResult _fib4(ScoreInputs i) {
  const id = 'fib4';
  const name = 'FIB-4';
  const formula = '(Age × AST) ÷ (Platelets × √ALT)';
  const about = 'A non-invasive estimate of liver fibrosis risk.';
  final missing = <String>[];
  if (i.age == null) missing.add('Age (in Profile)');
  if (i.ast == null) missing.add('AST');
  if (i.alt == null) missing.add('ALT');
  if (i.plateletsPerCmm == null) missing.add('Platelet Count');
  if (missing.isNotEmpty) {
    return ScoreResult(
      id: id, name: name, formula: formula, about: about,
      value: null, valueText: '—', level: ScoreLevel.unknown,
      bandLabel: 'Not enough data', interpretation: '', missing: missing,
    );
  }
  // Platelets stored per-µL (/cmm) → ×10⁹/L by dividing by 1000.
  final plt = i.plateletsPerCmm! / 1000;
  final v = (i.age! * i.ast!) / (plt * math.sqrt(i.alt!));
  final (level, band) = v < 1.3
      ? (ScoreLevel.good, 'Low risk')
      : v <= 2.67
          ? (ScoreLevel.warn, 'Indeterminate')
          : (ScoreLevel.bad, 'High risk');
  return ScoreResult(
    id: id, name: name, formula: formula, about: about,
    value: v, valueText: _fmt(v, decimals: 2), level: level, bandLabel: band,
    interpretation: level == ScoreLevel.good
        ? 'Below 1.3 makes advanced fibrosis unlikely.'
        : level == ScoreLevel.warn
            ? '1.3–2.67 is indeterminate — further evaluation may help.'
            : 'Above 2.67 suggests higher risk of advanced fibrosis.',
    inputsUsed: [
      'Age ${i.age}',
      'AST ${_fmt(i.ast!, decimals: 0)} U/L',
      'ALT ${_fmt(i.alt!, decimals: 0)} U/L',
      'Platelets ${_fmt(plt, decimals: 0)} ×10⁹/L',
    ],
  );
}

// ── Metabolic Syndrome (NCEP ATP III) ────────────────────────────────────────

ScoreResult _metabolicSyndrome(ScoreInputs i) {
  const id = 'mets';
  const name = 'Metabolic Syndrome';
  const formula = '≥3 of 5 NCEP ATP III criteria';
  const about = 'Clusters of risk factors that raise heart-disease and diabetes risk.';

  // Waist
  ScoreCriterion waist;
  if (i.waistCm == null) {
    waist = const ScoreCriterion(
        label: 'Waist', met: null, detail: 'needs Waist Circumference');
  } else if (!i.sexKnown) {
    waist = ScoreCriterion(
        label: 'Waist',
        met: null,
        detail: 'set sex in Profile (waist ${_fmt(i.waistCm!, decimals: 0)} cm)');
  } else {
    final cut = i.isFemale ? 88.0 : 102.0;
    final met = i.waistCm! >= cut;
    waist = ScoreCriterion(
        label: 'Waist',
        met: met,
        detail:
            '${_fmt(i.waistCm!, decimals: 0)} cm ${met ? '≥' : '<'} ${cut.toStringAsFixed(0)}');
  }

  // Triglycerides ≥ 150
  final tg = i.triglycerides == null
      ? const ScoreCriterion(
          label: 'Triglycerides', met: null, detail: 'needs Triglycerides')
      : ScoreCriterion(
          label: 'Triglycerides',
          met: i.triglycerides! >= 150,
          detail:
              '${_fmt(i.triglycerides!, decimals: 0)} ${i.triglycerides! >= 150 ? '≥' : '<'} 150');

  // HDL: <40 male / <50 female
  ScoreCriterion hdl;
  if (i.hdl == null) {
    hdl = const ScoreCriterion(
        label: 'HDL', met: null, detail: 'needs HDL Cholesterol');
  } else if (!i.sexKnown) {
    hdl = ScoreCriterion(
        label: 'HDL',
        met: null,
        detail: 'set sex in Profile (HDL ${_fmt(i.hdl!, decimals: 0)})');
  } else {
    final cut = i.isFemale ? 50.0 : 40.0;
    final met = i.hdl! < cut;
    hdl = ScoreCriterion(
        label: 'HDL',
        met: met,
        detail:
            '${_fmt(i.hdl!, decimals: 0)} ${met ? '<' : '≥'} ${cut.toStringAsFixed(0)}');
  }

  // Blood pressure ≥130/85
  ScoreCriterion bp;
  if (i.systolic == null && i.diastolic == null) {
    bp = const ScoreCriterion(
        label: 'Blood Pressure', met: null, detail: 'needs Blood Pressure');
  } else {
    final met = (i.systolic ?? 0) >= 130 || (i.diastolic ?? 0) >= 85;
    final s = i.systolic == null ? '—' : _fmt(i.systolic!, decimals: 0);
    final d = i.diastolic == null ? '—' : _fmt(i.diastolic!, decimals: 0);
    bp = ScoreCriterion(
        label: 'Blood Pressure',
        met: met,
        detail: '$s/$d ${met ? '≥' : '<'} 130/85');
  }

  // Fasting glucose ≥ 100
  final glu = i.glucose == null
      ? const ScoreCriterion(
          label: 'Glucose', met: null, detail: 'needs Fasting Glucose')
      : ScoreCriterion(
          label: 'Glucose',
          met: i.glucose! >= 100,
          detail:
              '${_fmt(i.glucose!, decimals: 0)} ${i.glucose! >= 100 ? '≥' : '<'} 100');

  final criteria = [waist, tg, hdl, bp, glu];
  final metCount = criteria.where((c) => c.met == true).length;
  final unknownCount = criteria.where((c) => c.met == null).length;

  final (level, band) = metCount >= 3
      ? (ScoreLevel.bad, 'Criteria met')
      : metCount >= 1
          ? (ScoreLevel.warn, 'Some risk factors')
          : (ScoreLevel.good, 'No criteria met');

  final note = unknownCount > 0
      ? ' ($unknownCount criteria can\'t be checked yet)'
      : '';

  return ScoreResult(
    id: id, name: name, formula: formula, about: about,
    value: metCount.toDouble(),
    valueText: '$metCount/5',
    level: level,
    bandLabel: band,
    interpretation: metCount >= 3
        ? 'Meeting 3 or more criteria defines metabolic syndrome.$note'
        : '$metCount of 5 risk factors present; 3+ defines metabolic syndrome.$note',
    criteria: criteria,
  );
}

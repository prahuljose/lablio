import 'dart:math' as math;

/// Raw biomarker inputs for PhenoAge, in the units Lablio stores (conventional).
class PhenoAgeInputs {
  final double? albuminGdl; // gm/dL
  final double? creatinineMgdl; // mg/dL
  final double? glucoseMgdl; // mg/dL
  final double? crpMgl; // mg/L (hs-CRP)
  final double? lymphocytePct; // %
  final double? mcvFl; // fL
  final double? rdwPct; // %
  final double? alpUl; // U/L
  final double? wbcPerCmm; // cells per µL (/cmm)
  final int? age; // years

  const PhenoAgeInputs({
    this.albuminGdl,
    this.creatinineMgdl,
    this.glucoseMgdl,
    this.crpMgl,
    this.lymphocytePct,
    this.mcvFl,
    this.rdwPct,
    this.alpUl,
    this.wbcPerCmm,
    this.age,
  });
}

/// One marker that fed the calculation, with the value shown and whether it
/// looks physiologically implausible (a likely data-entry / unit error).
class PhenoMetric {
  final String label; // e.g. "Glucose 90 mg/dL"
  final bool flagged;
  const PhenoMetric(this.label, {this.flagged = false});
}

class PhenoAgeResult {
  final double? bioAge; // years; null if not computable
  final int? chronoAge; // years
  final List<String> missing; // human-readable missing inputs
  final List<PhenoMetric> metrics;
  final String? note; // set when inputs are present but produce a bad result

  const PhenoAgeResult({
    this.bioAge,
    this.chronoAge,
    this.missing = const [],
    this.metrics = const [],
    this.note,
  });

  bool get computable => bioAge != null;

  /// bioAge − chronoAge. Negative = biologically younger.
  double? get deltaYears =>
      (bioAge != null && chronoAge != null) ? bioAge! - chronoAge! : null;
}

/// Levine et al. (2018) PhenoAge — biological age from 9 blood markers + age.
PhenoAgeResult computePhenoAge(PhenoAgeInputs i) {
  final missing = <String>[];
  void need(double? v, String label) {
    if (v == null) missing.add(label);
  }

  need(i.albuminGdl, 'Albumin');
  need(i.creatinineMgdl, 'Creatinine');
  need(i.glucoseMgdl, 'Fasting Glucose');
  need(i.crpMgl, 'hs-CRP');
  need(i.lymphocytePct, 'Lymphocytes %');
  need(i.mcvFl, 'MCV');
  need(i.rdwPct, 'RDW');
  need(i.alpUl, 'Alkaline Phosphatase');
  need(i.wbcPerCmm, 'WBC');
  if (i.age == null) missing.add('Age (in Profile)');

  if (missing.isNotEmpty) {
    return PhenoAgeResult(chronoAge: i.age, missing: missing);
  }

  // All the markers that go into the calculation, with the values entered —
  // shown on the card so the user can sanity-check each one. Each is flagged
  // if it falls outside a generous physiological window (a likely error that
  // could be skewing the result).
  String n(double v) => v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(v.abs() < 10 ? 2 : 1);
  PhenoMetric mk(String name, double v, String unit, double lo, double hi) =>
      PhenoMetric('$name ${n(v)}$unit', flagged: v < lo || v > hi);

  final considered = <PhenoMetric>[
    PhenoMetric('Age ${i.age}', flagged: i.age! < 1 || i.age! > 120),
    mk('Albumin', i.albuminGdl!, ' g/dL', 1.5, 6.5),
    mk('Creatinine', i.creatinineMgdl!, ' mg/dL', 0.2, 6.0),
    mk('Glucose', i.glucoseMgdl!, ' mg/dL', 40, 500),
    mk('hs-CRP', i.crpMgl!, ' mg/L', 0, 150),
    mk('Lymphocytes', i.lymphocytePct!, '%', 2, 90),
    mk('MCV', i.mcvFl!, ' fL', 50, 130),
    mk('RDW', i.rdwPct!, '%', 8, 30),
    mk('ALP', i.alpUl!, ' U/L', 10, 1000),
    mk('WBC', i.wbcPerCmm!, ' /cmm', 500, 60000),
  ];

  // Convert to the units the formula expects.
  final albumin = i.albuminGdl! * 10; // g/L
  final creatinine = i.creatinineMgdl! * 88.4; // µmol/L
  final glucose = i.glucoseMgdl! * 0.0555; // mmol/L
  // hs-CRP: mg/L → mg/dL, then natural log (floor to avoid ln(0)).
  final crpMgdl = math.max(i.crpMgl! / 10, 0.01);
  final lnCrp = math.log(crpMgdl);
  final wbc = i.wbcPerCmm! / 1000; // 10^3 cells/µL
  final age = i.age!.toDouble();

  final xb = -19.9067 -
      0.0336 * albumin +
      0.0095 * creatinine +
      0.1953 * glucose +
      0.0954 * lnCrp -
      0.0120 * i.lymphocytePct! +
      0.0268 * i.mcvFl! +
      0.3306 * i.rdwPct! +
      0.00188 * i.alpUl! +
      0.0554 * wbc +
      0.0804 * age;

  // 10-year mortality score from the Gompertz model, then map to PhenoAge.
  final m = 1 - math.exp(-1.51714 * math.exp(xb) / 0.0076927);
  final raw = 141.50225 + math.log(-0.00553 * math.log(1 - m)) / 0.090165;

  // The formula is unbounded — out-of-range or unrealistic marker values can
  // produce a negative or absurd age. If the result is implausible OR any
  // input looks physiologically impossible, don't show a misleading number —
  // surface the values so the user can re-check their entries.
  final anyFlagged = considered.any((m) => m.flagged);
  if (!raw.isFinite || raw < 1 || raw > 120 || anyFlagged) {
    return PhenoAgeResult(
      chronoAge: i.age,
      metrics: considered,
      note: 'One or more values look unusual and may be skewing the estimate. '
          'Double-check the highlighted figures and their units — a single bad '
          'marker can throw the whole calculation off.',
    );
  }

  return PhenoAgeResult(
    bioAge: raw,
    chronoAge: i.age,
    metrics: considered,
  );
}

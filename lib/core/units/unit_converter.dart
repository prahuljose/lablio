/// Unit system the user prefers values displayed in.
/// `conventional` = the units the reference data is stored in (mg/dL, etc.).
/// `si` = SI / molar units common outside the US (mmol/L, µmol/L, etc.).
enum UnitSystem { conventional, si }

class ConvertedRange {
  final double value;
  final String unit;
  final double? low;
  final double? high;
  const ConvertedRange({
    required this.value,
    required this.unit,
    this.low,
    this.high,
  });
}

/// A selectable unit for a biomarker. [factor] relates the unit to the
/// canonical (stored, conventional) unit: `valueInThisUnit = canonical * factor`.
/// The canonical unit itself has factor 1.0.
class UnitOption {
  final String label;
  final double factor;
  const UnitOption(this.label, this.factor);

  @override
  bool operator ==(Object other) =>
      other is UnitOption && other.label == label && other.factor == factor;
  @override
  int get hashCode => Object.hash(label, factor);
}

/// Per-biomarker conversion from the stored conventional unit to SI.
/// `siValue = conventionalValue * factor`.
///
/// Single source of truth for units across the app: it powers both the global
/// SI/conventional *display* toggle and the *unit picker* shown while logging.
/// Stored values are always canonical (conventional) — so scores and trends,
/// which assume conventional units, never change.
class UnitConverter {
  UnitConverter._();

  static const Map<String, ({String unit, double factor})> _si = {
    // Metabolic / lipids
    'glucose': (unit: 'mmol/L', factor: 0.0555),
    'glucose_2hr': (unit: 'mmol/L', factor: 0.0555),
    'eag': (unit: 'mmol/L', factor: 0.0555),
    'total_cholesterol': (unit: 'mmol/L', factor: 0.0259),
    'hdl': (unit: 'mmol/L', factor: 0.0259),
    'ldl': (unit: 'mmol/L', factor: 0.0259),
    'non_hdl': (unit: 'mmol/L', factor: 0.0259),
    'vldl': (unit: 'mmol/L', factor: 0.0259),
    'triglycerides': (unit: 'mmol/L', factor: 0.0113),
    'creatinine': (unit: 'µmol/L', factor: 88.4),
    'bun': (unit: 'mmol/L', factor: 0.357),
    'urea': (unit: 'mmol/L', factor: 0.1665),
    'uric_acid': (unit: 'µmol/L', factor: 59.48),
    'total_bilirubin': (unit: 'µmol/L', factor: 17.1),
    'direct_bilirubin': (unit: 'µmol/L', factor: 17.1),
    'calcium': (unit: 'mmol/L', factor: 0.25),
    'magnesium': (unit: 'mmol/L', factor: 0.411),
    'phosphorus': (unit: 'mmol/L', factor: 0.323),
    // Proteins
    'total_protein': (unit: 'g/L', factor: 10),
    'albumin': (unit: 'g/L', factor: 10),
    'globulin': (unit: 'g/L', factor: 10),
    // Iron studies
    'serum_iron': (unit: 'µmol/L', factor: 0.179),
    'tibc': (unit: 'µmol/L', factor: 0.179),
    // Hormones
    'testosterone_total': (unit: 'nmol/L', factor: 0.0347),
    'estradiol': (unit: 'pmol/L', factor: 3.67),
    'cortisol': (unit: 'nmol/L', factor: 27.59),
    'dhea_s': (unit: 'µmol/L', factor: 0.0271),
    'progesterone': (unit: 'nmol/L', factor: 3.18),
    'igf1': (unit: 'nmol/L', factor: 0.131),
    // Thyroid
    'free_t4': (unit: 'pmol/L', factor: 12.87),
    'free_t3': (unit: 'pmol/L', factor: 1.536),
    'total_t4': (unit: 'nmol/L', factor: 12.87),
    'total_t3': (unit: 'nmol/L', factor: 0.0154),
    // Diabetes / vitamins
    'fasting_insulin': (unit: 'pmol/L', factor: 6.945),
    'c_peptide': (unit: 'nmol/L', factor: 0.331),
    'vitamin_d': (unit: 'nmol/L', factor: 2.496),
    'vitamin_b12': (unit: 'pmol/L', factor: 0.738),
    'folate': (unit: 'nmol/L', factor: 2.266),
  };

  /// Whether a biomarker has a known SI conversion.
  static bool hasConversion(String biomarkerId) => _si.containsKey(biomarkerId);

  /// Units the user may pick from when entering a value: the canonical
  /// (conventional) unit first, plus the SI unit when one exists.
  static List<UnitOption> optionsFor(String biomarkerId, String canonicalUnit) {
    final opts = [UnitOption(canonicalUnit, 1.0)];
    final c = _si[biomarkerId];
    if (c != null && c.unit != canonicalUnit) opts.add(UnitOption(c.unit, c.factor));
    return opts;
  }

  /// Convert a value the user typed in [option] back to the canonical unit
  /// (what we store). Inverse of the display factor.
  static double toCanonical(double entered, UnitOption option) =>
      option.factor == 1.0 ? entered : entered / option.factor;

  /// The [UnitOption] matching the user's global display system, defaulting to
  /// canonical (conventional) when no SI conversion exists.
  static UnitOption defaultOptionFor(
      String biomarkerId, String canonicalUnit, UnitSystem system) {
    final opts = optionsFor(biomarkerId, canonicalUnit);
    if (system == UnitSystem.si && opts.length > 1) return opts.last;
    return opts.first;
  }

  static double _round(double v) {
    // Keep up to 3 significant-ish decimals without trailing noise.
    if (v == 0) return 0;
    final abs = v.abs();
    final decimals = abs >= 100 ? 0 : (abs >= 10 ? 1 : 2);
    return double.parse(v.toStringAsFixed(decimals));
  }

  /// Convert a single value to the requested system.
  static double convertValue(
      String biomarkerId, double value, UnitSystem system) {
    final c = _si[biomarkerId];
    if (system == UnitSystem.conventional || c == null) return value;
    return _round(value * c.factor);
  }

  /// The unit label to show for a biomarker in the requested system.
  static String unitFor(String biomarkerId, String fallback, UnitSystem system) {
    final c = _si[biomarkerId];
    if (system == UnitSystem.conventional || c == null) return fallback;
    return c.unit;
  }

  /// Returns the value + reference range in the requested unit system.
  static ConvertedRange display({
    required String biomarkerId,
    required double value,
    required String unit,
    double? low,
    double? high,
    required UnitSystem system,
  }) {
    final c = _si[biomarkerId];
    if (system == UnitSystem.conventional || c == null) {
      return ConvertedRange(value: value, unit: unit, low: low, high: high);
    }
    return ConvertedRange(
      value: _round(value * c.factor),
      unit: c.unit,
      low: low == null ? null : _round(low * c.factor),
      high: high == null ? null : _round(high * c.factor),
    );
  }
}

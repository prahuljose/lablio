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

/// Per-biomarker conversion from the stored conventional unit to SI.
/// `siValue = conventionalValue * factor`.
class UnitConverter {
  UnitConverter._();

  static const Map<String, ({String unit, double factor})> _si = {
    'glucose': (unit: 'mmol/L', factor: 0.0555),
    'glucose_2hr': (unit: 'mmol/L', factor: 0.0555),
    'total_cholesterol': (unit: 'mmol/L', factor: 0.0259),
    'hdl': (unit: 'mmol/L', factor: 0.0259),
    'ldl': (unit: 'mmol/L', factor: 0.0259),
    'non_hdl': (unit: 'mmol/L', factor: 0.0259),
    'vldl': (unit: 'mmol/L', factor: 0.0259),
    'triglycerides': (unit: 'mmol/L', factor: 0.0113),
    'creatinine': (unit: 'µmol/L', factor: 88.4),
    'bun': (unit: 'mmol/L', factor: 0.357),
    'uric_acid': (unit: 'µmol/L', factor: 59.48),
    'total_bilirubin': (unit: 'µmol/L', factor: 17.1),
    'direct_bilirubin': (unit: 'µmol/L', factor: 17.1),
    'calcium': (unit: 'mmol/L', factor: 0.25),
    'magnesium': (unit: 'mmol/L', factor: 0.411),
    'phosphorus': (unit: 'mmol/L', factor: 0.323),
    'serum_iron': (unit: 'µmol/L', factor: 0.179),
    'testosterone_total': (unit: 'nmol/L', factor: 0.0347),
    'estradiol': (unit: 'pmol/L', factor: 3.67),
    'cortisol': (unit: 'nmol/L', factor: 27.59),
    'vitamin_d': (unit: 'nmol/L', factor: 2.496),
    'total_protein': (unit: 'g/L', factor: 10),
    'albumin': (unit: 'g/L', factor: 10),
  };

  /// Whether a biomarker has a known SI conversion.
  static bool hasConversion(String biomarkerId) => _si.containsKey(biomarkerId);

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

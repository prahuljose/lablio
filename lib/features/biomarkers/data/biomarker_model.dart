class BiomarkerModel {
  final String id;
  final String name;
  final String shortName;
  final String category;
  final String unit;
  final double? refRangeLow;
  final double? refRangeHigh;
  // Optional sex-specific ranges; fall back to refRangeLow/High when null.
  final double? refRangeLowMale;
  final double? refRangeHighMale;
  final double? refRangeLowFemale;
  final double? refRangeHighFemale;
  final String? description;
  final String? explanationHigh;
  final String? explanationLow;

  const BiomarkerModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.category,
    required this.unit,
    this.refRangeLow,
    this.refRangeHigh,
    this.refRangeLowMale,
    this.refRangeHighMale,
    this.refRangeLowFemale,
    this.refRangeHighFemale,
    this.description,
    this.explanationHigh,
    this.explanationLow,
  });

  /// From local JSON asset (camelCase keys)
  factory BiomarkerModel.fromMap(Map<String, dynamic> map) => BiomarkerModel(
        id: map['id'] as String,
        name: map['name'] as String,
        shortName: map['shortName'] as String,
        category: map['category'] as String,
        unit: map['unit'] as String,
        refRangeLow: (map['refRangeLow'] as num?)?.toDouble(),
        refRangeHigh: (map['refRangeHigh'] as num?)?.toDouble(),
        refRangeLowMale: (map['refRangeLowMale'] as num?)?.toDouble(),
        refRangeHighMale: (map['refRangeHighMale'] as num?)?.toDouble(),
        refRangeLowFemale: (map['refRangeLowFemale'] as num?)?.toDouble(),
        refRangeHighFemale: (map['refRangeHighFemale'] as num?)?.toDouble(),
        description: map['description'] as String?,
      );

  /// From Supabase (snake_case keys)
  factory BiomarkerModel.fromDb(Map<String, dynamic> map) => BiomarkerModel(
        id: map['id'] as String,
        name: map['name'] as String,
        shortName: map['short_name'] as String,
        category: map['category'] as String,
        unit: map['unit'] as String,
        refRangeLow: (map['ref_range_low'] as num?)?.toDouble(),
        refRangeHigh: (map['ref_range_high'] as num?)?.toDouble(),
        refRangeLowMale: (map['ref_range_low_male'] as num?)?.toDouble(),
        refRangeHighMale: (map['ref_range_high_male'] as num?)?.toDouble(),
        refRangeLowFemale: (map['ref_range_low_female'] as num?)?.toDouble(),
        refRangeHighFemale: (map['ref_range_high_female'] as num?)?.toDouble(),
        description: map['description'] as String?,
        explanationHigh: map['explanation_high'] as String?,
        explanationLow: map['explanation_low'] as String?,
      );

  /// Whether this biomarker has distinct ranges per sex.
  bool get hasSexSpecificRange =>
      refRangeLowMale != null ||
      refRangeHighMale != null ||
      refRangeLowFemale != null ||
      refRangeHighFemale != null;

  /// Resolve the reference range for a given sex ('male' | 'female' | null).
  /// Falls back to the generic range when no sex-specific value is set.
  ({double? low, double? high}) rangeForSex(String? sex) {
    if (sex == 'male' && (refRangeLowMale != null || refRangeHighMale != null)) {
      return (low: refRangeLowMale, high: refRangeHighMale);
    }
    if (sex == 'female' &&
        (refRangeLowFemale != null || refRangeHighFemale != null)) {
      return (low: refRangeLowFemale, high: refRangeHighFemale);
    }
    return (low: refRangeLow, high: refRangeHigh);
  }

  RangeStatus statusForValue(double value, {String? sex}) {
    final range = rangeForSex(sex);
    if (range.low == null || range.high == null) return RangeStatus.unknown;
    if (value < range.low!) return RangeStatus.low;
    if (value > range.high!) return RangeStatus.high;
    return RangeStatus.normal;
  }
}

enum RangeStatus { normal, low, high, unknown }

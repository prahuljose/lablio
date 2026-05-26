class BiomarkerModel {
  final String id;
  final String name;
  final String shortName;
  final String category;
  final String unit;
  final double? refRangeLow;
  final double? refRangeHigh;
  final String? description;

  const BiomarkerModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.category,
    required this.unit,
    this.refRangeLow,
    this.refRangeHigh,
    this.description,
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
        description: map['description'] as String?,
      );

  RangeStatus statusForValue(double value) {
    if (refRangeLow == null || refRangeHigh == null) return RangeStatus.unknown;
    if (value < refRangeLow!) return RangeStatus.low;
    if (value > refRangeHigh!) return RangeStatus.high;
    return RangeStatus.normal;
  }
}

enum RangeStatus { normal, low, high, unknown }

class BiomarkerEntryModel {
  final String id;
  final String userId;
  final String? reportId;
  final String biomarkerId;
  final String biomarkerName;
  final String biomarkerCategory;
  final double value;
  final String unit;
  final DateTime date;
  final String? notes;
  final double? refRangeLow;
  final double? refRangeHigh;
  final List<String> tags;
  final DateTime createdAt;

  const BiomarkerEntryModel({
    required this.id,
    required this.userId,
    this.reportId,
    required this.biomarkerId,
    required this.biomarkerName,
    required this.biomarkerCategory,
    required this.value,
    required this.unit,
    required this.date,
    this.notes,
    this.refRangeLow,
    this.refRangeHigh,
    this.tags = const [],
    required this.createdAt,
  });

  factory BiomarkerEntryModel.fromMap(Map<String, dynamic> map) =>
      BiomarkerEntryModel(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        reportId: map['report_id'] as String?,
        biomarkerId: map['biomarker_id'] as String,
        biomarkerName: map['biomarker_name'] as String,
        biomarkerCategory: map['biomarker_category'] as String? ?? '',
        value: (map['value'] as num).toDouble(),
        unit: map['unit'] as String,
        date: DateTime.parse(map['date'] as String),
        notes: map['notes'] as String?,
        refRangeLow: (map['ref_range_low'] as num?)?.toDouble(),
        refRangeHigh: (map['ref_range_high'] as num?)?.toDouble(),
        tags: (map['tags'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        if (reportId != null) 'report_id': reportId,
        'biomarker_id': biomarkerId,
        'biomarker_name': biomarkerName,
        'biomarker_category': biomarkerCategory,
        'value': value,
        'unit': unit,
        'date': date.toIso8601String().split('T').first,
        if (notes != null) 'notes': notes,
        if (refRangeLow != null) 'ref_range_low': refRangeLow,
        if (refRangeHigh != null) 'ref_range_high': refRangeHigh,
        if (tags.isNotEmpty) 'tags': tags,
      };

  bool get isNormal =>
      refRangeLow != null &&
      refRangeHigh != null &&
      value >= refRangeLow! &&
      value <= refRangeHigh!;

  bool get isHigh => refRangeHigh != null && value > refRangeHigh!;
  bool get isLow => refRangeLow != null && value < refRangeLow!;
}

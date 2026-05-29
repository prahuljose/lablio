class BiomarkerNoteModel {
  final String biomarkerId;
  final String body;
  final DateTime updatedAt;

  const BiomarkerNoteModel({
    required this.biomarkerId,
    required this.body,
    required this.updatedAt,
  });

  factory BiomarkerNoteModel.fromMap(Map<String, dynamic> map) =>
      BiomarkerNoteModel(
        biomarkerId: map['biomarker_id'] as String,
        body: map['body'] as String? ?? '',
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}

class ReportModel {
  final String id;
  final String userId;
  final String title;
  final DateTime date;
  final String? notes;
  final String? pdfUrl;
  final String? pdfPath;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.date,
    this.notes,
    this.pdfUrl,
    this.pdfPath,
    required this.createdAt,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map) => ReportModel(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        title: map['title'] as String,
        date: DateTime.parse(map['date'] as String),
        notes: map['notes'] as String?,
        pdfUrl: map['pdf_url'] as String?,
        pdfPath: map['pdf_path'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'title': title,
        'date': date.toIso8601String().split('T').first,
        if (notes != null) 'notes': notes,
        if (pdfUrl != null) 'pdf_url': pdfUrl,
        if (pdfPath != null) 'pdf_path': pdfPath,
      };

  ReportModel copyWith({
    String? title,
    DateTime? date,
    String? notes,
    String? pdfUrl,
    String? pdfPath,
  }) =>
      ReportModel(
        id: id,
        userId: userId,
        title: title ?? this.title,
        date: date ?? this.date,
        notes: notes ?? this.notes,
        pdfUrl: pdfUrl ?? this.pdfUrl,
        pdfPath: pdfPath ?? this.pdfPath,
        createdAt: createdAt,
      );
}

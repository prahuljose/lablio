enum MedicalRecordKind { vaccination, allergy, condition }

extension MedicalRecordKindX on MedicalRecordKind {
  String get db => switch (this) {
        MedicalRecordKind.vaccination => 'vaccination',
        MedicalRecordKind.allergy => 'allergy',
        MedicalRecordKind.condition => 'condition',
      };
  String get label => switch (this) {
        MedicalRecordKind.vaccination => 'Vaccinations',
        MedicalRecordKind.allergy => 'Allergies',
        MedicalRecordKind.condition => 'Conditions',
      };
  static MedicalRecordKind fromDb(String s) => switch (s) {
        'vaccination' => MedicalRecordKind.vaccination,
        'allergy' => MedicalRecordKind.allergy,
        _ => MedicalRecordKind.condition,
      };
}

class MedicalRecordEntry {
  final String id;
  final MedicalRecordKind kind;
  final String name;
  final DateTime? occurredOn;
  final String? severity; // for allergies (mild / moderate / severe)
  final String? status;   // for conditions (active / resolved)
  final String? notes;
  final DateTime createdAt;

  const MedicalRecordEntry({
    required this.id,
    required this.kind,
    required this.name,
    this.occurredOn,
    this.severity,
    this.status,
    this.notes,
    required this.createdAt,
  });

  factory MedicalRecordEntry.fromMap(Map<String, dynamic> m) =>
      MedicalRecordEntry(
        id: m['id'] as String,
        kind: MedicalRecordKindX.fromDb(m['kind'] as String),
        name: m['name'] as String,
        occurredOn: m['occurred_on'] == null
            ? null
            : DateTime.parse(m['occurred_on'] as String),
        severity: m['severity'] as String?,
        status: m['status'] as String?,
        notes: m['notes'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, dynamic> toInsertMap(String userId) => {
        'user_id': userId,
        'kind': kind.db,
        'name': name,
        if (occurredOn != null)
          'occurred_on': occurredOn!.toIso8601String().split('T').first,
        if (severity != null) 'severity': severity,
        if (status != null) 'status': status,
        if (notes != null) 'notes': notes,
      };
}

class ProfileModel {
  final String id;
  final String? fullName;
  final DateTime? dateOfBirth;
  final String? sex;
  final double? heightCm;
  final double? weightKg;
  final String? bloodType;
  final String? avatarUrl;
  final String? avatarPath;

  const ProfileModel({
    required this.id,
    this.fullName,
    this.dateOfBirth,
    this.sex,
    this.heightCm,
    this.weightKg,
    this.bloodType,
    this.avatarUrl,
    this.avatarPath,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) => ProfileModel(
        id: map['id'] as String,
        fullName: map['full_name'] as String?,
        dateOfBirth: map['date_of_birth'] == null
            ? null
            : DateTime.parse(map['date_of_birth'] as String),
        sex: map['sex'] as String?,
        heightCm: (map['height_cm'] as num?)?.toDouble(),
        weightKg: (map['weight_kg'] as num?)?.toDouble(),
        bloodType: map['blood_type'] as String?,
        avatarUrl: map['avatar_url'] as String?,
        avatarPath: map['avatar_path'] as String?,
      );

  /// Only the user-editable demographic fields (avatar handled separately).
  Map<String, dynamic> toUpdateMap() => {
        'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
        'sex': sex,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'blood_type': bloodType,
      };

  ProfileModel copyWith({
    String? fullName,
    DateTime? dateOfBirth,
    String? sex,
    double? heightCm,
    double? weightKg,
    String? bloodType,
    String? avatarUrl,
    String? avatarPath,
  }) =>
      ProfileModel(
        id: id,
        fullName: fullName ?? this.fullName,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        sex: sex ?? this.sex,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        bloodType: bloodType ?? this.bloodType,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        avatarPath: avatarPath ?? this.avatarPath,
      );

  /// Age in whole years, or null if no DOB is set.
  int? get age {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final now = DateTime.now();
    var years = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return years;
  }

  /// Body Mass Index, or null if height/weight are missing.
  double? get bmi {
    final h = heightCm;
    final w = weightKg;
    if (h == null || w == null || h <= 0) return null;
    final m = h / 100;
    return w / (m * m);
  }
}

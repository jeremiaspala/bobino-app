class Animal {
  final String id;
  final String tag; // número de caravana
  final String? name;
  final String? breed;
  final String? sex;
  final DateTime? birthDate;
  final DateTime createdAt;

  Animal({
    required this.id,
    required this.tag,
    this.name,
    this.breed,
    this.sex,
    this.birthDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'tag': tag,
        'name': name,
        'breed': breed,
        'sex': sex,
        'birth_date': birthDate?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory Animal.fromMap(Map<String, dynamic> map) => Animal(
        id: map['id'] as String,
        tag: map['tag'] as String,
        name: map['name'] as String?,
        breed: map['breed'] as String?,
        sex: map['sex'] as String?,
        birthDate: map['birth_date'] != null
            ? DateTime.parse(map['birth_date'] as String)
            : null,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Animal copyWith({
    String? tag,
    String? name,
    String? breed,
    String? sex,
    DateTime? birthDate,
  }) =>
      Animal(
        id: id,
        tag: tag ?? this.tag,
        name: name ?? this.name,
        breed: breed ?? this.breed,
        sex: sex ?? this.sex,
        birthDate: birthDate ?? this.birthDate,
        createdAt: createdAt,
      );

  int? get ageMonths {
    if (birthDate == null) return null;
    final now = DateTime.now();
    return (now.year - birthDate!.year) * 12 + (now.month - birthDate!.month);
  }
}

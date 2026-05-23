class Measurement {
  final String id;
  final String animalId;
  final DateTime date;

  // ICC (Body Condition Score) 1.0-5.0
  final double? icc;
  final String iccMethod; // 'manual', 'ai', 'guided'

  // Weight
  final double? weightKg;
  final String weightMethod; // 'formula_schoorl', 'formula_anderson', 'manual', 'photo'

  // Morphometrics (cm)
  final double? heartGirthCm; // perímetro torácico
  final double? bodyLengthCm; // largo del cuerpo
  final double? hipWidthCm; // ancho de cadera
  final double? withersHeightCm; // alzada a la cruz
  final double? bodyDepthCm; // profundidad del cuerpo

  // From photo analysis
  final double? rumpAngleDeg; // ángulo de la grupa
  final double? coatScore; // condición del pelaje 1-5
  final double? bboxConfidence; // confianza del modelo YOLO

  // Photos (local paths)
  final String? photoSidePath;
  final String? photoRearPath;
  final String? photoFrontPath;

  // Notes
  final String? notes;

  Measurement({
    required this.id,
    required this.animalId,
    DateTime? date,
    this.icc,
    this.iccMethod = 'manual',
    this.weightKg,
    this.weightMethod = 'formula_schoorl',
    this.heartGirthCm,
    this.bodyLengthCm,
    this.hipWidthCm,
    this.withersHeightCm,
    this.bodyDepthCm,
    this.rumpAngleDeg,
    this.coatScore,
    this.bboxConfidence,
    this.photoSidePath,
    this.photoRearPath,
    this.photoFrontPath,
    this.notes,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'animal_id': animalId,
        'date': date.toIso8601String(),
        'icc': icc,
        'icc_method': iccMethod,
        'weight_kg': weightKg,
        'weight_method': weightMethod,
        'heart_girth_cm': heartGirthCm,
        'body_length_cm': bodyLengthCm,
        'hip_width_cm': hipWidthCm,
        'withers_height_cm': withersHeightCm,
        'body_depth_cm': bodyDepthCm,
        'rump_angle_deg': rumpAngleDeg,
        'coat_score': coatScore,
        'bbox_confidence': bboxConfidence,
        'photo_side_path': photoSidePath,
        'photo_rear_path': photoRearPath,
        'photo_front_path': photoFrontPath,
        'notes': notes,
      };

  factory Measurement.fromMap(Map<String, dynamic> map) => Measurement(
        id: map['id'] as String,
        animalId: map['animal_id'] as String,
        date: DateTime.parse(map['date'] as String),
        icc: map['icc'] as double?,
        iccMethod: map['icc_method'] as String? ?? 'manual',
        weightKg: map['weight_kg'] as double?,
        weightMethod: map['weight_method'] as String? ?? 'formula_schoorl',
        heartGirthCm: map['heart_girth_cm'] as double?,
        bodyLengthCm: map['body_length_cm'] as double?,
        hipWidthCm: map['hip_width_cm'] as double?,
        withersHeightCm: map['withers_height_cm'] as double?,
        bodyDepthCm: map['body_depth_cm'] as double?,
        rumpAngleDeg: map['rump_angle_deg'] as double?,
        coatScore: map['coat_score'] as double?,
        bboxConfidence: map['bbox_confidence'] as double?,
        photoSidePath: map['photo_side_path'] as String?,
        photoRearPath: map['photo_rear_path'] as String?,
        photoFrontPath: map['photo_front_path'] as String?,
        notes: map['notes'] as String?,
      );

  String get iccLabel {
    if (icc == null) return '—';
    return icc!.toStringAsFixed(1);
  }

  String? get rumpAngleLabel {
    if (rumpAngleDeg == null) return null;
    if (rumpAngleDeg! < 2) return 'Muy plana (< 2°)';
    if (rumpAngleDeg! <= 8) return 'Ideal (${rumpAngleDeg!.toStringAsFixed(1)}°)';
    return 'Inclinada (${rumpAngleDeg!.toStringAsFixed(1)}°)';
  }
}

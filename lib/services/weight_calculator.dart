import 'dart:math';

enum WeightFormula { schoorl, anderson, iccBased }

class WeightResult {
  final double weightKg;
  final WeightFormula formula;
  final double confidence; // 0.0 - 1.0
  final String description;

  WeightResult({
    required this.weightKg,
    required this.formula,
    required this.confidence,
    required this.description,
  });

  String get formulaName {
    switch (formula) {
      case WeightFormula.schoorl:
        return 'Schoorl';
      case WeightFormula.anderson:
        return 'Anderson';
      case WeightFormula.iccBased:
        return 'Estimado por ICC';
    }
  }
}

class WeightCalculator {
  /// Fórmula de Schoorl: W = (PT + 22)² / 100
  /// PT = perímetro torácico en cm
  static double schoorl(double heartGirthCm) {
    return pow(heartGirthCm + 22, 2) / 100;
  }

  /// Fórmula de Anderson (más precisa, necesita largo del cuerpo)
  /// W = (PT² × LC) / K
  /// K = 10840 (carne), 11000 (lechería)
  static double anderson(
      double heartGirthCm, double bodyLengthCm,
      {bool isDairy = false}) {
    final k = isDairy ? 11000.0 : 10840.0;
    return (heartGirthCm * heartGirthCm * bodyLengthCm) / k;
  }

  /// Estimación basada en ICC cuando no hay morfometría
  /// Tablas de referencia para bovinos de carne adultos (450-550 kg ideal)
  static double fromIcc(double icc, {double idealWeightKg = 480.0}) {
    // Factor de ajuste relativo al peso ideal en BCS 3.0
    // Cada punto de BCS ≈ 8-12% del peso corporal en bovinos
    const adjustmentPerPoint = 0.10; // 10% por punto de BCS
    final delta = (icc - 3.0) * adjustmentPerPoint;
    return idealWeightKg * (1 + delta);
  }

  /// Estimación desde foto con escala conocida
  /// Usa las dimensiones del bounding box y la escala para estimar PT
  static double fromPhotoMorphometrics({
    required double bodyLengthPixels,
    required double bodyHeightPixels,
    required double pixelsPerCm,
  }) {
    // Ignoramos largo por ahora; usamos solo alto para estimar PT
    final _ = bodyLengthPixels; // reservado para Anderson photo
    final heightCm = bodyHeightPixels / pixelsPerCm;
    // PT ≈ 2.1 × altura (relación anatómica aproximada, vista lateral)
    final estimatedGirthCm = heightCm * 2.1;
    return schoorl(estimatedGirthCm);
  }

  /// Calcular mejores estimaciones con todos los datos disponibles
  static WeightResult calculate({
    double? heartGirthCm,
    double? bodyLengthCm,
    double? icc,
    bool isDairy = false,
    double idealWeightKg = 480.0,
    // Photo-based
    double? bodyLengthPixels,
    double? bodyHeightPixels,
    double? pixelsPerCm,
  }) {
    // Prioridad 1: Anderson (más preciso, necesita PT + largo)
    if (heartGirthCm != null && bodyLengthCm != null) {
      return WeightResult(
        weightKg: anderson(heartGirthCm, bodyLengthCm, isDairy: isDairy),
        formula: WeightFormula.anderson,
        confidence: 0.90,
        description:
            'PT: ${heartGirthCm.toStringAsFixed(0)} cm, Largo: ${bodyLengthCm.toStringAsFixed(0)} cm',
      );
    }

    // Prioridad 2: Schoorl (solo necesita PT)
    if (heartGirthCm != null) {
      return WeightResult(
        weightKg: schoorl(heartGirthCm),
        formula: WeightFormula.schoorl,
        confidence: 0.80,
        description: 'PT: ${heartGirthCm.toStringAsFixed(0)} cm',
      );
    }

    // Prioridad 3: Desde foto con escala
    if (bodyLengthPixels != null &&
        bodyHeightPixels != null &&
        pixelsPerCm != null) {
      final w = fromPhotoMorphometrics(
        bodyLengthPixels: bodyLengthPixels,
        bodyHeightPixels: bodyHeightPixels,
        pixelsPerCm: pixelsPerCm,
      );
      return WeightResult(
        weightKg: w,
        formula: WeightFormula.schoorl,
        confidence: 0.60,
        description: 'Estimado desde foto (baja precisión sin referencia)',
      );
    }

    // Prioridad 4: Desde ICC
    if (icc != null) {
      return WeightResult(
        weightKg: fromIcc(icc, idealWeightKg: idealWeightKg),
        formula: WeightFormula.iccBased,
        confidence: 0.40,
        description: 'ICC: ${icc.toStringAsFixed(1)} (estimación aproximada)',
      );
    }

    throw ArgumentError(
        'Se necesita al menos el perímetro torácico, foto con escala o ICC');
  }

  /// Calcular ángulo de la grupa desde dos puntos en la imagen
  /// punto1 = tailhead (base de la cola), punto2 = hook bone (anca)
  static double calculateRumpAngle({
    required double tailheadX,
    required double tailheadY,
    required double hookX,
    required double hookY,
  }) {
    final deltaX = hookX - tailheadX;
    final deltaY = tailheadY - hookY; // Y invertido en pantalla
    return (atan2(deltaY, deltaX) * 180 / pi).abs();
  }

  /// Estimar PT desde detección por foto
  /// Requiere foto lateral y foto frontal del animal
  static double estimateHeartGirthFromPhotos({
    required double frontWidthPx,
    required double sideHeightPx,
    required double pixelsPerCm,
  }) {
    final widthCm = frontWidthPx / pixelsPerCm;
    final heightCm = sideHeightPx / pixelsPerCm;
    // Aproximar PT como perímetro de elipse
    // PT ≈ π × √((a² + b²) / 2) donde a=ancho/2, b=alto/2
    final a = widthCm / 2;
    final b = heightCm / 2;
    return pi * sqrt((a * a + b * b) / 2);
  }
}

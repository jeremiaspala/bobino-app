import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2E7D32);
  static const primaryLight = Color(0xFF60AD5E);
  static const primaryDark = Color(0xFF005005);
  static const secondary = Color(0xFFFF8F00);
  static const secondaryLight = Color(0xFFFFBF47);
  static const background = Color(0xFFF5F5F0);
  static const surface = Color(0xFFFFFFFF);
  static const error = Color(0xFFB71C1C);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);

  static const iccColors = [
    Color(0xFFB71C1C), // 1.0 - rojo oscuro
    Color(0xFFE53935), // 1.5
    Color(0xFFFF7043), // 2.0
    Color(0xFFFF8F00), // 2.5
    Color(0xFFFFC107), // 3.0 - amarillo (ideal bajo)
    Color(0xFF8BC34A), // 3.5 - verde claro (ideal)
    Color(0xFF43A047), // 4.0 - verde
    Color(0xFF00897B), // 4.5
    Color(0xFF00695C), // 5.0 - verde oscuro (gordo)
  ];
}

class AppStrings {
  static const appName = 'Bobino App';
  static const iccLabel = 'Índice de Condición Corporal';
  static const weightLabel = 'Peso estimado';
  static const tagLabel = 'Número de caravana';
}

// COCO class index for cow
const int kCowClassId = 19;
const double kConfidenceThreshold = 0.5;
const double kNmsIouThreshold = 0.45;
const int kYoloInputSize = 640;

// ICC scale: 1.0 to 5.0 in 0.5 steps
final List<double> kIccValues = [
  1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0
];

// ICC descriptions — no const because double keys override ==
// ignore: prefer_const_declarations
final Map<double, Map<String, String>> kIccDescriptions = {
  1.0: {
    'title': 'Emaciado',
    'desc':
        'Costillas, vértebras y pelvis muy prominentes. Sin tejido graso. Animal en peligro.',
    'ribs': 'Visibles sin palpar',
    'spine': 'Prominentes con punta afilada',
    'rump': 'Muy angular, cóncava',
  },
  1.5: {
    'title': 'Muy flaco',
    'desc': 'Costillas visibles, vértebras prominentes, poca masa muscular.',
    'ribs': 'Visibles fácilmente',
    'spine': 'Prominente',
    'rump': 'Angular',
  },
  2.0: {
    'title': 'Flaco',
    'desc':
        'Costillas visibles, algo de tejido sobre vértebras. Ancas y isquiones notorios.',
    'ribs': 'Visibles, palpables fácil',
    'spine': 'Palpable fácil',
    'rump': 'Algo plana',
  },
  2.5: {
    'title': 'Moderadamente flaco',
    'desc': 'Costillas palpables. Algo de tejido. Ancas aún notorias.',
    'ribs': 'Palpables con leve presión',
    'spine': 'Palpable',
    'rump': 'Algo cóncava',
  },
  3.0: {
    'title': 'Moderado (ideal)',
    'desc':
        'Condición ideal. Costillas palpables con presión. Anca redondeada. Vértebras suaves.',
    'ribs': 'Palpables con presión',
    'spine': 'Suave al tacto',
    'rump': 'Redondeada',
  },
  3.5: {
    'title': 'Ligeramente gordo',
    'desc':
        'Costillas difícilmente palpables. Depósitos grasos sobre costillas. Anca llena.',
    'ribs': 'Difícil de palpar',
    'spine': 'No palpable',
    'rump': 'Llena y redondeada',
  },
  4.0: {
    'title': 'Gordo',
    'desc':
        'Costillas solo con presión fuerte. Depósitos grasos visibles en anca y cola.',
    'ribs': 'Solo con presión fuerte',
    'spine': 'No palpable, cubierta de grasa',
    'rump': 'Cuadrada, llena',
  },
  4.5: {
    'title': 'Muy gordo',
    'desc':
        'Grasa sobre costillas, anca y cuello. Movilidad reducida posible.',
    'ribs': 'No palpables',
    'spine': 'No palpable',
    'rump': 'Grasa sobresaliendo',
  },
  5.0: {
    'title': 'Obeso',
    'desc':
        'Grasa abundante en todos los depósitos. Riesgo de cetosis y problemas reproductivos.',
    'ribs': 'No palpables',
    'spine': 'No palpable',
    'rump': 'Muy llena, grasa colgante',
  },
};

const List<String> kBreeds = [
  'Aberdeen Angus',
  'Hereford',
  'Brangus',
  'Braford',
  'Limousin',
  'Simmental',
  'Charolais',
  'Shorthorn',
  'Criolla',
  'Otra',
];

const List<String> kSexOptions = ['Vaca', 'Toro', 'Novillo', 'Vaquillona'];

// Weight formula constants (Anderson formula)
const double kBeefK = 10840.0;
const double kDairyK = 11000.0;

// Rump angle thresholds (degrees)
const double kRumpAngleFlat = 2.0;
const double kRumpAngleIdeal = 8.0;

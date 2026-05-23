# BovApp — Setup Guide

App Android offline para evaluación de bovinos: ICC (Índice de Condición Corporal) y Peso Estimado con YOLO.

## Requisitos

- Flutter SDK >= 3.0.0
- Android SDK (minSdk 24, es decir Android 7.0+)
- Dart >= 3.0.0

## Instalación

```bash
# 1. Instalar dependencias
flutter pub get

# 2. Agregar el modelo YOLO (ver instrucciones abajo)
# assets/models/yolov8n.tflite

# 3. Correr en Android
flutter run
```

## Modelo YOLO (requerido para detección automática)

La app funciona sin el modelo (modo manual), pero para la detección automática con IA necesitás el archivo TFLite.

### Opción rápida — YOLOv8 nano (COCO, detecta vacas)

```bash
pip install ultralytics
python -c "
from ultralytics import YOLO
model = YOLO('yolov8n.pt')
model.export(format='tflite', imgsz=640)
"
# Copiar el .tflite generado
cp yolov8n_saved_model/yolov8n_float32.tflite assets/models/yolov8n.tflite
```

### Opción avanzada — Modelo especializado en bovinos

Para mejor precisión en ICC, entrenár sobre dataset de bovinos con anotaciones BCS:

```bash
# Preparar dataset (imágenes etiquetadas con clase 'bovino')
yolo train model=yolov8n.pt data=bovinos.yaml epochs=100 imgsz=640

# Exportar
yolo export model=runs/detect/train/weights/best.pt format=tflite

cp runs/detect/train/weights/best_saved_model/best_float32.tflite \
   assets/models/yolov8n.tflite
```

## Lo que calcula la app

| Valor | Fuente | Precisión |
|-------|--------|-----------|
| ICC (1-5) | IA (foto lateral) o manual guiado | Alta si se usa guía visual |
| Peso | Fórmula Schoorl: `(PT + 22)² / 100` | ±10% con PT medido |
| Peso | Fórmula Anderson: `(PT² × Largo) / 10840` | ±8% con PT + largo |
| Ángulo de grupa | Foto trasera + marcado de puntos | Indicativo |
| Ancho de cadera | Foto trasera con referencia de escala | ±15% |
| Condición del pelaje | Análisis de brillo/saturación de la foto | Orientativo |

### Fórmulas de peso

- **Schoorl** (solo perímetro torácico): `W = (PT + 22)² / 100`
- **Anderson** (PT + largo del cuerpo): `W = (PT² × Largo) / 10.840`
- **Estimado por ICC**: tabla relativa al peso ideal de la raza

### Escala ICC utilizada

| ICC | Estado | Descripción |
|-----|--------|-------------|
| 1.0 | Emaciado | Costillas y vértebras muy prominentes |
| 1.5 | Muy flaco | Costillas visibles |
| 2.0 | Flaco | Costillas palpables fácil |
| 2.5 | Mod. flaco | Algo de tejido |
| 3.0 | **Ideal** | Costillas con presión, anca redondeada |
| 3.5 | Lev. gordo | Depósitos grasos iniciales |
| 4.0 | Gordo | Costillas solo con presión fuerte |
| 4.5 | Muy gordo | Grasa visible |
| 5.0 | Obeso | Grasa abundante |

## Ángulo de la grupa

- **< 2°**: Muy plana → riesgo de retención de placenta
- **2–8°**: Ideal → facilita el parto
- **> 8°**: Muy inclinada → puede dificultar el parto

## Estructura del proyecto

```
lib/
├── main.dart
├── app.dart
├── models/
│   ├── animal.dart         # Modelo de animal (caravana, raza, etc.)
│   └── measurement.dart    # Medición (ICC, peso, fotos, morfometría)
├── services/
│   ├── database_service.dart   # SQLite (sqflite)
│   ├── weight_calculator.dart  # Fórmulas Schoorl/Anderson
│   ├── yolo_detector.dart      # Inferencia YOLO + análisis de pelaje
│   └── icc_estimator.dart      # Estimación ICC desde foto
├── providers/
│   └── app_provider.dart   # Estado global (Provider)
├── screens/
│   ├── home_screen.dart        # Dashboard + guía ICC
│   ├── animal_list_screen.dart # Lista de animales
│   ├── animal_detail_screen.dart # Perfil + historia + gráficos
│   ├── add_animal_screen.dart  # Registrar/editar animal
│   └── new_measurement_screen.dart # Nueva medición (foto + manual)
└── widgets/
    ├── bcs_indicator.dart    # Indicador circular ICC + barra de escala
    ├── animal_card.dart      # Tarjeta de animal
    └── measurement_chart.dart # Gráfico de evolución ICC/peso
```

## Cómo tomar las fotos

### Vista lateral (para ICC y peso)
- Pararse a 3-5 metros del animal
- El animal debe verse completo (de cabeza a cola)
- Luz natural, sin sombras fuertes
- Incluir una cinta métrica visible o un objeto de tamaño conocido como referencia

### Vista trasera (para ancho de cadera y ángulo de grupa)
- Pararse directamente detrás del animal
- Centrar la foto en la grupa y ancas
- El animal debe estar parado en superficie plana

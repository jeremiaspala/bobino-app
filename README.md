# Bobino App
(me maté con el nombre)

**Evaluación offline de bovinos con IA — ICC y peso sin internet**

> [Jeremías Palazzesi](https://www.nerdadas.com) · Código abierto (MIT)

---

## Por qué existe esto

Soy programador y no tengo campo pero en la Argentina la ganadería es central. Hace poco me preguntaron porque los productores siguen evaluando el estado corporal de sus animales completamente a ojo, cuando la misma tecnología que usamos para detectar objetos en fotos podría hacer ese trabajo de forma objetiva, repetible y sin necesidad de internet ni equipamiento especial.

Bobino App nació de esa pregunta. No es un proyecto académico ni un paper: es una herramienta práctica para que un productor, parado al lado del corral con el teléfono en la mano, pueda obtener el **ICC (Índice de Condición Corporal)** y el **peso estimado** de sus animales sin comprar nada especial.

Todo lo que necesitás es el teléfono. Si querés el peso con buena precisión, una cinta métrica de \$200.

---

## Qué hace la app

- **Detección de bovinos con YOLO** — YOLOv8n corriendo en el teléfono, sin internet, clase 19 del dataset COCO = "cow"
- **ICC 1.0 a 5.0** en pasos de 0.5, escala estándar argentina (AACREA/INTA), con guía visual integrada por puntaje
- **Peso estimado** con fórmulas de Schoorl y Anderson, usando medidas morfométricas
- **Herramienta de medición interactiva** — marcás 5 puntos anatómicos sobre la foto y la app calcula largo corporal, profundidad torácica y estima el perímetro torácico
- **Análisis de pelaje** — estimación del estado del pelaje desde la foto (brillo/saturación)
- **Historial por animal** — registro con número de caravana, raza, sexo, historial de mediciones y gráficos de evolución ICC/peso
- **100% offline** — todos los modelos (13 MB) van dentro del APK

---

## Cómo funciona el cálculo de peso

### Fórmula de Schoorl
```
P (kg) = (PT + 22)² / 100
```
Solo necesita el **perímetro torácico** (PT) en cm. Simple, rápida, precisión ±5–10% con PT medido con cinta.

### Fórmula de Anderson
```
P (kg) = PT² × Largo / 10.840  (ganado de carne)
P (kg) = PT² × Largo / 11.000  (ganado lechero)
```
Más precisa: ±3–8% con PT real. Necesita PT + largo del cuerpo.

### Estimación desde foto (herramienta interactiva)
Marcás 5 puntos en la foto lateral:

| Punto | Para qué sirve |
|---|---|
| Referencia A + B | Calibración de escala px→cm |
| Punto anterior del hombro | Inicio del largo corporal |
| Isquión (trasero de la cadera) | Fin del largo corporal |
| Cruz (punto más alto del lomo) | Inicio de la profundidad torácica |
| Esternón (punto más bajo del pecho) | Fin de la profundidad torácica |

Con esos puntos la app calcula el largo y la profundidad torácica en cm reales. El **PT se estima** usando la sección transversal del tórax como una elipse:

```
PT ≈ π × √((a² + b²) / 2) × 2
donde:
  b = profundidad torácica / 2  (semieje vertical, medido)
  a = profundidad × 0.72 / 2   (semieje horizontal, estimado con proporción anatómica típica bovina)
```

Opcionales: también podés marcar rabija + anca para el **ángulo de la grupa**, y el suelo bajo las patas para la **alzada a la cruz**.

---

## Precisión real (sin filtros)

| Medición | Método | Precisión típica |
|---|---|---|
| Largo corporal | Desde foto, con referencia | ±3–8 cm |
| Profundidad torácica | Desde foto, con referencia | ±2–6 cm |
| PT estimado desde foto | Elipse desde profundidad | ±10–20% |
| Peso — Schoorl con PT de cinta | Fórmula directa | ±5–10% |
| Peso — Anderson con PT de cinta | Fórmula directa | ±3–8% |
| Peso — Schoorl con PT de foto | Error compuesto | ±15–25% |
| Peso — Anderson con PT de foto | Error compuesto | ±12–20% |
| ICC estimado por YOLO | Heurística de bounding box | ±0.5–1.0 puntos |

**El cuello de botella es el PT.** El perímetro torácico es una circunferencia y no se puede medir exactamente desde una sola foto lateral. La profundidad torácica sí se puede medir bien, pero la relación ancho/profundidad varía por raza (60–85%). Para peso con buena precisión, usá la cinta para el PT y dejá que la foto aporte el largo corporal (eso te da Anderson con ±4–8%).

**El PT estimado desde foto sirve como referencia rápida y orientativa, no como dato técnico.**

---

## La ciencia detrás (y por qué hacemos esto diferente)

Hay una literatura científica creciente sobre evaluación automatizada de BCS con IA. Los papers más relevantes:

### BCS-YOLO (Animals, MDPI, 2024)
**"Efficient Cow Body Condition Scoring Using BCS-YOLO"**
DOI: [10.3390/ani14243668](https://doi.org/10.3390/ani14243668)

Propone una arquitectura YOLO especializada en BCS bovino. Es 33% más liviana que YOLOv8n y logra +9.4% de mAP en el scoring de condición corporal respecto al modelo base. El dataset fue anotado con vacas Holstein/Friesian en granja controlada.

**Problema**: el modelo no está disponible públicamente. El dataset sí está disponible bajo solicitud en `scidb.cn`.

### EdgeBCS-YOLO (Animals, MDPI, 2025)
**"Real-Time Beef Cattle Body Condition Scoring Using EdgeBCS-YOLO"**
DOI: [10.3390/ani16081143](https://doi.org/10.3390/ani16081143)

Versión ultra-liviana de BCS-YOLO pensada para dispositivos edge (Jetson Orin). Solo 3.95 MB, corre a 33 FPS en tiempo real. Incorpora módulos propios: PSFF (feature fusion), TASM (atención espacial) y EGDH (detección de cabeza). Impresionante en términos de ingeniería de modelos.

**Problema**: tampoco disponible públicamente.

### Calves tracking con YOLOv8-pose (Frontiers, 2025)
**"Integrating YOLOv8-pose for calves tracking"**
DOI: [10.3389/fanim.2025.1718641](https://doi.org/10.3389/fanim.2025.1718641)

Fine-tuning de YOLOv8-pose para detectar keypoints anatómicos en terneros. Permite medir distancias morfométricas automáticamente desde video. Es el enfoque más cercano a lo que necesitamos para medir sin referencia física.

---

### Lo que hacemos diferente en Bobino App

Los papers mencionados trabajan con:
- Modelos especializados entrenados en datasets bovinos anotados
- Infraestructura de granja controlada (cámaras fijas, iluminación uniforme)
- Hardware dedicado (Jetson) o infraestructura cloud para entrenamiento

Nosotros trabajamos con:
- **Modelos COCO públicos** (YOLOv8n), sin fine-tuning, porque los especializados no están disponibles
- **El teléfono del productor**, con foto sacada en el campo, en cualquier condición
- **Medición asistida**: el productor hace el trabajo de anotación de puntos anatómicos que el modelo especializado haría automáticamente

La diferencia fundamental es que **compensamos la falta de modelo especializado con interacción humana**. El productor marca los puntos, la app hace los cálculos. Funciona hoy, con hardware de consumo, sin requerir un dataset de bovinos etiquetado.

**El camino a seguir para mejorar la precisión** sería hacer fine-tuning de YOLOv8n-pose con un dataset propio de bovinos argentinos (Angus, Hereford, Brangus) anotado con keypoints anatómicos. Con 500–1000 imágenes etiquetadas en Roboflow y entrenamiento en Google Colab (gratuito), se podría automatizar completamente la detección de puntos anatómicos y mejorar el ICC estimado. Eso sería un paper original sobre razas del cono sur.

---

## Modelos de IA incluidos

| Archivo | Tamaño | Uso | Fuente |
|---|---|---|---|
| `yolov8n.tflite` | 13 MB | Detección activa | [HuggingFace SpotLab](https://huggingface.co/SpotLab/YOLOv8Detection) |
| `yolov8n_seg.onnx` | 14 MB | Segmentación (stub, futuro) | [Ultralytics assets](https://github.com/ultralytics/assets/releases/download/v8.4.0/yolov8n-seg.onnx) |
| `yolo11n.onnx` | 11 MB | Detección alternativa (futuro) | Ultralytics |
| `yolov8n_pose.onnx` | 13 MB | Keypoints (futuro, requiere fine-tuning) | Ultralytics |

El modelo activo es `yolov8n.tflite`:
- Input: `[1, 640, 640, 3]` float32 NHWC, normalizado 0–1
- Output: `[1, 84, 8400]` — 4 coords + 80 clases × 8400 anchors
- Clase 19 = "cow"
- Versión: YOLOv8n v8.0.192, entrenado en COCO (2023-10-06)

---

## Qué necesitás para usarla

- **Android 8.0 o superior** (API 26+, requerido por TFLite)
- **Cámara trasera** — 8 MP mínimo recomendado
- **Sin internet** — todo funciona offline
- **Cinta métrica** (opcional pero recomendada para peso con precisión real)
- Foto lateral del animal, completo de cabeza a cola, a 3–5 metros de distancia

---

## Cómo compilar

```bash
# Dependencias
flutter pub get

# Análisis (debe pasar sin errores)
flutter analyze

# Compilar APK arm64
export JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64  # Java 17 requerido
export PATH=$JAVA_HOME/bin:$PATH
flutter build apk --release --target-platform android-arm64

# Instalar en dispositivo conectado por ADB
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

**Nota crítica**: Gradle 7.5 (el que usa este proyecto) es incompatible con Java 21. Siempre compilar con Java 17.

### Stack técnico

| Componente | Versión |
|---|---|
| Flutter | 3.13.6 |
| Dart | 3.1.3 |
| Gradle | 7.5 |
| Android Gradle Plugin | 7.3.0 |
| Kotlin | 1.7.10 |
| minSdkVersion | 26 (Android 8.0) |
| compileSdkVersion | 34 |

### Dependencias clave

| Paquete | Versión | Por qué |
|---|---|---|
| `tflite_flutter` | ^0.10.4 | Inferencia YOLO on-device |
| `sqflite` | ^2.3.0 | Base de datos SQLite offline |
| `image_picker` | ^1.0.7 | Cámara y galería |
| `image` | ^4.1.7 | Procesamiento de imagen |
| `provider` | ^6.1.2 | Estado global |
| `fl_chart` | ^0.64.0 | Gráficos de evolución |

Versiones pinadas para compatibilidad con Flutter 3.13.6. No subir sin probar.

---

## Estructura del proyecto

```
lib/
├── main.dart
├── app.dart
├── models/
│   ├── animal.dart          # Animal (caravana, raza, sexo)
│   └── measurement.dart     # Medición (ICC, peso, morfometría, fotos)
├── providers/
│   └── app_provider.dart    # Estado global, DB, YOLO init
├── services/
│   ├── database_service.dart    # SQLite (tablas: animals, measurements)
│   ├── yolo_detector.dart       # TFLite — detección + análisis de pelaje
│   ├── yolo_segmentor.dart      # Stub ONNX (deshabilitado)
│   ├── icc_estimator.dart       # Estimación ICC desde bounding box
│   ├── weight_calculator.dart   # Fórmulas Schoorl/Anderson
│   └── model_sources.dart       # URLs de descarga de todos los modelos
├── screens/
│   ├── home_screen.dart
│   ├── animal_list_screen.dart
│   ├── animal_detail_screen.dart
│   ├── add_animal_screen.dart
│   ├── new_measurement_screen.dart
│   ├── photo_measure_screen.dart  # ← herramienta de medición interactiva
│   └── about_screen.dart
├── widgets/
│   ├── bcs_indicator.dart     # Indicador circular ICC
│   ├── animal_card.dart
│   └── measurement_chart.dart # Gráfico fl_chart
└── utils/
    └── constants.dart         # Colores, ICC descriptions, umbrales YOLO
```

---

## Contribuir

Pull requests bienvenidos. Las áreas que más impacto tendrían:

1. **Fine-tuning del modelo** con razas argentinas (Angus, Hereford, Brangus) — haría el ICC automático real
2. **Segmentación activa** con `yolov8n_seg.onnx` + `flutter_onnxruntime` — mejor morfometría
3. **Detección de keypoints bovinos** con `yolov8n_pose.onnx` fine-tuneado — automatiza los 5 puntos que hoy marca el usuario
4. **Exportar PDF/CSV** del historial del animal
5. **Alertas** de ICC crítico (< 2.0 al parto, < 1.5 en cualquier etapa)

---

## Autor

**Jeremías Palazzesi**
Nerdo avanzado
[https://www.nerdadas.com](https://www.nerdadas.com)

Esta app se construyó como un ejercicio de qué tan lejos se puede llegar con IA disponible públicamente aplicada a ganadería real, sin infraestructura de granja controlada ni modelos propietarios. El resultado es imperfecto pero funcional, y esa es exactamente la idea.

---

## Licencia

MIT — libre para usar, modificar y distribuir con atribución.

Los modelos YOLO son propiedad de [Ultralytics](https://ultralytics.com) (AGPL-3.0).

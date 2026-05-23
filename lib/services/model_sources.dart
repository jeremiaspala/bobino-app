/// Documentación de todos los modelos usados en BovApp.
///
/// ─── MODELOS EN USO ───────────────────────────────────────────────────────────
///
/// 1. yolov8n.tflite  (13 MB, detección)
///    Fuente: https://huggingface.co/SpotLab/YOLOv8Detection/resolve/main/tflite_model.tflite
///    Modelo: YOLOv8n oficial de Ultralytics, entrenado en COCO (80 clases)
///    Metadata embebida: "Ultralytics YOLOv8n model trained on coco.yaml"
///    Version: 8.0.192 | Fecha: 2023-10-06
///    Input:  [1, 640, 640, 3] float32 (NHWC, normalizado 0-1)
///    Output: [1, 84, 8400]   float32  (4 coords + 80 clases × 8400 anchors)
///    Clase 19 = "cow" (bovino) ← usada en esta app
///
/// 2. yolov8n_seg.onnx  (14 MB, segmentación)
///    Fuente: https://github.com/ultralytics/assets/releases/download/v8.4.0/yolov8n-seg.onnx
///    Modelo: YOLOv8n-seg oficial de Ultralytics v8.4.0, entrenado en COCO
///    Input:  [1, 3, 640, 640] float32 (NCHW, normalizado 0-1)
///    Output: [1, 116, 8400]   + [1, 32, 160, 160] (boxes+masks+prototypes)
///    Útil para segmentar el contorno exacto del animal (mejor morfometría)
///
/// ─── MODELOS ALTERNATIVOS DISPONIBLES ─────────────────────────────────────────
///
/// 3. yolov8n-pose.onnx  (12 MB, keypoints humanos — requiere fine-tuning)
///    Fuente: https://github.com/ultralytics/assets/releases/download/v8.4.0/yolov8n-pose.onnx
///    Nota: entrenado para humanos (COCO keypoints). Fine-tuning con dataset
///    bovino (7 keypoints: cabeza, cruz, dorso, anca, cola, ancas, patas)
///    podría detectar puntos anatómicos para ICC más preciso.
///    Paper de referencia: "Integrating YOLOv8-pose for calves tracking" (2025)
///    DOI: 10.3389/fanim.2025.1718641
///
/// 4. BCS-YOLO  (modelo especializado en ICC/BCS — no disponible públicamente)
///    Paper: "Efficient Cow BCS Using BCS-YOLO" (Animals 2024)
///    DOI: https://doi.org/10.3390/ani14243668
///    Dataset: https://www.scidb.cn/en/detail?dataSetId=16b8bdaf31ee4c8b9891fc7e9df6e41c
///    Nota: 33% más liviano que YOLOv8n, +9.4% mAP en BCS scoring.
///          Modelo no liberado públicamente; contactar autores para acceso.
///
/// 5. EdgeBCS-YOLO  (ultra-liviano para edge, 3.95 MB — no disponible públ.)
///    Paper: "Real-Time Beef Cattle BCS Using EdgeBCS-YOLO" (Animals 2025)
///    DOI: https://doi.org/10.3390/ani16081143
///    Basado en YOLO11n con PSFF + TASM + EGDH. 33.35 FPS en Jetson Orin.
///
/// 6. YOLOv8n-seg STM32 INT8  (3.25 MB, ultra-compacto para embedded)
///    Fuente: https://huggingface.co/STMicroelectronics/yolov8n_pose
///    GitHub: https://github.com/stm32-hotspot/ultralytics
///    Nota: cuantizado INT8, diseñado para STM32. Sirve como referencia para
///          cuantizar nuestro modelo y reducir tamaño (de 13MB a ~3MB).
///
/// ─── DATASETS PARA ENTRENAMIENTO PROPIO ───────────────────────────────────────
///
/// - OpenImages V7 "Cow": https://storage.googleapis.com/openimages/web/index.html
///   (11K+ imágenes de vacas con bounding boxes)
/// - Roboflow Universe - Cattle: https://universe.roboflow.com/search?q=class:cattle
///   (múltiples datasets con distintas razas y condiciones)
/// - Kaggle Cattle Detection: https://www.kaggle.com/datasets/trainingdatapro/cows-detection-dataset
/// - BCS Dataset (requiere solicitud): https://www.scidb.cn/en/detail?dataSetId=16b8bdaf31ee4c8b9891fc7e9df6e41c

// ignore_for_file: unused_element

class ModelSources {
  ModelSources._();

  // Paths de assets en la app
  static const String detectionTflite = 'assets/models/yolov8n.tflite';
  static const String segmentationOnnx = 'assets/models/yolov8n_seg.onnx';

  // Fuentes de descarga
  static const String detectionSource =
      'https://huggingface.co/SpotLab/YOLOv8Detection/resolve/main/tflite_model.tflite';
  static const String segmentationSource =
      'https://github.com/ultralytics/assets/releases/download/v8.4.0/yolov8n-seg.onnx';
  static const String poseSource =
      'https://github.com/ultralytics/assets/releases/download/v8.4.0/yolov8n-pose.onnx';

  // Clase COCO para bovinos
  static const int cowClassId = 19;

  // Input specs
  static const int detectionInputSize = 640;      // 640×640 px
  static const int segmentationInputSize = 640;   // 640×640 px

  // Output specs
  // Detection TFLite: [1, 84, 8400] — 4 coords + 80 clases × 8400 anchors
  static const List<int> detectionOutputShape = [1, 84, 8400];
  // Segmentation ONNX: [1, 116, 8400] + [1, 32, 160, 160] proto masks
  static const List<int> segmentationBoxShape = [1, 116, 8400];
  static const List<int> segmentationMaskShape = [1, 32, 160, 160];
}

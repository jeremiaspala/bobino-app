# Modelos de IA — BovApp

## Modelos incluidos en la app

### 1. `yolov8n.tflite` — Detección (13 MB) ✅ INCLUIDO

**Fuente de descarga:**
```
https://huggingface.co/SpotLab/YOLOv8Detection/resolve/main/tflite_model.tflite
```

**Qué es:** YOLOv8n de Ultralytics, versión 8.0.192, entrenado en COCO (80 clases).  
**Clase usada:** 19 = "cow" (bovino)  
**Input:** `[1, 640, 640, 3]` float32, NHWC, normalizado 0–1  
**Output:** `[1, 84, 8400]` float32 — 4 coords + 80 clases × 8400 anchors  
**Uso en la app:** Detectar el bovino en la foto → bounding box → morfometría → peso

### 2. `yolov8n_seg.onnx` — Segmentación (14 MB) ✅ INCLUIDO

**Fuente de descarga (oficial Ultralytics v8.4.0):**
```
https://github.com/ultralytics/assets/releases/download/v8.4.0/yolov8n-seg.onnx
```

**Qué es:** YOLOv8n-seg, segmentación de instancias, COCO 80 clases.  
**Input:** `[1, 3, 640, 640]` float32, NCHW, normalizado 0–1  
**Output 0:** `[1, 116, 8400]` — boxes + clase + 32 coeficientes de máscara  
**Output 1:** `[1, 32, 160, 160]` — prototipos de máscaras  
**Uso en la app:** Segmentar el contorno exacto del animal para morfometría más precisa

---

## Modelos alternativos (no incluidos, requieren descarga manual)

### 3. `yolov8n-pose.onnx` — Estimación de pose humana (12 MB)

```
https://github.com/ultralytics/assets/releases/download/v8.4.0/yolov8n-pose.onnx
```

Entrenado para humanos (17 keypoints COCO). Para bovinos necesita fine-tuning.  
Con fine-tuning en dataset bovino puede detectar: cruz, lomo, anca, cola, patas.  
**Paper de referencia:** [YOLOv8-pose para terneros (2025)](https://doi.org/10.3389/fanim.2025.1718641)

### 4. `yolo11n.onnx` — YOLO11 nano, última generación (10 MB)

```
https://github.com/ultralytics/assets/releases/download/v8.4.0/yolo11n.onnx
```

Más liviano y preciso que YOLOv8n. Mismas clases COCO. Drop-in replacement.

### 5. BCS-YOLO — Estimación ICC/BCS directa ⚠️ No público

**Paper:** [Efficient Cow BCS Using BCS-YOLO (Animals 2024)](https://doi.org/10.3390/ani14243668)  
Modelo entrenado específicamente para clasificar bovinos en BCS 3.25–4.25.  
Input desde arriba (drone o cámara cenital), región de la cola.  
Dataset: [scidb.cn (requiere solicitud)](https://www.scidb.cn/en/detail?dataSetId=16b8bdaf31ee4c8b9891fc7e9df6e41c)

### 6. EdgeBCS-YOLO — Versión para edge devices ⚠️ No público

**Paper:** [Real-Time Beef Cattle BCS using EdgeBCS-YOLO (Animals 2025)](https://doi.org/10.3390/ani16081143)  
3.95 MB, 33 FPS en Jetson Orin. Basado en YOLO11n con PSFF + TASM + EGDH.

---

## Cómo regenerar los modelos incluidos

```bash
# Si querés regenerar en vez de usar los incluidos:

# 1. TFLite (detección)
pip install ultralytics
python -c "from ultralytics import YOLO; YOLO('yolov8n.pt').export(format='tflite')"
cp yolov8n_saved_model/yolov8n_float32.tflite assets/models/yolov8n.tflite

# 2. ONNX (segmentación) — descarga directa
curl -L -o assets/models/yolov8n_seg.onnx \
  https://github.com/ultralytics/assets/releases/download/v8.4.0/yolov8n-seg.onnx
```

---

## Datasets para entrenar modelo propio de ICC

| Dataset | Tamaño | Acceso |
|---------|--------|--------|
| [OpenImages V7 - Cow](https://storage.googleapis.com/openimages/web/index.html) | 11K imágenes | Libre |
| [Roboflow Cattle](https://universe.roboflow.com/search?q=class:cattle) | Varios | Libre/registro |
| [Kaggle Cattle Detection](https://www.kaggle.com/datasets/trainingdatapro/cows-detection-dataset) | ~1K | Libre |
| [BCS Dataset (scidb.cn)](https://www.scidb.cn/en/detail?dataSetId=16b8bdaf31ee4c8b9891fc7e9df6e41c) | Específico ICC | Solicitud |

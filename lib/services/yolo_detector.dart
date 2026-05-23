// Detección con YOLOv8n via TFLite.
//
// Modelo: yolov8n.tflite (13 MB)
// Fuente: https://huggingface.co/SpotLab/YOLOv8Detection/resolve/main/tflite_model.tflite
// Base:   Ultralytics YOLOv8n v8.0.192, entrenado en COCO (2023-10-06)
// Input:  [1, 640, 640, 3] float32 NHWC, normalizado 0-1
// Output: [1, 84, 8400]   float32  (4 coords + 80 clases × 8400 anchors)
// Clase 19 = "cow" (bovino)
//
// Para segmentación (contorno exacto del animal), ver yolo_segmentor.dart.

import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'model_sources.dart';
import '../utils/constants.dart';

class Detection {
  final int classId;
  final String label;
  final double confidence;
  // Normalized coordinates [0,1]
  final double x; // center x
  final double y; // center y
  final double width;
  final double height;

  Detection({
    required this.classId,
    required this.label,
    required this.confidence,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  double get left => x - width / 2;
  double get top => y - height / 2;
  double get right => x + width / 2;
  double get bottom => y + height / 2;

  double get area => width * height;
}

class MorphometricData {
  final double bodyLengthPixels;
  final double bodyHeightPixels;
  final double hipWidthPixels;
  final Detection detection;

  MorphometricData({
    required this.bodyLengthPixels,
    required this.bodyHeightPixels,
    required this.hipWidthPixels,
    required this.detection,
  });

  // Convert to cm using pixels-per-cm scale factor
  MorphometricCm toCm(double pixelsPerCm) => MorphometricCm(
        bodyLengthCm: bodyLengthPixels / pixelsPerCm,
        bodyHeightCm: bodyHeightPixels / pixelsPerCm,
        hipWidthCm: hipWidthPixels / pixelsPerCm,
      );
}

class MorphometricCm {
  final double bodyLengthCm;
  final double bodyHeightCm;
  final double hipWidthCm;

  MorphometricCm({
    required this.bodyLengthCm,
    required this.bodyHeightCm,
    required this.hipWidthCm,
  });
}

class CoatAnalysis {
  final double brightness; // 0-255
  final double saturation; // 0-1
  final double score; // 1-5 (condition score)
  final String description;

  CoatAnalysis({
    required this.brightness,
    required this.saturation,
    required this.score,
    required this.description,
  });
}

class YoloDetector {
  Interpreter? _interpreter;
  bool _modelLoaded = false;
  bool _modelAvailable = false;

  static const String _modelPath = ModelSources.detectionTflite;

  static final YoloDetector _instance = YoloDetector._internal();
  factory YoloDetector() => _instance;
  YoloDetector._internal();

  bool get isReady => _modelLoaded && _modelAvailable;

  Future<bool> loadModel() async {
    if (_modelLoaded) return _modelAvailable;
    try {
      // Check if model file exists in assets
      await rootBundle.load(_modelPath);
      _interpreter = await Interpreter.fromAsset(_modelPath);
      _modelAvailable = true;
    } catch (e) {
      // Model not bundled — app works without it (manual mode)
      _modelAvailable = false;
    }
    _modelLoaded = true;
    return _modelAvailable;
  }

  /// Run YOLO detection on an image, return cow detections
  Future<List<Detection>> detect(img.Image image) async {
    if (!isReady || _interpreter == null) return [];

    final inputTensor = _preprocessImage(image);
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    // YOLOv8 output: [1, 84, 8400]
    final output = List.generate(
      outputShape[0],
      (_) => List.generate(
        outputShape[1],
        (_) => List<double>.filled(outputShape[2], 0.0),
      ),
    );

    // tflite_flutter expects input wrapped in a list for batch dim
    _interpreter!.run([inputTensor], output);
    return _parseOutput(output[0], image.width, image.height);
  }

  Float32List _preprocessImage(img.Image image) {
    final resized =
        img.copyResize(image, width: kYoloInputSize, height: kYoloInputSize);
    final buffer = Float32List(1 * kYoloInputSize * kYoloInputSize * 3);
    int idx = 0;
    for (int y = 0; y < kYoloInputSize; y++) {
      for (int x = 0; x < kYoloInputSize; x++) {
        final pixel = resized.getPixel(x, y);
        buffer[idx++] = pixel.r / 255.0;
        buffer[idx++] = pixel.g / 255.0;
        buffer[idx++] = pixel.b / 255.0;
      }
    }
    return buffer;
  }

  List<Detection> _parseOutput(
      List<List<double>> output, int imgW, int imgH) {
    final detections = <Detection>[];
    final numBoxes = output[0].length; // 8400

    for (int i = 0; i < numBoxes; i++) {
      final cx = output[0][i];
      final cy = output[1][i];
      final w = output[2][i];
      final h = output[3][i];

      // Find max class score
      double maxScore = 0;
      int maxClass = -1;
      for (int c = 0; c < 80; c++) {
        final score = output[4 + c][i];
        if (score > maxScore) {
          maxScore = score;
          maxClass = c;
        }
      }

      // Only keep cows (class 19) with enough confidence
      if (maxClass == kCowClassId && maxScore >= kConfidenceThreshold) {
        detections.add(Detection(
          classId: maxClass,
          label: 'bovino',
          confidence: maxScore,
          x: cx,
          y: cy,
          width: w,
          height: h,
        ));
      }
    }

    return _nms(detections);
  }

  /// Non-Maximum Suppression
  List<Detection> _nms(List<Detection> detections) {
    if (detections.isEmpty) return [];
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    final kept = <Detection>[];
    final suppressed = List<bool>.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      kept.add(detections[i]);
      for (int j = i + 1; j < detections.length; j++) {
        if (!suppressed[j] &&
            _iou(detections[i], detections[j]) > kNmsIouThreshold) {
          suppressed[j] = true;
        }
      }
    }
    return kept;
  }

  double _iou(Detection a, Detection b) {
    final interLeft = max(a.left, b.left);
    final interTop = max(a.top, b.top);
    final interRight = min(a.right, b.right);
    final interBottom = min(a.bottom, b.bottom);
    if (interRight <= interLeft || interBottom <= interTop) return 0;
    final intersection =
        (interRight - interLeft) * (interBottom - interTop);
    final union = a.area + b.area - intersection;
    return intersection / union;
  }

  /// Extract morphometric data from the best detection
  MorphometricData? extractMorphometrics(
      Detection detection, int imageWidthPx, int imageHeightPx) {
    final pixelW = detection.width * imageWidthPx;
    final pixelH = detection.height * imageHeightPx;
    // Hip width estimated as 55% of body width (for side view)
    // For rear view, use 80% of bounding box width
    return MorphometricData(
      bodyLengthPixels: pixelW,
      bodyHeightPixels: pixelH,
      hipWidthPixels: pixelW * 0.55,
      detection: detection,
    );
  }

  /// Analyze coat condition from the detected region of the image
  CoatAnalysis analyzeCoat(img.Image image, Detection detection) {
    final imgW = image.width;
    final imgH = image.height;

    final left = (detection.left * imgW).round().clamp(0, imgW - 1);
    final top = (detection.top * imgH).round().clamp(0, imgH - 1);
    final right = (detection.right * imgW).round().clamp(0, imgW - 1);
    final bottom = (detection.bottom * imgH).round().clamp(0, imgH - 1);

    double totalBrightness = 0;
    double totalSaturation = 0;
    int count = 0;

    for (int y = top; y < bottom; y += 4) {
      for (int x = left; x < right; x += 4) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final b = pixel.b / 255.0;

        final maxC = max(r, max(g, b));
        final minC = min(r, min(g, b));
        totalBrightness += (maxC + minC) / 2 * 255;
        totalSaturation += maxC > 0 ? (maxC - minC) / maxC : 0;
        count++;
      }
    }

    if (count == 0) {
      return CoatAnalysis(
          brightness: 128, saturation: 0.5, score: 3, description: 'Normal');
    }

    final avgBrightness = totalBrightness / count;
    final avgSaturation = totalSaturation / count;

    // Healthy coat: bright, saturated, uniform color
    // Score heuristic: brighter + more saturated = better condition
    final brightnessScore = (avgBrightness / 255).clamp(0.0, 1.0);
    final rawScore = (brightnessScore * 0.6 + avgSaturation * 0.4) * 4 + 1;
    final score = rawScore.clamp(1.0, 5.0);

    String description;
    if (score < 2.0) {
      description = 'Pelaje opaco, posible deficiencia nutricional o ectoparásitos';
    } else if (score < 3.0) {
      description = 'Pelaje algo deslucido';
    } else if (score < 4.0) {
      description = 'Pelaje normal';
    } else {
      description = 'Pelaje brillante y saludable';
    }

    return CoatAnalysis(
      brightness: avgBrightness,
      saturation: avgSaturation,
      score: score,
      description: description,
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _modelLoaded = false;
  }
}

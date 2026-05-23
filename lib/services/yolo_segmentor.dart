// Segmentación YOLOv8n-seg — stub preparado para ONNX Runtime.
//
// Modelo incluido: assets/models/yolov8n_seg.onnx (14 MB)
// Fuente: https://github.com/ultralytics/assets/releases/download/v8.4.0/yolov8n-seg.onnx
//
// Para activar la segmentación real, agregar al pubspec.yaml:
//   flutter_onnxruntime: ^1.5.1
// y descomentar la implementación completa en este archivo.
//
// Mientras tanto, YoloDetector (TFLite) provee detección con bounding box.

import 'dart:math' show pi, sqrt;
import 'package:image/image.dart' as img;
import '../utils/constants.dart';

class SegmentedBox {
  final double left, top, right, bottom;
  final double confidence;

  const SegmentedBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.confidence,
  });

  double get width => right - left;
  double get height => bottom - top;
}

/// Stub del segmentador — siempre retorna null hasta integrar ONNX Runtime.
class YoloSegmentor {
  static final YoloSegmentor _instance = YoloSegmentor._internal();
  factory YoloSegmentor() => _instance;
  YoloSegmentor._internal();

  bool get isReady => false;

  Future<bool> loadModel() async => false;

  Future<SegmentedBox?> segment(img.Image image) async => null;

  void dispose() {}
}

/// Morfometría estimada desde bounding box de segmentación.
class MorphometryFromMask {
  static double bodyLengthCm(SegmentedBox seg, double pixelsPerCm) =>
      seg.width * kYoloInputSize / pixelsPerCm;

  static double withersHeightCm(SegmentedBox seg, double pixelsPerCm) =>
      seg.height * kYoloInputSize / pixelsPerCm;

  /// Perímetro torácico por aproximación elíptica desde vista lateral.
  static double heartGirthCm(SegmentedBox seg, double pixelsPerCm) {
    final a = bodyLengthCm(seg, pixelsPerCm) / 2;
    final b = withersHeightCm(seg, pixelsPerCm) / 2;
    return pi * sqrt((a * a + b * b) / 2);
  }
}

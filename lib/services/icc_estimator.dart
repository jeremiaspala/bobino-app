import 'package:image/image.dart' as img;
import 'yolo_detector.dart';

class IccEstimate {
  final double score; // 1.0 to 5.0
  final double confidence; // 0 to 1
  final String method; // 'ai', 'guided', 'manual'
  final List<double> regionScores; // partial scores per body region
  final String notes;

  IccEstimate({
    required this.score,
    required this.confidence,
    required this.method,
    this.regionScores = const [],
    this.notes = '',
  });

  double get roundedScore => (score * 2).round() / 2; // redondear a 0.5
}

/// Body regions used to estimate ICC
enum BodyRegion { ribs, spine, tailhead, rump, hooks }

class IccEstimator {
  final YoloDetector _detector;

  IccEstimator(this._detector);

  /// Estimate ICC from a side-view photo using regional analysis.
  /// When no YOLO model is available, returns null (use guided mode).
  Future<IccEstimate?> estimateFromSidePhoto(
      img.Image image, Detection detection) async {
    if (!_detector.isReady) return null;

    // Divide the detection box into anatomical regions
    final imgW = image.width;
    final imgH = image.height;

    final boxLeft = (detection.left * imgW).round();
    final boxTop = (detection.top * imgH).round();
    final boxRight = (detection.right * imgW).round();
    final boxBottom = (detection.bottom * imgH).round();
    final boxW = boxRight - boxLeft;
    final boxH = boxBottom - boxTop;

    // Estimate anatomical regions relative to bounding box
    // Ribs: middle 50% of the body, lower 40%
    final ribsScore = _analyzeRegion(
      image,
      left: boxLeft + (boxW * 0.25).round(),
      top: boxTop + (boxH * 0.40).round(),
      right: boxLeft + (boxW * 0.75).round(),
      bottom: boxBottom,
    );

    // Spine: top 20% of body, center 50%
    final spineScore = _analyzeRegion(
      image,
      left: boxLeft + (boxW * 0.25).round(),
      top: boxTop,
      right: boxLeft + (boxW * 0.75).round(),
      bottom: boxTop + (boxH * 0.25).round(),
    );

    // Tailhead: right 20% of body
    final tailheadScore = _analyzeRegion(
      image,
      left: boxRight - (boxW * 0.20).round(),
      top: boxTop + (boxH * 0.20).round(),
      right: boxRight,
      bottom: boxBottom,
    );

    // Weighted combination: tailhead and ribs are most diagnostic
    const weights = [0.30, 0.25, 0.45]; // ribs, spine, tailhead
    final rawScore = ribsScore * weights[0] +
        spineScore * weights[1] +
        tailheadScore * weights[2];

    // Map visual score (brightness-based) to ICC scale
    final icc = _mapToIcc(rawScore);

    return IccEstimate(
      score: icc,
      confidence: 0.65,
      method: 'ai',
      regionScores: [ribsScore, spineScore, tailheadScore],
      notes: 'Costillas: ${ribsScore.toStringAsFixed(2)}, '
          'Columna: ${spineScore.toStringAsFixed(2)}, '
          'Cola: ${tailheadScore.toStringAsFixed(2)}',
    );
  }

  /// Analyze a region of the image for ICC-related features.
  /// Returns a score 0.0-5.0 based on visual analysis.
  double _analyzeRegion(
    img.Image image, {
    required int left,
    required int top,
    required int right,
    required int bottom,
  }) {
    left = left.clamp(0, image.width - 1);
    top = top.clamp(0, image.height - 1);
    right = right.clamp(0, image.width - 1);
    bottom = bottom.clamp(0, image.height - 1);

    if (right <= left || bottom <= top) return 3.0;

    double totalGradient = 0;
    int count = 0;

    // Measure edge sharpness (prominent bones = high gradient)
    for (int y = top + 1; y < bottom - 1; y += 3) {
      for (int x = left + 1; x < right - 1; x += 3) {
        final center = _luminance(image.getPixel(x, y));
        final right_ = _luminance(image.getPixel(x + 1, y));
        final bottom_ = _luminance(image.getPixel(x, y + 1));
        final gx = (right_ - center).abs();
        final gy = (bottom_ - center).abs();
        totalGradient += gx + gy;
        count++;
      }
    }

    if (count == 0) return 3.0;
    final avgGradient = totalGradient / count;

    // High gradient = many edges = prominent bones = low ICC
    // Low gradient = smooth = fat covering = high ICC
    // Calibration: gradient ~0-80 typical range
    final normalizedGradient = (avgGradient / 40).clamp(0.0, 2.0);
    // Invert: high gradient → low ICC
    return (5.0 - normalizedGradient * 2.0).clamp(1.0, 5.0);
  }

  double _luminance(img.Pixel pixel) =>
      0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;

  double _mapToIcc(double rawScore) {
    // rawScore already in 1-5 range, just clamp to valid ICC values
    final clamped = rawScore.clamp(1.0, 5.0);
    // Snap to nearest 0.5
    return (clamped * 2).round() / 2;
  }

  /// Quick ICC estimate from a full image without bounding box.
  /// Less accurate but works as fallback.
  Future<IccEstimate?> estimateFromFullImage(img.Image image) async {
    if (!_detector.isReady) return null;
    final detections = await _detector.detect(image);
    if (detections.isEmpty) return null;
    // Use the highest-confidence detection
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    return estimateFromSidePhoto(image, detections.first);
  }
}

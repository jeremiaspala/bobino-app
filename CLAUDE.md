# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BovApp — offline Android app for cattle (bovine) evaluation: Body Condition Score (ICC, scale 1–5) and weight estimation using on-device YOLO AI. Flutter 3.13.6 / Dart 3.1.3.

## Build & Development Commands

```bash
# Install dependencies
flutter pub get

# Static analysis (must pass with zero issues before building)
flutter analyze

# Build release APK (arm64 only, uses Java 17)
export JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH
flutter build apk --release --target-platform android-arm64

# Install on phone over ADB WiFi
adb connect 192.168.1.32:39055
adb -s 192.168.1.32:39055 install -r build/app/outputs/flutter-apk/app-release.apk

# Run debug on connected device
flutter run
```

**Java version is critical:** Gradle 7.5 + Java 21 = build failure ("Unsupported class file major version 65"). Always set `JAVA_HOME` to Java 17 before building. Java 17 is at `/usr/lib/jvm/java-1.17.0-openjdk-amd64`.

**Android SDK:** `android-35` platform jar is corrupted on this machine. Use `compileSdkVersion 34` / `targetSdkVersion 34`.

## Architecture

```
lib/
├── main.dart                   # Entry point — locks orientation, initializes app
├── app.dart                    # MaterialApp + theme setup
├── models/
│   ├── animal.dart             # Animal entity (id, tag/caravana, breed, sex, birthDate)
│   └── measurement.dart        # Measurement entity (ICC, weight, morphometrics, photo paths)
├── providers/
│   └── app_provider.dart       # Single ChangeNotifier — owns all state, DB calls, YOLO init
├── services/
│   ├── database_service.dart   # SQLite singleton (sqflite) — tables: animals, measurements
│   ├── yolo_detector.dart      # TFLite singleton — detection + coat analysis
│   ├── yolo_segmentor.dart     # Stub only (ONNX disabled) — returns null always
│   ├── icc_estimator.dart      # Heuristic ICC from bounding box proportions
│   ├── weight_calculator.dart  # Schoorl/Anderson formulas + ICC-based estimate
│   └── model_sources.dart      # Asset paths + download URLs for all YOLO models
├── screens/                    # One screen per feature (home, list, detail, add, measure)
├── widgets/
│   ├── bcs_indicator.dart      # Circular ICC gauge + color-coded scale bar
│   ├── animal_card.dart        # Card with latest ICC/weight, tappable
│   └── measurement_chart.dart  # fl_chart line chart for ICC/weight history
└── utils/
    └── constants.dart          # Colors, ICC descriptions map, YOLO thresholds, breed list
```

### Key Design Decisions

**State management:** Single `AppProvider` (Provider pattern). All DB access goes through it. Screens consume it via `context.watch<AppProvider>()` / `context.read<AppProvider>()`.

**YOLO inference:** `YoloDetector` is a singleton loaded at startup. If the TFLite model is missing from assets, the app silently falls back to manual-entry mode — `yoloReady` stays `false` and the UI disables the AI button.

**Segmentor is stubbed:** `YoloSegmentor` always returns `null`. To re-enable ONNX segmentation, add `flutter_onnxruntime: ^1.5.1` to pubspec.yaml and restore the implementation in `yolo_segmentor.dart`.

**ICC scale:** Argentine standard, 1.0–5.0 in 0.5 steps. The full descriptions live in `kIccDescriptions` (a `final` map, not `const` — double keys override `==` and cannot be const in Dart).

**Weight formulas:**
- Schoorl: `W = (heartGirth_cm + 22)² / 100`
- Anderson (beef): `W = (heartGirth² × bodyLength) / 10840`
- Anderson (dairy): divisor is 11000

### YOLO Model Details

- **yolov8n.tflite** (13 MB) — active, bundled in assets. Input `[1, 640, 640, 3]` float32 NHWC, normalized 0–1. Output `[1, 84, 8400]`. COCO class 19 = cow.
- **yolov8n_seg.onnx**, **yolo11n.onnx**, **yolov8n_pose.onnx** — bundled but not used at runtime (stubs/future use).

All model download sources are documented in `lib/services/model_sources.dart`.

## Android Configuration

- `minSdkVersion 26` (required by tflite_flutter)
- `compileSdkVersion / targetSdkVersion 34`
- Gradle 7.5, AGP 7.3.0, Kotlin 1.7.10
- `aaptOptions { noCompress "tflite", "onnx" }` — must stay to prevent asset corruption
- `shrinkResources false` + `minifyEnabled false` — required for TFLite model loading
- Package: `com.bovapp.bovino`

## Database Schema

Two tables in `bovinos.db` (SQLite, version 1):
- **animals**: `id` (UUID), `tag`, `name`, `breed`, `sex`, `birth_date`, `created_at`
- **measurements**: `id`, `animal_id` (FK), `date`, `icc`, `icc_method`, `weight_kg`, `weight_method`, `heart_girth_cm`, `body_length_cm`, `hip_width_cm`, `withers_height_cm`, `body_depth_cm`, `rump_angle_deg`, `coat_score`, `bbox_confidence`, `photo_side_path`, `photo_rear_path`, `photo_front_path`, `notes`

No migrations are set up — schema changes require a DB version bump + `onUpgrade` handler in `DatabaseService._initDb`.

## Dependency Constraints

These versions are pinned for Flutter 3.13.6 compatibility — do not upgrade without testing:

| Package | Version | Reason |
|---|---|---|
| `tflite_flutter` | `^0.10.4` | 0.12.x requires Flutter 3.22+ |
| `permission_handler` | `^11.0.1` | 11.1.0+ requires Flutter 3.16+ |
| `path` | `^1.8.3` | flutter_test pins this |
| `fl_chart` | `^0.64.0` | 0.68+ changed tooltip API (`getTooltipColor` → `tooltipBgColor`) |
| `google_fonts` | removed | 6.2.0 has `FontFeature` incompatibility with Flutter 3.13.6 |

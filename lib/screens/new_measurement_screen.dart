import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/measurement.dart';
import '../providers/app_provider.dart';
import '../services/icc_estimator.dart';
import '../services/weight_calculator.dart';
import '../utils/constants.dart';
import '../widgets/bcs_indicator.dart';
import 'add_animal_screen.dart';
import 'photo_measure_screen.dart';

class NewMeasurementScreen extends StatefulWidget {
  final bool useCamera;
  final String? preselectedAnimalId;

  const NewMeasurementScreen({
    super.key,
    this.useCamera = false,
    this.preselectedAnimalId,
  });

  @override
  State<NewMeasurementScreen> createState() =>
      _NewMeasurementScreenState();
}

class _NewMeasurementScreenState extends State<NewMeasurementScreen> {
  final _formKey = GlobalKey<FormState>();

  // Animal selection
  String? _selectedAnimalId;

  // Photos
  File? _photoSide;
  File? _photoRear;

  // ICC
  double _icc = 3.0;
  String _iccMethod = 'manual';
  bool _analyzingIcc = false;

  // Morphometrics
  final _girthCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _hipWidthCtrl = TextEditingController();
  final _withersCtrl = TextEditingController();
  final _scaleRefCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Reference for photo-based calculation
  double? _pixelsPerCm;
  double? _detectedBodyLength;
  double? _detectedBodyHeight;

  // Results
  WeightResult? _weightResult;
  double? _rumpAngle;
  double? _coatScore;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _selectedAnimalId = widget.preselectedAnimalId;
    if (widget.useCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          _pickPhoto(ImageSource.camera, isSide: true));
    }
  }

  @override
  void dispose() {
    _girthCtrl.dispose();
    _lengthCtrl.dispose();
    _hipWidthCtrl.dispose();
    _withersCtrl.dispose();
    _scaleRefCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nueva medición'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AnimalSelector(
              selectedId: _selectedAnimalId,
              onSelect: (id) => setState(() => _selectedAnimalId = id),
            ),
            const SizedBox(height: 16),
            _PhotoSection(
              photoSide: _photoSide,
              photoRear: _photoRear,
              onPickSide: () => _pickPhoto(
                  widget.useCamera
                      ? ImageSource.camera
                      : ImageSource.gallery,
                  isSide: true),
              onPickRear: () => _pickPhoto(
                  widget.useCamera
                      ? ImageSource.camera
                      : ImageSource.gallery,
                  isSide: false),
              isAnalyzing: _analyzingIcc,
              onMeasurePhoto: _photoSide != null ? _openPhotoMeasure : null,
            ),
            const SizedBox(height: 16),
            _IccSection(
              icc: _icc,
              method: _iccMethod,
              onChanged: (v) => setState(() {
                _icc = v;
                _iccMethod = 'manual';
              }),
            ),
            const SizedBox(height: 16),
            _MorphometrySection(
              girthCtrl: _girthCtrl,
              lengthCtrl: _lengthCtrl,
              hipWidthCtrl: _hipWidthCtrl,
              withersCtrl: _withersCtrl,
              scaleRefCtrl: _scaleRefCtrl,
              pixelsPerCm: _pixelsPerCm,
              detectedBodyLength: _detectedBodyLength,
              detectedBodyHeight: _detectedBodyHeight,
              onCalculateWeight: _calculateWeight,
            ),
            if (_weightResult != null) ...[
              const SizedBox(height: 16),
              _WeightResultCard(result: _weightResult!),
            ],
            if (_rumpAngle != null) ...[
              const SizedBox(height: 12),
              _RumpAngleCard(angleDeg: _rumpAngle!),
            ],
            if (_coatScore != null) ...[
              const SizedBox(height: 12),
              _CoatCard(score: _coatScore!),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: 'Notas',
                prefixIcon:
                    const Icon(Icons.notes, color: AppColors.primary),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  _saving ? 'Guardando...' : 'Guardar medición',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source,
      {required bool isSide}) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
        source: source, imageQuality: 85, maxWidth: 1280);
    if (xfile == null) return;

    final file = File(xfile.path);
    setState(() {
      if (isSide) {
        _photoSide = file;
      } else {
        _photoRear = file;
      }
    });

    if (isSide) {
      await _analyzePhoto(file);
    }
  }

  Future<void> _analyzePhoto(File file) async {
    setState(() => _analyzingIcc = true);
    try {
      final provider = context.read<AppProvider>();
      final detector = provider.yoloDetector;
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return;

      // Run YOLO detection
      final detections = await detector.detect(image);
      if (detections.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No se detectó ningún bovino en la foto. '
                  'Tomá la foto de lado, asegurándote de que el animal '
                  'esté completamente visible.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final best = detections.reduce(
          (a, b) => a.confidence > b.confidence ? a : b);

      // Extract morphometrics from bounding box
      final morpho = detector.extractMorphometrics(
          best, image.width, image.height);
      if (morpho != null) {
        setState(() {
          _detectedBodyLength = morpho.bodyLengthPixels;
          _detectedBodyHeight = morpho.bodyHeightPixels;
        });
      }

      // Coat analysis
      final coat = detector.analyzeCoat(image, best);
      setState(() => _coatScore = coat.score);

      // ICC estimation
      final estimator = IccEstimator(detector);
      final iccEstimate =
          await estimator.estimateFromSidePhoto(image, best);
      if (iccEstimate != null && mounted) {
        setState(() {
          _icc = iccEstimate.roundedScore;
          _iccMethod = 'ai';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'ICC estimado por IA: ${iccEstimate.score.toStringAsFixed(1)} '
                '(confianza ${(iccEstimate.confidence * 100).toStringAsFixed(0)}%). '
                'Podés ajustarlo manualmente.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }

      // Try weight from photo if scale reference entered
      _calculateWeight();
    } finally {
      if (mounted) setState(() => _analyzingIcc = false);
    }
  }

  void _calculateWeight() {
    final girth =
        double.tryParse(_girthCtrl.text.replaceAll(',', '.'));
    final length =
        double.tryParse(_lengthCtrl.text.replaceAll(',', '.'));
    final scaleRef =
        double.tryParse(_scaleRefCtrl.text.replaceAll(',', '.'));

    // Calculate pixels per cm from scale reference
    double? pxPerCm;
    if (scaleRef != null &&
        scaleRef > 0 &&
        _detectedBodyLength != null) {
      // Scale ref = known length in cm of a reference object visible in photo
      // User marks this in a simple way: they enter "the tape shows X cm
      // spanning Y% of the animal's body length"
      // Simplified: assume scale ref is the heart girth entered manually
      pxPerCm = _detectedBodyLength! / scaleRef;
      setState(() => _pixelsPerCm = pxPerCm);
    }

    try {
      final result = WeightCalculator.calculate(
        heartGirthCm: girth,
        bodyLengthCm: length,
        icc: _icc,
        bodyLengthPixels: _detectedBodyLength,
        bodyHeightPixels: _detectedBodyHeight,
        pixelsPerCm: pxPerCm,
      );
      setState(() => _weightResult = result);
    } catch (_) {
      // Not enough data yet
    }
  }

  Future<void> _openPhotoMeasure() async {
    if (_photoSide == null) return;
    final result = await Navigator.push<PhotoMeasureResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoMeasureScreen(imageFile: _photoSide!),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _pixelsPerCm = result.pixelsPerCm;
      if (result.bodyLengthCm != null) {
        _lengthCtrl.text = result.bodyLengthCm!.toStringAsFixed(1);
      }
      if (result.estimatedHeartGirthCm != null && _girthCtrl.text.isEmpty) {
        _girthCtrl.text =
            result.estimatedHeartGirthCm!.toStringAsFixed(1);
      }
      if (result.withersHeightCm != null) {
        _withersCtrl.text = result.withersHeightCm!.toStringAsFixed(1);
      }
      if (result.rumpAngleDeg != null) {
        _rumpAngle = result.rumpAngleDeg;
      }
    });

    _calculateWeight();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Medidas cargadas desde foto. '
            '${result.estimatedHeartGirthCm != null ? 'PT estimado (±15%) — revisá y ajustá con cinta si tenés.' : ''}',
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (_selectedAnimalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccioná un animal primero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final girth =
        double.tryParse(_girthCtrl.text.replaceAll(',', '.'));
    final length =
        double.tryParse(_lengthCtrl.text.replaceAll(',', '.'));
    final hipWidth =
        double.tryParse(_hipWidthCtrl.text.replaceAll(',', '.'));
    final withers =
        double.tryParse(_withersCtrl.text.replaceAll(',', '.'));

    final m = Measurement(
      id: const Uuid().v4(),
      animalId: _selectedAnimalId!,
      date: DateTime.now(),
      icc: _icc,
      iccMethod: _iccMethod,
      weightKg: _weightResult?.weightKg,
      weightMethod: _weightResult?.formulaName ?? 'none',
      heartGirthCm: girth,
      bodyLengthCm: length,
      hipWidthCm: hipWidth,
      withersHeightCm: withers,
      rumpAngleDeg: _rumpAngle,
      coatScore: _coatScore,
      photoSidePath: _photoSide?.path,
      photoRearPath: _photoRear?.path,
      notes: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
    );

    await context.read<AppProvider>().addMeasurement(m);
    if (mounted) Navigator.pop(context);
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────

class _AnimalSelector extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  const _AnimalSelector(
      {required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final animals = provider.animals;
        return Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Animal',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedId,
                        hint: const Text('Seleccionar animal'),
                        items: animals
                            .map((a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text('# ${a.tag}'
                                      '${a.name != null ? ' - ${a.name}' : ''}'),
                                ))
                            .toList(),
                        onChanged: onSelect,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle,
                          color: AppColors.primary),
                      tooltip: 'Nuevo animal',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddAnimalScreen()),
                      ).then((_) {
                        provider.loadAnimals();
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PhotoSection extends StatelessWidget {
  final File? photoSide;
  final File? photoRear;
  final VoidCallback onPickSide;
  final VoidCallback onPickRear;
  final bool isAnalyzing;
  final VoidCallback? onMeasurePhoto;

  const _PhotoSection({
    required this.photoSide,
    required this.photoRear,
    required this.onPickSide,
    required this.onPickRear,
    required this.isAnalyzing,
    this.onMeasurePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Fotos',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary)),
                if (isAnalyzing) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 6),
                  const Text('Analizando con YOLO...',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.primary)),
                ],
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Foto lateral: permite estimar ICC y peso. '
              'Foto trasera: permite medir ancho de cadera.',
              style: TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _PhotoTile(
                  label: 'Vista lateral',
                  icon: Icons.photo_camera,
                  file: photoSide,
                  onTap: onPickSide,
                ),
                const SizedBox(width: 10),
                _PhotoTile(
                  label: 'Vista trasera',
                  icon: Icons.photo_camera_back,
                  file: photoRear,
                  onTap: onPickRear,
                ),
              ],
            ),
            if (onMeasurePhoto != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: onMeasurePhoto,
                  icon: const Icon(Icons.straighten, size: 18),
                  label: const Text('Marcar puntos y medir en foto'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final File? file;
  final VoidCallback onTap;

  const _PhotoTile({
    required this.label,
    required this.icon,
    this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.3)),
            image: file != null
                ? DecorationImage(
                    image: FileImage(file!), fit: BoxFit.cover)
                : null,
          ),
          child: file == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon,
                        color: AppColors.primary, size: 32),
                    const SizedBox(height: 4),
                    Text(label,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary)),
                  ],
                )
              : Stack(
                  children: [
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _IccSection extends StatelessWidget {
  final double icc;
  final String method;
  final ValueChanged<double> onChanged;

  const _IccSection({
    required this.icc,
    required this.method,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('ICC',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                if (method == 'ai')
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('IA',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Center(child: BcsIndicator(icc: icc, size: 72)),
            const SizedBox(height: 16),
            BcsScaleBar(icc: icc, onChanged: onChanged),
            const SizedBox(height: 8),
            Text(
              kIccDescriptions[icc]?['desc'] ??
                  kIccDescriptions[(icc * 2).round() / 2]?['desc'] ??
                  '',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MorphometrySection extends StatelessWidget {
  final TextEditingController girthCtrl;
  final TextEditingController lengthCtrl;
  final TextEditingController hipWidthCtrl;
  final TextEditingController withersCtrl;
  final TextEditingController scaleRefCtrl;
  final double? pixelsPerCm;
  final double? detectedBodyLength;
  final double? detectedBodyHeight;
  final VoidCallback onCalculateWeight;

  const _MorphometrySection({
    required this.girthCtrl,
    required this.lengthCtrl,
    required this.hipWidthCtrl,
    required this.withersCtrl,
    required this.scaleRefCtrl,
    this.pixelsPerCm,
    this.detectedBodyLength,
    this.detectedBodyHeight,
    required this.onCalculateWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Medidas corporales',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            const Text(
              'Perímetro torácico es el más importante para el peso.',
              style: TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _numField(girthCtrl, 'Perímetro torácico (cm)',
                Icons.straighten),
            const SizedBox(height: 10),
            _numField(lengthCtrl, 'Largo del cuerpo (cm)',
                Icons.open_in_full),
            const SizedBox(height: 10),
            _numField(
                hipWidthCtrl, 'Ancho de cadera (cm)', Icons.width_full),
            const SizedBox(height: 10),
            _numField(withersCtrl, 'Alzada a la cruz (cm)',
                Icons.height),
            if (detectedBodyLength != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detección YOLO',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text(
                      'Largo: ${detectedBodyLength!.toStringAsFixed(0)} px · '
                      'Alto: ${detectedBodyHeight?.toStringAsFixed(0) ?? '?'} px',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    _numField(
                      scaleRefCtrl,
                      'Referencia de escala: largo real del animal (cm)',
                      Icons.swap_horiz,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
                onPressed: onCalculateWeight,
                icon: const Icon(Icons.calculate),
                label: const Text('Calcular peso'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(
          TextEditingController ctrl, String label, IconData icon) =>
      TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: Colors.white,
        ),
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
      );
}

class _WeightResultCard extends StatelessWidget {
  final WeightResult result;

  const _WeightResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.secondary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: AppColors.secondary.withOpacity(0.5))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.scale,
                color: AppColors.secondary, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${result.weightKg.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  Text(
                    'Fórmula ${result.formulaName} · '
                    'Confianza ${(result.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                  Text(
                    result.description,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RumpAngleCard extends StatelessWidget {
  final double angleDeg;

  const _RumpAngleCard({required this.angleDeg});

  @override
  Widget build(BuildContext context) {
    final isIdeal = angleDeg >= kRumpAngleFlat && angleDeg <= kRumpAngleIdeal;
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          Icons.change_history,
          color: isIdeal ? AppColors.primary : Colors.orange,
          size: 36,
        ),
        title: Text(
          'Ángulo de grupa: ${angleDeg.toStringAsFixed(1)}°',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          angleDeg < kRumpAngleFlat
              ? 'Muy plana — riesgo de retención de placenta'
              : angleDeg <= kRumpAngleIdeal
                  ? 'Ideal — facilita el parto'
                  : 'Inclinada — puede dificultar el parto',
        ),
      ),
    );
  }
}

class _CoatCard extends StatelessWidget {
  final double score;

  const _CoatCard({required this.score});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          Icons.brush,
          color: score >= 3.5 ? AppColors.primary : Colors.orange,
          size: 36,
        ),
        title: Text(
          'Pelaje: ${score.toStringAsFixed(1)}/5',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          score < 2.0
              ? 'Opaco — posible parasitosis o deficiencia nutricional'
              : score < 3.5
                  ? 'Normal'
                  : 'Brillante y saludable',
        ),
      ),
    );
  }
}

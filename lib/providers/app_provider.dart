import 'package:flutter/foundation.dart';
import '../models/animal.dart';
import '../models/measurement.dart';
import '../services/database_service.dart';
import '../services/yolo_detector.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final YoloDetector _yolo = YoloDetector();

  List<Animal> _animals = [];
  Map<String, Measurement?> _latestMeasurements = {};
  List<Measurement> _recentMeasurements = [];
  Map<String, dynamic> _stats = {};
  bool _yoloReady = false;
  bool _loading = false;

  List<Animal> get animals => _animals;
  Map<String, Measurement?> get latestMeasurements => _latestMeasurements;
  List<Measurement> get recentMeasurements => _recentMeasurements;
  Map<String, dynamic> get stats => _stats;
  bool get yoloReady => _yoloReady;
  bool get loading => _loading;

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    _loading = true;
    notifyListeners();
    await Future.wait([
      loadAnimals(),
      loadStats(),
      _initYolo(),
    ]);
    _loading = false;
    notifyListeners();
  }

  Future<void> _initYolo() async {
    _yoloReady = await _yolo.loadModel();
    notifyListeners();
  }

  Future<void> loadAnimals({String? search}) async {
    _animals = await _db.getAnimals(searchQuery: search);
    // Load latest measurements for each animal
    final futures = _animals.map((a) async {
      _latestMeasurements[a.id] = await _db.getLatestMeasurement(a.id);
    });
    await Future.wait(futures);
    await _loadRecentMeasurements();
    notifyListeners();
  }

  Future<void> _loadRecentMeasurements() async {
    final allMeasurements = <Measurement>[];
    for (final a in _animals) {
      final measurements = await _db.getMeasurements(a.id);
      allMeasurements.addAll(measurements);
    }
    allMeasurements.sort((a, b) => b.date.compareTo(a.date));
    _recentMeasurements = allMeasurements.take(20).toList();
  }

  Future<void> loadStats() async {
    _stats = await _db.getStats();
    notifyListeners();
  }

  Animal? animalById(String id) {
    try {
      return _animals.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addAnimal(Animal animal) async {
    await _db.insertAnimal(animal);
    await loadAnimals();
    await loadStats();
  }

  Future<void> updateAnimal(Animal animal) async {
    await _db.updateAnimal(animal);
    await loadAnimals();
  }

  Future<void> deleteAnimal(String id) async {
    await _db.deleteAnimal(id);
    _latestMeasurements.remove(id);
    await loadAnimals();
    await loadStats();
  }

  Future<void> addMeasurement(Measurement measurement) async {
    await _db.insertMeasurement(measurement);
    _latestMeasurements[measurement.animalId] = measurement;
    await _loadRecentMeasurements();
    await loadStats();
    notifyListeners();
  }

  Future<void> deleteMeasurement(String id) async {
    await _db.deleteMeasurement(id);
    await loadAnimals();
    await loadStats();
  }

  Future<List<Measurement>> getMeasurementsForAnimal(
      String animalId) async {
    return _db.getMeasurements(animalId);
  }

  Future<bool> tagExists(String tag, {String? excludeId}) =>
      _db.tagExists(tag, excludeId: excludeId);

  YoloDetector get yoloDetector => _yolo;
}

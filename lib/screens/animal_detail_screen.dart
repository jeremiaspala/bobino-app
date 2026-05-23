import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/animal.dart';
import '../models/measurement.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../widgets/bcs_indicator.dart';
import '../widgets/measurement_chart.dart';
import 'add_animal_screen.dart';
import 'new_measurement_screen.dart';

class AnimalDetailScreen extends StatefulWidget {
  final String animalId;

  const AnimalDetailScreen({super.key, required this.animalId});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  List<Measurement> _measurements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadMeasurements();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMeasurements() async {
    final provider = context.read<AppProvider>();
    final m = await provider.getMeasurementsForAnimal(widget.animalId);
    if (mounted) {
      setState(() {
        _measurements = m;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final animal = provider.animalById(widget.animalId);
        if (animal == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Animal')),
            body: const Center(child: Text('Animal no encontrado')),
          );
        }
        final latest = provider.latestMeasurements[widget.animalId];

        return Scaffold(
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddAnimalScreen(animal: animal),
                      ),
                    ).then((_) => provider.loadAnimals()),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _Header(animal: animal, latest: latest),
                ),
                bottom: TabBar(
                  controller: _tabCtrl,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'Resumen'),
                    Tab(text: 'Historia'),
                    Tab(text: 'Gráficos'),
                  ],
                ),
              ),
            ],
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _SummaryTab(
                          animal: animal, latest: latest),
                      _HistoryTab(
                        measurements: _measurements,
                        onDelete: (id) async {
                          await provider.deleteMeasurement(id);
                          _loadMeasurements();
                        },
                      ),
                      _ChartsTab(measurements: _measurements),
                    ],
                  ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.secondary,
            child: const Icon(Icons.add_a_photo, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NewMeasurementScreen(
                    preselectedAnimalId: widget.animalId),
              ),
            ).then((_) => _loadMeasurements()),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final Animal animal;
  final Measurement? latest;

  const _Header({required this.animal, this.latest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          BcsIndicator(icc: latest?.icc, size: 72, showLabel: true),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('# ${animal.tag}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14)),
                if (animal.name != null)
                  Text(
                    animal.name!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (animal.breed != null || animal.sex != null)
                  Text(
                    [animal.breed, animal.sex]
                        .whereType<String>()
                        .join(' · '),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                if (latest?.weightKg != null)
                  Text(
                    '${latest!.weightKg!.toStringAsFixed(0)} kg',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final Animal animal;
  final Measurement? latest;

  const _SummaryTab({required this.animal, this.latest});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (latest != null) ...[
          _section('Última medición', [
            _row('Fecha',
                DateFormat('dd/MM/yyyy').format(latest!.date)),
            if (latest!.icc != null)
              _row('ICC', '${latest!.icc!.toStringAsFixed(1)} — '
                  '${kIccDescriptions[latest!.icc]?['title'] ?? ''}'),
            if (latest!.weightKg != null)
              _row('Peso estimado',
                  '${latest!.weightKg!.toStringAsFixed(1)} kg (${latest!.weightMethod})'),
            if (latest!.heartGirthCm != null)
              _row('Perímetro torácico',
                  '${latest!.heartGirthCm!.toStringAsFixed(1)} cm'),
            if (latest!.bodyLengthCm != null)
              _row('Largo del cuerpo',
                  '${latest!.bodyLengthCm!.toStringAsFixed(1)} cm'),
            if (latest!.hipWidthCm != null)
              _row('Ancho de cadera',
                  '${latest!.hipWidthCm!.toStringAsFixed(1)} cm'),
            if (latest!.rumpAngleDeg != null)
              _row('Ángulo de grupa',
                  latest!.rumpAngleLabel ?? ''),
            if (latest!.coatScore != null)
              _row('Condición del pelaje',
                  '${latest!.coatScore!.toStringAsFixed(1)} / 5'),
          ]),
          const SizedBox(height: 16),
          if (latest!.icc != null)
            _IccCard(icc: latest!.icc!),
        ] else
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                  'Sin mediciones aún. Usá el botón + para agregar una.'),
            ),
          ),
        const SizedBox(height: 16),
        _section('Datos del animal', [
          _row('Caravana', '# ${animal.tag}'),
          if (animal.name != null) _row('Nombre', animal.name!),
          if (animal.breed != null) _row('Raza', animal.breed!),
          if (animal.sex != null) _row('Categoría', animal.sex!),
          if (animal.birthDate != null)
            _row('Nacimiento',
                DateFormat('dd/MM/yyyy').format(animal.birthDate!)),
          if (animal.ageMonths != null)
            _row(
                'Edad',
                animal.ageMonths! < 12
                    ? '${animal.ageMonths} meses'
                    : '${animal.ageMonths! ~/ 12} años'),
        ]),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              )),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(children: children),
            ),
          ),
        ],
      );

  Widget _row(String label, String value) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
}

class _IccCard extends StatelessWidget {
  final double icc;

  const _IccCard({required this.icc});

  @override
  Widget build(BuildContext context) {
    final info = kIccDescriptions[icc] ??
        kIccDescriptions[(icc * 2).round() / 2]!;
    final colorIndex =
        ((icc - 1.0) / 0.5).round().clamp(0, 8);
    final color = AppColors.iccColors[colorIndex];

    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  'ICC ${icc.toStringAsFixed(1)} — ${info['title']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(info['desc']!, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final List<Measurement> measurements;
  final void Function(String id) onDelete;

  const _HistoryTab(
      {required this.measurements, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return const Center(child: Text('Sin mediciones registradas'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: measurements.length,
      itemBuilder: (context, i) {
        final m = measurements[i];
        return _MeasurementTile(m: m, onDelete: onDelete);
      },
    );
  }
}

class _MeasurementTile extends StatelessWidget {
  final Measurement m;
  final void Function(String id) onDelete;

  const _MeasurementTile({required this.m, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        leading: BcsIndicator(icc: m.icc, size: 40, showLabel: false),
        title: Text(
          DateFormat('dd/MM/yyyy').format(m.date),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            if (m.icc != null) 'ICC ${m.icc!.toStringAsFixed(1)}',
            if (m.weightKg != null) '${m.weightKg!.toStringAsFixed(0)} kg',
          ].join(' · '),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _confirmDelete(context),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                if (m.heartGirthCm != null)
                  _row('Perímetro torácico',
                      '${m.heartGirthCm!.toStringAsFixed(1)} cm'),
                if (m.bodyLengthCm != null)
                  _row('Largo del cuerpo',
                      '${m.bodyLengthCm!.toStringAsFixed(1)} cm'),
                if (m.hipWidthCm != null)
                  _row('Ancho de cadera',
                      '${m.hipWidthCm!.toStringAsFixed(1)} cm'),
                if (m.rumpAngleDeg != null)
                  _row('Ángulo de grupa', m.rumpAngleLabel ?? ''),
                if (m.coatScore != null)
                  _row('Pelaje', '${m.coatScore!.toStringAsFixed(1)}/5'),
                if (m.notes != null && m.notes!.isNotEmpty)
                  _row('Notas', m.notes!),
                if (m.photoSidePath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(m.photoSidePath!),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      );

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar medición'),
        content: const Text('¿Eliminar esta medición?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete(m.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _ChartsTab extends StatelessWidget {
  final List<Measurement> measurements;

  const _ChartsTab({required this.measurements});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: MeasurementChart(
                measurements: measurements, metric: 'icc'),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: MeasurementChart(
                measurements: measurements, metric: 'weight'),
          ),
        ),
      ],
    );
  }
}

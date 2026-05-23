import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../widgets/bcs_indicator.dart';
import 'about_screen.dart';
import 'animal_list_screen.dart';
import 'new_measurement_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Bobino App',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.pets, color: Colors.white),
                tooltip: 'Ver animales',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const AnimalListScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                tooltip: 'Acerca de',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const AboutScreen())),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Consumer<AppProvider>(
              builder: (context, provider, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatsCards(stats: provider.stats),
                    const SizedBox(height: 20),
                    _QuickActions(provider: provider),
                    const SizedBox(height: 20),
                    if (provider.recentMeasurements.isNotEmpty)
                      _RecentActivity(provider: provider),
                    const SizedBox(height: 80),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        onPressed: () => _startNewMeasurement(context),
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text('Nueva medición',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _startNewMeasurement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewMeasurementScreen()),
    );
  }
}

class _StatsCards extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _StatsCards({required this.stats});

  @override
  Widget build(BuildContext context) {
    final avgIcc = stats['avgIcc'] as double?;
    final avgWeight = stats['avgWeight'] as double?;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.pets,
            label: 'Animales',
            value: '${stats['animals'] ?? 0}',
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.monitor_weight_outlined,
            label: 'Mediciones',
            value: '${stats['measurements'] ?? 0}',
            color: AppColors.secondary,
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.favorite_outline,
            label: 'ICC prom.',
            value: avgIcc != null ? avgIcc.toStringAsFixed(1) : '—',
            color: AppColors.primaryLight,
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.scale,
            label: 'Peso prom.',
            value: avgWeight != null
                ? '${avgWeight.toStringAsFixed(0)} kg'
                : '—',
            color: Colors.blueGrey,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final AppProvider provider;

  const _QuickActions({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acciones rápidas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionTile(
                icon: Icons.add_a_photo,
                label: 'Foto + IA',
                subtitle: 'Detectar con YOLO',
                color: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const NewMeasurementScreen(useCamera: true)),
                ),
              ),
              const SizedBox(width: 12),
              _ActionTile(
                icon: Icons.edit_note,
                label: 'Manual',
                subtitle: 'Ingresar medidas',
                color: AppColors.secondary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const NewMeasurementScreen(useCamera: false)),
                ),
              ),
              const SizedBox(width: 12),
              _ActionTile(
                icon: Icons.help_outline,
                label: 'Guía ICC',
                subtitle: 'Referencia visual',
                color: AppColors.primaryLight,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const IccGuideScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final AppProvider provider;

  const _RecentActivity({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Actividad reciente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AnimalListScreen()),
                ),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...provider.recentMeasurements.take(5).map((m) {
            final animal = provider.animalById(m.animalId);
            if (animal == null) return const SizedBox.shrink();
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: BcsIndicator(icc: m.icc, size: 40, showLabel: false),
              title: Text('# ${animal.tag}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                [
                  if (m.icc != null) 'ICC ${m.icc!.toStringAsFixed(1)}',
                  if (m.weightKg != null)
                    '${m.weightKg!.toStringAsFixed(0)} kg',
                ].join(' · '),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              trailing: Text(
                _formatDate(m.date),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return '${d.day}/${d.month}';
  }
}

// Placeholder import (real screen defined elsewhere)
class IccGuideScreen extends StatelessWidget {
  const IccGuideScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const _IccGuideScreenImpl();
}

class _IccGuideScreenImpl extends StatelessWidget {
  const _IccGuideScreenImpl();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guía ICC'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: kIccValues.length,
        itemBuilder: (context, i) {
          final val = kIccValues[i];
          final info = kIccDescriptions[val]!;
          final color = AppColors.iccColors[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        val.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info['title']!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          info['desc']!,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        _row('Costillas', info['ribs']!),
                        _row('Columna', info['spine']!),
                        _row('Anca', info['rump']!),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 60,
              child: Text(
                '$label:',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
}

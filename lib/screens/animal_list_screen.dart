import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/animal.dart';
import '../utils/constants.dart';
import '../widgets/animal_card.dart';
import 'animal_detail_screen.dart';
import 'add_animal_screen.dart';

class AnimalListScreen extends StatefulWidget {
  const AnimalListScreen({super.key});

  @override
  State<AnimalListScreen> createState() => _AnimalListScreenState();
}

class _AnimalListScreenState extends State<AnimalListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Animales'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por caravana o nombre...',
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white70),
                hintStyle: const TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      const BorderSide(color: Colors.white54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          context
                              .read<AppProvider>()
                              .loadAnimals();
                        },
                      )
                    : null,
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (v) {
                setState(() => _searchQuery = v);
                context.read<AppProvider>().loadAnimals(search: v);
              },
            ),
          ),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final animals = provider.animals;
          if (animals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No hay animales registrados'
                        : 'No se encontraron resultados',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16),
                  ),
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary),
                      onPressed: () => _addAnimal(context),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Agregar animal',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: animals.length,
            itemBuilder: (context, i) {
              final animal = animals[i];
              return AnimalCard(
                animal: animal,
                latestMeasurement:
                    provider.latestMeasurements[animal.id],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AnimalDetailScreen(animalId: animal.id),
                  ),
                ).then((_) => provider.loadAnimals()),
                onDelete: () => _confirmDelete(context, provider, animal),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _addAnimal(context),
      ),
    );
  }

  void _addAnimal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAnimalScreen()),
    ).then((_) => context.read<AppProvider>().loadAnimals());
  }

  void _confirmDelete(
      BuildContext context, AppProvider provider, Animal animal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar animal'),
        content: Text(
            '¿Eliminar el animal con caravana # ${animal.tag}? '
            'Se borrarán todas sus mediciones.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteAnimal(animal.id);
            },
            style:
                TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

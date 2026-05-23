import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/animal.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

class AddAnimalScreen extends StatefulWidget {
  final Animal? animal; // null = new, set = edit mode

  const AddAnimalScreen({super.key, this.animal});

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tagCtrl;
  late final TextEditingController _nameCtrl;
  String? _breed;
  String? _sex;
  DateTime? _birthDate;
  bool _saving = false;

  bool get _isEdit => widget.animal != null;

  @override
  void initState() {
    super.initState();
    final a = widget.animal;
    _tagCtrl = TextEditingController(text: a?.tag ?? '');
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _breed = a?.breed;
    _sex = a?.sex;
    _birthDate = a?.birthDate;
  }

  @override
  void dispose() {
    _tagCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar animal' : 'Nuevo animal'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field(
              controller: _tagCtrl,
              label: 'Número de caravana *',
              icon: Icons.tag,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Requerido';
                }
                return null;
              },
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _nameCtrl,
              label: 'Nombre (opcional)',
              icon: Icons.pets,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _sex,
              decoration: _decor('Sexo', Icons.male),
              items: kSexOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _sex = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _breed,
              decoration: _decor('Raza', Icons.grass),
              items: kBreeds
                  .map((b) =>
                      DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (v) => setState(() => _breed = v),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today,
                  color: AppColors.primary),
              title: Text(
                _birthDate == null
                    ? 'Fecha de nacimiento (opcional)'
                    : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                style: TextStyle(
                  color: _birthDate == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
              contentPadding: EdgeInsets.zero,
              onTap: _pickDate,
              trailing: _birthDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () =>
                          setState(() => _birthDate = null),
                    )
                  : null,
            ),
            const Divider(),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : Text(
                        _isEdit ? 'Guardar cambios' : 'Registrar animal',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decor(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) =>
      TextFormField(
        controller: controller,
        decoration: _decor(label, icon),
        validator: validator,
        keyboardType: keyboardType,
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    final tag = _tagCtrl.text.trim();

    // Check for duplicate tag
    final exists = await provider.tagExists(tag,
        excludeId: _isEdit ? widget.animal!.id : null);
    if (!mounted) return;
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya existe un animal con ese número de caravana'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final animal = Animal(
      id: _isEdit ? widget.animal!.id : const Uuid().v4(),
      tag: tag,
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      breed: _breed,
      sex: _sex,
      birthDate: _birthDate,
      createdAt: _isEdit ? widget.animal!.createdAt : DateTime.now(),
    );

    if (_isEdit) {
      await provider.updateAnimal(animal);
    } else {
      await provider.addAnimal(animal);
    }

    if (mounted) Navigator.pop(context);
  }
}

import 'package:flutter/material.dart';
import '../models/animal.dart';
import '../models/measurement.dart';
import '../utils/constants.dart';
import 'bcs_indicator.dart';

class AnimalCard extends StatelessWidget {
  final Animal animal;
  final Measurement? latestMeasurement;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const AnimalCard({
    super.key,
    required this.animal,
    this.latestMeasurement,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final m = latestMeasurement;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ICC indicator
              BcsIndicator(icc: m?.icc, size: 52, showLabel: false),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '# ${animal.tag}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (animal.sex != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            animal.sex!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (animal.name != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        animal.name!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (animal.breed != null)
                          Text(
                            animal.breed!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (animal.ageMonths != null) ...[
                          const Text(' · ',
                              style:
                                  TextStyle(color: AppColors.textSecondary)),
                          Text(
                            _formatAge(animal.ageMonths!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (m != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (m.icc != null)
                            _chip('ICC ${m.icc!.toStringAsFixed(1)}',
                                AppColors.primary),
                          if (m.weightKg != null) ...[
                            const SizedBox(width: 6),
                            _chip(
                                '${m.weightKg!.toStringAsFixed(0)} kg',
                                AppColors.secondary),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Delete button
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: onDelete,
                ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  String _formatAge(int months) {
    if (months < 12) return '$months meses';
    final years = months ~/ 12;
    final rem = months % 12;
    if (rem == 0) return '$years año${years > 1 ? "s" : ""}';
    return '$years a ${rem}m';
  }
}

import 'package:flutter/material.dart';
import '../utils/constants.dart';

class BcsIndicator extends StatelessWidget {
  final double? icc;
  final double size;
  final bool showLabel;

  const BcsIndicator({
    super.key,
    this.icc,
    this.size = 60,
    this.showLabel = true,
  });

  Color get _color {
    if (icc == null) return Colors.grey;
    final index = ((icc! - 1.0) / 0.5).round().clamp(0, 8);
    return AppColors.iccColors[index];
  }

  String get _label {
    if (icc == null) return '—';
    return kIccDescriptions[_roundedIcc]?['title'] ?? '';
  }

  double get _roundedIcc {
    if (icc == null) return 3.0;
    return (icc! * 2).round() / 2;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              icc?.toStringAsFixed(1) ?? '—',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (showLabel && icc != null) ...[
          const SizedBox(height: 6),
          Text(
            _label,
            style: TextStyle(
              fontSize: 12,
              color: _color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class BcsScaleBar extends StatelessWidget {
  final double? icc;
  final ValueChanged<double>? onChanged;
  final bool readOnly;

  const BcsScaleBar({
    super.key,
    this.icc,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: Row(
            children: List.generate(kIccValues.length, (i) {
              final val = kIccValues[i];
              final selected =
                  icc != null && (icc! - val).abs() < 0.01;
              return Expanded(
                child: GestureDetector(
                  onTap: readOnly ? null : () => onChanged?.call(val),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.iccColors[i]
                          : AppColors.iccColors[i].withOpacity(0.35),
                      borderRadius: BorderRadius.circular(4),
                      border: selected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        val == val.truncateToDouble()
                            ? val.toInt().toString()
                            : val.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: selected ? 12 : 10,
                          color: Colors.white,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        if (icc != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Center(
              child: Text(
                kIccDescriptions[icc]?['title'] ??
                    kIccDescriptions[(icc! * 2).round() / 2]?['title'] ??
                    '',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

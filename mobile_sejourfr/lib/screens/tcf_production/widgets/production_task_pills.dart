import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Pastilles de tâche T1 / T2 / T3 (`.task-pills` du prototype).
///
/// Elles font partie de la **navigation** du prototype, que le client a
/// demandé de reprendre : on change de tâche sans repasser par l'écran
/// précédent. Pastille de numéro 24×24 `radius 8`, actif = fond plein accent.
class ProductionTaskPills extends StatelessWidget {
  const ProductionTaskPills({
    super.key,
    required this.active,
    required this.accent,
    required this.onChanged,
    this.labels = const ['Tâche 1', 'Tâche 2', 'Tâche 3'],
  });

  /// Numéro de tâche actif (1-based).
  final int active;
  final Color accent;
  final ValueChanged<int> onChanged;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _Pill(
              number: i + 1,
              label: labels[i],
              on: active == i + 1,
              accent: accent,
              onTap: () => onChanged(i + 1),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.number,
    required this.label,
    required this.on,
    required this.accent,
    required this.onTap,
  });

  final int number;
  final String label;
  final bool on;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = on ? AppColors.white : AppColors.inkSoft;
    return Material(
      color: on ? accent : AppColors.white,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: on ? accent : AppColors.line,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on
                      ? AppColors.white.withValues(alpha: 0.18)
                      : accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  '$number',
                  style: AppFonts.ui(
                    size: 11,
                    weight: FontWeight.w900,
                    color: on ? AppColors.white : accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppFonts.ui(
                  size: 13,
                  weight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

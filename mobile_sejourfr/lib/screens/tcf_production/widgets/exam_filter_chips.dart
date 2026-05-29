import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Chips de filtre Tous / À faire / Terminés pour les listes d'examens blancs.
/// Le caller construit les `labels` finaux (compteur intégré au texte) parce
/// que QCM et EE/EO calculent leurs compteurs sur des structures différentes.
class ExamFilterChips extends StatelessWidget {
  const ExamFilterChips({
    super.key,
    required this.active,
    required this.labels,
    required this.onChanged,
  });

  final int active;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final on = active == i;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? AppColors.blue : AppColors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: on ? AppColors.blue : AppColors.line),
              ),
              child: Text(
                labels[i],
                style: AppFonts.jakarta(
                  size: 12,
                  weight: FontWeight.w700,
                  color: on ? AppColors.white : AppColors.muted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

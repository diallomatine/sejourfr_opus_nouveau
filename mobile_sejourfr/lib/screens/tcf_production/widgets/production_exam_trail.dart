import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Barre segmentée « Parcours examens blancs · n/N » : un segment par examen,
/// rempli quand l'examen a été passé.
class ProductionExamTrail extends StatelessWidget {
  const ProductionExamTrail({
    super.key,
    required this.done,
    required this.total,
    required this.accent,
    this.note,
  });

  final int done;
  final int total;
  final Color accent;

  /// Mention libre alignée sous le titre (« Niveau estimé · B1 »). Absente
  /// tant que le backend n'a pas rendu de bilan : on n'écrit pas un niveau
  /// qu'on ne connaît pas.
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parcours examens blancs',
                      style: AppFonts.ui(size: 13, weight: FontWeight.w800),
                    ),
                    if (note != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        note!,
                        style:
                            AppFonts.ui(size: 11, color: AppColors.inkFaint),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '$done/$total',
                style: AppFonts.ui(
                  size: 12,
                  weight: FontWeight.w800,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 1; i <= total; i++) ...[
                if (i > 1) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: i <= done ? accent : AppColors.surface3,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

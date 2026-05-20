import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Carte "Nombre de mots" fond ambre-light, icone clock, info a gauche + pill
/// blanc compteur a droite. Style constant (ne change pas selon l'etat) :
/// c'est dans `WritingZone` qu'on signale dans/hors plage.
/// Equivalent de `.mots-card` du mockup HTML.
class MotsCard extends StatelessWidget {
  const MotsCard({
    super.key,
    required this.current,
    required this.min,
    required this.max,
  });

  final int current;
  final int min;
  final int max;

  static const _ambreText = Color(0xFFB5780E);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 18, color: _ambreText),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nombre de mots',
                  style: AppFonts.jakarta(
                    size: 13,
                    weight: FontWeight.w700,
                    color: _ambreText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$min a $max mots attendus',
                  style: AppFonts.jakarta(
                    size: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: _ambreText.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$current mots',
              style: AppFonts.jakarta(
                size: 13,
                weight: FontWeight.w700,
                color: _ambreText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

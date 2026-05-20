import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';
import 'level_pill.dart';

/// Ligne d'une tache dans le bilan global : nom + pill niveau cible a gauche,
/// score /20 + pill niveau obtenu a droite.
/// Equivalent de `.tache-bilan-row` du mockup HTML.
class TacheBilanRow extends StatelessWidget {
  const TacheBilanRow({
    super.key,
    required this.name,
    required this.niveauCible,
    this.score,
    this.niveauObtenu,
  });

  final String name;
  final String niveauCible;
  final double? score;
  final NiveauCecrl? niveauObtenu;

  NiveauCecrl? _parseNiveauCible() {
    switch (niveauCible.toUpperCase()) {
      case 'A1':
        return NiveauCecrl.a1;
      case 'A2':
        return NiveauCecrl.a2;
      case 'B1':
        return NiveauCecrl.b1;
      case 'B2':
        return NiveauCecrl.b2;
      case 'C1':
        return NiveauCecrl.c1;
      case 'C2':
        return NiveauCecrl.c2;
      default:
        return null;
    }
  }

  String _formatScore(double s) {
    if (s == s.truncateToDouble()) return s.toInt().toString();
    return s.toStringAsFixed(1).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final cible = _parseNiveauCible();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  name,
                  style: AppFonts.jakarta(
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                if (cible != null) LevelPill(level: cible, small: true),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (score != null)
            Text(
              '${_formatScore(score!)}/20',
              style: AppFonts.jakarta(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.ink,
              ),
            )
          else
            Text(
              '—',
              style: AppFonts.jakarta(size: 13, color: AppColors.muted),
            ),
          if (niveauObtenu != null) ...[
            const SizedBox(width: 10),
            LevelPill(level: niveauObtenu!, small: true),
          ],
        ],
      ),
    );
  }
}

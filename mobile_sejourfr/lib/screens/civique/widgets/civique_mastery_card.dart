import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Carte « Ma maîtrise » du hub Civique : remplace la carte CECRL du TCF
/// (Civique n'a pas de niveau CECRL).
///
/// Progression = maîtrise : bonnes réponses / total de questions du module.
/// Affiche ce % + la barre, avec le compteur de questions vues (X/Y) en
/// secondaire. Si rien n'a encore été tenté, affiche un message d'amorce.
class CiviqueMasteryCard extends StatelessWidget {
  const CiviqueMasteryCard({
    super.key,
    required this.answered,
    required this.correct,
    required this.total,
  });

  /// Nombre de questions distinctes tentées au moins une fois.
  final int answered;

  /// Nombre de questions distinctes réussies au moins une fois.
  final int correct;

  /// Taille totale du pool de questions Civique.
  final int total;

  @override
  Widget build(BuildContext context) {
    final hasStarted = answered > 0 && total > 0;
    // Progression = maîtrise (bonnes réponses / total). La barre la reflète.
    final mastery = total == 0 ? 0.0 : (correct / total).clamp(0.0, 1.0);
    final masteryPct = (mastery * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MAÎTRISE GLOBALE',
                      style: AppFonts.mono(
                        size: 9.5,
                        color: AppColors.muted,
                        letterSpacing: 1.4,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasStarted ? '$masteryPct %' : '—',
                      style: AppFonts.jakarta(
                        size: 22,
                        weight: FontWeight.w800,
                        color: AppColors.ink,
                      ).copyWith(letterSpacing: -0.4),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RÉUSSIES',
                    style: AppFonts.mono(
                      size: 9.5,
                      color: AppColors.muted,
                      letterSpacing: 1.4,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    total == 0 ? '—' : '$correct / $total',
                    style: AppFonts.jakarta(
                      size: 13.5,
                      weight: FontWeight.w700,
                      color: AppColors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Stack(
              children: [
                Container(height: 4, color: AppColors.line2),
                FractionallySizedBox(
                  widthFactor: mastery,
                  child: Container(
                    height: 4,
                    color: AppColors.blue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasStarted
                ? 'Bonnes réponses sur l\'ensemble du programme · $answered vues'
                : 'Lance un thème pour démarrer ta progression',
            style: AppFonts.jakarta(size: 11.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

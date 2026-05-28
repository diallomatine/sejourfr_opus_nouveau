import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Carte « Ma maîtrise » du hub Civique : remplace la carte CECRL du TCF
/// (Civique n'a pas de niveau CECRL).
///
/// Affiche le % de bonnes réponses sur questions tentées + le compteur
/// brut (X/Y vues) + une barre bleue. Si rien n'a encore été tenté, affiche
/// un message d'amorce.
class CiviqueMasteryCard extends StatelessWidget {
  const CiviqueMasteryCard({
    super.key,
    required this.answered,
    required this.total,
    required this.precisionPercent,
  });

  /// Nombre de questions distinctes tentées au moins une fois.
  final int answered;

  /// Taille totale du pool de questions Civique.
  final int total;

  /// % de bonnes réponses sur les questions tentées (null si rien tenté).
  final int? precisionPercent;

  @override
  Widget build(BuildContext context) {
    final hasStarted = answered > 0 && total > 0;
    final coverage = total == 0 ? 0.0 : (answered / total).clamp(0.0, 1.0);

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
                      hasStarted && precisionPercent != null
                          ? '$precisionPercent %'
                          : '—',
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
                    'COUVERTURE',
                    style: AppFonts.mono(
                      size: 9.5,
                      color: AppColors.muted,
                      letterSpacing: 1.4,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    total == 0 ? '—' : '$answered / $total',
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
                  widthFactor: coverage,
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
                ? 'Questions du programme déjà rencontrées'
                : 'Lance un thème pour démarrer ta progression',
            style: AppFonts.jakarta(size: 11.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

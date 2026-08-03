import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';

/// Niveau observe SUR CETTE TACHE, toujours accompagne de sa confiance.
///
/// Garde-fou non negociable : pas de niveau sans confiance. Si le backend n'a
/// pas les deux (evaluation anterieure au contrat v4), la carte disparait —
/// l'ecran redevient exactement celui d'avant.
///
/// Le niveau qui fait foi reste celui du bilan des trois taches ; c'est ce que
/// rappelle `avertissementNiveau`, fourni pret a afficher par le backend.
class NiveauObserveCard extends StatelessWidget {
  const NiveauObserveCard({super.key, required this.evaluation});

  final EvaluationResult evaluation;

  @override
  Widget build(BuildContext context) {
    if (!evaluation.hasNiveauObserve) return const SizedBox.shrink();
    final niveau = evaluation.niveauObserve!;
    final confiance = evaluation.confiance!;
    final raisons = evaluation.feedback.confianceRaisons;
    final color = niveau.color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.gauge, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Performance observée sur cette tâche : '
                  'proche du niveau ${niveau.displayName}',
                  style: AppFonts.ui(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Estimation pédagogique — ${confiance.displayName}.',
            style: AppFonts.ui(
              size: 12.5,
              weight: FontWeight.w600,
              color: AppColors.muted,
              height: 1.45,
            ),
          ),
          if (evaluation.avertissementNiveau != null) ...[
            const SizedBox(height: 4),
            Text(
              evaluation.avertissementNiveau!,
              style: AppFonts.ui(
                size: 12.5,
                color: AppColors.muted,
                height: 1.45,
              ),
            ),
          ],
          if (raisons.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final raison in raisons)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 8),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        raison,
                        style: AppFonts.ui(
                          size: 12.5,
                          color: AppColors.ink2,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

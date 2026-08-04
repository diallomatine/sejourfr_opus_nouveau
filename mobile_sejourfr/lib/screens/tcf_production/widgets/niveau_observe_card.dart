import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';

/// Niveau observe SUR CETTE TACHE, en tete du rapport : c'est l'information
/// que le candidat cherche, elle se lit d'un coup d'oeil (pastille du niveau +
/// confiance). Les precautions passent dessous, en second plan.
///
/// Garde-fou non negociable : pas de niveau sans confiance. Si le backend n'a
/// pas les deux (evaluation anterieure), la carte disparait entierement — pas
/// de niveau orphelin.
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NiveauBadge(niveau: niveau, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NIVEAU OBSERVÉ SUR CETTE TÂCHE',
                      style: AppFonts.label(size: 10, color: AppColors.muted)
                          .copyWith(letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Proche du niveau ${niveau.displayName}',
                      style: AppFonts.ui(
                        size: 15,
                        weight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ConfiancePill(confiance: confiance),
                  ],
                ),
              ),
            ],
          ),
          if (evaluation.avertissementNiveau != null) ...[
            const SizedBox(height: 12),
            Text(
              evaluation.avertissementNiveau!,
              style: AppFonts.ui(
                size: 12,
                color: AppColors.muted,
                height: 1.45,
              ),
            ),
          ],
          if (raisons.isNotEmpty) ...[
            const SizedBox(height: 8),
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
                          size: 12,
                          color: AppColors.muted,
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

/// Pastille du niveau, pleine : le seul element colore fort de l'ecran de
/// resultat, pour qu'il se voie sans lire.
class _NiveauBadge extends StatelessWidget {
  const _NiveauBadge({required this.niveau, required this.color});

  final NiveauCecrl niveau;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // « A1 non atteint » ne tient pas a la taille d'un « B1 » : seul ce libelle
    // long descend en taille, les six autres gardent le gros chiffre.
    final isLongLabel = niveau == NiveauCecrl.a1NonAtteint;
    return Container(
      width: 68,
      height: 68,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        niveau.displayName,
        textAlign: TextAlign.center,
        style: AppFonts.display(
          size: isLongLabel ? 14 : 30,
          weight: FontWeight.w700,
          color: AppColors.white,
        ).copyWith(height: 1.15, letterSpacing: -0.5),
      ),
    );
  }
}

/// La confiance ne quitte jamais le niveau : elle dit ce que l'evaluation sait,
/// pas ce que vaut la production.
class _ConfiancePill extends StatelessWidget {
  const _ConfiancePill({required this.confiance});

  final ConfianceEvaluation confiance;

  Color get _tone => switch (confiance) {
        ConfianceEvaluation.haute => AppColors.green,
        ConfianceEvaluation.moyenne => AppColors.amber,
        ConfianceEvaluation.faible => AppColors.muted,
      };

  @override
  Widget build(BuildContext context) {
    final label = confiance.displayName;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _tone.withValues(alpha: 0.45)),
      ),
      child: Text(
        '${label[0].toUpperCase()}${label.substring(1)}',
        style: AppFonts.ui(
          size: 12,
          weight: FontWeight.w700,
          color: _tone,
        ),
      ),
    );
  }
}

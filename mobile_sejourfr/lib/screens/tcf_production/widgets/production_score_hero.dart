import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_date.dart';
import 'tcf_note_scale.dart';

/// Note de la tache ET niveau observe, dans UN SEUL bloc, avec la regle de
/// lecture du TCF sous les yeux.
///
/// Pourquoi ensemble : separes, la note se lisait comme une note scolaire
/// francaise. « 4,5/20 » n'est pas une catastrophe, c'est un A2 — notre note est
/// une ESTIMATION exprimee sur l'echelle du TCF (0 = A1 non atteint, 1 = A1,
/// 2-5 = A2, 6-9 = B1, 10-20 = B2). L'echelle est celle de l'examen ; la
/// correction, elle, est la notre. L'echelle est donc affichee avec la note,
/// pas ailleurs.
///
/// Deux regles non negociables :
/// - jamais de niveau sans sa confiance ([EvaluationResult.hasNiveauObserve]) ;
/// - la confiance ne s'affiche QUE lorsqu'elle n'est pas haute : une confiance
///   haute est le cas normal, l'annoncer n'apprend rien et inquiete.
///
/// Notre niveau est une **estimation** : le libelle dit « proche du niveau B1 »,
/// jamais « B1 » sec — affirmer le palier engagerait plus que ce qu'on sait.
///
/// Phrase de pied : `avertissementNiveau` (envoye par le backend) **remplace**
/// la phrase generique, il ne s'y ajoute pas. Les deux disent la meme chose ;
/// les empiler est exactement la repetition que cette refonte corrige.
const String kNotePorteeSurLaTache =
    'Cette note est une estimation, exprimée sur l\'échelle du TCF : c\'est elle '
    'qui donne le niveau. Elle porte ici sur cette seule tâche — au TCF, la note '
    'sur 20 est celle de l\'épreuve entière, vos trois tâches.';

/// Repli quand le correcteur signale une confiance basse sans dire pourquoi :
/// une pastille seule laisse le candidat sans explication.
const String kConfianceSansRaison =
    'Une partie de votre production était difficile à analyser : cette note est '
    'à prendre avec prudence.';

class ProductionScoreHero extends StatelessWidget {
  const ProductionScoreHero({super.key, required this.evaluation});

  final EvaluationResult evaluation;

  Color get _tone {
    final note = evaluation.noteSurVingt;
    final band = note == null ? null : TcfNoteScale.bandFor(note);
    return band?.tone ?? AppColors.muted2;
  }

  @override
  Widget build(BuildContext context) {
    final note = evaluation.noteSurVingt;
    final confiance = evaluation.confiance;
    final showConfiance =
        confiance != null && confiance != ConfianceEvaluation.haute;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOTE DE LA TÂCHE',
                      style: AppFonts.label(size: 10, color: AppColors.muted),
                    ),
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: note == null ? '—' : formatScore(note),
                            style: AppFonts.display(
                              size: 38,
                              weight: FontWeight.w700,
                              color: _tone,
                            ),
                          ),
                          TextSpan(
                            text: '/20',
                            style: AppFonts.ui(
                              size: 15,
                              weight: FontWeight.w600,
                              color: AppColors.muted2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (evaluation.hasNiveauObserve) ...[
                const SizedBox(width: 12),
                Flexible(child: _NiveauBadge(niveau: evaluation.niveauObserve!)),
              ],
            ],
          ),
          const SizedBox(height: 16),
          TcfNoteScale(note: note),
          const SizedBox(height: 14),
          Text(
            evaluation.avertissementNiveau ?? kNotePorteeSurLaTache,
            style: AppFonts.ui(size: 12, color: AppColors.muted, height: 1.5),
          ),
          if (showConfiance) ...[
            const SizedBox(height: 14),
            _ConfianceBlock(
              confiance: confiance,
              raisons: evaluation.feedback.confianceRaisons,
            ),
          ],
        ],
      ),
    );
  }
}

/// Pastille du niveau : le seul element colore fort du bloc, pour qu'il se voie
/// sans etre lu.
class _NiveauBadge extends StatelessWidget {
  const _NiveauBadge({required this.niveau});

  final NiveauCecrl niveau;

  /// « Proche du niveau B1 », pas « B1 ». Sauf pour le plancher, ou « proche
  /// de » n'a aucun sens : on n'est pas proche d'un niveau non atteint.
  String get _label => niveau == NiveauCecrl.a1NonAtteint
      ? 'Niveau A1 non atteint'
      : 'Proche du niveau ${niveau.displayName}';

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92, maxWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: niveau.color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Niveau observé sur cette tâche',
            textAlign: TextAlign.center,
            style: AppFonts.label(
              size: 9,
              color: AppColors.white.withValues(alpha: 0.85),
            ).copyWith(height: 1.3),
          ),
          const SizedBox(height: 3),
          Text(
            _label,
            textAlign: TextAlign.center,
            style: AppFonts.display(
              size: 15,
              weight: FontWeight.w700,
              color: AppColors.white,
            ).copyWith(height: 1.2),
          ),
        ],
      ),
    );
  }
}

/// La confiance dit ce que l'evaluation SAIT, pas ce que vaut la production.
/// Elle n'apparait que lorsqu'elle n'est pas haute — sinon c'est du bruit.
class _ConfianceBlock extends StatelessWidget {
  const _ConfianceBlock({required this.confiance, required this.raisons});

  final ConfianceEvaluation confiance;
  final List<String> raisons;

  Color get _tone => confiance == ConfianceEvaluation.moyenne
      ? AppColors.amber
      : AppColors.muted;

  @override
  Widget build(BuildContext context) {
    final label = confiance.displayName;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: _tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: _tone, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${label[0].toUpperCase()}${label.substring(1)}',
            style: AppFonts.ui(size: 13, weight: FontWeight.w700, color: _tone),
          ),
          for (final raison in raisons.isEmpty
              ? const [kConfianceSansRaison]
              : raisons) ...[
            const SizedBox(height: 6),
            Text(
              raison,
              style: AppFonts.ui(size: 12, color: AppColors.muted, height: 1.45),
            ),
          ],
        ],
      ),
    );
  }
}

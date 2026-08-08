import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../production_result_labels.dart';

/// Ligne récap d'une tâche dans le bilan d'une session EE/EO.
///
/// Layout : titre de la tâche en haut, sous-titre récap en bas ("Niveau B1",
/// "Évaluation en cours…", "Évaluation échouée — à relancer" ou "Non évaluée").
/// À droite : un chevron qui signale qu'on peut tapoter pour ouvrir
/// l'évaluation détaillée. Le chevron disparaît quand la ligne n'est pas
/// tappable (pending ou absence d'éval).
///
/// La ligne portait « Note 14 / 20 ». Ce commentaire disait « aucun niveau
/// CECRL par tâche » : c'était la décision du 2026-06-11, prise quand le
/// backend avait retiré le niveau par tâche de son DTO. Il l'y a remis
/// (`EvaluationResult.niveauObserve`, contrat v4), et la règle est désormais
/// l'inverse — au TCF, une tâche reçoit un niveau, jamais une note ; le /20 ne
/// porte que sur l'épreuve entière, qui reste affichée par [BilanHero]
/// au-dessus.
class TacheBilanRow extends StatelessWidget {
  const TacheBilanRow({
    super.key,
    required this.name,
    this.niveau,
    this.evaluated = false,
    this.pending = false,
    this.notRendered = false,
    this.failed = false,
  });

  final String name;

  /// Palier observé sur cette tâche, `null` sur une évaluation trop ancienne
  /// pour en porter un (cf. `tacheNiveau`) — la ligne dit alors « Évaluée »
  /// plutôt qu'un niveau inventé.
  final NiveauCecrl? niveau;

  /// L'évaluation IA a abouti. Distinct de `niveau != null` : c'est lui qui
  /// décide du chevron, sinon une évaluation sans niveau perdait l'accès à son
  /// rapport.
  final bool evaluated;

  /// Quand `true`, l'évaluation IA tourne encore : on affiche un mini-spinner
  /// et le texte "Évaluation en cours" au lieu du score.
  final bool pending;

  /// Quand `true`, la tâche n'a jamais été rendue (examen terminé / abandonné) :
  /// elle est comptée 0 au bilan et affichée « Non rendue ».
  final bool notRendered;

  /// Quand `true`, la production a bien été rendue mais son évaluation IA a
  /// échoué (submission `FAILED`). C'est le seul cas où le candidat a une
  /// action à faire : relancer la correction depuis l'écran de résultat. On le
  /// dit en rouge et on garde le chevron — sans lui, la ligne racontait « Non
  /// évaluée » avec une icône « rien à voir ici », et le bouton « Réessayer
  /// l'évaluation » restait à un tap invisible. Libellé aligné au mot près sur
  /// le web (`ProductionSession`).
  final bool failed;

  @override
  Widget build(BuildContext context) {
    // Une tâche en échec reste tappable : c'est l'écran de résultat qui porte
    // la relance.
    final showChevron = evaluated || failed;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppFonts.ui(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _Subtitle(
                  pending: pending,
                  notRendered: notRendered,
                  failed: failed,
                  evaluated: evaluated,
                  niveau: niveau,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (pending)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (showChevron)
            Icon(
              LucideIcons.chevronRight,
              size: 22,
              color: failed ? AppColors.red : AppColors.muted2,
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                LucideIcons.circleMinus,
                size: 18,
                color: AppColors.muted2,
              ),
            ),
        ],
      ),
    );
  }
}

/// Sous-titre récap sous le nom de la tâche, selon l'état :
/// - Niveau connu → "Niveau B1"
/// - Évaluée sans niveau (éval antérieure au contrat v4) → "Évaluée"
/// - Évaluation en cours → "Évaluation IA en cours…"
/// - Évaluation en échec → "Évaluation échouée — à relancer"
/// - Aucune éval → "Non évaluée"
class _Subtitle extends StatelessWidget {
  const _Subtitle({
    required this.pending,
    required this.evaluated,
    required this.niveau,
    this.notRendered = false,
    this.failed = false,
  });

  final bool pending;
  final bool notRendered;
  final bool failed;
  final bool evaluated;
  final NiveauCecrl? niveau;

  @override
  Widget build(BuildContext context) {
    final (text, color) = notRendered
        ? ('Non rendue', AppColors.muted)
        : switch ((pending, failed, evaluated, niveau)) {
            (true, _, _, _) => ('Évaluation IA en cours…', AppColors.blue),
            (false, true, _, _) =>
              ('Évaluation échouée — à relancer', AppColors.red),
            // Encre neutre, pas la teinte du palier : la ligne dit un état, et
            // le web rend exactement le même sous-titre sans couleur.
            (false, false, true, final NiveauCecrl n) =>
              (tacheNiveauLabel(n), AppColors.ink2),
            (false, false, true, _) => (kTacheEvalueeLabel, AppColors.ink2),
            _ => ('Non évaluée', AppColors.muted),
          };
    return Text(
      text,
      style: AppFonts.ui(
        size: 12,
        weight: pending || failed ? FontWeight.w600 : FontWeight.w500,
        color: color,
      ),
    );
  }
}

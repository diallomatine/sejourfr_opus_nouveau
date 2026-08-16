import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/skill_models.dart';

/// Ce qu'on dit d'un **jalon** du Plan.
///
/// Le serveur n'en fournit **aucun** libellé : il expose des faits (quelle
/// épreuve, quel slot, verrouillé ou non), la phrase appartient aux fronts —
/// même partage que `PlanChange`.
///
/// ⚠️ **Contrat gelé, miroir mot pour mot du web**
/// (`web_sejoufr/lib/diagnostic.ts`, section « jalons »). Ces chaînes ne
/// transitent pas par le réseau : chaque front en tient sa copie, un libellé qui
/// bouge, ce sont **deux** fichiers à changer dans la même passe.
///
/// **Ton** : un jalon est une étape de progression, pas une sanction. Le
/// candidat vient prouver ce qu'il a acquis, on ne le met pas en garde.
const String kPlanMilestoneSectionTitle = 'Votre prochain jalon';
const String kPlanMilestoneSectionText =
    'Un cran au-dessus des étapes : venez prouver ce que vous avez déjà acquis.';
const String kPlanMilestonePill = 'Jalon';
const String kPlanMilestoneCta = 'Passer l\'examen blanc';
const String kPlanMilestoneLockedCta = 'Débloquer cet examen blanc';
const String kPlanMilestoneLockNote =
    'Cet examen blanc fait partie de l\'abonnement Intégral. Votre plan, lui, '
    'reste entier.';
const String kPlanMilestoneFullTitle = 'Examen blanc TCF complet';
const String kPlanMilestoneFullText =
    'L\'écrit et l\'oral ont chacun franchi leur jalon. Il reste à les tenir '
    'ensemble, sur les 4 épreuves du TCF.';

extension PlanMilestoneLabels on PlanMilestone {
  /// Titre : « Examen blanc — Expression écrite / orale », ou l'examen complet.
  /// C'est [PlanMilestone.epreuve] qui tranche, jamais une section (il n'y en a
  /// pas sur un jalon).
  String get displayTitle => isFullExam
      ? kPlanMilestoneFullTitle
      : 'Examen blanc — ${_section.productionLabel}';

  /// Pourquoi ce jalon est proposé maintenant — une phrase, pas un
  /// avertissement.
  String get displayText => isFullExam
      ? kPlanMilestoneFullText
      : 'Vos compétences en ${_section.productionLabel.toLowerCase()} tiennent '
          'en exercice ciblé. Enchaînez les 3 tâches en conditions d\'examen '
          'pour le confirmer.';

  /// Le repère factuel sous le titre : quel examen de la grille, quelle durée.
  /// La durée vient du DTO, jamais d'un nombre écrit ici.
  String get displayMeta =>
      'Examen blanc n°$slotNumber · ≈ $estimatedMinutes min';

  SkillSection get _section =>
      epreuve == EpreuveType.tcfEo ? SkillSection.eo : SkillSection.ee;
}

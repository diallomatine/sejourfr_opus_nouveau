/// **Les phrases du rapport du diagnostic rapide, de sa transition et de
/// « Revoir ma réponse »** (2026-10-04).
///
/// 🛑 **Miroir MOT POUR MOT de `web_sejoufr/lib/diagnostic-rapport.ts`** : une
/// seule autorité par front. Le serveur sert des **faits** (niveau, objectif,
/// situation, statut de communication, priorités du lot du Plan) ; ce fichier
/// les met en mots, sans jamais trier, compter autrement ni recalculer.
///
/// Les libellés en capitales sont écrits en casse normale et mis en majuscules
/// à l'affichage, comme le CSS du web.
library;

import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/journey_models.dart';
import '../../core/models/skill_models.dart';
import '../../core/utils/cecrl_track.dart';
import '../plan/journey_labels.dart';

/* ================================================================ ÉCRAN 1 */

/// 🛑 « Votre estimation », pas « Votre niveau TCF » : le diagnostic rapide
/// n'observe qu'une production écrite.
const String kDiagnosticReportKicker = 'Diagnostic rapide terminé';
const String kDiagnosticReportTitle = 'Votre estimation';

/// 🛑 **Wording imposé** : « Niveau estimé sur cet exercice ».
const String kDiagnosticLevelEyebrow = 'Niveau estimé sur cet exercice';
const String kDiagnosticGoalLabel = 'Votre objectif';

/// Le niveau d'une production non évaluable (P3) : un tiret, jamais A1 ni 0.
const String kDiagnosticLevelUnknown = '—';
const String kDiagnosticIncompleteTag = 'Évaluation incomplète';

/// La production a-t-elle été rendue sans que rien n'y soit observable ?
/// 🛑 Même test des deux côtés, sur le fait **servi** `evaluabilite`.
bool diagnosticNonEvaluable(DiagnosticResult result) =>
    result.written?.evaluabilite == ProductionEvaluabilite.nonEvaluable;

/// La phrase de situation, sur `situationObjectif` **servi**. `null` ⇒ rien.
String? diagnosticSituationPhrase(
  SituationObjectif? situation,
  TargetLevel? objectif,
) {
  if (situation == null || objectif == null) return null;
  final x = objectif.wire;
  return switch (situation) {
    SituationObjectif.unPalierSousObjectif =>
      'Vous avez déjà les bases pour viser le niveau $x.',
    SituationObjectif.plusieursPaliersSousObjectif =>
      'Votre plan va vous faire progresser étape par étape vers le niveau $x.',
    SituationObjectif.objectifAtteint =>
      'Votre estimation atteint déjà votre objectif $x sur cet exercice.',
  };
}

/// Le repère du palier du candidat sur la piste : « B1 · Vous ».
const String kDiagnosticTrackYou = 'Vous';
const String kDiagnosticTrackGoal = 'Objectif';
const String kDiagnosticTrackLegend = "Votre progression vers l'objectif";

/// Les libellés de colonnes de la piste : le palier du candidat devient
/// « {N} · Vous ». Jamais de pourcentage.
List<String> diagnosticTrackLevels(CecrlTrack track) => [
      for (var i = 0; i < track.levels.length; i++)
        i == track.currentIndex
            ? '${track.levels[i]} · $kDiagnosticTrackYou'
            : track.levels[i],
    ];

/// Phrase 1 de la synthèse, sur `communicationStatus` **servi** (AR-4 : le
/// résumé du correcteur n'est plus affiché). `null` ⇒ rien.
String? diagnosticSynthesePhrase1(DiagnosticCommunicationStatus? status) =>
    switch (status) {
      DiagnosticCommunicationStatus.effective =>
        'Votre production est claire et efficace.',
      DiagnosticCommunicationStatus.partial =>
        "Votre production transmet l'essentiel, avec encore quelques points à clarifier.",
      DiagnosticCommunicationStatus.ineffective =>
        'Votre production reste encore difficile à suivre par endroits.',
      null => null,
    };

/// Phrase 2 de la synthèse : la priorité n°1 **du lot du Plan** (rang servi,
/// jamais retriée). Aucune priorité ⇒ rien.
String? diagnosticSynthesePhrase2(DiagnosticResult result) {
  final priorities = result.planPriorities;
  if (priorities.isEmpty) return null;
  final titre = _minusculeInitiale(priorities.first.skillTitle);
  final objectif = result.objectiveLevel;
  if (objectif != null &&
      result.situationObjectif != SituationObjectif.objectifAtteint) {
    return 'Ce qui vous sépare principalement du ${objectif.wire} : $titre.';
  }
  return 'Votre priorité principale : $titre.';
}

String _minusculeInitiale(String texte) =>
    texte.isEmpty ? texte : '${texte[0].toLowerCase()}${texte.substring(1)}';

const String kDiagnosticObserveTitle = 'Ce que nous avons observé';
const String kDiagnosticObservePositive = 'Point fort';
const String kDiagnosticObservePriority = 'Priorité';

/// Plafond d'affichage du point fort : une ligne, comme avant la refonte.
const int kDiagnosticObserveMaxPositive = 1;

typedef DiagnosticObservation = ({
  bool positive,
  String kicker,
  String titre,
  String? texte,
});

/// Le(s) point(s) fort(s) — **même source qu'avant** : les compétences que le
/// serveur a marquées `SOLID` (observées), à défaut les phrases `strengths` —,
/// puis **une carte par priorité du lot du Plan**, toutes, dans l'ordre servi.
///
/// 🛑 Plus jamais `result.priorities` : ce sont celles du diagnostic, qui ne
/// coïncident pas avec le Plan.
List<DiagnosticObservation> diagnosticObservations(DiagnosticResult result) {
  final solides =
      (result.written?.skills ?? const <DiagnosticSkillObservation>[]).where(
          (skill) =>
              skill.observed && skill.status == LearningPlanSkillStatus.solid);
  final positives = solides.isNotEmpty
      ? <DiagnosticObservation>[
          for (final skill in solides.take(kDiagnosticObserveMaxPositive))
            (
              positive: true,
              kicker: kDiagnosticObservePositive,
              titre: skill.skillTitle,
              texte: skill.explanation,
            ),
        ]
      : <DiagnosticObservation>[
          for (final force
              in result.strengths.take(kDiagnosticObserveMaxPositive))
            (
              positive: true,
              kicker: kDiagnosticObservePositive,
              titre: force,
              texte: null,
            ),
        ];
  return [
    ...positives,
    for (final p in result.planPriorities)
      (
        positive: false,
        kicker: kDiagnosticObservePriority,
        titre: p.skillTitle,
        texte: p.explanation,
      ),
  ];
}

/// 🛑 **Obligation d'honnêteté** : une seule production écrite a été observée.
const String kDiagnosticInfoTitle =
    'Une première estimation, pas encore votre niveau TCF complet';
const String kDiagnosticInfoText =
    'Votre niveau final dépend également de la compréhension orale, de la compréhension écrite et de l\'expression orale.';

const String kDiagnosticReportPlanCta = 'Découvrir mon plan';
const String kDiagnosticReportAnswerLink = 'Revoir ma réponse';

/* ================================================================ ÉCRAN 2 */

const String kDiagnosticTransitionKicker = 'Votre diagnostic est analysé';
const String kDiagnosticTransitionTitle = 'Votre plan commence ici';

String diagnosticTransitionPhrase(TargetLevel? objectif) => objectif == null
    ? 'Nous avons transformé vos résultats en priorités concrètes pour vous faire progresser.'
    : 'Nous avons transformé vos résultats en priorités concrètes pour vous rapprocher de votre objectif ${objectif.wire}.';

String diagnosticPrioritiesTitle(int n) =>
    n == 1 ? 'Votre priorité identifiée' : 'Vos $n priorités identifiées';

const String kDiagnosticPrioritiesSub = 'À travailler pendant votre parcours';

/// La pastille de la carte : le nom de l'épreuve **seulement** si toutes les
/// priorités en partagent une. Sinon, rien.
String? diagnosticPrioritiesPill(List<DiagnosticPlanPriority> priorities) {
  if (priorities.isEmpty) return null;
  final section = priorities.first.section;
  return priorities.every((p) => p.section == section) ? section.label : null;
}

/// La note sous la liste, sur `inCurrentCycle` **servi** de la première.
String? diagnosticPrioritiesNote(List<DiagnosticPlanPriority> priorities) {
  if (priorities.isEmpty) return null;
  final une = priorities.length == 1;
  return priorities.first.inCurrentCycle
      ? (une
          ? 'Elle est déjà intégrée à votre plan.'
          : 'Elles sont déjà intégrées à votre plan.')
      : (une
          ? 'Elle rejoindra votre plan au prochain cycle.'
          : 'Elles rejoindront votre plan au prochain cycle.');
}

const String kDiagnosticBridgeTitle =
    'Et pour connaître votre niveau réel au TCF ?';
const String kDiagnosticBridgeText =
    'Votre plan vous fera passer un examen blanc dans chaque épreuve encore à mesurer.';
const String kDiagnosticEpreuveEvaluee = 'Évaluée';
const String kDiagnosticEpreuveAMesurer = 'À mesurer';

/// Les quatre tuiles, dans l'ordre CO · CE · EE · EO.
const List<({SkillSection section, EpreuveType epreuve})>
    kDiagnosticBridgeEpreuves = [
  (section: SkillSection.co, epreuve: EpreuveType.tcfCo),
  (section: SkillSection.ce, epreuve: EpreuveType.tcfCe),
  (section: SkillSection.ee, epreuve: EpreuveType.tcfEe),
  (section: SkillSection.eo, epreuve: EpreuveType.tcfEo),
];

/// L'état d'une épreuve, lu sur `plan.domaines[].evaluated` **servi**.
/// `null` (plan non chargé, épreuve absente) ⇒ aucun état affiché.
String? diagnosticEpreuveEtat(bool? evaluated) => switch (evaluated) {
      true => kDiagnosticEpreuveEvaluee,
      false => kDiagnosticEpreuveAMesurer,
      null => null,
    };

const String kDiagnosticNextStepEyebrow = 'Votre prochaine étape';
const String kDiagnosticNextStepText =
    'Les prochaines évaluations viendront affiner votre plan progressivement.';

/// Le titre de la carte « Votre prochaine étape » : l'étape courante
/// (`journey.current`) **telle que le Plan la nomme** — les libellés du
/// parcours, jamais une phrase de plus. Un examen se dit « {épreuve} ·
/// {nature} », la nature étant « Mesurer mon niveau » sur un cycle de mesure
/// ([journeyMesureMots]), « Examen blanc » sinon.
String diagnosticNextStepTitle(Journey journey, JourneyStep etape) {
  final titre = journeyStepTitle(etape);
  if (etape.type != JourneyStepType.sectionExam) return titre;
  final nature = journeyMesureMots(journey, etape, civique: false)?.kind ??
      journeyStepSubtitle(etape);
  return nature == null ? titre : '$titre · $nature';
}

const String kDiagnosticPlanCta = 'Voir mon plan';
const String kDiagnosticBackToReport = '← Revenir au rapport';

/* ================================================================ ÉCRAN 3 */

const String kDiagnosticAnswerKicker = 'Diagnostic rapide';
const String kDiagnosticAnswerTitle = 'Votre réponse';
const String kDiagnosticAnswerSubject = 'Le sujet';
const String kDiagnosticAnswerText = 'Votre réponse';
const String kDiagnosticAnswerUnavailable =
    'Impossible de charger votre réponse.';

String diagnosticWordCountLabel(int n) => n > 1 ? '$n mots' : '$n mot';

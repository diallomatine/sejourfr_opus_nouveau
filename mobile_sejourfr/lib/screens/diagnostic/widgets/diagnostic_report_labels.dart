/// **Les phrases du rapport de diagnostic.**
///
/// ⚠️ **Miroirs mot pour mot du web** (`app/_components/diagnostic/
/// DiagnosticView.tsx` et `DiagnosticLevelCard.tsx`) : ces chaînes ne
/// transitent pas par le réseau, chaque front en tient sa copie écrite à la
/// main. Elles vivent ici plutôt que dans les widgets — une chaîne posée au
/// milieu d'un `Text` est exactement la façon dont les deux fronts ont déjà
/// divergé.
///
/// ⚠️ **Vouvoiement.** La maquette du propriétaire tutoie, mais elle ne donne
/// que la direction **visuelle** — structure, ordre des blocs, densité, ce
/// qu'on retire. Le registre, lui, reste celui de l'application : le rapport et
/// le Plan vouvoient, seul le module « Compétences » tutoie (arbitrage du
/// 2026-08-21).
///
/// 🛑 Les libellés en **capitales** sont écrits ici en casse normale et mis en
/// majuscules **à l'affichage** (`toUpperCase()`) : côté web c'est le CSS qui
/// s'en charge, et deux casses différentes ne seraient plus des miroirs.
library;

import '../../../core/models/diagnostic_models.dart';

/* ------------------------------------------------------------- l'en-tête */

/// Titre de l'en-tête d'écran une fois le rapport rendu.
///
/// ⚠️ C'est **« Diagnostic »**, pas « Votre rapport » : la référence de cet
/// écran est `MDiag` étape `result` (le bilan **in-app** d'un candidat
/// connecté), et non `MRapportGratuit`, qui est celui du **visiteur**. La
/// confusion entre les deux maquettes est ce qui avait fait dériver l'écran.
const String kDiagnosticReportTitle = 'Diagnostic';
const String kDiagnosticReportSubPremium = 'Rapport complet';
const String kDiagnosticReportSubFree = 'Estimation d\'entraînement Séjour';

/* ------------------------------------------------------ la carte de niveau */

const String kDiagnosticLevelEyebrow = 'Votre niveau estimé';
const String kDiagnosticLevelObjective = 'Objectif';
const String kDiagnosticLevelObjectiveUnknown = 'à définir';
const String kDiagnosticLevelText =
    'Estimation établie sur vos deux productions. Les compétences à rendre '
    'plus stables sont listées ci-dessous.';

/* ---------------------------------------------------- mon profil TCF */

/// La ligne sous le nom d'un domaine, **sur le bilan du diagnostic**.
///
/// ⚠️ **Volontairement différente de `planDomainSubtitle`** : le Plan explique
/// par quoi mesurer un domaine (c'est son rôle), le bilan dit seulement où en
/// est le profil au sortir des deux productions. Deux écrans, deux phrases —
/// ce n'est pas une copie qui a dérivé.
///
/// Un domaine jamais mesuré reste **inconnu, jamais mauvais** : aucun niveau ne
/// lui est prêté.
String diagnosticDomainSubtitle(PlanDomain domain) {
  final level = domain.niveau;
  if (!domain.evaluated || level == null) return kDiagnosticDomainNotEvaluated;
  return '${level.displayName} — quelques compétences observées';
}

const String kDiagnosticDomainNotEvaluated =
    'Votre profil se complétera avec une première série';

/// La carte qui ouvre la mesure des domaines encore inconnus.
///
/// 🛑 **Elle n'est rendue que si elle est VRAIE** : le diagnostic mesure les
/// deux domaines d'**expression**, jamais la compréhension — mais un candidat a
/// pu passer un examen blanc CO ou CE avant. Sans domaine de compréhension à
/// mesurer, la carte n'existe pas.
const String kDiagnosticCompleteProfileText =
    'Votre diagnostic n\'a pas encore évalué la compréhension. Deux épreuves '
    'suffisent — maintenant ou plus tard depuis votre plan.';

/// ⚠️ La durée qui suit ce libellé est **calculée**, jamais écrite : elle vient
/// des `estimatedMinutes` que le serveur pose sur chaque mesure, eux-mêmes lus
/// chez `DureeEpreuve`. La maquette affiche « 14 min », qui n'est la durée
/// d'aucune de nos épreuves.
const String kDiagnosticCompleteProfileCta = 'Compléter maintenant';

/// La seule phrase de l'écran qui dise ce que vaut l'estimation.
const String kDiagnosticEstimationNote =
    'Estimation d\'entraînement Séjour, non officielle. Elle ne remplace pas '
    'le résultat du TCF.';

/* ----------------------------------------------------------- les sections */

const String kDiagnosticPrioritiesTitle = 'Vos priorités';

/// Le sous-titre des priorités, **pour un compte sans accès seulement** : il
/// dit ce que le rideau cache, donc il n'a rien à dire à un abonné, qui les
/// voit toutes.
String diagnosticPrioritiesSub(int total) =>
    'Votre priorité actuelle sur $total détectées';

/// Repli : le serveur n'a désigné aucune priorité classée. On ne promeut pas
/// des points relevés en priorités mesurées.
const String kDiagnosticPrioritiesTitleUnranked = 'Ce qu\'il y a à travailler';
const String kDiagnosticPrioritiesTextUnranked =
    'Ces points viennent de vos deux productions. Ils ne sont pas encore '
    'classés en priorités.';

const String kDiagnosticStrengthsTitle = 'Vos points forts';

/// ⚠️ Le compte vient du serveur (`solidSkillCount`), jamais de la longueur de
/// ce qui est affiché : un compte gratuit n'en voit que deux.
String diagnosticStrengthsSub(int total) =>
    'Compétences observées et déjà solides · $total';

const String kDiagnosticPlanReadyTitle = 'Votre plan personnalisé est prêt';
const String kDiagnosticPlanReadyText =
    'Il commence par votre priorité n°1 et se réordonne à chacune de vos '
    'nouvelles productions.';
const String kDiagnosticPlanTodayLabel = 'Aujourd\'hui';

/* --------------------------------------------------------------- l'offre */

/// Ce que l'abonnement ouvre, dit du point de vue du candidat qui vient de lire
/// son diagnostic.
///
/// ⚠️ **Liste distincte de celle du Plan** et de celle de l'écran de passes :
/// elle ne vend pas le catalogue, elle nomme la suite de CE rapport. Ne pas la
/// fusionner avec un argumentaire commercial générique.
const List<String> kDiagnosticPremiumBenefits = <String>[
  'Toutes vos priorités détectées',
  'Les petits sujets ciblés, compétence par compétence',
  'Les corrections IA et la version au niveau visé',
  'Votre plan qui se réordonne à chaque production',
  'Le moment où vous êtes prêt pour un examen blanc',
];

/// Le titre de la carte d'offre. ⚠️ Distinct de celui du Plan : ici on ferme un
/// rapport, là-bas on ouvre un écran.
const String kDiagnosticUnlockTitle = 'Débloquez votre plan complet';

/* ---------------------------------------------------------- les actions */

const String kDiagnosticCtaPlan = 'Voir mon plan';

/// Le repère d'une ligne qui ne porte aucun domaine (repli sans compétence).
const String kDiagnosticPriorityRankLabel = 'Priorité détectée';
const String kDiagnosticPointLabel = 'Point à travailler';

/// Le numéro de tâche porté par un code de compétence d'**expression**
/// (`EE2-C7` → 2). `null` en compréhension (`CO-A2`) : ces compétences
/// n'appartiennent à aucune des six tâches officielles — on n'en invente pas.
/// Miroir de `skillTaskNumber` (`web_sejoufr/lib/diagnostic.ts`).
int? diagnosticSkillTaskNumber(String skillCode) {
  final match = RegExp(r'^(?:EE|EO)([1-3])(?:-|$)').firstMatch(skillCode);
  final task = match?.group(1);
  return task == null ? null : int.parse(task);
}

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

/* ------------------------------------------------------------- l'en-tête */

/// Titre de l'en-tête d'écran une fois le rapport rendu : l'écran a cessé
/// d'être un parcours, il est devenu un document.
const String kDiagnosticReportTitle = 'Votre rapport';
const String kDiagnosticReportSubPremium = 'Rapport complet';
const String kDiagnosticReportSubFree = 'Estimation d\'entraînement Séjour';

/* ------------------------------------------------------ la carte de niveau */

const String kDiagnosticLevelEyebrow = 'Votre niveau estimé';
const String kDiagnosticLevelObjective = 'Objectif';
const String kDiagnosticLevelObjectiveUnknown = 'à définir';
const String kDiagnosticLevelText =
    'Estimation établie sur vos deux productions. Les compétences à rendre '
    'plus stables sont listées ci-dessous.';

/// La note discrète sous la carte.
///
/// 🛑 **Elle ne s'affiche que si elle est VRAIE** : le diagnostic mesure les
/// deux domaines d'**expression**, jamais la compréhension — mais un candidat a
/// pu passer un examen blanc CO ou CE avant. On ne rend donc la phrase que
/// quand **aucun** des deux domaines de compréhension n'est évalué ; profil
/// complet, ou un seul des deux manquant, la bande de quatre colonnes dit déjà
/// « — » et suffit. Une seconde formulation « partielle » ferait un libellé de
/// plus à tenir des deux côtés pour un cas rare.
const String kDiagnosticProfileIncompleteNote =
    'La compréhension orale et écrite n\'a pas encore été évaluée : vous '
    'pourrez compléter votre profil quand vous voulez.';

/// La seule phrase de l'écran qui dise ce que vaut l'estimation.
const String kDiagnosticEstimationNote =
    'Estimation d\'entraînement Séjour, non officielle. Elle ne remplace pas '
    'le résultat du TCF.';

/* ----------------------------------------------------------- les sections */

const String kDiagnosticPrioritiesTitle = 'Vos principales priorités';
const String kDiagnosticPrioritiesText =
    'Le diagnostic ne liste pas vos erreurs : il désigne les compétences qui '
    'feront bouger votre niveau.';

/// Repli : le serveur n'a désigné aucune priorité classée. On ne promeut pas
/// des points relevés en priorités mesurées.
const String kDiagnosticPrioritiesTitleUnranked = 'Ce qu\'il y a à travailler';
const String kDiagnosticPrioritiesTextUnranked =
    'Ces points viennent de vos deux productions. Ils ne sont pas encore '
    'classés en priorités.';

const String kDiagnosticStrengthsTitle = 'Vos points forts';
const String kDiagnosticStrengthsText =
    'Ce que vos deux productions ont déjà montré de solide.';

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

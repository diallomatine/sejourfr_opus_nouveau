/// Les phrases de l'**Accueil** — **pures**, déclarées une fois.
///
/// 🛑 **Miroirs mot pour mot du web** (`web_sejoufr/app/(app)/dashboard/page.tsx`).
/// Le serveur n'expose aucun libellé pour cet écran : il sert des faits, les
/// deux fronts les mettent en mots — et ils doivent les mettre dans les
/// **mêmes** mots, sinon le même compte lit deux prochaines actions selon
/// l'appareil.
library;

import '../../core/models/diagnostic_models.dart';

/* ------------------------------------------------------------- en-tête --- */

/// « Bonjour Abdoul ». Sans prénom servi, on ne fabrique pas d'identité.
String homeHello(String? firstName) {
  final prenom = firstName?.trim();
  return prenom == null || prenom.isEmpty
      ? 'Bonjour à vous'
      : 'Bonjour $prenom';
}

/// Le bandeau d'un compte **sans démarche déclarée**. C'est la seule chose qui
/// manque pour personnaliser la préparation : on le dit, et on ouvre l'écran
/// qui en est l'autorité.
const String kHomeParcoursBannerTitle = 'Choisissez votre parcours';
const String kHomeParcoursBannerText =
    'CSP, carte de résident ou naturalisation, pour personnaliser votre '
    'préparation.';

/* ----------------------------------------------------- sections de page --- */

const String kHomeNowTitle = 'À faire maintenant';

/* ------------------------------------------------- « Où vous en êtes » ---- */

/// La section des cartes d'épreuve, entre l'action du jour et l'aperçu du Plan.
const String kHomeSituationTitle = 'Où vous en êtes';

/// Le lien de tête de section, vers le Plan **du module affiché** (maquette
/// v3, 2026-09-24). ⚠️ L'ancienne carte-enveloppe (« Votre niveau par
/// épreuve » / « … par thème » et leurs phrases de cadrage) est supprimée avec
/// elle. Miroir web : `SITUATION_PLAN_LINK`.
const String kHomeSituationPlanLink = 'Mon plan';

/// La note de pied de carte (maquette du propriétaire, 2026-09-16).
///
/// 🛑 **Elle dit ce qui fait bouger le palier**, et c'est la même règle que la
/// page de résultats : un entraînement libre ou un petit sujet n'y entre pas.
/// Sans elle, un candidat qui vient d'enchaîner des séries lit un niveau
/// inchangé et croit à une panne.
const String kHomeSituationNote =
    'Le niveau affiché évolue uniquement avec vos diagnostics et vos '
    'épreuves complètes.';

/// Ce que propose la ligne d'un thème civique.
///
/// 🛑 **Elle ne démarre rien, et elle ne mène plus au Plan** (demande du
/// propriétaire, 2026-09-19) : elle ouvre **l'historique des examens blancs du
/// thème**, la page qui existe déjà — pendant exact du « Voir mes résultats »
/// d'une épreuve TCF mesurée. Le lanceur de série reste au Plan.
/// Miroir web : `SITUATION_CIVIC_CTA`.
const String kHomeSituationCivicCta = 'Voir mes résultats';

/// L'intitulé de la bande de tête civique.
///
/// 🛑 **Ce n'est PAS « Objectif actuel »** : le civique n'a aucun objectif servi
/// comparable au palier CECRL du TCF. Ce que le serveur sert, c'est le
/// **dernier résultat** et le seuil de son format — la bande le dit, et rien
/// d'autre. Miroir web : `SITUATION_CIVIC_RESULT_LABEL`.
const String kHomeSituationCivicResultLabel = 'Votre dernier résultat';

const String kHomeGoalLabel = 'Objectif actuel';

/// « Atteindre B1 partout ». Le palier est **servi** (`ProgressTcf.objectif`,
/// dérivé de la démarche) — aucun écran ne le devine.
String homeGoalText(String niveau) => 'Atteindre $niveau partout';

// 🛑 `kHomePlanTitle`, `kHomePlanCurrentLabel`, `kHomePlanLink`,
// `kHomeProgressTitle`, `kHomeTracksTitle` et `kHomeTrackLink` sont
// **supprimés** le 2026-09-19 (arbitrage du propriétaire) : l'aperçu « Votre
// Plan », les deux compteurs de « Votre progression » et les lignes de « Vos
// parcours » ont quitté l'Accueil, des deux côtés. Ne pas les recréer.

/* --------------------------------------------- l'action du jour — TCF ----- */

// 🛑 **D-69 (2026-09-28)** : la carte « Découvrez ce qui vous bloque au TCF »
// (`kHomeDiagStart*`, `kHomeStartBadge`, `kHomeLaterCta`,
// `homeDiagStartSubtitle` / `homeDiagStartObjective`) est **supprimée** : sans
// diagnostic, l'Accueil montre l'action du Plan, et le diagnostic n'y est plus
// proposé du tout (la carte « Affinez votre plan » est supprimée elle aussi).
// Ne pas les recréer.

/// Le total d'exercices à rendre, **servi**. Sans lui, l'analyse en cours
/// annonçait « vos deux réponses » sur un diagnostic qui n'en attend qu'une.
String homeDiagAnalyzingObjective(DiagnosticFormat? format) =>
    (format?.hasOral ?? false)
        ? 'Vos deux réponses sont enregistrées ; vous pouvez revenir voir le '
            'résultat.'
        : 'Votre réponse est enregistrée ; vous pouvez revenir voir le '
            'résultat.';

const String kHomeDiagAnalyzingTitle = 'Votre analyse est en préparation';
const String kHomeDiagResumeTitle = 'Reprenez votre diagnostic';
const String kHomeDiagBadge = 'Diagnostic en cours';
const String kHomeDiagResumeObjective =
    'Continuez exactement à l\'étape où vous vous êtes arrêté.';
const String kHomeDiagAnalyzingCta = 'Voir l\'analyse';
const String kHomeDiagResumeCta = 'Reprendre mon diagnostic';

/// « 1 / 2 terminé ». Les **deux** nombres sont servis : le total vient du
/// format du diagnostic, il n'est plus écrit en dur — un diagnostic à une
/// seule production affichait « 1 / 2 » alors qu'il était fini.
String homeDiagCount(int done, int total) =>
    '$done / $total terminé${done > 1 ? 's' : ''}';

const String kHomePriorityBadge = 'Votre priorité du jour';
const String kHomePriorityFallback = 'Continuez votre plan personnalisé';
const String kHomePlanCta = 'Continuer mon plan';
const String kHomeCiviquePlanCta = 'Continuer mon Plan civique';
const String kHomeStartDirectCta = 'Commencer directement';

// ⚠️ `homeExerciseMeta` (« Argumenter · 12 min ») est **supprimé** le
// 2026-09-16 : le sous-titre de la carte d'action vient désormais de
// `planNowCard`, la même autorité que le Plan — l'Accueil ne compose plus de
// repère à lui.

/* ----------------------------------------- l'action du jour — CIVIQUE ----- */

/// Ce que le plan civique a **observé** sur sa cible de rang 1.
const String kHomeCivicObservedLabel = 'Ce que le plan a observé';

// 🛑 `homeWorkedLabel` / `homeMasteredLabel` sont **supprimés** le 2026-09-19
// avec « Votre progression », leur unique lecteur. ⚠️ Les compteurs eux-mêmes
// ne perdent rien : `ProgressCompetences.travaillees` / `maitrisees` et
// `ProgressCivique.grainNotion` restent lus par l'écran **Progrès**
// (`progresCompetencesLabel` / `progresCiviqueLabel`, `progres_labels.dart`),
// qui les dit d'une autre façon. Ne pas recréer une seconde mise en mots ici.

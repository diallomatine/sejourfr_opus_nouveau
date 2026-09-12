/// Les phrases de l'**Accueil** — **pures**, déclarées une fois.
///
/// 🛑 **Miroirs mot pour mot du web** (`web_sejoufr/app/(app)/dashboard/page.tsx`).
/// Le serveur n'expose aucun libellé pour cet écran : il sert des faits, les
/// deux fronts les mettent en mots — et ils doivent les mettre dans les
/// **mêmes** mots, sinon le même compte lit deux prochaines actions selon
/// l'appareil.
library;

/* ------------------------------------------------------------- en-tête --- */

/// « Bonjour Abdoul ». Sans prénom servi, on ne fabrique pas d'identité.
String homeHello(String? firstName) {
  final prenom = firstName?.trim();
  return prenom == null || prenom.isEmpty ? 'Bonjour à vous' : 'Bonjour $prenom';
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
const String kHomePlanTitle = 'Votre Plan';
const String kHomePlanCurrentLabel = 'Priorité actuelle';
const String kHomePlanLink = 'Voir mon Plan';
const String kHomeProgressTitle = 'Votre progression';
const String kHomeTracksTitle = 'Vos parcours';

/// « Expression orale · Tâche 3 ». Le domaine et le rang de la tâche sont
/// **servis** — aucun des deux n'est écrit ici.
String homePlanTaskTitle(String domaine, int tache) =>
    '$domaine · Tâche $tache';

/* --------------------------------------------- l'action du jour — TCF ----- */

const String kHomeDiagStartTitle = 'Découvrez ce qui vous bloque au TCF';
const String kHomeDiagStartSubtitle = '2 exercices · ≈ 8 à 10 min';
const String kHomeStartBadge = 'Votre point de départ';
const String kHomeDiagStartObjective =
    'On analyse votre écrit et votre oral pour construire votre premier plan.';
const String kHomeDiagStartCta = 'Faire mon diagnostic';
const String kHomeLaterCta = 'Plus tard';

const String kHomeDiagAnalyzingTitle = 'Votre analyse est en préparation';
const String kHomeDiagResumeTitle = 'Reprenez votre diagnostic';
const String kHomeDiagBadge = 'Diagnostic en cours';
const String kHomeDiagAnalyzingObjective =
    'Vos deux réponses sont enregistrées ; vous pouvez revenir voir le '
    'résultat.';
const String kHomeDiagResumeObjective =
    'Continuez exactement à l\'étape où vous vous êtes arrêté.';
const String kHomeDiagAnalyzingCta = 'Voir l\'analyse';
const String kHomeDiagResumeCta = 'Reprendre mon diagnostic';

/// « 1 / 2 terminé ». Le compteur est **servi**, jamais recompté ici.
String homeDiagCount(int done) => '$done / 2 terminé${done > 1 ? 's' : ''}';

const String kHomePriorityBadge = 'Votre priorité du jour';
const String kHomePriorityFallback = 'Continuez votre plan personnalisé';
const String kHomePlanCta = 'Continuer mon plan';
const String kHomeCiviquePlanCta = 'Continuer mon Plan civique';
const String kHomeStartDirectCta = 'Commencer directement';

/// « Argumenter · 12 min ». `null` sans exercice désigné : on n'annonce ni
/// titre ni durée qu'on n'a pas.
String homeExerciseMeta(String title, int minutes) => '$title · $minutes min';

/* ----------------------------------------- l'action du jour — CIVIQUE ----- */

/// Ce que le plan civique a **observé** sur sa cible de rang 1.
const String kHomeCivicObservedLabel = 'Ce que le plan a observé';

/* -------------------------------------------------------- progression ----- */

/// Les deux compteurs de la maquette. 🛑 Ils sont **servis**
/// (`GET /api/me/progress`), jamais recomptés — et le civique compte des
/// **notions ou des thèmes** selon ce que le tagging permet, donc son libellé
/// suit le grain **servi** au lieu de dire « compétences » à tort.
String homeWorkedLabel(int n, {required bool civique, required bool notion}) {
  final s = n > 1 ? 's' : '';
  final nom = civique ? (notion ? 'notion' : 'thème') : 'compétence';
  final accord = civique && !notion ? 'travaillé' : 'travaillée';
  return '$nom$s $accord$s';
}

String homeMasteredLabel(int n, {required bool civique, required bool notion}) {
  final s = n > 1 ? 's' : '';
  final nom = civique ? (notion ? 'notion' : 'thème') : 'compétence';
  final accord = civique && !notion ? 'maîtrisé' : 'maîtrisée';
  return '$nom$s $accord$s';
}

/* ----------------------------------------------------------- parcours ----- */

/// Ce que chaque ligne de « Vos parcours » propose. 🛑 Elle mène au **Plan** du
/// module, pas à son hub d'entraînement : c'est ce que dit la maquette, et la
/// bottom nav porte déjà Réviser et Examens.
const String kHomeTrackLink = 'Voir mon Plan';

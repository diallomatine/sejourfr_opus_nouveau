/// Les phrases de l'**Accueil** — **pures**, déclarées une fois.
///
/// 🛑 **Miroirs mot pour mot du web** (`web_sejoufr/app/(app)/dashboard/`).
/// Le serveur n'expose aucun libellé pour cet écran : il sert des faits, les
/// deux fronts les mettent en mots — et ils doivent les mettre dans les
/// **mêmes** mots.
///
/// Navigation v2 (phase 3, 2026-10-03) : textes éditoriaux de la maquette
/// `docs/redesign/sejourfr-navigation-mobile.html`, repris tels quels (R8),
/// sauf quand ils portent une valeur — elle est alors servie.
library;

import '../../core/models/diagnostic_models.dart';

/* ------------------------------------------------------------- en-tête --- */

/// « Bonjour {prénom nom} » — le nom du compte. Sans nom servi, on ne
/// fabrique pas d'identité.
String homeHello(String? firstName, String? lastName) {
  final nom = [firstName?.trim(), lastName?.trim()]
      .whereType<String>()
      .where((part) => part.isNotEmpty)
      .join(' ');
  return nom.isEmpty ? 'Bonjour à vous' : 'Bonjour $nom';
}

/// Le sous-titre statique de la maquette mobile.
const String kHomeLead = 'Tout votre parcours, sans vous demander où aller.';

/// Le bandeau d'un compte **sans démarche déclarée**. C'est la seule chose qui
/// manque pour personnaliser la préparation : on le dit, et on ouvre l'écran
/// qui en est l'autorité.
const String kHomeParcoursBannerTitle = 'Choisissez votre parcours';
const String kHomeParcoursBannerText =
    'CSP, carte de résident ou naturalisation, pour personnaliser votre '
    'préparation.';

/* ----------------------------------------------------- sections de page --- */

const String kHomeObjectivesTitle = 'Mes objectifs';
const String kHomeNowTitle = 'À faire maintenant';

/// Le nom des deux modules, sur les lignes d'objectif et les cartes d'action.
const String kHomeTcfLabel = 'TCF IRN';
const String kHomeCiviqueLabel = 'Examen civique';

/* -------------------------------------------------------- mes objectifs --- */

/// « Atteindre B2 partout ». Le palier est **servi** (`targetLevel`, plancher
/// de la démarche appliqué) — aucun écran ne le devine.
String homeGoalText(String niveau) => 'Atteindre $niveau partout';

const String kHomeTcfObjectiveMeta = 'Progression vers l\'objectif';

/// « B1 → B2 ». Les deux paliers sont servis ; un palier inconnu s'écrit « — ».
String homeTcfObjectiveValue(String actuel, String cible) => '$actuel → $cible';

const String kHomeCiviqueObjectiveTitle = 'Être prêt pour l\'examen';

/// « Objectif : avoir 32/40 » — seuil et nombre de questions de l'examen
/// civique officiel (`CivicExamFormat`, miroir gelé de l'enum serveur).
String homeCiviqueObjectiveMeta(int seuil, int questions) =>
    'Objectif : avoir $seuil/$questions';

/* --------------------------------------------------- à faire maintenant --- */

const String kHomeTcfCta = 'Continuer le TCF';
const String kHomeCiviqueCta = 'Continuer le civique';

/// La méta d'une carte d'action : les morceaux servis, dans l'ordre, joints par
/// « · ». Un morceau absent (durée non servie…) est **omis**, jamais inventé.
/// `null` quand il ne reste rien.
String? homeActionMeta(Iterable<String?> morceaux) {
  final parts = morceaux
      .whereType<String>()
      .where((part) => part.trim().isNotEmpty)
      .toList();
  return parts.isEmpty ? null : parts.join(' · ');
}

/* ------------------------------------------------------ états de bloc --- */

const String kHomeBlockError = 'Ce bloc n\'a pas pu être chargé.';
const String kHomeRetry = 'Réessayer';

/* --------------------------------------- le diagnostic rapide en cours --- */

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
/// format du diagnostic, il n'est plus écrit en dur.
String homeDiagCount(int done, int total) =>
    '$done / $total terminé${done > 1 ? 's' : ''}';

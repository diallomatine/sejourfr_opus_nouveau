import '../../core/router/shell_navigation.dart';

/// **Les phrases des écrans de module et de la barre d'onglets**
/// (Navigation v2, maquette `docs/redesign/sejourfr-navigation-mobile.html`).
/// Textes éditoriaux statiques, repris tels quels (R8) — miroir mot pour mot
/// des libellés de navigation du web.

/* ------------------------------------------------------- barre d'onglets --- */

const String kTabAccueil = 'Accueil';
const String kTabTcf = 'TCF';
const String kTabCivique = 'Civique';
const String kTabProfil = 'Profil';

/* ----------------------------------------------------- en-têtes de module --- */

const String kModuleTcfKicker = 'Préparation TCF IRN';
const String kModuleTcfTitle = 'Mon TCF';
const String kModuleTcfLead = 'Plan, entraînement et examens au même endroit.';

const String kModuleCiviqueKicker = 'Préparation civique';
const String kModuleCiviqueTitle = 'Examen civique';
const String kModuleCiviqueLead =
    'Révisez les thèmes officiels et mesurez votre maîtrise.';

/* -------------------------------------------------------------- segments --- */

/// Les mêmes trois libellés pour le TCF et le civique (D1-A).
String moduleSegmentLabel(ModuleSegment segment) => switch (segment) {
      ModuleSegment.plan => 'Plan',
      ModuleSegment.entrainement => 'Entraînement',
      ModuleSegment.examens => 'Examens',
    };

/* ----------------------------------------------- carte « Ma progression » --- */

/// Le lien de tête de « Priorités actuelles » (Plan des deux modules) vers le
/// segment Entraînement. Miroir de `PLAN_PRIORITES_ACTION` (web).
const String kPlanPrioritesAction = 'Tout l\'entraînement';

const String kModuleProgressLabel = 'Ma progression';
const String kModuleProgressAction = 'Voir le détail';

/// Une valeur absente s'écrit « — » : *null = inconnu, jamais mauvais*.
const String kModuleProgressUnknown = '—';

/// « Objectif : B2 dans les 4 compétences » — palier visé et nombre
/// d'épreuves officielles, tous deux lus, jamais écrits ici.
String moduleTcfProgressMeta(String cible, int epreuves) =>
    'Objectif : $cible dans les $epreuves compétences';

/// « 17 séries terminées » / « 1 série terminée » / « 0 série terminée ».
String moduleCiviqueProgressMeta(int terminees) =>
    terminees > 1 ? '$terminees séries terminées' : '$terminees série terminée';

/// « 39 % » — le pourcentage d'avancement en séries, déjà calculé.
String moduleCiviqueProgressValue(int pourcentage) => '$pourcentage %';

/* -------------------------------------------- segment « Entraînement » --- */

/// Le titre de la grille des épreuves TCF (maquette mobile, R8).
const String kModuleTcfEpreuvesTitle = 'Choisir une épreuve';

/// Le geste d'une tuile d'épreuve (`.metric`) : il ouvre le hub existant.
const String kModuleTrainCta = "S'entraîner";

/// Le geste d'une carte de thème (`.theme-card`) : il ouvre le hub du thème.
const String kModuleThemeCta = 'Continuer';

/// « {terminées}/{total} séries » — l'avancement civique en séries, déjà calculé par
/// `avancementSeriesCivique` (jamais recompté ici).
String moduleCiviqueSeriesBadge(int terminees, int total) =>
    '$terminees/$total séries';

/// Le hero « Entretien en temps réel » (D3 B) : texte éditorial de la
/// maquette, il mène au hub de l'expression orale — aucune donnée inventée.
const String kModuleRealtimeTitle = 'Entretien en temps réel';
const String kModuleRealtimeLabel = "Simulation d'entretien · IA";
const String kModuleRealtimeHeadline = "Entraînez-vous comme à l'examen";
const String kModuleRealtimeSub =
    'Répondez à des consignes et des relances dans un format vivant : '
    'réactivité, aisance, confiance.';
const String kModuleRealtimeStat = 'expression orale';
const String kModuleRealtimeCta = 'Lancer une simulation';

/* ------------------------------------------------------ états de bloc --- */

/// L'erreur d'un bloc des écrans de navigation v2 (brief §7) : le bloc le
/// dit, le reste de l'écran reste utilisable. Une seule chaîne pour l'Accueil,
/// les cartes « Ma progression » et les segments des modules.
const String kModuleBlockError = 'Ce bloc n\'a pas pu être chargé.';
const String kModuleRetry = 'Réessayer';

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

import '../../core/models/enums.dart';
import '../../core/models/tcf_diagnostic_models.dart';

/// Règles d'affichage du diagnostic TCF 4 épreuves — **pures**, déclarées une
/// fois pour tout le mobile.
///
/// 🛑 Le serveur n'expose que des **faits** (état d'une section, niveau, rang
/// d'une priorité). Les phrases vivent ici, et sont des **miroirs mot pour mot**
/// de `web_sejoufr/lib/tcf-diagnostic.ts` : un libellé qui bouge, ce sont deux
/// fichiers dans la même passe.
///
/// 🛑 Ce fichier ne **dérive** aucun état pédagogique : `etat` et `niveau`
/// arrivent servis. Il ne fait que les mettre en mots.

/// Titre de la page. « Diagnostic TCF », jamais « examen blanc » (`10_` §4.1).
const String kTcfDiagnosticTitle = 'Diagnostic TCF';
const String kTcfDiagnosticSubtitle =
    '4 épreuves, à faire séparément quand vous voulez.';

/// Le résultat n'arrive qu'à la fin — c'est dit avant, pas découvert après.
const String kTcfDiagnosticResultNote =
    'Votre résultat complet s\'affichera une fois les 4 sections terminées.';

/// Une section commencée se termine d'une traite (`10_` §4.2). L'écran le dit
/// **avant** de lancer, pas après.
const String kTcfDiagnosticSectionWarning =
    'Une fois commencée, cette section se termine d\'une traite.';

/// Le micro est annoncé avant l'oral, jamais demandé par surprise.
const String kTcfDiagnosticMicWarning = 'Cette section utilise votre micro.';

const String kTcfDiagnosticEstimationNote =
    'Estimation SejourFR, non officielle.';

/// 🛑 Le délai écoulé n'est **pas** une perte : les sections faites comptent
/// toujours, les autres restent « non évaluée ». Le message doit le dire.
const String kTcfDiagnosticRepriseEcoulee =
    'Le délai de reprise est écoulé. Nous calculerons votre résultat sur les sections terminées.';

/// 🛑 `null` = inconnu, jamais un palier plancher. Afficher « A1 » sur une
/// épreuve non passée serait un verdict que personne n'a rendu.
const String kNiveauNonEvalue = 'Non évaluée';

const String kTcfDiagnosticRassuranceTitle =
    'Vous n\'avez pas besoin de tout retravailler';
const String kTcfDiagnosticDejaTitle = 'Déjà au niveau attendu';
const String kTcfDiagnosticPlanCta = 'Découvrir mon plan';
const String kTcfDiagnosticStartCta = 'Commencer mon diagnostic';
const String kTcfDiagnosticResultCta = 'Voir mon résultat';

/// Le bouton dit ce qui va se passer.
String sectionCtaLabel(TcfDiagnosticSectionState etat) => switch (etat) {
      TcfDiagnosticSectionState.aFaire => 'Commencer',
      TcfDiagnosticSectionState.enCours => 'Reprendre',
      TcfDiagnosticSectionState.terminee => 'Terminée',
    };

String sectionEtatLabel(TcfDiagnosticSectionState etat) => switch (etat) {
      TcfDiagnosticSectionState.aFaire => 'À faire',
      TcfDiagnosticSectionState.enCours => 'En cours',
      TcfDiagnosticSectionState.terminee => 'Terminée',
    };

/// Libellé et pictogramme d'une épreuve. Table unique du mobile pour cet écran.
({String icon, String label}) epreuvePresentation(EpreuveType e) => switch (e) {
      EpreuveType.tcfCo => (icon: '🎧', label: 'Compréhension orale'),
      EpreuveType.tcfCe => (icon: '📖', label: 'Compréhension écrite'),
      EpreuveType.tcfEe => (icon: '✍️', label: 'Expression écrite'),
      EpreuveType.tcfEo => (icon: '🎙️', label: 'Expression orale'),
      _ => (icon: '•', label: e.wire),
    };

/// « 2 sections sur 4 terminées ». Compté sur ce que le serveur a servi.
String progressionLabel(TcfDiagnosticDto d) {
  final faites = d.sections
      .where((s) => s.etat == TcfDiagnosticSectionState.terminee)
      .length;
  final total = d.sections.length;
  final pluriel = faites > 1 ? 's' : '';
  return '$faites section$pluriel sur $total terminée$pluriel';
}

/// Toutes les sections existantes sont closes ⇒ le résultat est demandable.
bool resultatDisponible(TcfDiagnosticDto d) {
  final existantes = d.sections.where((s) => s.attemptId != null).toList();
  if (existantes.isEmpty) return false;
  return existantes.every((s) => s.etat == TcfDiagnosticSectionState.terminee);
}

/// Section absente du diagnostic (aucun contenu en base).
///
/// 🛑 Le candidat ne doit **jamais** voir qu'il manque du contenu (`00_` §7.4) :
/// on la nomme « non évaluée », comme une épreuve qu'il n'a pas passée.
bool sectionIndisponible(TcfDiagnosticSectionDto s) => s.attemptId == null;

/// Le décompte de jours restants, calculé à l'affichage et jamais persisté.
int joursRestants(DateTime expiresAt, {DateTime? now}) {
  final reste = expiresAt.difference(now ?? DateTime.now());
  final jours = (reste.inMinutes / (60 * 24)).ceil();
  return jours < 0 ? 0 : jours;
}

/// Titre du bloc de conversion, contextualisé par la cible servie.
String blocageTitle(NiveauCecrl? cible) => cible == null
    ? 'Ce qui vous limite aujourd\'hui'
    : 'Ce qui vous empêche aujourd\'hui d\'atteindre ${cible.wire}';

/// « Priorité 1 — Expression orale, tâche 3 ». La tâche est nommée, jamais la
/// compétence : `eo_nuancer` ne se comprend pas, « tâche 3 » si.
String prioriteTitle(int rang, String epreuveLabel, String? taskCode) {
  final tache = taskCode == null
      ? ''
      : ', tâche ${taskCode.substring(taskCode.length - 1)}';
  return 'Priorité $rang — $epreuveLabel$tache';
}

String rassuranceText(NiveauCecrl? cible) => cible == null
    ? 'Votre plan se concentrera d\'abord sur les tâches qui ont le plus d\'impact.'
    : 'Votre plan se concentrera d\'abord sur les tâches qui ont le plus d\'impact pour atteindre ${cible.wire}.';

/// Le paramètre que les écrans de passation reçoivent quand la section
/// appartient à un diagnostic.
///
/// 🛑 **Sa seule fonction est le RETOUR** : une section de diagnostic ramène à
/// l'accueil des 4 sections, jamais au bilan individuel — exactement comme une
/// épreuve d'examen complet ramène à son hub. Il ne change rien d'autre : ni la
/// passation, ni la notation, ni le chrono.
///
/// Miroir de `TCF_DIAGNOSTIC_PARAM` (`web_sejoufr/lib/tcf-diagnostic.ts`).
const String kTcfDiagnosticParam = 'tcfDiagnosticId';

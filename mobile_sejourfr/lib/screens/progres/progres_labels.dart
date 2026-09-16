import '../../core/models/progress_models.dart';

/// Les **mots** de l'écran Progrès (T28, `30_` §7) — **purs**, déclarés une
/// fois pour tout le mobile.
///
/// 🛑 **Le serveur n'expose que des faits** : un palier, un sens d'évolution, un
/// compte de jours. Les phrases vivent ici, et sont des **miroirs mot pour mot**
/// de `web_sejoufr/lib/progres.ts`.
///
/// 🛑 **Deux règles de la spec que ce fichier fait respecter** :
/// - **aucun pourcentage de progression vers un palier** — un palier CECRL
///   n'est pas une barre ;
/// - **aucune gamification** — l'activité se dit en jours travaillés, sans
///   record à battre.

const String kProgresTitle = 'Ce qui a bougé';
const String kProgresLead =
    'Votre mouvement depuis votre diagnostic — pas un tableau de bord.';

const String kProgresNiveauTitle = 'Votre niveau';
const String kProgresEpreuvesTitle = 'Par épreuve';
const String kProgresCompetencesTitle = 'Vos compétences';
const String kProgresCompetencesLocked =
    'Le détail de vos compétences tenues fait partie de l\'abonnement. '
    'Vos compteurs, eux, restent les vôtres.';
const String kProgresActiviteTitle = 'Votre activité';

/// Bloc 5 — 🛑 un LIEN, pas une seconde liste.
const String kProgresHistoriqueTitle = 'Vos rapports';
const String kProgresHistoriqueText =
    'Vos examens et vos productions restent consultables.';

const String kProgresCiviqueTitle = 'Examen civique';

/// Le détail par thème du civique.
///
/// 🛑 Le libellé d'un état vient de `CivicThemeState.label` et son ton de
/// `civicThemeTone` (`screens/plan/civic_plan_labels.dart`) : ce sont les
/// **autorités déjà en place** pour cet enum, employées aussi par le Plan et le
/// rapport de diagnostic. Une seconde table finirait par nommer autrement le
/// même état.
const String kProgresCiviqueThemesTitle = 'Par thème';

/// État vide (`30_` §7).
const String kProgresVideText =
    'Votre progression s\'affichera après votre premier diagnostic.';

/// Le niveau et son objectif. 🛑 **Aucun pourcentage** : on nomme deux paliers,
/// on ne trace pas une barre entre eux.
String? progresNiveauLabel(ProgressTcf tcf) {
  final actuel = tcf.niveauActuel;
  if (actuel == null) return null;
  final objectif = tcf.objectif;
  return objectif == null
      ? actuel.displayName
      : '${actuel.displayName} → objectif ${objectif.displayName}';
}

/// Le marqueur d'évolution d'une épreuve.
///
/// 🛑 **`inconnue` ne rend rien** — surtout pas « = » : une épreuve non
/// comparable n'a ni progressé ni tenu, et lui donner le signe de la stabilité
/// déguiserait une absence de mesure en bonne nouvelle.
///
/// 🛑 **`baisse` se dit.** La masquer rendrait la mesure de progression
/// invendable.
String? progresEvolutionLabel(ProgressEpreuve epreuve) {
  final initial = epreuve.niveauInitial;
  return switch (epreuve.evolution) {
    NiveauEvolution.hausse =>
      initial == null ? '↑' : '↑ depuis ${initial.displayName}',
    NiveauEvolution.baisse =>
      initial == null ? '↓' : '↓ depuis ${initial.displayName}',
    NiveauEvolution.stable => '=',
    NiveauEvolution.inconnue => null,
  };
}

/// Le ton du marqueur. `inconnue` et `stable` restent **neutres**.
enum ProgresEvolutionTone { up, down, flat }

ProgresEvolutionTone progresEvolutionTone(NiveauEvolution evolution) =>
    switch (evolution) {
      NiveauEvolution.hausse => ProgresEvolutionTone.up,
      NiveauEvolution.baisse => ProgresEvolutionTone.down,
      NiveauEvolution.stable ||
      NiveauEvolution.inconnue =>
        ProgresEvolutionTone.flat,
    };

/// « B2 » ou « Non évaluée ». 🛑 Jamais « A1 » pour une absence de mesure.
String progresEpreuveNiveau(ProgressEpreuve epreuve) =>
    epreuve.niveau?.displayName ?? 'Non évaluée';

/// Libellés **gelés** du statut d'une épreuve face à l'objectif (spec V2 §2),
/// miroirs mot pour mot de `PROGRES_STATUT_LABEL` côté web.
///
/// 🛑 Le statut est **servi** : ce fichier ne fait que poser un mot dessus.
/// Aucun front ne compare deux paliers CECRL.
const Map<StatutObjectif, String> kProgresStatutLabel = {
  StatutObjectif.targetReached: 'Objectif atteint',
  StatutObjectif.closeToTarget: 'Proche de l\'objectif',
  StatutObjectif.toReinforce: 'À renforcer',
};

/// Le statut d'une épreuve, dit au candidat.
///
/// 🛑 **Une épreuve jamais mesurée ne se dit PAS « à renforcer »** : le serveur
/// la range bien dans `TO_REINFORCE`, mais son `niveau` vaut `null` et c'est ce
/// qu'il faut lire — « À évaluer ». Fondre les deux cas dans le même mot
/// rejouerait l'incident V040/V041/V042, où une absence de mesure était devenue
/// un verdict.
///
/// `null` quand aucune démarche n'est déclarée : sans objectif, rien à situer.
String? progresStatutLabel(ProgressEpreuve epreuve) {
  final statut = epreuve.status;
  if (statut == null) return null;
  if (epreuve.niveau == null) return 'À évaluer';
  return kProgresStatutLabel[statut];
}

/// Le ton du statut. `muted` = non mesuré, ou sans objectif — pas un degré de
/// gravité de plus.
enum ProgresStatutTone { ok, warn, hot, muted }

ProgresStatutTone progresStatutTone(ProgressEpreuve epreuve) {
  final statut = epreuve.status;
  if (statut == null || epreuve.niveau == null) return ProgresStatutTone.muted;
  return switch (statut) {
    StatutObjectif.targetReached => ProgresStatutTone.ok,
    StatutObjectif.closeToTarget => ProgresStatutTone.warn,
    StatutObjectif.toReinforce => ProgresStatutTone.hot,
  };
}

/// « 4 compétences maîtrisées sur 11 travaillées ».
///
/// `null` quand rien n'a jamais été observé : « 0 sur 0 » ne dit rien.
String? progresCompetencesLabel(ProgressCompetences competences) {
  if (competences.travaillees <= 0) return null;
  final m = competences.maitrisees;
  final t = competences.travaillees;
  return '$m compétence${m > 1 ? 's' : ''} maîtrisée${m > 1 ? 's' : ''} '
      'sur $t travaillée${t > 1 ? 's' : ''}';
}

/// « 12 jours travaillés sur les 28 derniers ».
///
/// 🛑 La fenêtre vient du **serveur** : aucun écran n'écrit « 30 » en dur.
String progresActiviteLabel(ProgressActivite activite) {
  final j = activite.joursActifs;
  return '$j jour${j > 1 ? 's' : ''} travaillé${j > 1 ? 's' : ''} '
      'sur les ${activite.fenetreJours} derniers';
}

/// La régularité, dite sans jugement. 🛑 Ni objectif, ni série à tenir.
String? progresRegulariteLabel(ProgressActivite activite) {
  if (activite.semaines.isEmpty) return null;
  final actives = activite.semaines.where((s) => s.jours > 0).length;
  if (actives == 0) return null;
  return '$actives semaine${actives > 1 ? 's' : ''} sur ${activite.semaines.length} '
      'avec au moins une séance';
}

/// « 3 notions tenues sur 12 travaillées », ou « thèmes » tant que le tagging
/// n'a pas basculé.
///
/// 🛑 L'écran **nomme** ce qu'il compte : le plan civique ne se dit jamais plus
/// précis qu'il ne l'est.
String? progresCiviqueLabel(ProgressCivique civique) {
  if (civique.travaillees <= 0) return null;
  final nom = civique.grainNotion ? 'notion' : 'thème';
  final m = civique.maitrisees;
  final t = civique.travaillees;
  return '$m $nom${m > 1 ? 's' : ''} tenu${m > 1 ? 's' : ''} '
      'sur $t travaillé${t > 1 ? 's' : ''}';
}

/// Le dernier score civique, comparable au seuil. `null` s'il n'y en a aucun.
String? progresCiviqueScore(ProgressCivique civique) {
  if (civique.historique.isEmpty) return null;
  final dernier = civique.historique.last;
  return '${dernier.bonnes} / ${dernier.posees} · '
      'seuil ${dernier.seuil} / ${dernier.format}';
}

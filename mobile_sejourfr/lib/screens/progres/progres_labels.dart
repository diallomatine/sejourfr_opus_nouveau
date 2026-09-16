import '../../core/models/enums.dart';
import '../../core/models/progress_models.dart';
import '../../core/widgets/sejour/sejour_kit.dart';

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
  if (epreuve.niveau == null) return kNonMesureLabel;
  return kProgresStatutLabel[statut];
}

/// Le mot d'une chose **jamais mesurée** — épreuve sans palier, thème civique
/// `NON_EVALUE`.
///
/// 🛑 **Un seul endroit** : il vit sur la pastille d'une carte d'accueil, sur
/// le statut d'une épreuve de Progrès et sur les thèmes civiques. Recopié, il
/// finirait par diverger d'une surface à l'autre — et c'est le mot qui empêche
/// une absence de mesure de se lire comme un verdict (V040/V041/V042). Miroir
/// web : `NON_MESURE_LABEL`.
const String kNonMesureLabel = 'À évaluer';

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

/// ---------------------------------------------------------------------------
/// « Où vous en êtes » — la carte compacte d'une épreuve sur l'ACCUEIL
/// ---------------------------------------------------------------------------
///
/// 🛑 **Une seule dérivation pour les deux écrans.** Progrès dit « où vous en
/// êtes face à l'objectif » ; l'Accueil dit la même chose **plus ce qu'il faut
/// faire**. Deux tables auraient fini par nommer différemment le même statut
/// servi, sur deux écrans que le candidat voit dans la même minute — c'est le
/// défaut le plus cher du dépôt.
///
/// 🛑 **Rien n'est classé ici.** Les deux seuls faits lus sont **servis** :
/// `status` ([StatutObjectif], dérivé par `StatutObjectifResolver`) et
/// `evolution` ([NiveauEvolution], dérivé par
/// `TcfDiagnosticProgressionResolver`). Aucun nombre n'entre, aucun palier
/// n'est comparé à un autre.
///
/// 🛑 **Miroir mot pour mot de `accueilEpreuveEtat` côté web**
/// (`web_sejoufr/lib/progres.ts`).
enum AccueilEpreuveEtat {
  /// Jamais mesurée. 🛑 Elle ne se dit **jamais** « à renforcer » : le serveur
  /// la range bien dans `TO_REINFORCE`, mais son niveau vaut `null` et c'est ce
  /// qu'il faut lire (V040/V041/V042).
  aEvaluer,

  /// Mesurée, et le palier a **monté** depuis la première mesure. 🛑 Ce cas
  /// passe **avant** le statut : dire « à renforcer » à quelqu'un qui vient de
  /// progresser lui cache la seule bonne nouvelle qu'il a.
  enProgression,

  /// Au niveau visé, ou au-dessus.
  solide,

  /// Un cran sous l'objectif.
  proche,

  /// Mesurée, et loin de l'objectif.
  aRenforcer,

  /// Mesurée, mais aucune démarche déclarée : rien vers quoi situer.
  sansObjectif,
}

/// L'état d'une épreuve **sur l'Accueil**, dans l'ordre où il se décide.
AccueilEpreuveEtat accueilEpreuveEtat(ProgressEpreuve epreuve) {
  if (epreuve.niveau == null) return AccueilEpreuveEtat.aEvaluer;
  if (epreuve.evolution == NiveauEvolution.hausse) {
    return AccueilEpreuveEtat.enProgression;
  }
  return switch (epreuve.status) {
    null => AccueilEpreuveEtat.sansObjectif,
    StatutObjectif.targetReached => AccueilEpreuveEtat.solide,
    StatutObjectif.closeToTarget => AccueilEpreuveEtat.proche,
    StatutObjectif.toReinforce => AccueilEpreuveEtat.aRenforcer,
  };
}

/// La phrase courte de la carte. `null` = rien à dire, pas « rien à faire ».
///
/// 🛑 [AccueilEpreuveEtat.proche] et [AccueilEpreuveEtat.aRenforcer] reprennent
/// **les libellés gelés** de [kProgresStatutLabel] : même statut servi, même
/// mot, d'un écran à l'autre.
String? accueilEpreuveStatut(ProgressEpreuve epreuve) =>
    switch (accueilEpreuveEtat(epreuve)) {
      AccueilEpreuveEtat.aEvaluer => 'Pas encore évaluée',
      AccueilEpreuveEtat.enProgression => 'En progression',
      AccueilEpreuveEtat.solide => 'Solide · à maintenir',
      AccueilEpreuveEtat.proche =>
        kProgresStatutLabel[StatutObjectif.closeToTarget],
      AccueilEpreuveEtat.aRenforcer =>
        kProgresStatutLabel[StatutObjectif.toReinforce],
      AccueilEpreuveEtat.sansObjectif => null,
    };

/// La pastille de niveau. « À évaluer » quand rien n'a été mesuré.
///
/// 🛑 [NiveauCecrl.shortName] et jamais un troncage maison : `A1_NON_ATTEINT`
/// se rend « &lt;A1 », pas « A1 ».
String accueilEpreuveBadge(ProgressEpreuve epreuve) =>
    epreuve.niveau?.shortName ?? kNonMesureLabel;

/// Ce que la carte propose de faire.
///
/// 🛑 **Dérivé de l'état, jamais un texte fixe** : une épreuve jamais mesurée
/// ne propose pas de « voir » des résultats qui n'existent pas, et une épreuve
/// qui monte propose de continuer plutôt que de relire.
String accueilEpreuveCta(ProgressEpreuve epreuve) =>
    switch (accueilEpreuveEtat(epreuve)) {
      AccueilEpreuveEtat.aEvaluer => 'Faire un exercice',
      AccueilEpreuveEtat.enProgression => 'Continuer',
      _ => 'Voir mes résultats',
    };

/// La carte mène-t-elle à un **exercice** plutôt qu'aux résultats ?
///
/// 🛑 Le chemin d'un exercice est celui du Plan, jamais un second : c'est la
/// fiche du domaine qui porte les lanceurs.
bool accueilEpreuveOuvreLExercice(ProgressEpreuve epreuve) {
  final etat = accueilEpreuveEtat(epreuve);
  return etat == AccueilEpreuveEtat.aEvaluer ||
      etat == AccueilEpreuveEtat.enProgression;
}

/// Le ton de la jauge et du statut.
SfBarTone accueilEpreuveTon(ProgressEpreuve epreuve) =>
    switch (accueilEpreuveEtat(epreuve)) {
      AccueilEpreuveEtat.aEvaluer ||
      AccueilEpreuveEtat.sansObjectif =>
        SfBarTone.muted,
      AccueilEpreuveEtat.enProgression => SfBarTone.now,
      AccueilEpreuveEtat.solide => SfBarTone.ok,
      AccueilEpreuveEtat.proche => SfBarTone.warn,
      AccueilEpreuveEtat.aRenforcer => SfBarTone.hot,
    };

/// Le remplissage de la jauge.
///
/// 🛑 **Ce n'est PAS un pourcentage de progression vers un palier** — la règle
/// qui l'interdit (`30_` §7) tient toujours, et aucun chiffre n'est affiché.
/// C'est le **codage visuel d'un état servi**, à cinq positions fixes : la
/// barre dit la même chose que le mot juste en dessous, elle ne mesure rien de
/// plus. Un palier CECRL n'est toujours pas une barre.
double accueilEpreuveJauge(ProgressEpreuve epreuve) =>
    switch (accueilEpreuveEtat(epreuve)) {
      AccueilEpreuveEtat.aEvaluer || AccueilEpreuveEtat.sansObjectif => 0,
      AccueilEpreuveEtat.aRenforcer => 0.35,
      AccueilEpreuveEtat.enProgression => 0.55,
      AccueilEpreuveEtat.proche => 0.75,
      AccueilEpreuveEtat.solide => 1,
    };

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

import '../../core/models/civic_diagnostic_models.dart';
import '../../core/models/civic_plan_models.dart';
import '../../core/models/dashboard_models.dart';
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

/// L'écran a-t-il **vraiment** l'écran vide ?
///
/// 🛑 **Ce n'est plus `!tcf.disponible && !civique.disponible`** (2026-09-16) :
/// depuis que les 4 épreuves sont servies indépendamment du diagnostic
/// 4 épreuves, un candidat dont la CO est mesurée par un examen de module a de
/// quoi remplir le bloc « Par épreuve ». Garder l'ancienne condition aurait
/// affiché « votre progression s'affichera après votre premier diagnostic »
/// juste au-dessus de sa progression.
///
/// 🛑 **Rien n'est classé ici** : on lit trois faits servis — deux booléens et
/// la présence d'un palier. Miroir de `progresEcranVide` côté web.
bool progresEcranVide(ProgressTcf tcf, ProgressCivique civique) =>
    !tcf.disponible &&
    !civique.disponible &&
    tcf.epreuves.every((e) => e.niveau == null);

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

/* ------------------------ L'AUTORITÉ D'AFFICHAGE du niveau d'une épreuve --- */

/// **Le niveau ACTUEL d'une épreuve, tel qu'il est AFFICHÉ partout.**
///
/// 🛑 **L'autorité d'affichage, et elle seule** : `tcfDomainProfile` publie le
/// niveau de `TcfProfileService.levelProfileAccueil` — la **moyenne des ≤ 3
/// derniers examens qualifiants** —, exactement ce que disent l'Accueil, le
/// Profil, le Diagnostic et Réviser. Les écrans de suivi lisaient
/// `DashboardCategoryStat.level`, une **troisième** autorité (le dernier
/// niveau CECRL de n'importe quelle soumission, **entraînements compris**) :
/// un candidat dont la seule trace EO était un entraînement de trois minutes y
/// lisait un palier pendant que tous les autres écrans disaient « à évaluer ».
/// → `docs/decisions/diagnostic.md`, 2026-09-16.
///
/// 🛑 **`null` = pas mesuré, jamais un plancher** : la ligne retombe alors sur
/// ce que son écran sait **compter**.
///
/// Le code de catégorie **est** la valeur de `epreuve` pour les quatre
/// épreuves : aucune table de correspondance n'est écrite ici.
/// `TCF_STRUCTURE` et les thèmes civiques n'y figurent pas — ils rendent
/// `null`, ce qui est exact : aucun palier CECRL ne leur est servi.
///
/// 🛑 **Miroir de `niveauActuelEpreuve` côté web** (`lib/progres.ts`).
NiveauCecrl? niveauActuelEpreuve(TcfDomainProfile? profil, String code) {
  for (final domaine in profil?.domaines ?? const <TcfDomain>[]) {
    if (domaine.epreuve.wire == code) return domaine.niveau;
  }
  return null;
}

/// 🛑 Miroir web : `SUIVI_SANS_EXAMEN_LABEL`.
const String kSuiviSansExamenLabel = "Pas encore d'examen";

/// La ligne de niveau d'une épreuve sur un écran de **suivi chiffré**
/// (écran Progrès, `/statistiques`) — jamais sur un écran de constat.
///
/// 🛑 **Non mesurée ⇒ aucun palier inventé.** On ne dit pas « À évaluer » ici,
/// qui est le mot d'un constat (l'Accueil) : on dit ce qui **manque à
/// compter** — aucun examen qualifiant n'a encore été passé.
String suiviNiveauLabel(NiveauCecrl? niveau) => niveau == null
    ? kSuiviSansExamenLabel
    : 'Niveau estimé ${niveau.displayName}';

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
      AccueilEpreuveEtat.aEvaluer => 'Évaluer mon niveau',
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

/// Le ton du statut — la pastille colorée devant l'état, sur la ligne d'épreuve.
///
/// ⚠️ Il ne teinte plus de jauge depuis le 2026-09-16 : `accueilEpreuveJauge`
/// est **supprimée**, l'échelle CECRL ayant pris la place du rail. Une jauge à
/// cinq positions fixes disait la même chose que le mot juste à côté ;
/// l'échelle, elle, situe un palier servi.
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

/* ------ L'ÉCHELLE CECRL d'une ligne d'épreuve (maquette v2, 2026-09-16) ---- */

/// Les **quatre crans** de l'échelle : A1 · A2 · B1 · B2.
///
/// 🛑 **L'échelle s'arrête à B2**, comme partout ailleurs dans le produit : le
/// profil TCF IRN ne délivre jamais au-delà, et `CecrlScale` n'affiche déjà que
/// A1 → B2. ⚠️ La maquette du propriétaire en montrait **six**, C1 et C2
/// compris, grisés et hors d'atteinte — il a **tranché pour la règle** le
/// 2026-09-16, en cours de passe : deux paliers que la notation ne rend jamais
/// n'ont rien à faire sur l'échelle d'un candidat.
///
/// 🛑 **Ce n'est pas une seconde autorité** : la position d'un palier se lit
/// par [NiveauCecrl.scaleIndex], la même que le rail des bilans — d'où le
/// rabattement de C1/C2 sur B2 pour relire un historique sans mentir.
///
/// Miroir web : `ACCUEIL_ECHELLE_CECRL`.
const List<NiveauCecrl> kAccueilEchelleCecrl = [
  NiveauCecrl.a1,
  NiveauCecrl.a2,
  NiveauCecrl.b1,
  NiveauCecrl.b2,
];

/// Les quatre crans d'une épreuve, **composés** pour le kit.
///
/// 🛑 **Rien n'est classé ici** : on pose deux paliers **servis** — celui de
/// l'épreuve et l'objectif de la démarche — sur une échelle fixe. Aucun nombre
/// n'entre, aucune note n'est convertie.
///
/// 🛑 **`a1NonAtteint` n'allume AUCUN cran** : le candidat n'a atteint aucun
/// des quatre paliers, et allumer A1 lui annoncerait celui qu'il n'a justement
/// pas. La pastille dit « &lt;A1 » et l'échelle reste vide — on ne ment jamais
/// vers le haut. ⚠️ Ce **n'est pas** le rendu d'une épreuve non mesurée : la
/// ligne garde son fond blanc, son repère plein et ses crans pleins mais
/// éteints, là où une épreuve à évaluer passe en contour.
///
/// Miroir web : `accueilEchelons`.
/// Le rang d'un palier **servi** sur l'échelle de l'Accueil.
///
/// C'est [NiveauCecrl.scaleIndex] — la même table que le rail des bilans — plus
/// la seule garde qui manque ici : `a1NonAtteint` y vaut **0**, parce que cette
/// barre-là n'a que quatre libellés et confond « A1 » avec « A1 non atteint ».
/// Sur une échelle qui **remplit** les crans, cette confusion allumerait A1.
/// Miroir exact de `cecrlIndex` côté web, qui rend -1 pour ce cas.
int _accueilRangCecrl(NiveauCecrl? niveau) =>
    niveau == null || niveau == NiveauCecrl.a1NonAtteint
        ? -1
        : niveau.scaleIndex;

List<SfLadderStep> accueilEchelons(
  ProgressEpreuve epreuve,
  NiveauCecrl? objectif,
) {
  final atteint = _accueilRangCecrl(epreuve.niveau);
  final vise = _accueilRangCecrl(objectif);
  return [
    for (var rang = 0; rang < kAccueilEchelleCecrl.length; rang++)
      SfLadderStep(
        label: kAccueilEchelleCecrl[rang].shortName,
        state: rang <= atteint
            ? SfLadderState.done
            : rang == vise
                ? SfLadderState.target
                : SfLadderState.empty,
        current: rang == atteint,
        goal: rang == vise,
      ),
  ];
}

/// **Les quatre paliers de l'échelle**, pour la légende rendue une seule fois
/// au-dessus de la liste (2026-09-17).
///
/// 🛑 **La même table que les crans** (`kAccueilEchelleCecrl`) : deux listes de
/// paliers finiraient par ne plus se superposer. Miroir web :
/// `accueilEchelleLegende`.
List<String> accueilEchelleLegende() =>
    [for (final niveau in kAccueilEchelleCecrl) niveau.shortName];

/// Le rang du palier **visé** sur cette échelle, ou `null` sans démarche
/// déclarée — le seul repère que les libellés par ligne portaient et qui dise
/// quelque chose, et il est **global** aux quatre épreuves.
///
/// Miroir web : `accueilEchelleRangObjectif`.
int? accueilEchelleRangObjectif(NiveauCecrl? objectif) {
  final rang = _accueilRangCecrl(objectif);
  return rang < 0 ? null : rang;
}

/// Ce que l'échelle dit à un lecteur d'écran — elle est rendue en image, ses
/// libellés sont décoratifs.
///
/// 🛑 **« &lt;A1 » se DIT**, il ne se lit pas : « Niveau inférieur à A1 ».
///
/// Miroir web : `accueilEchelleLabel`.
String accueilEchelleLabel(ProgressEpreuve epreuve, NiveauCecrl? objectif) {
  final niveau = epreuve.niveau;
  final debut = niveau == null
      ? 'Non évaluée'
      : niveau == NiveauCecrl.a1NonAtteint
          ? 'Niveau inférieur à A1'
          : 'Niveau ${niveau.shortName}';
  return objectif == null ? debut : '$debut, objectif ${objectif.shortName}';
}

/// Le compteur du bandeau d'objectif — « 3 / 4 » et ses pastilles.
///
/// 🛑 **On compte des mesures, on n'en classe aucune** : le seul fait lu est la
/// présence d'un `niveau` servi. Le total est la liste servie elle-même, jamais
/// un « 4 » écrit en dur — c'est le serveur qui décide combien d'épreuves il
/// publie, et c'est lui qui pose le nombre de pastilles.
///
/// ⚠️ **Remplace `accueilEvalueesLabel`** (2026-09-16) : la maquette v2 rend le
/// compte, les pastilles et le mot séparément — une chaîne « 3 / 4 évaluées »
/// ne se découpe pas.
///
/// Miroir web : `accueilEvaluees`.
({int faites, int total})? accueilEvaluees(List<ProgressEpreuve> epreuves) {
  if (epreuves.isEmpty) return null;
  return (
    faites: epreuves.where((e) => e.niveau != null).length,
    total: epreuves.length,
  );
}

/// Le mot sous le compteur du bandeau. Miroir web : `ACCUEIL_EVALUEES_CAPTION`.
const String kAccueilEvalueesCaption = 'évaluées';

/// Le compteur du bandeau **civique** — les thèmes réellement mesurés.
///
/// 🛑 **Même geste qu'en TCF, sur la seule donnée que le civique sert** : on
/// compte les thèmes dont l'`etat` n'est pas `NON_EVALUE`, et le total est la
/// liste servie. Aucun « 5 » n'est écrit ici, et rien n'est classé — `etat`
/// arrive du moteur civique.
///
/// Miroir web : `accueilEvaluesCivique`.
({int faites, int total})? accueilEvaluesCivique(
  List<CivicPlanThemeLigne> themes,
) {
  if (themes.isEmpty) return null;
  return (
    faites: themes.where((t) => t.etat != CivicThemeState.nonEvalue).length,
    total: themes.length,
  );
}

/// Le mot sous le compteur civique — on compte des **thèmes**, au masculin.
/// Miroir web : `ACCUEIL_EVALUES_CAPTION_CIVIQUE`.
const String kAccueilEvaluesCaptionCivique = 'évalués';

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

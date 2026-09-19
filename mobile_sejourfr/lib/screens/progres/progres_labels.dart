import 'dart:math' as math;

import '../../core/models/civic_diagnostic_models.dart';
import '../../core/models/civic_plan_models.dart';
import '../../core/models/dashboard_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/epreuve_historique_models.dart';
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
  final fleche = progresEvolutionFleche(epreuve.evolution);
  if (fleche == null) return null;
  final initial = epreuve.niveauInitial;
  if (initial == null || epreuve.evolution == NiveauEvolution.stable) {
    return fleche;
  }
  return '$fleche depuis ${initial.displayName}';
}

/// Le **glyphe seul** du marqueur d'évolution — la flèche de la bande des
/// paliers, où la phrase entière ne tient pas.
///
/// 🛑 **Une seule table de flèches** : [progresEvolutionLabel] en dérive. Deux
/// jeux de signes finiraient par ne plus dire la même chose du même fait servi,
/// sur deux blocs du même écran.
///
/// 🛑 **`inconnue` ne rend rien** — surtout pas le signe de la stabilité.
///
/// Miroir web : `progresEvolutionFleche`.
String? progresEvolutionFleche(NiveauEvolution evolution) =>
    switch (evolution) {
      NiveauEvolution.hausse => '↑',
      NiveauEvolution.baisse => '↓',
      NiveauEvolution.stable => '=',
      NiveauEvolution.inconnue => null,
    };

/// Le ton de la flèche, pour le kit.
///
/// 🛑 Il **lit** le sens servi, il ne le déduit d'aucune série de paliers.
/// Miroir web : `progresEvolutionTrendTone`.
SfTrendTone progresEvolutionTrendTone(NiveauEvolution evolution) =>
    switch (evolution) {
      NiveauEvolution.hausse => SfTrendTone.up,
      NiveauEvolution.baisse => SfTrendTone.down,
      NiveauEvolution.stable || NiveauEvolution.inconnue => SfTrendTone.flat,
    };

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

/* ---------------------------------------- L'échelle d'un thème civique --- */

/// **Les crans d'un thème civique** — les états **mesurés** de
/// [CivicThemeState], du plus fragile au plus tenu.
///
/// 🛑 **Ce n'est ni une échelle CECRL, ni un objectif, ni un palier** : le
/// civique n'en sert aucun (`docs/regles/progression.md`, arbitrage du
/// 2026-09-16). C'est l'**enum servi lui-même**, posé à plat : le nombre de
/// crans est le nombre d'états que le moteur civique peut rendre, moins
/// `nonEvalue` — qui n'est pas un cran mais une absence de mesure.
///
/// 🛑 **Aucun nombre n'entre ici.** Le front ne classe pas un ratio en état : il
/// reçoit `etat` servi et lit son rang dans cette table.
///
/// Miroir web : `ACCUEIL_ECHELLE_CIVIQUE`.
const List<CivicThemeState> kAccueilEchelleCivique = [
  CivicThemeState.faible,
  CivicThemeState.aRenforcer,
  CivicThemeState.solide,
];

/// Les crans d'un thème, **composés** pour le kit — le même [SfLevelLadder] que
/// les quatre épreuves du TCF.
///
/// ⚠️ **Il remplace la jauge continue** (`SfProgressMini`, supprimée le
/// 2026-09-19, demande du propriétaire) : « afficher le cran de la même manière
/// que le TCF ». Le codage visuel ne change pas de sens — les quatre positions
/// fixes de l'ancienne jauge (0 · 0,3 · 0,6 · 1) étaient déjà les quatre états
/// servis, ce sont maintenant des segments.
///
/// 🛑 **Aucun cran d'objectif** : `goal` est toujours faux et aucun cran ne
/// passe en [SfLadderState.target]. Le civique ne sert pas d'objectif, et en
/// peindre un serait inventer une cible que personne n'a posée.
///
/// Miroir web : `accueilEchelonsCivique`.
List<SfLadderStep> accueilEchelonsCivique(CivicThemeState etat) {
  final atteint = kAccueilEchelleCivique.indexOf(etat);
  return [
    for (var rang = 0; rang < kAccueilEchelleCivique.length; rang++)
      SfLadderStep(
        label: kAccueilEchelleCivique[rang].label,
        state: rang <= atteint ? SfLadderState.done : SfLadderState.empty,
        current: rang == atteint,
        goal: false,
      ),
  ];
}

/// **Les états de l'échelle civique**, pour la légende rendue une seule fois
/// au-dessus de la liste — le pendant de [accueilEchelleLegende].
///
/// 🛑 **La même table que les crans** ([kAccueilEchelleCivique]), et les mêmes
/// libellés **gelés** que la pastille de droite ([CivicThemeState.label]) : deux
/// listes finiraient par ne plus se superposer.
///
/// Miroir web : `accueilEchelleLegendeCivique`.
List<String> accueilEchelleLegendeCivique() =>
    [for (final etat in kAccueilEchelleCivique) etat.label];

/// Ce que l'échelle d'un thème dit à un lecteur d'écran — elle est rendue en
/// image, ses libellés sont décoratifs.
///
/// 🛑 **Le libellé servi, jamais une phrase de plus** : « Non évalué » se dit
/// tel quel, et surtout pas « faible ».
///
/// Miroir web : `accueilEchelleLabelCivique`.
String accueilEchelleLabelCivique(CivicThemeState etat) => etat.label;

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

/* ===========================================================================
 * L'ÉCRAN « VOTRE PROGRESSION » — la progression GLOBALE, ouverte du Profil
 * (template `docs/progression/ecran_progression_normal.html`, 2026-09-19)
 * =========================================================================== */

/// 🛑 **À ne pas confondre avec [kProgresTitle]** (« Ce qui a bougé », le bloc
/// de mouvement) ni avec « Ma progression » (`/plan/progression`, l'historique
/// des cycles). Celui-ci est le titre de l'écran lui-même.
const String kProgressionEyebrow = 'TCF IRN';
const String kProgressionTitle = 'Votre progression';
const String kProgressionLead =
    'Suivez votre niveau réel, examen après examen.';

/* ------------------------------------------------- le bandeau d'objectif -- */

const String kProgressionHeroLabel = 'Vers votre objectif';
const String kProgressionHeroMeta = 'Niveau mesuré par vos examens';

/// « Objectif B1 ». `null` sans démarche déclarée.
///
/// 🛑 [NiveauCecrl.shortName] et jamais un troncage maison : `A1_NON_ATTEINT`
/// se rend « <A1 ».
String? progressionObjectifPill(NiveauCecrl? objectif) =>
    objectif == null ? null : 'Objectif ${objectif.shortName}';

/// « 2 épreuves sur 4 ».
///
/// 🛑 **De l'arithmétique d'AFFICHAGE, jamais une classification** : les deux
/// nombres sont servis ([accueilEvaluees] ne fait que compter la présence d'un
/// palier), et le total est la liste servie elle-même — aucun « 4 » n'est écrit
/// ici. `null` quand le serveur n'en publie aucune : on n'annonce alors aucun
/// chiffre. Miroir web : `progressionMesureesLabel`.
String? progressionMesureesLabel(({int faites, int total})? compte) {
  if (compte == null || compte.total <= 0) return null;
  final n = compte.faites;
  return '$n épreuve${n > 1 ? 's' : ''} sur ${compte.total}';
}

/// La part parcourue du rail. `null` ⇒ pas de rail.
///
/// 🛑 **Ce n'est PAS un pourcentage de progression vers un palier** — règle que
/// le dépôt interdit et qui tient toujours : c'est la part des épreuves
/// **mesurées**, la lecture du compteur que [progressionMesureesLabel] écrit
/// déjà en mots. Miroir web : `progressionMesureesPart`.
double? progressionMesureesPart(({int faites, int total})? compte) =>
    compte == null || compte.total <= 0
        ? null
        : compte.faites / compte.total;

/// « 50 % ». `null` quand l'un des deux nombres n'est pas servi.
/// Miroir web : `progressionMesureesPourcent`.
String? progressionMesureesPourcent(({int faites, int total})? compte) {
  final part = progressionMesureesPart(compte);
  return part == null ? null : '${(part * 100).round()} %';
}

/// Le palier d'une épreuve sur la bande et sur sa ligne.
///
/// 🛑 **« — » et jamais « A1 »** : `null` = inconnu, jamais mauvais.
/// Miroir web : `progressionPalier`.
String progressionPalier(ProgressEpreuve epreuve) =>
    epreuve.niveau?.shortName ?? '—';

/* -------------------------------------------------------- « Votre évolution » */

const String kProgressionCourbeTitle = 'Votre évolution';
const String kProgressionCourbeSub = 'Basée uniquement sur vos examens';
const String kProgressionNiveauActuelLabel = 'Niveau actuel';

/// Le lien du pied de la courbe, vers « Vos résultats » de l'épreuve.
const String kProgressionVoirLabel = 'Voir';

const String kProgressionCourbeVideTitle = 'Aucune mesure pour l\'instant';

/// Le pied de la courbe quand rien n'a encore été mesuré. 🛑 Le titre est
/// [kSuiviSansExamenLabel], le mot déjà en place pour « aucun examen
/// qualifiant » sur un écran de suivi : on n'en écrit pas un second.
const String kProgressionSansExamenText =
    'Passez une épreuve complète pour mesurer votre niveau.';

/// 🛑 **Elle nomme l'épreuve** : le template écrit « une épreuve complète
/// d'expression orale », donc la phrase suit l'onglet ouvert.
String progressionCourbeVideText(EpreuveType epreuve) =>
    'Une épreuve complète de ${epreuve.displayLabel.toLowerCase()} fera '
    'apparaître votre évolution ici.';

/// Le pied « Examen blanc · 15 sept. » — provenance **servie** et date servie.
///
/// 🛑 `null` quand rien n'a été mesuré. Une date absente n'est pas inventée :
/// la provenance seule se suffit. Miroir web : `progressionDerniereMesure`.
String? progressionDerniereMesure(EvaluationQualifiante? derniere) {
  if (derniere == null) return null;
  final jour = jourLong(derniere.mesureA);
  return jour == null ? derniere.source.label : '${derniere.source.label} · $jour';
}

/* ----------------------------------------------------------- « Vos épreuves » */

const String kProgressionEpreuvesTitle = 'Vos épreuves';
const String kProgressionEpreuvesSub = 'Niveau + tendance récente';

/// L'intitulé sous le palier d'une ligne : « actuel » quand il y a une mesure,
/// « niveau » quand il n'y en a pas — comme le template.
String progressionPalierCaption(ProgressEpreuve epreuve) =>
    epreuve.niveau == null ? 'niveau' : 'actuel';

/// La suite des paliers d'une épreuve — « A2 → B1 → B1 ».
///
/// 🛑 **Rien n'est interprété et rien n'est retrié** : les paliers arrivent
/// **servis** (`GET /api/me/progress/tcf/{epreuve}/historique`) et on les lit
/// du plus ancien au plus récent, le sens de lecture que la courbe emploie
/// déjà. Aucun palier n'est comparé à un autre : la tendance, elle, est servie
/// (`evolution`) et se lit ailleurs sur la même ligne.
///
/// `null` quand l'historique est vide — l'appelant dit alors ce qui **manque à
/// compter** ([kSuiviSansExamenLabel]), jamais un palier inventé.
///
/// Miroir web : `progressionSerieLabel`.
String? progressionSerieLabel(List<EvaluationQualifiante> servies) {
  if (servies.isEmpty) return null;
  return servies.reversed.map((e) => e.niveau.shortName).join(' → ');
}

/* ===========================================================================
 * LA COURBE D'UNE ÉPREUVE — échelle, points et dates
 *
 * 🛑 **Extrait à sa 2ᵉ surface** (2026-09-19) : « Vos résultats »
 * (`epreuve_historique_screen`) et « Votre progression » (`progres_screen`)
 * dessinent la MÊME courbe à partir de la MÊME liste servie. Deux copies
 * auraient fini par ne plus situer un palier à la même hauteur.
 * =========================================================================== */

const List<String> _kMois = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

/// « 14 sept. 2026 ». `null` quand le serveur n'a pas de date — on n'en
/// invente pas.
String? jourLong(DateTime? quand) {
  if (quand == null) return null;
  final local = quand.toLocal();
  return '${local.day} ${_kMois[local.month - 1]} ${local.year}';
}

/// « 14 sept. » — l'abscisse de la courbe, où l'année ne tient pas.
String jourCourt(DateTime? quand) {
  if (quand == null) return '—';
  final local = quand.toLocal();
  return '${local.day} ${_kMois[local.month - 1]}';
}

/// L'échelle **affichée**, du haut vers le bas.
///
/// 🛑 **Elle suit les données servies**, elle ne les rabat pas : une mesure en
/// dessous de A2 ouvre l'échelle vers le bas. La fenêtre minimale est A2 → B2,
/// celle de la maquette — trois lignes, l'amplitude utile du TCF IRN.
///
/// Miroir web : `echelleAffichee`.
List<String> echelleAffichee(List<int> rangs) {
  var bas = 2;
  var haut = 4;
  for (final r in rangs) {
    if (r < bas) bas = r;
    if (r > haut) haut = r;
  }
  return [
    for (var i = haut; i >= bas; i--) kTcfPaliers[i].shortName,
  ];
}

/// **La courbe d'une épreuve, prête pour le kit** : son échelle et ses points.
///
/// 🛑 [servies] arrive dans l'**ordre servi** (la plus récente d'abord) et
/// n'est pas retriée : on la lit à l'envers parce qu'une courbe se lit du plus
/// ancien au plus récent. Aucune interpolation, aucune moyenne — un point par
/// évaluation servie.
///
/// Miroir web : `progresCourbe`.
({List<SfChartRung> rungs, List<SfChartPoint> points}) progresCourbe(
  List<EvaluationQualifiante> servies,
  NiveauCecrl? objectif,
) {
  final chronologie = servies.reversed.toList(growable: false);
  final ladder = echelleAffichee([
    for (final e in chronologie) e.niveau.tcfPalierIndex,
    if (objectif != null) objectif.tcfPalierIndex,
  ]);
  final haut = ladder.isEmpty
      ? 4
      : kTcfPaliers.indexWhere((p) => p.shortName == ladder.first);
  // 🛑 **Les paliers CECRL sont RÉGULIÈREMENT espacés**, et c'est cette
  // fonction — pas la brique — qui le dit : un cran par palier, à hauteur
  // égale. La brique reçoit des hauteurs, elle n'en invente aucune, ce qui la
  // rend réutilisable par une échelle de valeurs (`civiqueThemeCourbe`).
  final crans = math.max(ladder.length - 1, 1);
  double hauteur(int rang) => ladder.length > 1 ? (haut - rang) / crans : 0.5;
  return (
    rungs: [
      for (var i = 0; i < ladder.length; i++)
        SfChartRung(
          label: ladder[i],
          at: ladder.length > 1 ? i / crans : 0.5,
        ),
    ],
    points: [
      for (final e in chronologie)
        SfChartPoint(
          date: jourCourt(e.mesureA),
          level: e.niveau.shortName,
          at: hauteur(e.niveau.tcfPalierIndex),
        ),
    ],
  );
}

/* ===========================================================================
 * « VOS RÉSULTATS » D'UN THÈME CIVIQUE — l'écran ouvert depuis l'Accueil
 *
 * 🛑 **Aucun palier, aucun objectif CECRL** : le civique se mesure en thèmes et
 * en scores face à un seuil, jamais en paliers (`docs/regles/progression.md`).
 * Ce qui est servi, et rien de plus : l'`etat` du thème (`CivicThemeState`,
 * rendu par `CivicThemeState.label`) et ses examens blancs, avec pour chacun
 * son score, son total de questions et son seuil de réussite.
 *
 * Miroirs web : les mêmes noms dans `lib/progres.ts`.
 * =========================================================================== */

const String kThemeResultatsTitle = 'Vos résultats';

/// Le héros : le dernier score servi, face au seuil servi avec lui.
const String kThemeResultatsHeroLabel = 'Dernier résultat';
const String kThemeResultatsSeuilLabel = 'Seuil de réussite';

/// Ce qui compte dans cet écran, dit au candidat plutôt que deviné par lui.
///
/// 🛑 **Formulée pour rester vraie quand la liste est vide**, et pour ne rien
/// promettre que le serveur ne serve : les séries d'entraînement et le
/// diagnostic civique sont exclus par la requête elle-même
/// (`AttemptRepository.findByUserFiltered`).
const String kThemeResultatsLead =
    'Vos examens blancs sur ce thème, et votre score face au seuil de '
    'réussite. Vos séries d\'entraînement et votre diagnostic n\'y figurent '
    'pas.';

/* -------------------------------------------------------------- courbe --- */

const String kThemeResultatsCourbeTitle = 'Votre évolution';
const String kThemeResultatsCourbeSub = 'Touchez un point pour voir l\'examen.';

/// La phrase qui remplace la courbe quand un seul examen a été passé.
const String kThemeResultatsCourbeUnPoint =
    'Un seul examen pour l\'instant : la courbe se dessinera au prochain.';

/* ---------------------------------------------------------- historique --- */

const String kThemeResultatsListeTitle = 'Historique';

/// « 3 examens blancs ». 🛑 On compte des lignes servies, rien d'autre.
String themeResultatsCountLabel(int n) =>
    '$n examen${n > 1 ? 's' : ''} blanc${n > 1 ? 's' : ''}';

/// 🛑 **Une absence de mesure se DIT** — jamais un `0 / 20`, jamais un état
/// pédagogique inventé.
const String kThemeResultatsVide = 'Pas encore d\'examen sur ce thème.';
const String kThemeResultatsVideAide =
    'Votre premier examen blanc de ce thème apparaîtra ici dès qu\'il sera '
    'terminé.';

const String kThemeResultatsErreur =
    'Vos résultats n\'ont pas pu être chargés. Réessayez dans un instant.';

/// « Examen blanc 3 » — le slot servi, rien de plus.
String themeResultatsExamenTitle(int? slot) =>
    slot == null ? 'Examen blanc' : 'Examen blanc $slot';

/// « 17 / 20 » — deux nombres servis, mis côte à côte.
String themeResultatsScore(int score, int total) => '$score / $total';

/// « Seuil de réussite : 16 / 20. » — le seuil SERVI avec cet examen-là.
String themeResultatsSeuilDetail(int seuil, int total) =>
    'Seuil de réussite : $seuil / $total.';

/// Le score comparé au seuil, **deux nombres servis** — pas un état pédagogique
/// ni un palier. C'est l'information utile d'un examen civique, et la même
/// comparaison que `ExamReportScreen` et la grille d'examens font déjà.
///
/// `null` quand aucun seuil n'est servi (attempt antérieur au champ) : on ne
/// conclut rien sans la barre.
String? themeResultatsVerdict(int score, int? seuil) {
  if (seuil == null) return null;
  return score >= seuil ? 'Au-dessus du seuil.' : 'Sous le seuil de réussite.';
}

/// Le repli d'une ligne dont le serveur ne sert **aucun** seuil (attempt
/// antérieur au champ). 🛑 On dit l'absence, on n'invente pas la barre.
const String kThemeResultatsSansSeuil =
    'Cet examen ne porte pas de seuil de réussite.';

/// Ce que la liste compte, et ce qu'elle ne compte pas.
const String kThemeResultatsPorteeTitle = 'Ce qui compte ici :';
const String kThemeResultatsPorteeText =
    ' vos examens blancs de ce thème et leur seuil de réussite. Un thème '
    'civique n\'a aucun niveau CECRL — c\'est votre score face au seuil qui '
    'compte.';

/// Le lien de pied : c'est là qu'on PASSE un examen, pas qu'on le relit.
const String kThemeResultatsExamensLabel = 'Passer un examen blanc';

/* ------------------------------------------------------ échelle servie --- */

/// Un examen blanc de thème, réduit aux trois nombres dont la courbe a besoin.
class ThemeMesure {
  const ThemeMesure({
    required this.date,
    required this.score,
    required this.total,
    required this.seuil,
  });

  /// Date servie, ou `null` — [jourCourt] en fait « — ».
  final DateTime? date;
  final int score;
  final int total;

  /// `null` quand le serveur n'a pas de seuil sur cet attempt.
  final int? seuil;
}

/// **La courbe d'un thème civique, prête pour le kit** : son échelle et ses
/// points, sur la MÊME brique que le TCF ([SfLevelChart]).
///
/// 🛑 **L'échelle est SERVIE, pas fabriquée** : le maximum est le
/// `totalQuestions` des examens servis, le seuil leur `passThreshold`. Les deux
/// nombres du format de thème (20 / 16) ne sont écrits nulle part ici — ils
/// viennent de `AttemptService`, avec chaque examen.
///
/// 🛑 **Les crans portent leur hauteur RÉELLE** : `16` se pose à 20 % du haut
/// d'un cadre `0 → 20`, pas au milieu. C'est exactement pourquoi [SfChartRung]
/// prend un `at` plutôt qu'un rang.
///
/// 🛑 **Le seuil n'est dessiné que s'il est le MÊME sur tous les examens
/// servis** : deux seuils différents sur une même courbe ne se lisent pas, et
/// en choisir un serait une invention.
///
/// 🛑 [mesures] arrive dans l'**ordre servi** (la plus récente d'abord,
/// `ORDER BY a.startedAt DESC`) et n'est pas retriée : on la lit à l'envers
/// parce qu'une courbe se lit du plus ancien au plus récent. Aucune
/// interpolation, aucune moyenne — un point par examen servi, donc **un seul
/// examen ⇒ un seul point**.
///
/// Miroir web : `civiqueThemeCourbe`.
({List<SfChartRung> rungs, List<SfChartPoint> points}) civiqueThemeCourbe(
  List<ThemeMesure> mesures,
) {
  if (mesures.isEmpty) return (rungs: const [], points: const []);
  final chronologie = mesures.reversed.toList(growable: false);
  var max = 0;
  for (final m in chronologie) {
    if (m.total > max) max = m.total;
  }
  if (max <= 0) return (rungs: const [], points: const []);
  final seuils = <int>{
    for (final m in chronologie)
      if (m.seuil != null) m.seuil!,
  };
  final seuil = seuils.length == 1 && seuils.first > 0 && seuils.first < max
      ? seuils.first
      : null;
  return (
    rungs: [
      SfChartRung(label: '$max', at: 0),
      if (seuil != null)
        SfChartRung(
          label: '$seuil',
          at: (max - seuil) / max,
          seuil: true,
        ),
      const SfChartRung(label: '0', at: 1),
    ],
    points: [
      for (final m in chronologie)
        SfChartPoint(
          date: jourCourt(m.date),
          level: themeResultatsScore(m.score, m.total),
          at: ((max - m.score) / max).clamp(0.0, 1.0),
        ),
    ],
  );
}

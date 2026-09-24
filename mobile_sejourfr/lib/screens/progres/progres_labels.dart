import '../../core/models/civic_diagnostic_models.dart';
import '../../core/models/civic_plan_models.dart';
import '../../core/models/dashboard_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/progress_models.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../progression/progression_labels.dart' show kProgressionSansExamen;

/// Les **mots** de « Où vous en êtes » (Accueil) et l'autorité d'affichage du
/// niveau d'une épreuve (Accueil, Réviser, recommandations) — **purs**, déclarés
/// une fois pour tout le mobile, **miroirs mot pour mot** de
/// `web_sejoufr/lib/progres.ts`.
///
/// ⚠️ **L'ancien écran Progrès est SUPPRIMÉ** (2026-09-24, avec
/// `EpreuveHistoriqueScreen` et `ThemeHistoriqueScreen`) : ses phrases, sa
/// courbe et ses compteurs sont partis avec lui. Les écrans de progression ont
/// leurs propres mots : `screens/progression/progression_labels.dart`.
///
/// 🛑 **Le serveur n'expose que des faits** : un palier, un statut, un sens
/// d'évolution. **Aucun pourcentage de progression vers un palier.**

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

/// Le mot d'une chose **jamais mesurée** — épreuve sans palier, thème civique
/// `NON_EVALUE`.
///
/// 🛑 **Un seul endroit** : il vit sur la pastille d'une carte d'accueil, sur
/// le statut d'une épreuve de Progrès et sur les thèmes civiques. Recopié, il
/// finirait par diverger d'une surface à l'autre — et c'est le mot qui empêche
/// une absence de mesure de se lire comme un verdict (V040/V041/V042). Miroir
/// web : `NON_MESURE_LABEL`.
const String kNonMesureLabel = 'À évaluer';

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

/// 🛑 Le mot d'une épreuve sans examen, sur un écran de suivi chiffré — **le
/// même** que celui des écrans de progression, déclaré là-bas une seule fois.
/// Miroir web : `SUIVI_SANS_EXAMEN_LABEL`.
const String kSuiviSansExamenLabel = kProgressionSansExamen;

/// La ligne de niveau d'une épreuve sur un écran de **suivi chiffré**
/// (les recommandations) — jamais sur un écran de constat.
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
      AccueilEpreuveEtat.solide => 'Solide, à maintenir',
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

/// Ce que l'échelle d'un thème dit à un lecteur d'écran — elle est rendue en
/// image, ses libellés sont décoratifs.
///
/// 🛑 **Le libellé servi, jamais une phrase de plus** : « Non évalué » se dit
/// tel quel, et surtout pas « faible ».
///
/// Miroir web : `accueilEchelleLabelCivique`.
String accueilEchelleLabelCivique(CivicThemeState etat) => etat.label;

/// Le dernier score civique, comparable au seuil. `null` s'il n'y en a aucun.
String? progresCiviqueScore(ProgressCivique civique) {
  if (civique.historique.isEmpty) return null;
  final dernier = civique.historique.last;
  return '${dernier.bonnes} / ${dernier.posees} · '
      'seuil ${dernier.seuil} / ${dernier.format}';
}

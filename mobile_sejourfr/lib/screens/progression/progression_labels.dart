import '../../core/models/civic_diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/progress_models.dart';
import '../../core/models/progression_models.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/epreuve_duration.dart';
import '../../core/utils/format_date.dart';
import '../../core/utils/tcf_epreuves.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../plan/civic_plan_labels.dart';
import '../plan/plan_labels.dart';
import '../tcf_production/production_nav.dart';
import '../tcf_production/tcf_production_module.dart';

/// **Les écrans de progression** (maquettes
/// `docs/progression/maquettes-progression/`, arbitrages D1–D20 du
/// 2026-09-24) — leurs adresses, leurs mots et la mise en forme des valeurs
/// **servies**.
///
/// 🛑 **Rien n'est classé ici.** Palier, état, bandes, écart, sens, ordinal,
/// meilleur / premier / dernier, durée fiable, seuil atteint et points
/// manquants arrivent tous servis (`GET /api/me/progression/*`,
/// `docs/regles/progression.md` § « Écrans de progression »). Ce fichier ne
/// fait que les ÉCRIRE : un nombre devient une chaîne, un enum servi devient
/// un mot.
///
/// 🛑 `null` = inconnu : « — », jamais `0`, jamais « A1 ». Un écart `null` ne
/// rend AUCUN marqueur (surtout pas « +0 ») ; un sens `INCONNUE` non plus.
///
/// 🛑 **Miroir mot pour mot de `web_sejoufr/lib/progression.ts`.**

/* --------------------------------------------------------------- adresses */

/// **Où mène « Voir → »** — choisi par le `rapport.kind` SERVI, jamais déduit
/// d'une route ni d'une provenance.
///
/// `PRODUCTION` a besoin de l'épreuve (EE ou EO) pour nommer son bilan : elle
/// n'existe que sur l'écran d'une épreuve, qui la connaît. `null` = pas de lien.
String? progressionRapportPath(
  ProgressionRapport kind,
  String attemptId, [
  EpreuveType? epreuve,
]) =>
    switch (kind) {
      ProgressionRapport.qcm => AppRoutes.examReportPath(attemptId),
      ProgressionRapport.examenComplet =>
        AppRoutes.tcfFullExamBilanPath(attemptId),
      ProgressionRapport.production => switch (epreuve) {
          EpreuveType.tcfEe =>
            productionSessionReportPath(TcfProductionModule.ee, attemptId),
          EpreuveType.tcfEo =>
            productionSessionReportPath(TcfProductionModule.eo, attemptId),
          _ => null,
        },
    };

/// Le CTA d'une épreuve : sa GRILLE d'examens, jamais un démarrage direct.
String progressionEpreuveCtaPath(EpreuveType epreuve) => switch (epreuve) {
      EpreuveType.tcfCe => AppRoutes.tcfCeExams,
      EpreuveType.tcfEe => productionExamsPath(TcfProductionModule.ee),
      EpreuveType.tcfEo => productionExamsPath(TcfProductionModule.eo),
      _ => AppRoutes.tcfCoExams,
    };

/* ------------------------------------------------------------ mots communs */

const String kProgressionEyebrow = 'Votre progression';
const String kProgressionLoading = 'Chargement…';
const String kProgressionError = 'Impossible de charger votre progression.';
const String kProgressionRetry = 'Réessayer';
const String kProgressionScoreLabel = 'Score';
const String kProgressionTempsLabel = 'Temps';
const String kProgressionVide = '—';

/// Le retour de l'historique complet à la vue courte (D8).
const String kProgressionListeMoinsLink = 'Afficher les 3 derniers';

/// Une épreuve sans examen blanc — le mot des écrans de suivi chiffré.
const String kProgressionSansExamen = "Pas encore d'examen";

/// Un thème sans examen de thème (D10 : aucun repli sur un examen global).
const String kProgressionSansExamenTheme = "Pas encore d'examen de thème";

/* ------------------------------------------------------------ mise en forme */

/// Un score servi, tel qu'il s'écrit : entier, ou une décimale à la française.
String progressionNombre(double n) => formatScore(n);

/// « 422 / 499 », « 12,5 / 20 », « 29 / 40 » ; `null` ⇒ « — ».
String progressionScore(double? score, int max) =>
    score == null ? kProgressionVide : '${progressionNombre(score)} / $max';

/// La valeur seule (le gros chiffre) ; `null` ⇒ « — ».
String progressionValeur(double? score) =>
    score == null ? kProgressionVide : progressionNombre(score);

/// L'unité accolée au gros chiffre : « / 499 ».
String progressionUnite(int max) => '/ $max';

const List<String> _kMoisLongs = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// Les mois abrégés de `fr-FR` (`toLocaleDateString(…, {month: "short"})`),
/// pour que les deux fronts écrivent la même date.
const List<String> _kMoisCourts = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

/// « 22 septembre 2026 ». `null` ⇒ « — ».
String progressionDateLongue(DateTime? d) => d == null
    ? kProgressionVide
    : '${d.day} ${_kMoisLongs[d.month - 1]} ${d.year}';

/// « 22 sept. » — l'axe de la courbe.
String progressionDateCourte(DateTime? d) =>
    d == null ? kProgressionVide : '${d.day} ${_kMoisCourts[d.month - 1]}';

/// « 22 septembre » — la date sous un meilleur score.
String progressionDateJour(DateTime? d) =>
    d == null ? kProgressionVide : '${d.day} ${_kMoisLongs[d.month - 1]}';

/// L'année seule, sous « Dernier examen ».
String progressionAnnee(DateTime? d) =>
    d == null ? kProgressionVide : '${d.year}';

/// La durée **fiable** servie (D9) ; `null` ⇒ « — ».
String progressionDuree(int? secondes) =>
    epreuveDurationLabel(secondes) ?? kProgressionVide;

/// Un palier servi, forme courte (« <A1 » pour A1 non atteint) ; `null` ⇒ « — ».
String progressionPalier(NiveauCecrl? niveau) =>
    niveau?.shortName ?? kProgressionVide;

/// « Niveau B2 » — la pastille d'un palier servi.
String? progressionNiveauPill(NiveauCecrl? niveau) =>
    niveau == null ? null : 'Niveau ${niveau.shortName}';

/// Le libellé gelé d'un état civique servi.
String? progressionEtatLabel(CivicThemeState? etat) => etat?.label;

/// Le ton d'un état civique servi — l'autorité existante, pas une seconde table.
SfBarTone progressionEtatTon(CivicThemeState? etat) =>
    etat == null ? SfBarTone.muted : civicThemeBarTone(etat);

/* ------------------------------------------------------------- évolution */

String? _sensGlyphe(NiveauEvolution sens) => switch (sens) {
      NiveauEvolution.hausse => '↗',
      NiveauEvolution.stable => '→',
      NiveauEvolution.baisse => '↘',
      NiveauEvolution.inconnue => null,
    };

/// Le ton de la pastille d'écart : il suit le SENS servi, jamais un signe.
SfBarTone progressionSensTon(NiveauEvolution sens) => switch (sens) {
      NiveauEvolution.hausse => SfBarTone.ok,
      NiveauEvolution.baisse => SfBarTone.warn,
      NiveauEvolution.stable || NiveauEvolution.inconnue => SfBarTone.muted,
    };

String _pointsMot(double ecart) => ecart.abs() >= 2 ? 'points' : 'point';

/// « ↗ +148 points » — l'écart servi (`dernier − premier`), avec son sens
/// servi.
///
/// 🛑 `null` avec un seul examen ⇒ rien. `INCONNUE` ⇒ rien. Jamais « +0 ».
String? progressionEcart(
  double? ecart,
  NiveauEvolution sens, {
  bool depuisLeDebut = false,
}) {
  final glyphe = _sensGlyphe(sens);
  if (ecart == null || glyphe == null) return null;
  final suffixe = depuisLeDebut ? ' depuis le début' : '';
  if (sens == NiveauEvolution.stable) return '$glyphe Stable$suffixe';
  final signe = ecart > 0
      ? '+'
      : ecart < 0
          ? '−'
          : '';
  return '$glyphe $signe${progressionNombre(ecart.abs())} '
      '${_pointsMot(ecart)}$suffixe';
}

/// L'évolution de PALIER des examens complets (D6) — aucun point, aucun score.
String? progressionEvolutionPalier(NiveauEvolution sens) => switch (sens) {
      NiveauEvolution.hausse =>
        '↗ En hausse depuis votre premier examen complet',
      NiveauEvolution.baisse =>
        '↘ En baisse depuis votre premier examen complet',
      NiveauEvolution.stable => '→ Stable depuis votre premier examen complet',
      NiveauEvolution.inconnue => null,
    };

/* ------------------------------------------------------------- échelle */

/// « / 499 » en bout d'axe : ce que mesure la courbe.
String progressionEchelleNote(ProgressionEchelle echelle) =>
    switch (echelle.unite) {
      ProgressionUnite.progression499 =>
        'Score de progression · /${echelle.max}',
      ProgressionUnite.note20 => "Note d'épreuve · /${echelle.max}",
      ProgressionUnite.questions => 'Bonnes réponses · /${echelle.max}',
    };

/// Le libellé d'une bande servie : son palier (EE/EO) ou son état (civique).
String progressionBandeLabel(ProgressionBande bande) {
  final niveau = bande.niveau;
  if (niveau != null) return niveau.shortName;
  final etat = bande.etat;
  if (etat != null) return etat.label;
  return kProgressionVide;
}

/// « 10–20 / 20 », « 0 / 20 ».
String progressionBandeEtendue(ProgressionBande bande, int max) {
  final etendue =
      bande.min == bande.max ? '${bande.min}' : '${bande.min}–${bande.max}';
  return '$etendue / $max';
}

/// Le ton d'une bande servie : l'état civique porte le sien, un palier n'en a
/// pas (rampe neutre de la courbe).
SfBarTone? progressionBandeTon(ProgressionBande bande) {
  final etat = bande.etat;
  return etat == null ? null : civicThemeBarTone(etat);
}

/// La phrase qui remplace la légende quand l'échelle n'a PAS de bande (D2).
const String kProgressionPortee499 =
    "Score de progression : il mesure votre avancée d'un examen à l'autre. "
    'Votre niveau se lit palier par palier, à côté de chaque examen.';

/// La courbe d'un écran, prête pour le kit : les bandes, les repères et le
/// seuil **servis**, un point par examen **servi** (du plus ancien au plus
/// récent — l'ordre servi est inverse). Un examen sans score n'est pas placé :
/// on ne pose pas « — » sur un axe.
({
  List<SfProgressBand> bands,
  List<double> reperes,
  double? seuil,
  List<SfProgressChartPoint> points,
}) progressionCourbe(
  ProgressionEchelle echelle,
  List<ProgressionMesure> examens,
) {
  final seuil = echelle.seuil;
  return (
    bands: [
      for (final b in echelle.bandes)
        SfProgressBand(
          from: b.min.toDouble(),
          to: b.max.toDouble(),
          label: '${progressionBandeLabel(b)} · ${b.min}–${b.max}',
          tone: progressionBandeTon(b),
        ),
    ],
    reperes: [for (final r in echelle.reperes) r.toDouble()],
    seuil: seuil?.toDouble(),
    points: [
      for (final m in examens.reversed)
        if (m.score != null)
          SfProgressChartPoint(
            value: m.score!,
            valueLabel: progressionNombre(m.score!),
            date: progressionDateCourte(m.date),
          ),
    ],
  );
}

/// La légende des bandes servies (vide en CO/CE : il n'y en a pas, D2).
List<SfProgressScaleItem> progressionLegende(ProgressionEchelle echelle) => [
      for (final b in echelle.bandes)
        (
          label: progressionBandeLabel(b),
          range: progressionBandeEtendue(b, echelle.max),
        ),
    ];

/// La sparkline d'une carte : la série servie, sur l'axe servi.
SfProgressSpark? progressionSpark(ProgressionCarte carte) =>
    carte.resume.serie.isEmpty
        ? null
        : (
            serie: carte.resume.serie,
            min: carte.echelle.min.toDouble(),
            max: carte.echelle.max.toDouble(),
          );

/* ----------------------------------------------------------- seuil civique */

/// Le verdict servi face au seuil : « Seuil atteint » / « Il manque 3 points ».
String? progressionSeuilVerdict(ProgressionMesure? mesure, int? seuil) {
  if (mesure == null || seuil == null) return null;
  final atteint = mesure.seuilAtteint;
  if (atteint == null) return null;
  if (atteint) return 'Seuil de réussite atteint ($seuil / ${mesure.max})';
  final n = mesure.pointsManquants;
  if (n == null) return null;
  return 'Il manque $n ${_pointsMot(n.toDouble())} pour le seuil de '
      '$seuil / ${mesure.max}';
}

/// Le centre de l'anneau civique : le taux servi, écrit.
String? progressionTaux(double? taux) =>
    taux == null ? null : '${(taux * 100).round()} %';

/// L'anneau civique (D5) : taux servi, seuil atteint servi. `null` sans taux.
SfProgressRing? progressionAnneau(ProgressionMesure? mesure) {
  final taux = mesure?.taux;
  final texte = progressionTaux(taux);
  if (mesure == null || taux == null || texte == null) return null;
  return (ratio: taux, label: texte, reached: mesure.seuilAtteint ?? false);
}

/* ---------------------------------------------------------------- compteurs */

String progressionTermines(int n) => n > 1 ? 'terminés' : 'terminé';

String progressionExamensTermines(int n) =>
    n > 1 ? 'examens blancs terminés' : 'examen blanc terminé';

/* ======================================================================
   Écran d'une ÉPREUVE TCF (`progression_epreuve_tcf.html`)
   ====================================================================== */

const String kEpreuveBackLabel = 'Progression globale';
const String kEpreuveCta = 'Nouvel examen blanc';
const String kEpreuveHeroLabel = 'Dernier résultat';
const String kEpreuveMeilleurLabel = 'Meilleur score';
const String kEpreuveNombreLabel = 'Examens réalisés';
const String kEpreuveCourbeTitle = 'Évolution de votre score';
const String kEpreuveListeTitle = 'Mes examens blancs';
const String kEpreuveListeSub = 'Vos résultats, du plus récent au plus ancien.';
const String kEpreuveVide =
    "Aucun examen blanc de cette épreuve pour l'instant.";

String epreuveTitre(EpreuveType epreuve) => epreuve.displayLabel;

String epreuveLead(EpreuveType epreuve) => epreuve == EpreuveType.tcfEe ||
        epreuve == EpreuveType.tcfEo
    ? "Suivez l'évolution de votre note sur 20 au fil de vos examens blancs."
    : "Suivez l'évolution de votre score de progression au fil de vos "
        'examens blancs.';

String epreuveCourbeSub(EpreuveType epreuve) =>
    'Chaque point correspond à un examen blanc de '
    '${epreuve.displayLabel.toLowerCase()}.';

/// D4 — le niveau de l'Accueil, en ligne secondaire.
String? epreuveNiveauActuel(NiveauCecrl? niveau) =>
    niveau == null ? null : 'Niveau actuel estimé : ${niveau.shortName}';

/// « Niveau B2 · 22 septembre » sous le meilleur score.
String? epreuveMeilleurSub(ProgressionMesure? mesure) {
  if (mesure == null) return null;
  final jour = progressionDateJour(mesure.date);
  final niveau = mesure.niveau;
  return niveau == null ? jour : 'Niveau ${niveau.shortName} · $jour';
}

/// La ligne sous le titre d'un examen : sa date, et d'où il vient (servi).
String epreuveExamenDate(ProgressionMesure mesure) {
  final date = progressionDateLongue(mesure.date);
  return mesure.provenance == ProgressionProvenance.examenComplet
      ? '$date · examen complet'
      : date;
}

String examenBlancTitre(int numero) => 'Examen blanc n°$numero';

/// Le pied des épreuves notées sur 20 (D3 : l'écart note ⇄ palier est assumé).
const String kEpreuveNote20Portee =
    'La note sur 20 est celle de votre bilan. Le niveau tient compte de chaque '
    'tâche : il peut rester en dessous de la bande de la note.';

/* ======================================================================
   Écran TCF GLOBAL (`progression_global_tcf.html`)
   ====================================================================== */

const String kTcfBackLabel = 'Accueil';
const String kTcfCta = 'Faire un examen blanc';
const String kTcfTitle = 'Progression globale';
const String kTcfLead =
    "Suivez l'évolution de vos résultats sur toutes les épreuves du TCF.";
const String kTcfHeroLabel = 'Niveau global estimé';
const String kTcfStatNombre = 'Examens blancs';
const String kTcfStatMeilleur = 'Meilleur résultat';
const String kTcfStatPremier = 'Première évaluation';
const String kTcfStatDernier = 'Dernier examen';
const String kTcfEpreuvesTitle = 'Progression par épreuve';
const String kTcfEpreuvesSub =
    'Touchez une épreuve pour voir son évolution détaillée.';
const String kTcfCarteSub = 'Dernier examen blanc';
const String kTcfListeTitle = 'Mes derniers examens blancs';
const String kTcfListeSub = 'Une vue rapide de vos résultats complets.';
const String kTcfListeTousTitle = 'Tous mes examens blancs';
const String kTcfListeTousSub =
    'Vos examens blancs complets, du plus récent au plus ancien.';
const String kTcfListeTousLink = 'Tous mes examens blancs →';
const String kTcfListeVide =
    "Aucun examen blanc complet terminé pour l'instant.";
const String kTcfHint =
    "Le détail de chaque épreuve ouvre l'écran de progression dédié.";

/// « Dernier examen complet : B1 · partiel » — servi (D6, D7).
String? tcfDernierComplet(NiveauCecrl? niveau, bool partiel) => niveau == null
    ? null
    : 'Dernier examen complet : ${niveau.shortName}'
        '${partiel ? ' · partiel' : ''}';

/// Le palier global est un plancher : on dit sur combien d'épreuves il repose.
String? tcfNiveauPartielNote(int epreuves, bool partiel) {
  if (!partiel) return null;
  return 'Estimé sur $epreuves épreuve${epreuves > 1 ? 's' : ''} sur '
      '${kTcfEpreuvesOfficielles.length}';
}

const String kTcfNiveauInconnuNote =
    'Passez un examen blanc pour obtenir un premier niveau.';

/// « Examen n°3 · 22 sept. 2026 » sous un palier d'examen complet.
String tcfExamenSub(int numero, DateTime? date) =>
    'Examen n°$numero · ${date == null ? kProgressionVide : '${progressionDateCourte(date)} ${date.year}'}';

/// La ligne sous le titre d'un examen complet : date, et « partiel » servi.
String tcfExamenDate(DateTime? date, bool partiel, int comptees) {
  final jour = progressionDateLongue(date);
  return partiel
      ? '$jour · partiel ($comptees/${kTcfEpreuvesOfficielles.length} épreuves)'
      : jour;
}

/// Le repère court d'une épreuve (« CO »).
String tcfEpreuveMark(EpreuveType epreuve) =>
    planDomainSection(epreuve)?.wire ?? epreuve.wire;

/// Le nom d'une épreuve (« Compréhension orale »).
String tcfEpreuveNom(EpreuveType epreuve) => epreuve.displayLabel;

/* ======================================================================
   Écran CIVIQUE GLOBAL (`progression_global_civique.html`)
   ====================================================================== */

const String kCiviqueBackLabel = 'Accueil';
const String kCiviqueCta = 'Faire un examen blanc global';
const String kCiviqueTitle = 'Examen civique';
const String kCiviqueLead =
    'Suivez votre progression globale et celle de chaque thème.';
const String kCiviqueHeroLabel = 'Dernier résultat global';
const String kCiviqueStatNombre = 'Examens globaux';
const String kCiviqueStatMeilleur = 'Meilleur résultat';
const String kCiviqueStatPremier = 'Premier résultat';
const String kCiviqueStatDernier = 'Dernier examen';
const String kCiviqueThemesTitle = 'Progression par thème';
const String kCiviqueThemesSub =
    'Touchez un thème pour voir son évolution détaillée.';
const String kCiviqueCarteSub = 'Dernier examen du thème';
const String kCiviqueListeTitle = 'Mes derniers examens globaux';
const String kCiviqueListeSub =
    'Vos résultats par thème : bonnes réponses sur questions posées.';
const String kCiviqueListeTousTitle = 'Tous mes examens globaux';
const String kCiviqueListeTousLink = 'Tous mes examens globaux →';
const String kCiviqueListeVide =
    "Aucun examen civique global terminé pour l'instant.";
const String kCiviqueHint =
    "Chaque carte thème ouvre l'écran de progression détaillée du thème.";

String civiqueExamenTitre(int numero) => 'Examen civique global n°$numero';

/// « Global : 29 / 40 ».
String civiqueGlobalBadge(ProgressionMesure mesure) =>
    'Global : ${progressionScore(mesure.score, mesure.max)}';

/// La part d'un thème dans un examen global (D11) : « 3 / 4 », « — » si non
/// posé.
String civiquePart(int bonnes, int posees) =>
    posees == 0 ? kProgressionVide : '$bonnes / $posees';

/* ======================================================================
   Écran d'un THÈME civique (`progression_theme_civique.html`)
   ====================================================================== */

const String kThemeBackLabel = 'Examen civique';
const String kThemeCta = 'Nouvel examen blanc';
const String kThemeLead =
    'Suivez vos résultats sur ce thème précis à travers vos examens blancs.';
const String kThemeHeroLabel = 'Dernier résultat';
const String kThemeMeilleurLabel = 'Meilleur score';
const String kThemeNombreLabel = 'Examens réalisés';
const String kThemeNombreSub = 'sur ce thème';
const String kThemeCourbeTitle = 'Évolution de votre score';
const String kThemeCourbeSub =
    'Chaque point correspond à un examen blanc sur ce thème.';
const String kThemeListeTitle = 'Mes examens blancs du thème';
const String kThemeListeSub = 'Vos résultats, du plus récent au plus ancien.';
const String kThemeVide = "Aucun examen blanc de ce thème pour l'instant.";
const String kThemeFoot =
    'Cet écran suit uniquement la progression du thème sélectionné.';
const String kThemeIntrouvable = 'Ce thème est introuvable.';

String themeTitre(String label) => 'Thème : $label';

String themeExamenTitre(int numero) => 'Examen thème n°$numero';

/// « Solide · 22 septembre » sous le meilleur score d'un thème.
String? themeMeilleurSub(ProgressionMesure? mesure) {
  if (mesure == null) return null;
  final jour = progressionDateJour(mesure.date);
  final etat = progressionEtatLabel(mesure.etat);
  return etat == null ? jour : '$etat · $jour';
}

import '../../core/models/civic_diagnostic_models.dart';

/// Règles d'affichage du diagnostic **civique** — **pures**, déclarées une fois
/// pour tout le mobile.
///
/// 🛑 Le serveur n'expose que des **faits** (un état de thème, un compte, une
/// projection). Les phrases vivent ici, et sont des **miroirs mot pour mot** de
/// `web_sejoufr/lib/civic-diagnostic.ts`.
///
/// 🛑 Ce fichier ne **dérive** aucun état pédagogique.

/// L'en-tête de l'**intro** (maquette `civique-intro`).
const String kCivicIntroKicker = 'Diagnostic';
const String kCivicIntroTitle = 'Examen civique';
const String kCivicIntroLead =
    'Découvrez les thèmes et notions que vous devez travailler en priorité.';

/// L'en-tête du **résultat** (maquette `civique-resultat`).
const String kCivicResultKicker = 'Examen civique';
const String kCivicResultTitle = 'Votre diagnostic';
const String kCivicResultBadge = 'Diagnostic terminé';

/// Le format OFFICIEL de l'examen — miroir de `CivicExamFormat` côté Java, où
/// ces deux nombres sont du **code** et non un réglage.
///
/// 🛑 Ils ne servent qu'à l'écran **d'intro**, seul moment du parcours où aucune
/// session n'existe encore : dès qu'un résultat est servi, ce sont
/// `formatQuestions` et `seuilReussite` du DTO qui font foi, jamais ceux-ci.
const int kCivicExamQuestions = 40;
const int kCivicExamSeuilReussite = 32;

/// Les thèmes du livret officiel. Structure de l'épreuve, pas un réglage.
const int kCivicThemesCount = 5;

const String kCivicIntroThemesTitle = 'Les 5 thèmes du livret';
const String kCivicIntroSituationsNote =
    'Certaines questions sont des mises en situation, pour vérifier que vous '
    'savez appliquer les règles à des cas concrets.';

/// Les libellés de la carte de statistiques de l'intro.
const String kCivicIntroStatQuestions = 'Questions';
const String kCivicIntroStatThemes = 'Thèmes évalués';
const String kCivicIntroStatSeuil = 'Seuil de réussite';

/// La légende sous le CTA de l'intro. Le constat est gratuit, on le dit.
const String kCivicIntroFreeCaption = 'Votre premier diagnostic est offert.';

/// 🛑 Le diagnostic **n'est pas** un examen blanc (`20_` §4.1), et l'écran doit
/// le dire avant de commencer : sinon le candidat lit son résultat comme un
/// pronostic de réussite.
const String kCivicDiagnosticNotExam =
    'Ce n\'est pas un examen blanc : il sert à repérer ce qu\'il vous reste à travailler.';

const String kCivicDiagnosticStartCta = 'Commencer mon diagnostic';

/// Le tunnel **invité** (`V053`), en mots.
///
/// 🛑 **La démarche est demandée AVANT le tirage**, et ce n'est pas un
/// formulaire de confort : c'est elle qui choisit les questions. Un candidat
/// naturalisation mesuré sur des questions de carte de séjour repartirait avec
/// un diagnostic flatteur et un plan incomplet.
const String kCivicDiagnosticGuestTitle = 'Quelle démarche préparez-vous ?';

/// 🛑 Promesse tenue par le serveur : aucun compte n'est demandé pour répondre.
const String kCivicDiagnosticGuestNote =
    'Pas besoin de compte pour commencer. Il ne vous sera demandé qu\'au moment '
    'de voir votre résultat.';
const String kCivicDiagnosticGuestBadge = 'Sans compte';

/// Le résultat est ce qu'on échange contre le compte — dit sans détour.
const String kCivicDiagnosticGateEyebrow = 'Dernière étape';
const String kCivicDiagnosticGateTitle = 'Vos réponses sont enregistrées';
const String kCivicDiagnosticGateLead =
    'Créez votre compte gratuit pour voir votre résultat et votre plan. '
    'Vos 40 réponses sont déjà en sécurité : elles vous suivent.';
const String kCivicDiagnosticResumeCta = 'Reprendre';
const String kCivicDiagnosticResultCta = 'Voir mon résultat';
const String kCivicDiagnosticPlanCta = 'Découvrir mon plan';

/// L'en-tête d'un diagnostic déjà ouvert (reprise).
const String kCivicDiagnosticEnCoursLabel = 'Votre diagnostic en cours';

/// Les trois démarches, dans l'ordre du livret.
const Map<String, String> kMentionLabel = {
  'CSP': 'Carte de séjour pluriannuelle',
  'CR': 'Carte de résident',
  'NAT': 'Naturalisation',
};

/// Ce que l'écran dit à un compte **dont la démarche est déjà connue**.
///
/// 🛑 **On ne repose pas une question déjà posée.** La démarche est collectée à
/// l'inscription / à l'onboarding (`TargetPathScreen`) : la redemander ici
/// ferait croire qu'elle n'a pas été enregistrée. Elle reste **affichée**,
/// parce qu'elle choisit les questions — le candidat doit pouvoir vérifier sur
/// quel programme il va être mesuré —, et modifiable d'un bouton vers l'écran
/// qui en est déjà l'autorité.
///
/// Miroir de `civicProcedureLine` côté web.
String civicProcedureLine(String wire) =>
    'Vous préparez : ${kMentionLabel[wire] ?? wire}.';

const String kCivicDiagnosticProcedureChangeCta = 'Modifier ma démarche';

/// L'écran qui est **déjà** l'autorité de la démarche (`TargetPathScreen`),
/// avec le retour vers ce hub. Miroir du `/parcours?from=…` du web : aucun
/// écran neuf n'est créé pour changer de démarche.
const String kCivicProcedureChangePath =
    '/target-path?from=%2Fdiagnostic-civique';

/// « 12 sur 40 répondues ». Compté sur ce que le serveur a servi.
String civicProgressionLabel(int repondues, int total) =>
    '$repondues sur $total répondue${repondues > 1 ? 's' : ''}';

const String kCivicScoreLabel = 'Bonnes réponses';

/// La mise en perspective sous le score.
///
/// **Deux formulations, et la différence est de l'honnêteté :** le format
/// entier posé ⇒ le score EST le résultat, on ne projette rien ; un catalogue
/// sous-doté ⇒ on projette, et on le dit, parce qu'un report n'est pas une
/// mesure.
///
/// 🛑 `null` ⇒ aucune phrase : « on n'a rien mesuré » ne se dit pas « vous
/// auriez 0 ».
String? civicPerspectiveLine(CivicDiagnosticResultDto r) {
  final projection = r.projection40;
  if (projection == null) return null;
  if (r.posees == r.formatQuestions) {
    return 'Votre résultat est directement comparable à l\'examen : '
        'vos ${r.posees} questions sont au format de l\'épreuve.';
  }
  return 'Votre résultat actuel correspond à environ $projection / '
      '${r.formatQuestions} sur un examen complet.';
}

/// L'encart de seuil.
///
/// 🛑 **Aucune promesse de réussite.** On dit le seuil, jamais « vous êtes
/// prêt » ni « vous allez échouer ». La mention « estimation » n'apparaît que
/// quand le nombre affiché **est** une estimation : la coller sur un score
/// complet ferait douter d'une mesure exacte.
String civicThresholdLine(CivicDiagnosticResultDto r) {
  final seuil = 'Seuil de référence : ${r.seuilReussite} / ${r.formatQuestions}.';
  return r.posees == r.formatQuestions
      ? seuil
      : '$seuil Il s\'agit d\'une estimation, pas d\'une prédiction de réussite.';
}

/// Le ton d'un thème. 🛑 `nonEvalue` n'a **pas** de couleur d'alerte.
enum CivicThemeTone { ok, warn, hot, muted }

CivicThemeTone civicThemeTone(CivicThemeState etat) => switch (etat) {
      CivicThemeState.solide => CivicThemeTone.ok,
      CivicThemeState.aRenforcer => CivicThemeTone.warn,
      CivicThemeState.faible => CivicThemeTone.hot,
      CivicThemeState.nonEvalue => CivicThemeTone.muted,
    };

const String kCivicThemesTitle = 'Vos thèmes';

const String kCivicSituationsTitle = 'Mises en situation';
const String kCivicSituationsLabel = 'Application des règles';
const String kCivicSituationsText =
    'Les mises en situation demandent d\'appliquer les règles à un cas concret. '
    'C\'est souvent ce qui fait la différence à l\'examen.';

/// « 8 réponses correctes sur 12 ». `null` quand aucune n'a été posée : le mode
/// dégradé **masque toute la section** plutôt que d'annoncer un zéro.
String? situationsLine(CivicDiagnosticResultDto r) {
  if (r.situations.posees <= 0) return null;
  final n = r.situations.reussies;
  return '$n réponse${n > 1 ? 's' : ''} correcte${n > 1 ? 's' : ''} '
      'sur ${r.situations.posees}';
}

/// Le titre du bloc 4, volontairement concret (`20_` §4.5).
const String kCivicPrioritesTitle = 'Ce qui vous coûte le plus de points';

/// 🛑 **Plafond d'AFFICHAGE, jamais un budget.** Le serveur classe *tous* les
/// thèmes sous l'objectif ; l'écran en montre trois et **compte** le reste.
const int kCivicPrioritesVisibles = 3;

const String kCivicRassuranceTitle = 'Vous n\'avez pas besoin de tout réviser';

/// 🛑 `null` quand aucun thème n'est solide : « 0 thème est déjà solide » serait
/// une phrase de consolation qui sonne faux au pire moment.
String? civicRassuranceText(CivicDiagnosticResultDto r) {
  final solides =
      r.themes.where((t) => t.etat == CivicThemeState.solide).length;
  if (solides <= 0) return null;
  return '$solides thème${solides > 1 ? 's sont déjà solides' : ' est déjà solide'}. '
      'Votre plan se concentrera sur ce qui vous fait perdre le plus de points.';
}

const String kCivicPlanTeaserTitle = 'Votre plan Examen civique est prêt';

/// « + 2 autres thèmes à consolider ».
///
/// 🛑 **Un vrai nombre**, celui que le plafond d'affichage n'a pas montré —
/// jamais un « + d'autres » décoratif : le candidat doit pouvoir vérifier.
/// `null` quand la liste servie tient entière à l'écran.
///
/// 🛑 **Le grain est le THÈME**, pas la notion : aucune question n'est encore
/// taguée par notion (`20_` §3.4), et annoncer des « notions » promettrait une
/// finesse que la base ne sert pas.
String? civicAutresPrioritesLine(int total) {
  final reste = total - kCivicPrioritesVisibles;
  if (reste <= 0) return null;
  return '+ $reste autre${reste > 1 ? 's' : ''} thème${reste > 1 ? 's' : ''} '
      'à consolider';
}

/// Le paramètre que le runner reçoit quand la série appartient à un diagnostic
/// civique.
///
/// 🛑 **Sa seule fonction est le RETOUR** — exactement comme
/// [kTcfDiagnosticParam]. Sans lui, le candidat termine ses 40 questions et
/// atterrit sur le bilan de série générique, très loin de son diagnostic. Il ne
/// change **rien d'autre** : ni la passation, ni la correction, ni le décompte.
const String kCivicDiagnosticParam = 'civicDiagnosticId';

/// Le runner, avec le marqueur de retour vers le diagnostic.
String civicRunnerPath(String attemptId, String sessionId) =>
    '/runner/$attemptId?$kCivicDiagnosticParam=$sessionId';

import '../../core/models/civic_diagnostic_models.dart';

/// Règles d'affichage du diagnostic **civique** — **pures**, déclarées une fois
/// pour tout le mobile.
///
/// 🛑 Le serveur n'expose que des **faits** (un état de thème, un compte, une
/// projection). Les phrases vivent ici, et sont des **miroirs mot pour mot** de
/// `web_sejoufr/lib/civic-diagnostic.ts`.
///
/// 🛑 Ce fichier ne **dérive** aucun état pédagogique.

const String kCivicDiagnosticTitle = 'Mon diagnostic — Examen civique';

/// 🛑 Le diagnostic **n'est pas** un examen blanc (`20_` §4.1), et l'écran doit
/// le dire avant de commencer : sinon le candidat lit son résultat comme un
/// pronostic de réussite.
const String kCivicDiagnosticNotExam =
    'Ce n\'est pas un examen blanc : il sert à repérer ce qu\'il vous reste à travailler.';

const String kCivicDiagnosticStartCta = 'Commencer mon diagnostic';
const String kCivicDiagnosticResumeCta = 'Reprendre';
const String kCivicDiagnosticResultCta = 'Voir mon résultat';
const String kCivicDiagnosticPlanCta = 'Découvrir mon plan';

/// 🛑 Le nombre de questions n'est **pas** écrit en dur : il est servi. Le figer
/// dans une phrase reproduirait le piège de la table des paliers en six copies.
String civicDiagnosticSubtitle(int total) =>
    '$total questions, comme à l\'examen, réparties sur les 5 thèmes.';

/// Le badge de mention en tête du résultat (`20_` §4.5).
const Map<String, String> kMentionLabel = {
  'CSP': 'Carte de séjour pluriannuelle',
  'CR': 'Carte de résident',
  'NAT': 'Naturalisation',
};

String mentionBadge(String wire) => kMentionLabel[wire] ?? wire;

/// « 12 sur 40 répondues ». Compté sur ce que le serveur a servi.
String civicProgressionLabel(int repondues, int total) =>
    '$repondues sur $total répondue${repondues > 1 ? 's' : ''}';

/// La phrase sous le score.
///
/// **Deux formulations, et la différence est de l'honnêteté :** le format
/// entier posé ⇒ le score EST le résultat, on ne projette rien ; un catalogue
/// sous-doté ⇒ on projette, et on le dit, parce qu'un report n'est pas une
/// mesure.
///
/// 🛑 `null` ⇒ aucune phrase : « on n'a rien mesuré » ne se dit pas « vous
/// auriez 0 ». Et **aucune promesse de réussite** — on dit le seuil, jamais
/// « vous êtes prêt ».
String? projectionLine(CivicDiagnosticResultDto r) {
  final projection = r.projection40;
  if (projection == null) return null;
  final seuil = 'Le seuil de réussite est de ${r.seuilReussite}.';
  if (r.posees == r.formatQuestions) return seuil;
  return 'Soit environ $projection / ${r.formatQuestions} à l\'examen. $seuil';
}

/// Le ton d'un thème. 🛑 `nonEvalue` n'a **pas** de couleur d'alerte.
enum CivicThemeTone { ok, warn, hot, muted }

CivicThemeTone civicThemeTone(CivicThemeState etat) => switch (etat) {
      CivicThemeState.solide => CivicThemeTone.ok,
      CivicThemeState.aRenforcer => CivicThemeTone.warn,
      CivicThemeState.faible => CivicThemeTone.hot,
      CivicThemeState.nonEvalue => CivicThemeTone.muted,
    };

const String kCivicSituationsTitle = 'Mises en situation';
const String kCivicSituationsText =
    'Les mises en situation demandent d\'appliquer les règles à un cas concret. '
    'C\'est souvent ce qui fait la différence à l\'examen.';

/// « 8 sur 12 réussies ». `null` quand aucune n'a été posée (mode dégradé).
String? situationsLine(CivicDiagnosticResultDto r) {
  if (r.situations.posees <= 0) return null;
  final n = r.situations.reussies;
  return '$n sur ${r.situations.posees} réussie${n > 1 ? 's' : ''}';
}

/// Le titre du bloc 4, volontairement concret (`20_` §4.5).
const String kCivicPrioritesTitle = 'Ce qui vous coûte le plus de points';

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

const String kCivicPlanTeaserTitle = 'Votre plan de révision est prêt';

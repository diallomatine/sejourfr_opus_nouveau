import 'enums.dart';
import 'preparation_models.dart';

/// Les phrases de « Ma préparation » — **pures**, déclarées une fois pour tout
/// le mobile.
///
/// 🛑 **Le serveur sert l'ÉTAPE, ce fichier sert la PHRASE.** « Affiner avec
/// le diagnostic » est une formulation, pas une donnée.
///
/// 🛑 **Trois portes, un seul état.** L'Accueil, le Plan et les Examens
/// appellent tous les trois `preparation()` et passent par ces fonctions.
/// Aucun écran ne déduit son propre libellé — c'est ce qui garantit qu'ils
/// proposent la même prochaine action.
///
/// Miroir mot pour mot de `web_sejoufr/lib/preparation.ts`.

const String kPreparationTitle = 'Ma préparation';
const String kTcfLabel = 'TCF IRN';
const String kCiviqueLabel = 'Examen civique';

/// « Objectif · Naturalisation » — le kicker de l'Accueil (Navigation v2,
/// maquette `#accueil`).
///
/// ⚠️ **Remplace `objectifLabel`** (« Objectif : naturalisation », pastille de
/// l'ancien Accueil, son seul lecteur) — refonte = suppression de l'ancien.
///
/// 🛑 Démarche absente ⇒ `null` : pas de kicker, jamais une démarche par défaut
/// (l'invitation à la choisir est le bandeau de l'Accueil). Miroir mot pour mot
/// de `objectifKicker` (`web_sejoufr/lib/preparation.ts`) ; la table des
/// démarches reste l'autorité unique [TargetProcedure.mentionLabel].
String? objectifKicker(TargetProcedure? procedure) =>
    procedure == null ? null : 'Objectif · ${procedure.mentionLabel}';

/// Où mène la prochaine action d'un module.
typedef PreparationAction = ({String statut, String cta, String route});

/// « B1 → objectif B2 ». `null` si rien n'est mesuré : jamais un palier inventé.
///
/// 🛑 Le palier passe par [NiveauCecrl.displayName], l'autorité d'affichage :
/// jamais le code servi — `wire` écrivait « A1_NON_ATTEINT → objectif B2 ».
String? niveauLine(ModulePreparation m) {
  final niveau = m.niveau;
  if (niveau == null) return null;
  final cible = m.cible;
  return cible == null
      ? niveau.displayName
      : '${niveau.displayName} → objectif ${cible.displayName}';
}

/// **TCF** — le Plan est TOUJOURS la prochaine action.
///
/// 🛑 **D-69 (2026-09-28)** : le Plan existe pour tout compte, diagnostic fait
/// ou non — sans diagnostic, il commence par un cycle d'examens blancs. Le
/// diagnostic n'est plus une porte, ni même une proposition de l'Accueil ou
/// du Plan.
PreparationAction tcfAction(ModulePreparation m) =>
    (statut: _tcfStatut(m), cta: 'Continuer mon plan', route: '/tcf/plan');

/// Ce qu'on sait du candidat.
///
/// 🛑 **Aucun compteur « N / 4 »** : il décrivait l'avancement du diagnostic
/// complet, parcours retiré le 2026-09-26. Le palier mesuré prime dès qu'il est
/// servi, et `null` veut dire « pas encore mesuré », jamais A1.
String _tcfStatut(ModulePreparation m) =>
    niveauLine(m) ??
    (m.estimationSessionId != null
        ? 'Première estimation terminée'
        : 'Diagnostic non réalisé');

/// **CIVIQUE** — le Plan civique est TOUJOURS la prochaine action (D-69) ;
/// seul le statut dit où en est le diagnostic.
PreparationAction civiqueAction(ModulePreparation m) {
  const cta = 'Continuer mon plan';
  const route = '/civique/plan';
  switch (m.etape) {
    case PreparationEtape.diagnosticAFaire:
    // 🛑 `estimationFaite` n'existe PAS côté civique — il n'a qu'UN
    // diagnostic. Ce cas est ici parce que le type est partagé, pas parce
    // qu'il peut arriver.
    case PreparationEtape.estimationFaite:
      return (statut: 'Diagnostic non réalisé', cta: cta, route: route);
    case PreparationEtape.diagnosticEnCours:
      final fait = m.fait;
      final total = m.total;
      return (
        statut: fait != null && total != null
            ? 'Diagnostic : $fait / $total questions'
            : 'Diagnostic en cours',
        cta: cta,
        route: route,
      );
    case PreparationEtape.planPret:
      return (
        statut: aRenforcerLine(m) ?? 'Diagnostic terminé',
        cta: cta,
        route: route,
      );
  }
}

/// « 3 thèmes à renforcer ».
///
/// 🛑 `null` tant que rien n'est mesuré, et une phrase **différente** quand le
/// compte est zéro : « 0 thème à renforcer » se lit comme une erreur
/// d'affichage alors que c'est une bonne nouvelle.
String? aRenforcerLine(ModulePreparation m) {
  final n = m.aRenforcer;
  if (n == null) return null;
  if (n == 0) return 'Tous vos thèmes sont solides';
  return '$n thème${n > 1 ? 's' : ''} à renforcer';
}

/// **Le diagnostic de ce module a-t-il été FAIT (clos) ?** — le seul prédicat
/// qui décide si la ligne « Mon diagnostic » du Plan s'affiche.
///
/// 🛑 **Lu sur un fait servi, jamais déduit** : côté TCF,
/// `estimationSessionId` n'est servi que si un diagnostic **rapide** est clos ;
/// côté civique, l'étape `PLAN_PRET` dit que le diagnostic civique est clos.
/// Préparation absente ⇒ l'appelant ne l'appelle pas, et la ligne reste masquée.
///
/// 🛑 **Le diagnostic n'est plus PROPOSÉ** ni sur l'Accueil ni sur le Plan
/// (la carte « Affinez votre plan avec le diagnostic » et `diagnosticAAffiner`
/// sont supprimées) : on n'y renvoie que pour **relire** un résultat existant.
///
/// Miroir mot pour mot de `diagnosticFait` (`web_sejoufr/lib/preparation.ts`).
bool diagnosticFait(ModulePreparation m, {required bool civique}) => civique
    ? m.etape == PreparationEtape.planPret
    : m.estimationSessionId != null;

// ---------------------------------------------------------------------------
// Le diagnostic COMPLET — RETIRÉ des fronts le 2026-09-26
// ---------------------------------------------------------------------------
//
// 🛑 Décision du propriétaire : le diagnostic complet (4 épreuves) n'est plus
// un parcours proposé. `kDiagnosticCompletRoute` et ses deux CTA (« Faire le
// diagnostic complet » / « Continuer le diagnostic ») sont supprimés, avec les
// écrans `/diagnostic-tcf` (la route redirige vers le Plan). Le rapide ouvre le
// Plan ; les épreuves qu'il ne mesure pas se mesurent par l'examen blanc que le
// Plan propose. `affinerPlan()` / `AffinerPlanCard` l'étaient déjà depuis le
// 2026-09-19. Ne pas les recréer.
//
// ⚠️ Le serveur sert ENCORE l'avancement d'un complet commencé avant le retrait
// (`etape: diagnosticEnCours`, `fait`/`total` sur 4, `prochaineEpreuve`) : ces
// écrans ne l'affichent plus et n'y renvoient plus. Nettoyage backend à
// suivre.

/// **Le marqueur « lance-le tout de suite »** de `/diagnostic`.
///
/// 🛑 Demande du propriétaire (2026-09-12) : le geste du diagnostic, depuis le
/// Plan ou l'Accueil, doit **lancer** le diagnostic, pas ouvrir une page qui
/// redemande de le lancer. Le bouton porte déjà la décision.
///
/// 🛑 **Un marqueur, aucun identifiant** : rien ne voyage dans l'URL que ce
/// drapeau. La présentation reste l'écran normal de `/diagnostic` — elle garde
/// tout son sens pour qui y arrive sans l'avoir demandé (lien profond,
/// visiteur, où elle porte aussi le choix TCF / civique).
///
/// Miroir de `DIAGNOSTIC_START_PARAM` (`web_sejoufr/lib/preparation.ts`).
class DiagnosticDemarrageDirect {
  const DiagnosticDemarrageDirect._();

  static const parametre = 'demarrer';
  static const valeur = '1';

  /// Le chemin à ouvrir pour démarrer sans présentation.
  String chemin(String route) => '$route?$parametre=$valeur';

  /// Le marqueur est-il posé sur cette URL ?
  bool lu(Uri uri) => uri.queryParameters[parametre] == valeur;
}

const kDiagnosticDemarrageDirect = DiagnosticDemarrageDirect._();

import 'enums.dart';
import 'preparation_models.dart';

/// Les phrases de « Ma préparation » — **pures**, déclarées une fois pour tout
/// le mobile.
///
/// 🛑 **Le serveur sert l'ÉTAPE, ce fichier sert la PHRASE.** « Faire mon
/// diagnostic » est une formulation, pas une donnée.
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

/// La pastille d'objectif de l'Accueil : **la démarche servie**, jamais le
/// module — la bascule juste en dessous annonce déjà le parcours.
///
/// 🛑 Démarche absente ⇒ « Choisir mon parcours » : on n'en devine aucune.
/// Miroir mot pour mot de `objectifLabel` (`web_sejoufr/lib/preparation.ts`),
/// et la table des démarches reste l'autorité unique
/// [TargetProcedure.mentionLabel].
String objectifLabel(TargetProcedure? procedure) => procedure == null
    ? 'Choisir mon parcours'
    : 'Objectif : ${procedure.mentionLabel.toLowerCase()}';

/// Où mène la prochaine action d'un module.
typedef PreparationAction = ({String statut, String cta, String route});

/// « B1 → objectif B2 ». `null` si rien n'est mesuré : jamais un palier inventé.
String? niveauLine(ModulePreparation m) {
  final niveau = m.niveau;
  if (niveau == null) return null;
  final cible = m.cible;
  return cible == null
      ? niveau.wire
      : '${niveau.wire} → objectif ${cible.wire}';
}

/// **TCF** — le diagnostic rapide ouvre le Plan.
///
/// 🛑 **Dès que le Plan existe, c'est LUI la prochaine action** (arbitrage du
/// propriétaire, 2026-09-12) — y compris quand un diagnostic complet commencé
/// avant son retrait (2026-09-26) reste ouvert côté serveur.
///
/// 🛑 Seul le RAPIDE se reprend. Un `diagnosticEnCours` qui porte un
/// avancement (`fait != null`) est un complet commencé sans rapide : ce
/// parcours n'existe plus, et il ne fonde pas de Plan tant qu'il n'est pas
/// clos. La porte qui ouvre le Plan est le rapide — on y envoie.
PreparationAction tcfAction(ModulePreparation m) {
  if (m.planDisponible) {
    return (statut: _tcfStatut(m), cta: 'Continuer mon plan', route: '/plan');
  }
  if (m.etape == PreparationEtape.diagnosticEnCours && m.fait == null) {
    return (
      statut: 'Diagnostic en cours',
      cta: 'Reprendre',
      route: kDiagnosticDemarrageDirect.chemin('/diagnostic'),
    );
  }
  return (
    statut: 'Diagnostic non réalisé',
    cta: 'Faire mon diagnostic',
    route: kDiagnosticDemarrageDirect.chemin('/diagnostic'),
  );
}

/// Ce qu'on sait du candidat quand son Plan existe.
///
/// 🛑 **Aucun compteur « N / 4 »** : il décrivait l'avancement du diagnostic
/// complet, parcours retiré le 2026-09-26. Le palier mesuré prime dès qu'il est
/// servi, et `null` veut dire « pas encore mesuré », jamais A1.
String _tcfStatut(ModulePreparation m) =>
    niveauLine(m) ?? 'Première estimation terminée';

/// **CIVIQUE** — un seul diagnostic.
PreparationAction civiqueAction(ModulePreparation m) {
  switch (m.etape) {
    case PreparationEtape.diagnosticAFaire:
    // 🛑 `estimationFaite` n'existe PAS côté civique — il n'a qu'UN
    // diagnostic. Ce cas est ici parce que le type est partagé, pas parce
    // qu'il peut arriver.
    case PreparationEtape.estimationFaite:
      return (
        statut: 'Diagnostic non réalisé',
        cta: 'Faire mon diagnostic civique',
        route: '/diagnostic-civique',
      );
    case PreparationEtape.diagnosticEnCours:
      final fait = m.fait;
      final total = m.total;
      return (
        statut: fait != null && total != null
            ? 'Diagnostic : $fait / $total questions'
            : 'Diagnostic en cours',
        cta: 'Reprendre',
        route: '/diagnostic-civique',
      );
    case PreparationEtape.planPret:
      return (
        statut: aRenforcerLine(m) ?? 'Diagnostic terminé',
        cta: 'Continuer mon plan',
        route: '/plan?module=CIVIQUE',
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

/// Le Plan d'un module peut-il être construit ?
typedef PlanIndisponible = ({
  String titre,
  String texte,
  String cta,
  String route,
});

/// 🛑 `null` = **oui**, l'onglet affiche le vrai Plan. Sinon, il explique
/// pourquoi et ouvre la seule porte qui débloque — jamais un plan vide, jamais
/// un plan bâti sur une mesure qui n'existe pas.
PlanIndisponible? planIndisponible(ModulePreparation m, {required bool civique}) {
  // 🛑 **Le fait servi, jamais l'étape.** Arbitrage du propriétaire du
  // 2026-09-12 : le diagnostic complet n'est plus un prérequis d'accès au Plan,
  // seulement un moyen de l'affiner. Dès que le diagnostic rapide est clos, le
  // serveur sait bâtir un Plan provisoire mais **réel** — ses priorités
  // viennent d'observations vraies, et aucun domaine non mesuré n'en reçoit.
  // Lire `etape` ici ferait dire « pas encore prêt » à un écran que le moteur
  // sert déjà.
  if (m.planDisponible) return null;

  // 🛑 **Un diagnostic COMMENCÉ ne se « fait » pas, il se REPREND.**
  // Redemander « Faire mon diagnostic » à quelqu'un qui vient d'en répondre la
  // moitié lui fait croire que son travail est perdu.
  //
  // 🛑 Côté TCF, seul le **rapide** se reprend (`fait == null`). Un complet
  // commencé sans rapide (`fait != null`) ne se reprend plus — parcours retiré
  // le 2026-09-26 — et ne fonde pas de Plan tant qu'il n'est pas clos : la
  // porte est le rapide, comme pour un candidat qui n'a rien commencé.
  if (civique && m.etape == PreparationEtape.diagnosticEnCours) {
    return (
      titre: 'Votre diagnostic civique est commencé',
      texte: _avancement(m) ??
          'Terminez-le pour que votre plan se construise.',
      cta: 'Reprendre mon diagnostic',
      route: '/diagnostic-civique',
    );
  }
  if (!civique &&
      m.etape == PreparationEtape.diagnosticEnCours &&
      m.fait == null) {
    return (
      titre: 'Votre diagnostic TCF est commencé',
      texte: 'Terminez-le pour que votre plan se construise.',
      cta: 'Reprendre mon diagnostic',
      route: kDiagnosticDemarrageDirect.chemin('/diagnostic'),
    );
  }

  if (civique) {
    return (
      titre: 'Votre plan civique commence par un diagnostic',
      texte: 'Répondez à quelques questions pour identifier les thèmes et les '
          'notions à travailler.',
      cta: 'Faire mon diagnostic civique',
      route: '/diagnostic-civique',
    );
  }

  return (
    titre: 'Votre plan TCF commence par un diagnostic',
    texte: 'Une première estimation écrite ouvre votre plan. Les autres '
        'épreuves se mesurent ensuite par un examen blanc, depuis votre plan.',
    cta: 'Faire mon diagnostic',
    route: kDiagnosticDemarrageDirect.chemin('/diagnostic'),
  );
}

/// « Vous avez répondu à 14 questions sur 40. » — l'avancement du diagnostic
/// CIVIQUE, seul lecteur depuis le retrait du complet TCF (2026-09-26).
///
/// 🛑 `null` quand le serveur n'a pas servi d'avancement : on ne fabrique pas un
/// compteur pour remplir une phrase.
String? _avancement(ModulePreparation m) {
  final fait = m.fait;
  final total = m.total;
  if (fait == null || total == null) return null;
  return 'Vous avez répondu à $fait question${fait > 1 ? 's' : ''} sur $total.';
}

/// Le module sur lequel ouvrir le toggle : celui qui a quelque chose à dire.
///
/// 🛑 On ouvre sur le module DÉJÀ commencé plutôt que toujours sur le TCF : un
/// candidat qui ne prépare que le civique n'a aucune raison d'arriver sur un
/// onglet vide.
bool moduleCiviqueParDefaut(PreparationDto prep) =>
    prep.tcf.etape == PreparationEtape.diagnosticAFaire &&
    prep.civique.etape != PreparationEtape.diagnosticAFaire;

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
// écrans ne l'affichent plus et n'y renvoient plus (voir [tcfAction] et
// [planIndisponible]). Nettoyage backend à suivre.

/// **Le marqueur « lance-le tout de suite »** de `/diagnostic`.
///
/// 🛑 Demande du propriétaire (2026-09-12) : « Faire mon diagnostic », depuis le
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

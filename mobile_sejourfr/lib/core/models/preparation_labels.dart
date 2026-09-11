import 'preparation_models.dart';

/// Les phrases de « Ma préparation » — **pures**, déclarées une fois pour tout
/// le mobile.
///
/// 🛑 **Le serveur sert l'ÉTAPE, ce fichier sert la PHRASE.** « Faire mon
/// diagnostic complet » est une formulation, pas une donnée.
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

/// **TCF** — deux diagnostics, deux objectifs.
PreparationAction tcfAction(ModulePreparation m) {
  switch (m.etape) {
    case PreparationEtape.diagnosticAFaire:
      return (
        statut: 'Diagnostic non réalisé',
        cta: 'Faire mon diagnostic',
        route: '/diagnostic',
      );
    case PreparationEtape.diagnosticEnCours:
      final fait = m.fait;
      final total = m.total;
      return (
        statut: fait != null && total != null
            ? 'Diagnostic complet : $fait / $total épreuves'
            : 'Diagnostic en cours',
        cta: 'Reprendre',
        route: fait != null ? '/diagnostic-tcf' : '/diagnostic',
      );
    case PreparationEtape.estimationFaite:
      // 🛑 Le rapide est TERMINÉ, et on le dit — mais il ne suffit pas à bâtir
      // le Plan : il n'a observé qu'une production écrite.
      return (
        statut: 'Première estimation terminée',
        cta: 'Faire mon diagnostic complet',
        route: '/diagnostic-tcf',
      );
    case PreparationEtape.planPret:
      return (
        statut: niveauLine(m) ?? 'Diagnostic terminé',
        cta: 'Continuer mon plan',
        route: '/plan',
      );
  }
}

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

/// Le lien secondaire de la porte d'entrée du Plan : consulter ce qui est
/// déjà fait.
///
/// 🛑 **Aucun écran de rapport n'est recréé** : `/diagnostic` sert déjà le
/// rapport quand la session est close (`DiagnosticScreen`, miroir du web).
/// Une seconde route vers le même contenu aurait fini par en montrer une
/// version qui ne bouge plus.
///
/// Miroir de `PLAN_GATE_RAPPORT_CTA` (`web_sejoufr/lib/preparation.ts`).
const String kPlanGateRapportCta = 'Revoir mon diagnostic rapide';

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
  if (m.etape == PreparationEtape.planPret) return null;

  // 🛑 **Un diagnostic COMMENCÉ ne se « fait » pas, il se REPREND.**
  // Redemander « Faire mon diagnostic » à quelqu'un qui vient d'en répondre la
  // moitié lui fait croire que son travail est perdu.
  if (m.etape == PreparationEtape.diagnosticEnCours) {
    return (
      titre: civique
          ? 'Votre diagnostic civique est commencé'
          : 'Votre diagnostic TCF est commencé',
      texte: _avancement(m) ??
          'Terminez-le pour que votre plan se construise.',
      cta: 'Reprendre mon diagnostic',
      route: civique
          ? '/diagnostic-civique'
          : (m.fait != null ? '/diagnostic-tcf' : '/diagnostic'),
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

  if (m.etape == PreparationEtape.estimationFaite) {
    return (
      titre: 'Votre plan TCF n\'est pas encore prêt',
      texte: 'Votre première estimation a identifié quelques axes, mais nous '
          'devons aussi évaluer votre oral et vos compréhensions.',
      cta: 'Faire mon diagnostic TCF complet',
      route: '/diagnostic-tcf',
    );
  }

  return (
    titre: 'Votre plan TCF commence par un diagnostic',
    texte: 'Une première estimation écrite, puis les quatre épreuves : c\'est ce '
        'qui permet de savoir quoi travailler en premier.',
    cta: 'Faire mon diagnostic',
    route: '/diagnostic',
  );
}

/// « Vous avez répondu à 14 questions sur 40. »
///
/// 🛑 `null` quand le serveur n'a pas servi d'avancement : on ne fabrique pas un
/// compteur pour remplir une phrase.
String? _avancement(ModulePreparation m) {
  final fait = m.fait;
  final total = m.total;
  if (fait == null || total == null) return null;
  return total > 4
      ? 'Vous avez répondu à $fait question${fait > 1 ? 's' : ''} sur $total.'
      : 'Vous avez terminé $fait épreuve${fait > 1 ? 's' : ''} sur $total.';
}

/// Le module sur lequel ouvrir le toggle : celui qui a quelque chose à dire.
///
/// 🛑 On ouvre sur le module DÉJÀ commencé plutôt que toujours sur le TCF : un
/// candidat qui ne prépare que le civique n'a aucune raison d'arriver sur un
/// onglet vide.
bool moduleCiviqueParDefaut(PreparationDto prep) =>
    prep.tcf.etape == PreparationEtape.diagnosticAFaire &&
    prep.civique.etape != PreparationEtape.diagnosticAFaire;

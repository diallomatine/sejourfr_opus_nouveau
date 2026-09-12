import 'enums.dart';
import 'preparation_models.dart';

/// Les phrases de « Ma préparation » — **pures**, déclarées une fois pour tout
/// le mobile.
///
/// 🛑 **Le serveur sert l'ÉTAPE, ce fichier sert la PHRASE.** « Faire le
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

/// **TCF** — deux diagnostics, deux objectifs.
///
/// 🛑 **Dès que le Plan existe, c'est LUI la prochaine action** (arbitrage du
/// propriétaire, 2026-09-12). Le diagnostic complet n'est plus une porte à
/// franchir : il affine, et cette invitation-là vit dans [affinerPlan], en
/// action **secondaire**. Envoyer ici vers `/diagnostic-tcf` remettrait une
/// étape obligatoire devant un plan déjà utilisable.
PreparationAction tcfAction(ModulePreparation m) {
  if (m.planDisponible) {
    return (statut: _tcfStatut(m), cta: 'Continuer mon plan', route: '/plan');
  }
  // Sans base close, deux diagnostics inachevés peuvent rester : le complet
  // commencé sans rapide (`fait != null`) et le rapide lui-même.
  if (m.etape == PreparationEtape.diagnosticEnCours) {
    final fait = m.fait;
    return fait != null
        ? (
            statut: 'Diagnostic complet : $fait / ${m.total} épreuves',
            cta: kDiagnosticCompletCtaResume,
            route: kDiagnosticCompletRoute,
          )
        : (statut: 'Diagnostic en cours', cta: 'Reprendre', route: '/diagnostic');
  }
  return (
    statut: 'Diagnostic non réalisé',
    cta: 'Faire mon diagnostic',
    route: '/diagnostic',
  );
}

/// Ce qu'on sait du candidat quand son Plan existe.
///
/// 🛑 **Jamais « 0 / 4 »** : un compteur à zéro se lit comme un échec alors que
/// le candidat vient de terminer son estimation. Le palier mesuré prime dès
/// qu'il existe — c'est le complet qui le sert, et `null` veut dire « pas
/// encore mesuré », jamais A1.
String _tcfStatut(ModulePreparation m) {
  final niveau = niveauLine(m);
  if (niveau != null) return niveau;
  final fait = m.fait;
  final total = m.total;
  if (fait != null && total != null && fait > 0) {
    return 'Diagnostic complet : $fait / $total épreuves';
  }
  return 'Première estimation terminée';
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
  if (m.etape == PreparationEtape.diagnosticEnCours) {
    return (
      titre: civique
          ? 'Votre diagnostic civique est commencé'
          : 'Votre diagnostic TCF est commencé',
      texte: _avancement(m) ??
          'Terminez-le pour que votre plan se construise.',
      // Côté TCF, deux diagnostics inachevés peuvent fermer la porte, et ils
      // ne se reprennent pas au même endroit : le **rapide** (`fait == null`,
      // aucun complet ouvert), et le **complet commencé par quelqu'un qui n'a
      // pas fait le rapide** (`fait != null`) — 🛑 même à 3 / 4, il ne fonde
      // pas de Plan tant qu'il n'est pas clos (arbitrage du 2026-09-12).
      cta: !civique && m.fait != null
          ? kDiagnosticCompletCtaResume
          : 'Reprendre mon diagnostic',
      route: civique
          ? '/diagnostic-civique'
          : (m.fait != null ? kDiagnosticCompletRoute : '/diagnostic'),
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

// ---------------------------------------------------------------------------
// AFFINER le Plan — le diagnostic complet devient une action SECONDAIRE
// ---------------------------------------------------------------------------

/// L'invitation au diagnostic complet, sous ses **trois** formes.
///
/// 🛑 **Le complet ne bloque jamais le Plan** (arbitrage du propriétaire,
/// 2026-09-12) : il l'affine. Cette carte se pose donc **après** le contenu
/// principal, et ne concurrence jamais le CTA d'abonnement d'un compte gratuit.
///
/// Trois formes, décidées par des **faits servis**, jamais par un compteur
/// reconstruit :
/// - `0 / 4`, jamais commencé → « Affiner votre Plan ». 🛑 **On n'affiche pas
///   « 0 / 4 »** : un compteur à zéro se lit comme un retard alors que rien n'a
///   été promis.
/// - `1 / 4` à `3 / 4` → « Diagnostic complet en cours », avec sa progression,
///   sa barre, et la prochaine épreuve **si le serveur la sert**.
/// - `4 / 4` → `null`, plus aucune invitation nulle part.
typedef AffinerPlan = ({
  /// Épreuves terminées du diagnostic complet — **servi**.
  int fait,
  int total,

  /// `true` dès la première épreuve terminée.
  bool enCours,
  String titre,
  String texte,

  /// « 2 / 4 épreuves terminées ». `null` tant que rien n'est commencé.
  String? progression,

  /// « Prochaine épreuve : Expression orale ». 🛑 `null` si non servie.
  String? prochaineEpreuve,
  String cta,
  String route,
});

/// Où le candidat reprend son diagnostic complet.
///
/// 🛑 **Le hub, jamais un lancement direct.** C'est lui qui « reprend où on
/// s'est arrêté » : une épreuve terminée n'y porte plus aucun bouton, et une
/// épreuve qui démarre le fait après son avertissement (« une fois commencée,
/// elle se termine d'une traite »). Un lien profond qui lancerait la prochaine
/// épreuve sauterait cet avertissement et déclencherait un chrono par surprise.
const String kDiagnosticCompletRoute = '/diagnostic-tcf';

/// 🛑 **LES DEUX SEULS LIBELLÉS du diagnostic complet**, et ils sont décidés par
/// son avancement — arbitrage du propriétaire, 2026-09-12 :
///
/// | avancement | CTA |
/// |---|---|
/// | jamais commencé | « Faire le diagnostic complet » |
/// | `1/4` · `2/4` · `3/4` | « Continuer le diagnostic » |
/// | terminé | **aucun CTA de diagnostic** |
///
/// La variante « Faire mon diagnostic complet » est **supprimée** : elle
/// cohabitait avec « Faire mon diagnostic TCF complet » et « Faire le
/// diagnostic complet », trois phrases pour un seul geste. Tout le mobile les
/// lit ici. Miroir de `web_sejoufr/lib/preparation.ts`.
const String kDiagnosticCompletCtaStart = 'Faire le diagnostic complet';
const String kDiagnosticCompletCtaResume = 'Continuer le diagnostic';

/// Le retour vers le rapport du diagnostic **rapide**.
///
/// 🛑 **Un lien, jamais un bouton, jamais une carte**, et posé en bas de page :
/// le Plan sert à avancer, le rapport sert seulement à revenir comprendre d'où
/// viennent les premières priorités. Il ne doit concurrencer ni « Débloquer mon
/// plan » (compte gratuit) ni « À faire maintenant » (abonné).
const String kPlanRevoirEstimation = 'Revoir mon diagnostic rapide';

/// Miroir mot pour mot de `affinerPlan` (`web_sejoufr/lib/preparation.ts`).
AffinerPlan? affinerPlan(
  ModulePreparation m, {
  required bool accueil,
  required bool abonne,
}) {
  // Pas de Plan ⇒ rien à affiner : la porte d'entrée dit déjà quoi faire.
  if (!m.planDisponible) return null;
  final fait = m.fait;
  final total = m.total;
  // 🛑 Aucun compteur servi ⇒ aucune carte. On ne fabrique pas un « 0 / 4 »
  // pour remplir un emplacement (le civique n'a qu'un diagnostic, il n'a jamais
  // rien à affiner).
  if (fait == null || total == null || total <= 0) return null;
  // 4 / 4 : plus aucune invitation, plus aucune progression, nulle part.
  if (fait >= total) return null;

  final enCours = fait > 0;
  final restant = total - fait;
  final progression = enCours ? '$fait / $total épreuves terminées' : null;
  final prochaine = m.prochaineEpreuve == null
      ? null
      : 'Prochaine épreuve : ${m.prochaineEpreuve!.displayLabel}';

  if (accueil) {
    // 🛑 L'Accueil ne montre le complet **que** s'il est commencé : une
    // invitation de plus sur un écran qui en porte déjà deux deviendrait du
    // bruit, et elle vit déjà sur le Plan.
    if (!enCours) return null;
    return (
      fait: fait,
      total: total,
      enCours: enCours,
      titre: 'Continuez votre diagnostic complet',
      texte: 'Il vous reste $restant épreuve${restant > 1 ? 's' : ''} pour '
          'compléter l\'analyse de vos compétences.',
      progression: progression,
      prochaineEpreuve: prochaine,
      cta: kDiagnosticCompletCtaResume,
      route: kDiagnosticCompletRoute,
    );
  }

  if (enCours) {
    return (
      fait: fait,
      total: total,
      enCours: enCours,
      titre: 'Diagnostic complet en cours',
      texte: 'Continuez votre diagnostic pour affiner progressivement votre '
          'Plan.',
      progression: progression,
      prochaineEpreuve: prochaine,
      cta: kDiagnosticCompletCtaResume,
      route: kDiagnosticCompletRoute,
    );
  }

  // Jamais commencé. Deux formulations : un compte gratuit vient de voir ce qui
  // a été détecté et doit d'abord débloquer ; un abonné utilise déjà son Plan
  // et n'a qu'à le préciser.
  return (
    fait: fait,
    total: total,
    enCours: enCours,
    titre: abonne ? 'Rendez votre Plan encore plus précis' : 'Affiner votre Plan',
    texte: abonne
        ? 'Complétez le diagnostic complet pour analyser les autres compétences '
            'et affiner vos priorités.'
        : 'Votre diagnostic rapide nous a permis d\'identifier vos premières '
            'priorités. Le diagnostic complet analyse vos 4 compétences pour '
            'rendre votre Plan encore plus précis.',
    progression: null,
    prochaineEpreuve: null,
    cta: kDiagnosticCompletCtaStart,
    route: kDiagnosticCompletRoute,
  );
}

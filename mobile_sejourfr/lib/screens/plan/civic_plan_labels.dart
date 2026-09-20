import '../../core/models/civic_diagnostic_models.dart';
import '../../core/models/civic_plan_models.dart';
import '../../core/models/journey_models.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import 'journey_labels.dart';
import 'plan_now_card.dart';

/// Les **mots** du plan civique (L10, `20_` §6) — **purs**, déclarés une fois
/// pour tout le mobile.
///
/// 🛑 **Le serveur n'expose que des faits** : un état de maîtrise, une boîte,
/// une échéance, un compte d'erreurs. Les phrases vivent ici, et sont des
/// **miroirs mot pour mot** de `web_sejoufr/lib/civic-plan.ts` : un libellé qui
/// bouge, ce sont deux fichiers dans la même passe.
///
/// ✅ **L'asymétrie d'inventaire de P8.7 est REFERMÉE** (2026-09-20, second
/// arbitrage du propriétaire : « pour la partie Examen civique du plan, pour un
/// non abonné, il faut aussi la même chose qu'un abonné, sauf qu'il peut pas
/// travailler dessus »). A84 avait laissé trois helpers côté Dart seulement,
/// parce que l'écran **gratuit** civique gardait son anatomie propre. Les deux
/// anatomies gratuites ayant disparu, la divergence tombe d'elle-même :
/// `civicPlanAutresLabel` part avec sa section, [CivicCibleTone] **reste** (son
/// dernier lecteur n'est plus le Plan mais l'écran Progrès et l'Accueil), et
/// [kCivicPlanLockedCta] est **promu** côté web sous le nom
/// `CIVIC_PLAN_LOCKED_CTA` — il a maintenant un lecteur des deux côtés.
/// ⚠️ **A89 est donc révoquée** : ce que D-50 arbitrait pour le plan d'un
/// abonné vaut désormais pour les deux.
///
/// ⚠️ `20_` §10 prévoyait un `civic_plan_item.reason_text` calculé serveur. Il
/// n'existe pas, et c'est délibéré : un texte composé côté serveur ne se relit
/// pas dans deux mises en page différentes.

/// Bloc 2 — à faire maintenant.
const String kCivicPlanNowTitle = 'À faire maintenant';

/// Le geste d'une action **fermée** — la série, pas le plan entier.
///
/// 🛑 **Aucune chaîne neuve n'est gelée** : elle existait déjà ici et n'avait
/// jamais eu de lecteur web. Elle en a un des deux côtés depuis que le Plan
/// civique gratuit porte l'anatomie de l'abonné (miroir :
/// `CIVIC_PLAN_LOCKED_CTA`).
///
/// ⚠️ **Distincte de [kJourneyStepUnlockLink]** (« Débloquer mon plan → »), qui
/// est le geste d'une **ligne du cycle** : là on parle du plan entier, ici d'une
/// série. Même raison que `kPlanNowLockedCta` côté TCF (A114).
const String kCivicPlanLockedCta = 'Débloquer cette série';
const String kCivicPlanLockedNote =
    'Les séries ciblées font partie de l\'abonnement. Votre plan, lui, reste entier.';

/// Le geste d'une cible ou d'une unité, hors carte d'action. Miroir de
/// `CIVIC_PLAN_WORK_CTA` (`web_sejoufr/lib/civic-plan.ts`).
const String kCivicPlanWorkCta = 'Travailler';

/// Bloc 5 — révision d'entretien. 🛑 Jamais présentée comme une alerte.
const String kCivicPlanReviewTitle = 'À revoir bientôt';

/// La note de grain — elle **dit** à quel niveau le plan travaille.
///
/// 🛑 Le plan ne fait pas semblant d'être plus précis qu'il ne l'est. Tant que
/// les questions ne sont pas taguées, il travaille thème par thème (`20_` §3.3,
/// phase 1) et l'écrit. `null` une fois que tout a basculé.
String? civicPlanGrainNote(CivicPlanGrainDto grain) {
  if (grain.courant == CivicPlanGrain.notion) return null;
  return 'Votre plan travaille thème par thème. Il deviendra plus précis, '
      'notion par notion, à mesure que le référentiel civique se complète.';
}

/// L'ordre de grandeur d'une série. **Dérivé** de ce que le serveur sert :
/// raccourcir la série raccourcit la promesse, sans toucher un écran.
///
/// 🛑 Ordre de grandeur, jamais un chrono.
String civicSerieLabel(CivicPlanCible cible) {
  final minutes = (cible.dureeEstimeeSec / 60).round().clamp(1, 999);
  return '${cible.questionsSerie} questions ciblées · ~$minutes min';
}

/// **Pourquoi cette cible est là.** Une phrase, tirée des faits servis.
///
/// 🛑 **Jamais un reproche sur une absence de mesure.** Une cible que le
/// candidat n'a jamais touchée n'a rien raté : elle est « pas encore
/// travaillée », et ce n'est pas la même chose.
String civicPlanRaison(CivicPlanCible cible) {
  if (cible.erreursRecentes > 0) {
    final s = cible.erreursRecentes > 1 ? 's' : '';
    return '${cible.erreursRecentes} erreur$s récente$s';
  }
  if (cible.aRevoir) return 'À revoir pour ne pas l\'oublier';
  if (cible.reponses == 0) return 'Pas encore travaillé';
  if (cible.maitrise == CivicMaitrise.aTravailler) {
    return 'Fragile à la dernière tentative';
  }
  return 'En cours d\'acquisition';
}

/// Le ton d'une cible. 🛑 `nonEvaluee` n'a **pas** de couleur d'alerte : c'est
/// une absence de mesure, pas un échec.
enum CivicCibleTone { hot, warn, ok, muted }

/// « à revoir dans 2 jours ». `null` quand l'échéance est absente.
String? civicRevueLabel(CivicPlanCible cible, DateTime maintenant) {
  final revue = cible.prochaineRevue;
  if (revue == null) return null;
  final jours = revue.difference(maintenant).inHours / 24;
  final arrondi = jours.ceil();
  if (arrondi <= 0) return 'à revoir maintenant';
  return 'à revoir dans $arrondi jour${arrondi > 1 ? 's' : ''}';
}

/* --------------------------------------------- l'écran « Mon plan » (kit)   */

const String kCivicPlanTopKicker =
    'Votre préparation personnalisée à l\'Examen civique';
const String kCivicPlanTopKickerFree = 'Créé à partir de votre diagnostic';
const String kCivicPlanScreenTitle = 'Mon plan du jour';

/// Le ton d'un état de thème **servi**.
CivicCibleTone civicThemeTone(CivicThemeState etat) => switch (etat) {
      CivicThemeState.solide => CivicCibleTone.ok,
      CivicThemeState.aRenforcer => CivicCibleTone.warn,
      CivicThemeState.faible => CivicCibleTone.hot,
      CivicThemeState.nonEvalue => CivicCibleTone.muted,
    };

/// Le ton de la **jauge** d'un thème, sur les cartes « Où vous en êtes ».
///
/// 🛑 Il **dérive** de [civicThemeTone], il ne reclasse pas l'état : une
/// seconde table finirait par colorer autrement le même thème d'un écran à
/// l'autre. Miroir web : `civicBarTone` (`lib/civic-plan.ts`).
SfBarTone civicThemeBarTone(CivicThemeState etat) =>
    switch (civicThemeTone(etat)) {
      CivicCibleTone.ok => SfBarTone.ok,
      CivicCibleTone.warn => SfBarTone.warn,
      CivicCibleTone.hot => SfBarTone.hot,
      CivicCibleTone.muted => SfBarTone.muted,
    };

/* ⚠️ **`civicThemeJauge` est SUPPRIMÉE** (2026-09-19). Elle rendait le
   remplissage d'une jauge continue à quatre positions fixes (0 · 0,3 · 0,6 · 1)
   pour la ligne de thème de l'Accueil. Cette ligne rend désormais son état avec
   le **même cran segmenté que l'échelle TCF**, et les crans sont les valeurs
   mesurées de l'enum servi — `accueilEchelonsCivique`
   (`screens/progres/progres_labels.dart`). Son dernier lecteur et sa primitive
   (`SfProgressMini`) partent dans la même passe. Miroir web : `civicBarJauge`,
   supprimée aussi. */

/// Le libellé de l'encart bleu de la carte d'action.
///
/// ⚠️ « Objectif de cette séance » de la maquette n'est **pas servi** (aucun
/// `reason_text`) : on nomme ce qu'on sait dire, c'est-à-dire **pourquoi** cette
/// cible passe maintenant.
const String kCivicPlanNowWhy = 'Pourquoi maintenant';

const String kCivicPlanReviewPill = 'Révision courte';

/// La ligne d'une révision d'entretien. 🛑 **La boîte Leitner ne s'affiche
/// jamais** : on dit la maîtrise servie et l'échéance.
String civicPlanReviewText(CivicPlanCible cible, DateTime maintenant) {
  final revue = civicRevueLabel(cible, maintenant);
  final base = '${cible.maitrise.label}.';
  return revue == null
      ? '$base Une courte révision est prévue pour vérifier qu\'elle tient '
          'encore.'
      : '$base Une courte révision est prévue $revue, pour vérifier qu\'elle '
          'tient encore.';
}

/* --------------------------------------- l'offre d'un compte sans pass ---- */

/* 🛑 **La carte bleue « Passez du diagnostic à la progression » ET le sélecteur
   de pass sont SUPPRIMÉS** (demande du propriétaire, 2026-09-20), avec leurs
   libellés : `kCivicPlanUnlockHeroTitle` / `…Text`, `kCivicPassTitle` /
   `…Subtitle` / `…Note`, l'enum `CivicPassDuree` et `civicPlanUnlockCaption`.
   La promesse vit sur l'écran de transition (`plan_unlock_labels.dart`) et le
   choix de la durée sur l'écran d'offre, seule autorité du catalogue. */

const String kCivicPlanUnlockCta = 'Débloquer mon plan';

/* ------------------------------------------ « À faire maintenant » civique */

/// **Le geste d'une CIBLE du plan dérivé** — la seule autorité civique sur « que
/// se passe-t-il quand on la touche ».
///
/// 🛑 **Un écran ne redéduit jamais ce geste d'un `locked` ni d'un statut
/// d'abonnement.** C'est la transposition exacte de [planNowCard] (A114) : le
/// drapeau `free` **court-circuite avant** le verrou servi, donc aucun écran ne
/// peut faire partir une série pour un compte sans accès — et c'est le seul
/// endroit à relire pour s'en assurer (D-33, que `CivicPlanService` oppose déjà
/// en 403).
///
/// ⚠️ Miroir mot pour mot du web (`civicCibleGeste`, `lib/civic-plan.ts`).
PlanNowGeste civicCibleGeste(CivicPlanCible cible, {bool free = false}) =>
    free || cible.locked ? PlanNowGeste.debloquer : PlanNowGeste.lancer;

/// Ce que la carte « À faire maintenant » civique **lance**.
sealed class CivicNowSource {
  const CivicNowSource();
}

/// Une **unité officielle** du cycle (D-48) — `startCivicUniteSerie`.
class CivicNowUnite extends CivicNowSource {
  const CivicNowUnite(this.code);

  final String code;
}

/// Une **cible** du plan dérivé (une notion, ou un thème en mode dégradé) —
/// `startCivicSerie`.
class CivicNowCible extends CivicNowSource {
  const CivicNowCible(this.cible);

  final CivicPlanCible cible;
}

/// L'identité **complète** de la carte : ce qu'elle montre, et ce qu'elle lance.
class CivicNowCard {
  const CivicNowCard({
    required this.geste,
    required this.etapeRoute,
    required this.source,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.objectiveLabel,
    required this.objective,
    required this.meta,
    required this.cta,
    required this.locked,
  });

  /// 🛑 **Ce que le geste fait**, décidé dans [civicNowCard] et nulle part
  /// ailleurs.
  final PlanNowGeste geste;

  /// **Où mène [PlanNowGeste.ouvrirEtape]** — servi avec lui, `null` partout
  /// ailleurs. 🛑 Un écran ne recompose jamais cette adresse.
  final String? etapeRoute;

  /// `null` quand rien ne se résout — la carte nomme l'étape et s'arrête là.
  final CivicNowSource? source;

  final String title;
  final String? subtitle;
  final String? badge;
  final String? objectiveLabel;
  final String? objective;

  /// La ligne de méta, **sans son icône** : celle-ci appartient à l'écran.
  final String? meta;

  final String cta;

  /// Le verrou **lu**, jamais déduit d'un rang ni d'un abonnement.
  final bool locked;
}

/// **« À faire maintenant », côté civique** — l'autorité unique des deux écrans
/// (abonné et sans accès) et des deux fronts.
///
/// 🛑 **Le CYCLE décide quelle étape** (D-50 §2) : `journey.current` passe
/// **avant** le plan dérivé, et c'est lui qui a supprimé, le 2026-09-16, la
/// contradiction où l'Accueil annonçait une action et le Plan une autre au même
/// instant.
///
/// 🛑 **Le repli sur `plan.prochaine` est la MÊME forme que [planNowCard]**
/// (`duParcours ?? plan.currentPriority`), et il n'est pas décoratif : dès que
/// le serveur verrouillera les étapes d'entraînement civiques d'un compte sans
/// accès (cf. la moitié backend de cette passe), `JourneyReadService.elire` les
/// sautera et `journey.current` vaudra `null` — exactement ce qui arrive déjà au
/// TCF gratuit. Sans repli, la carte **disparaîtrait** le jour où le verrou est
/// servi, et l'écran gratuit perdrait ce que le propriétaire demande d'y voir.
///
/// 🛑 **`free` ne décide QUE du geste** (A114, transposée) : un compte sans
/// accès reçoit **exactement** la carte d'un abonné — titre, bloc, méta, constat
/// du correcteur — et son bouton ouvre l'**offre** au lieu de lancer. La
/// contradiction #1 reste fermée : on floute l'action, jamais le résultat
/// mesuré.
///
/// ⚠️ Miroir mot pour mot du web (`civicNowCard`, `lib/civic-plan.ts`).
CivicNowCard? civicNowCard(
  CivicPlan plan, {
  Journey? journey,
  bool free = false,
}) {
  final etape = journey?.current;
  if (etape != null) {
    final unite = etape.unite;
    // 🛑 Un examen de bloc ne se lance pas d'ICI : il a son encart dans le
    // cycle. Rien ne se résout ⇒ aucun geste (garde-fou du 2026-09-17).
    final resoluble = unite != null && etape.type == JourneyStepType.trainSkill;
    final verrou = free || etape.locked;
    // 🛑 **UNE UNITÉ CIVIQUE OUVRE SON ÉCRAN, elle ne lance plus sa série**
    // (demande du propriétaire, 2026-09-20) — la même règle et le **même
    // prédicat** que le TCF ([journeyEtapeASeries]), lus ici pour que le bouton
    // « Travailler » aboutisse au même écran que la ligne du cycle.
    // `debloquer` reste prioritaire.
    final serie = journeyEtapeASeries(etape);
    return CivicNowCard(
      geste: verrou
          ? PlanNowGeste.debloquer
          : serie
              ? PlanNowGeste.ouvrirEtape
              : resoluble
                  ? PlanNowGeste.lancer
                  : PlanNowGeste.aucun,
      etapeRoute: serie ? journeyEtapeRoute(etape.id) : null,
      source: resoluble ? CivicNowUnite(unite.code) : null,
      title: journeyStepTitle(etape),
      subtitle: etape.bloc?.label,
      badge: etape.locked ? kJourneyLockedBadge : null,
      objectiveLabel: null,
      objective: null,
      // `journeyStepSubtitle` peut ne rien avoir à dire : on n'affiche alors
      // aucune méta plutôt qu'une ligne vide.
      meta: journeyStepSubtitle(etape),
      cta: verrou ? kCivicPlanLockedCta : kCivicPlanWorkCta,
      locked: etape.locked,
    );
  }

  final cible = plan.prochaine;
  // 🛑 `null` est un cas NORMAL : plus rien à faire. La carte disparaît, elle
  // n'affiche jamais un squelette.
  if (cible == null) return null;
  final geste = civicCibleGeste(cible, free: free);
  return CivicNowCard(
    geste: geste,
    // Une cible du plan **dérivé** n'est pas une étape du cycle : elle n'a pas
    // d'écran d'étape, et son geste reste le lanceur de série.
    etapeRoute: null,
    source: CivicNowCible(cible),
    title: cible.label,
    subtitle: cible.label == cible.themeLabel || cible.themeLabel.isEmpty
        ? null
        : cible.themeLabel,
    badge: cible.locked ? kJourneyLockedBadge : null,
    objectiveLabel: kCivicPlanNowWhy,
    objective: '${cible.maitrise.label} · ${civicPlanRaison(cible)}',
    meta: civicSerieLabel(cible),
    cta: geste == PlanNowGeste.debloquer
        ? kCivicPlanLockedCta
        : kCivicPlanWorkCta,
    locked: cible.locked,
  );
}

/* ⚠️ **SUPPRIMÉS par la refonte du plan civique abonné** (P8.7, D-50,
   2026-09-20), avec leur dernier lecteur — « refonte = suppression immédiate de
   l'ancien » :

   - `kCivicPathLabels` / `kCivicPathTitle` / `civicPath` / `civicPathCounter`
     — le « parcours de la notion ». Il illustrait la cible du plan **dérivé**,
     et « À faire maintenant » lit désormais le **cycle** : les cinq étapes du
     Leitner n'ont plus d'écran où se poser.
   - `kCivicChangesTitle` / `civicTransitionLabel` / `civicNextStepLabel` —
     « Progression détectée ». Le TCF l'a retirée le 2026-09-19 : elle redisait
     les blocs du cycle en moins précis.
   - `civicPlanEngineLine`, `civicPlanThemesPill`, `civicPlanCiblesPill` — la
     carte de contexte, que la bande objectif remplace (D-50 §1). C'est aussi la
     2ᵉ occurrence de `DETTE-P1` qui disparaît : mobile disait « 4 thèmes /
     17 notions » et web « 17 à consolider / 3 à revoir », même carte, faits
     différents.
   - `kCivicPlanDoneTitle` / `civicPlanDoneRow` (« Déjà travaillé et validé »),
     `kCivicPlanAllGoodTitle` / `_Text` et `kCivicPlanExamCta` (l'état « rien
     d'urgent », que le cycle dit mieux), `kCivicPlanNowBadge` (le rang, qui
     n'avait de sens que sur la carte d'un abonné), `civicCibleTone` (la
     fonction ; l'enum [CivicCibleTone] reste, dix lecteurs).

   ⚠️ **SUPPRIMÉS à leur tour par l'anatomie unique du 2026-09-20** (l'écran
   gratuit reçoit celle de l'abonné), avec leur dernier lecteur :
   `kCivicPlanResultLabel` / `civicPlanResultNote` (la carte de score du
   diagnostic — elle se lit sur le rapport de diagnostic et sur « Où vous en
   êtes »), `kCivicPlanThemesTitle` / `civicPlanThemes` /
   `civicPlanThemesATravailler` (« Thèmes à travailler »),
   `kCivicPlanPrioritiesTitle` et `civicPlanAutresLabel` (« Vos priorités », que
   le cycle dit mieux et sans plafond), `kCivicPlanFirstStepTitle` /
   `kCivicPlanStepLocks` (« Votre première étape est prête » et ses cinq
   bénéfices verrouillés) et `kCivicPlanNowCta` (« Commencer » — la carte
   d'action porte désormais le même [kCivicPlanWorkCta] que l'abonné).

   🛑 `CivicPlan.changements` et `Cible.parcours` restent **servis** et restent
   dans le modèle : c'est l'affichage qui part, pas le contrat.  */

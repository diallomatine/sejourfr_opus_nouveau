import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/journey_models.dart';
import '../../core/models/skill_models.dart';
import 'journey_labels.dart';
import 'plan_labels.dart';
import 'plan_seance_state.dart';

/// **Ce que la carte « À faire maintenant » annonce.**
///
/// 🛑 **Une seule autorité pour les SIX sites d'appel** — le Plan, l'Accueil et
/// **Réviser**, web et mobile. La règle « une MESURE passe devant tout le
/// reste » vivait dans `_nowCard` (Plan mobile) et `ActionMaintenant` (Plan
/// web) ; les deux cartes d'Accueil (`_actionTcf`, `ActionPrincipale`) ne
/// l'avaient **jamais** reçue et lisaient `currentPriority` seule. Sur les
/// mêmes données, l'Accueil annonçait « Raconter brièvement une expérience
/// passée · VOTRE PRIORITÉ DU JOUR » pendant que le Plan annonçait « Compléter
/// mon évaluation de compréhension écrite · À ÉVALUER » : deux « à faire
/// maintenant » contradictoires pour le même candidat, au même instant.
///
/// ⚠️ **La carte « Reprendre là où vous vous êtes arrêté » de Réviser en dérive
/// aussi** (`reviserResumeTcf`, `screens/reviser/reviser_labels.dart`) : elle
/// lisait `plan.seance.items.first` puis retombait sur `currentPriority`, donc
/// une mesure qui n'ouvrait pas la séance lui échappait — troisième écran, même
/// contradiction.
///
/// ⚠️ Miroir mot pour mot du web (`planNowCard`, `lib/plan-domain.ts`), drapeau
/// `free` compris : depuis le 2026-09-20, les deux fronts rendent le plan
/// gratuit et le plan abonné avec la **même** carte, et `free` n'y décide que
/// le geste.
enum PlanNowNature {
  /// Une **mesure de domaine** : le candidat a produit et le correcteur n'a
  /// rien pu observer. Tout ce qui suivrait travaillerait à l'aveugle.
  mesure,

  /// L'étape est terminée : le Plan demande une **vérification en situation**.
  verification,

  /// Le cas courant : l'étape de la priorité n°1.
  etape,

  /// 🛑 **Le parcours a désigné une étape dont l'action ne se résout pas.**
  /// La carte nomme alors **cette étape-là**, sans bouton — et **jamais** une
  /// autre compétence ni un autre examen.
  ///
  /// Elle existe parce que le repli silencieux sur `plan.currentPriority`
  /// annonçait l'étape du parcours et lançait autre chose : le candidat lisait
  /// « Tâche 2 » et atterrissait sur la compétence que le Plan priorisait ce
  /// jour-là. Deux causes connues, toutes deux transitoires : une compétence
  /// dont le transfert vient d'être prouvé (le Plan l'a sortie de ses
  /// priorités), et une compétence hors de la fenêtre d'affichage des
  /// priorités.
  indisponible,
}

/// **Le geste de la carte** — la seule autorité sur « que se passe-t-il quand on
/// la touche ».
///
/// 🛑 **Un écran ne redéduit jamais ce geste d'un `locked`.** Les six surfaces
/// qui portent cette carte (Plan, Accueil, Réviser, web et mobile) lisent ce
/// champ ; recalculer « verrouillé ⇒ offre » de chaque côté est exactement ce
/// qui avait laissé le Plan web muet sur une étape verrouillée.
///
/// ⚠️ Miroir mot pour mot du web (`PlanNowGeste`, `lib/plan-domain.ts`).
enum PlanNowGeste {
  /// La carte démarre ce qu'elle annonce (mesure ou exercice).
  lancer,

  /// L'étape annoncée est **fermée** : le geste ouvre le paywall (spec §7 /
  /// D-18 — « le tap ouvre la popup *Débloquer mon plan* »).
  ///
  /// 🛑 **Prioritaire sur [ouvrirEtape]** : une étape fermée ouvre l'offre,
  /// jamais son écran. L'ordre des tests ne change pas.
  debloquer,

  /// L'étape se travaille **par séries** : le geste ouvre son écran
  /// ([PlanNowCard.etapeRoute]), qui déplie la compétence ou l'unité et ses
  /// deux séries, au lieu de lancer l'exercice.
  ouvrirEtape,

  /// Rien ne se résout : la carte **nomme** l'étape et s'arrête là.
  aucun,
}

/// L'identité **complète** de la carte : ce qu'elle montre, et ce qu'elle lance.
class PlanNowCard {
  const PlanNowCard({
    required this.nature,
    required this.geste,
    required this.etapeRoute,
    required this.mesure,
    required this.priority,
    required this.exercise,
    required this.section,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.objectiveLabel,
    required this.objective,
    required this.minutesLabel,
    required this.kindLabel,
    required this.lines,
    required this.cta,
    required this.locked,
  });

  final PlanNowNature nature;

  /// 🛑 **Ce que le geste fait**, décidé dans [planNowCard] et nulle part
  /// ailleurs.
  final PlanNowGeste geste;

  /// **Où mène [PlanNowGeste.ouvrirEtape]** — servi avec lui, `null` partout
  /// ailleurs.
  ///
  /// 🛑 **Un écran ne recompose jamais cette adresse** : c'est l'autorité qui
  /// la sert, comme elle sert le geste.
  final String? etapeRoute;

  /// **La mesure que le bouton LANCE**, `null` dès que la carte porte une étape.
  /// C'est elle qui décide du verrou comme du démarrage
  /// ([startPlanSeanceItem]).
  final PlanSeanceItem? mesure;

  /// `null` sur la nature [PlanNowNature.indisponible] — il n'y a **rien** à
  /// lancer — et sur une étape dont l'exercice est **servi** hors des 5
  /// priorités : dans les deux cas, nommer la priorité du Plan désignerait une
  /// autre compétence que celle que le bouton ouvre.
  final LearningPlanPriority? priority;

  /// L'exercice de la priorité — celui que la carte lance **hors mesure**.
  final PlanRecommendedExercise? exercise;

  /// 🛑 **Le domaine réellement lancé** — celui de la **mesure** quand elle
  /// passe devant, celui de la priorité sinon. `null` seulement quand le
  /// domaine mesuré n'est pas l'un des quatre du Plan.
  ///
  /// ⚠️ Miroir du web (`PlanNowVue.section`) : un écran qui a besoin de
  /// l'épreuve lancée la **lit** ici, il ne la redérive pas de la priorité.
  final SkillSection? section;

  /// 🛑 **L'icône du domaine réellement lancé.** Elle empruntait celle de la
  /// priorité : le candidat lisait une tâche d'expression orale et atterrissait
  /// dans l'examen blanc de compréhension orale de la mesure.
  final IconData icon;

  final String title;
  final String? subtitle;

  /// 🛑 Une mesure n'est pas la priorité n°1 : sa pastille dit sa **nature**
  /// servie, celle que le serveur a posée sur l'item de séance.
  ///
  /// `null` quand la carte ne classe rien : une étape dont l'action est servie
  /// hors des priorités n'a **aucune** nature connue, et une pastille vide en
  /// aurait dessiné une. ⚠️ Miroir du web (`PlanNowVue.badge`, nullable depuis
  /// toujours) — le mobile portait ici une chaîne vide, donc une pastille vide.
  final String? badge;

  final String? objectiveLabel;
  final String? objective;

  /// « ≈ 4 min » ou « 5 petits sujets · ≈ 4 min chacun ». `null` quand aucune
  /// durée n'est servie — jamais un chiffre inventé.
  final String? minutesLabel;

  /// La nature de l'exercice lancé. `null` sur une mesure : le sous-titre porte
  /// déjà le parcours réel, et nommer ici l'exercice de la priorité dirait le
  /// contraire.
  final String? kindLabel;

  /// Le constat, ligne par ligne — jamais concaténé.
  final List<String> lines;

  /// Ce que dit le bouton de la carte : « Compléter la mesure », « Faire la
  /// vérification », « Découvrir », « Continuer » ou « Commencer ».
  final String cta;

  /// Le verrou **lu**, jamais déduit d'un rang.
  final bool locked;

  bool get estMesure => nature == PlanNowNature.mesure;
  bool get estVerification => nature == PlanNowNature.verification;
  bool get estIndisponible => nature == PlanNowNature.indisponible;
  bool get estADebloquer => geste == PlanNowGeste.debloquer;
}

/// **Ce qu'une ligne du cycle LANCE** — l'action de l'étape, résolue par les
/// mêmes autorités que la carte « À faire maintenant ».
///
/// 🛑 **GARDE-FOU du 2026-09-17, appliqué ligne par ligne** : une ligne ne lance
/// **jamais** autre chose que l'étape qu'elle annonce. `null` quand rien ne se
/// résout — l'écran nomme alors l'étape **sans bouton**, exactement comme la
/// nature [PlanNowNature.indisponible] de la carte.
///
/// 🛑 **Aucune règle nouvelle ici** : [_priorityDe] et [_mesureDe] sont les deux
/// résolutions que [planNowCard] emploie déjà. Cette fonction les expose pour
/// une étape **quelconque** du cycle, au lieu de la seule étape courante — le
/// Plan en affiche désormais toutes.
///
/// ⚠️ Miroir mot pour mot du web (`planStepAction`, `lib/plan-domain.ts`).
class PlanStepAction {
  const PlanStepAction({this.mesure, this.exercise, this.priority});

  /// La mesure à lancer ([startPlanSeanceItem]), `null` sur une compétence.
  final PlanSeanceItem? mesure;

  /// L'exercice à lancer ([openPlanExercise]), `null` sur un examen.
  final PlanRecommendedExercise? exercise;

  /// La priorité qui porte l'exercice — son état de maîtrise sert la mesure
  /// d'audience du lanceur. `null` sur une mesure, et `null` aussi quand
  /// l'exercice vient de l'étape elle-même : hors de la fenêtre des 5
  /// priorités, il n'y a **aucune** priorité à citer, et le lancement reste
  /// possible.
  final LearningPlanPriority? priority;
}

PlanStepAction? planStepAction(LearningPlan plan, JourneyStep etape) {
  final mesure = _mesureDe(plan, etape);
  if (mesure != null) return PlanStepAction(mesure: mesure);
  final priority = _priorityDe(plan, etape);
  // 🛑 **L'exercice SERVI passe devant** (même raisonnement que `assessment`,
  // A24). Les priorités du Plan sont une **vue bornée** à
  // `display.prioritiesMaxActions` (= 5) ; la file, non. Un cycle de six
  // compétences ou plus avait donc des étapes dont l'action ne se trouvait nulle
  // part — c'est exactement ce que le propriétaire voyait sur l'expression
  // écrite : deux étapes nommées, aucun lien pour les lancer.
  //
  // Le repli sur la priorité reste, et il est **nécessaire** : un client servi
  // par un backend antérieur au champ `exercise` continue de fonctionner.
  final exercise = etape.exercise ?? priority?.recommendedExercise;
  // 🛑 **GARDE-FOU A25 intact** : rien ne se résout ⇒ pas de bouton. Mais
  // `priority` n'en fait plus partie — elle ne sert qu'à la mesure d'audience du
  // lanceur, et une action vraie ne se refuse pas faute de statistique.
  if (exercise == null) return null;
  return PlanStepAction(exercise: exercise, priority: priority);
}

/// **Le verrou SERVI de l'action d'une étape** — le seul endroit qui compose
/// les deux verrous d'une action résolue.
///
/// 🛑 **Le verrou de l'ACTION n'est pas celui de l'ÉTAPE** : une étape servie
/// ouverte peut porter un exercice — ou une mesure — fermé, et c'est par là que
/// le geste sautait l'écran de transition pour finir sur un 403 (A146). On lit
/// donc le verrou de ce que la ligne **lance**, avant tout appel.
///
/// 🛑 **Lu, jamais déduit** : [planSeanceItemLocked] pour une mesure (elle lit
/// l'item ET son exercice), `locked` servi pour un exercice. Ni rang, ni statut
/// d'abonnement lu côté client.
///
/// ⚠️ Miroir mot pour mot du web (`planStepActionLocked`, `lib/plan-domain.ts`).
bool planStepActionLocked(PlanStepAction action) {
  final mesure = action.mesure;
  if (mesure != null) return planSeanceItemLocked(mesure);
  return action.exercise?.locked ?? false;
}

/// **La carte « À faire maintenant » d'un plan TCF**, ou `null` quand le serveur
/// n'a désigné aucune priorité (l'écran affiche alors son état vide).
///
/// 🛑 **Rien n'est décidé ici** : la précédence de la mesure, la nature de
/// l'action, les minutes et le verrou sont tous **servis**. Cette fonction ne
/// fait que choisir *laquelle* des deux identités la carte porte, et le dire une
/// seule fois pour les deux écrans.
///
/// 🛑 **[free] ne décide QUE du geste** (demande du propriétaire, 2026-09-20 :
/// « faire en sorte qu'un non abonné voie également le "à faire maintenant"
/// d'un abonné, seulement au lieu du bouton commencer, mettre débloquer »).
/// Un compte sans accès reçoit donc **exactement** la carte d'un abonné —
/// titre, pastille « Priorité n°1 », métas, explication du correcteur,
/// progression — et son bouton ouvre l'**offre** au lieu de lancer.
///
/// ⚠️ **Ce que ça révoque** : l'anatomie distincte du 2026-09-12
/// (`_freeStepCard` et ses trois bénéfices verrouillés, « aucun geste ne part
/// de cette carte »). **Ce qui TIENT** : « dans le plan, on ne travaille rien
/// si on n'est pas abonné » — [free] force [PlanNowGeste.debloquer]
/// **inconditionnellement**, et `_nowCard` ne branche que sur `geste`, donc
/// aucun lanceur n'est joignable depuis un plan gratuit.
///
/// 🛑 **La contradiction #1 reste fermée** (D-18) : l'explication du correcteur,
/// la progression et les compteurs sont des **résultats mesurés**. On floute
/// l'action pas encore accessible, jamais le résultat mesuré.
/// **Ce que le cycle propose pour UNE épreuve**, pour la carte de tête de son
/// écran d'entraînement (demande du propriétaire, 2026-09-20).
///
/// 🛑 **Ce n'est pas un second moteur** : la fonction ne décide rien. Elle
/// **choisit un bloc** dans la file servie, y prend la première étape encore
/// ouverte, et délègue tout le reste aux autorités en place — [planStepAction]
/// pour l'action, [journeyStepTitle] / [journeyNowCta] pour les mots. Le tap
/// fait donc exactement ce que ferait la même étape tapée depuis le Plan.
///
/// 🛑 **Les étapes d'entraînement passent avant l'examen du bloc**, qui ne se
/// propose que lorsqu'il ne reste plus rien à travailler — c'est l'ordre de la
/// file, pas une règle inventée ici.
///
/// `null` est un cas **normal** et fréquent : l'épreuve n'a pas de bloc dans ce
/// cycle (« Structure de la langue » n'en a **jamais** — elle est hors des
/// quatre épreuves du TCF IRN), son bloc est terminé, ou rien ne se résout. La
/// carte disparaît alors, elle ne s'affiche jamais vide ni morte.
///
/// ⚠️ Miroir mot pour mot du web (`planEpreuveCarte`, `lib/plan-domain.ts`).
class PlanEpreuveCarte {
  const PlanEpreuveCarte({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.geste,
    required this.etapeRoute,
    required this.cta,
    required this.action,
  });

  final JourneyStep step;
  final String title;
  final String? subtitle;
  final String? meta;

  /// 🛑 Servi par les mêmes règles que la carte du Plan, jamais redéduit.
  final PlanNowGeste geste;

  /// **Où mène [PlanNowGeste.ouvrirEtape]**, `null` sinon — servi, jamais
  /// recomposé par l'écran d'épreuve.
  final String? etapeRoute;
  final String cta;

  /// `null` dès que le geste est [PlanNowGeste.debloquer] — rien à lancer.
  final PlanStepAction? action;
}

PlanEpreuveCarte? planEpreuveCarte(
  LearningPlan? plan,
  Journey? journey,
  String blocCode, {
  bool free = false,
}) {
  JourneyBloc? bloc;
  for (final b in journey?.blocs ?? const <JourneyBloc>[]) {
    if (b.bloc.code == blocCode) {
      bloc = b;
      break;
    }
  }
  if (bloc == null) return null;
  bool ouverte(JourneyStep s) =>
      s.status == JourneyStepStatus.current ||
      s.status == JourneyStepStatus.upcoming;
  JourneyStep? step;
  for (final s in bloc.steps) {
    if (ouverte(s)) {
      step = s;
      break;
    }
  }
  final exam = bloc.exam;
  step ??= exam != null && ouverte(exam) ? exam : null;
  if (step == null) return null;
  final locked = free || step.locked;
  final action = locked || plan == null ? null : planStepAction(plan, step);
  // 🛑 Rien à lancer et pas de verrou à lever ⇒ **pas de carte** : on ne pose
  // jamais un bouton mort (garde-fou A25, transposé).
  if (!locked && action == null) return null;
  // 🛑 **La même règle que le Plan et que la ligne du cycle** : une étape de
  // séries ouvre son écran. Elle est lue ICI, pas dans l'écran d'épreuve.
  final serie = journeyEtapeASeries(step);
  return PlanEpreuveCarte(
    step: step,
    title: journeyStepTitle(step),
    subtitle: journeyStepSubtitle(step),
    meta: journeyNowMeta(step),
    geste: locked
        ? PlanNowGeste.debloquer
        : serie
            ? PlanNowGeste.ouvrirEtape
            : PlanNowGeste.lancer,
    etapeRoute: serie ? journeyEtapeRoute(step.id) : null,
    cta: journeyNowCta(step, locked),
    action: action,
  );
}

PlanNowCard? planNowCard(
  LearningPlan plan, {
  Journey? journey,
  bool free = false,
}) {
  // 🛑 **LE PARCOURS DÉCIDE QUELLE ÉTAPE, LE PLAN FOURNIT COMMENT LA LANCER**
  // (décision A18, `docs/decisions-autonomes-parcours-tcf.md`).
  //
  // `JourneyStep` porte l'identité d'une étape — et **aucune action à lancer**.
  // Le catalogue d'actions vit chez ses autorités : le petit sujet précis chez
  // `RecommendedExerciseSelector`, « par quoi mesurer une épreuve » chez
  // `PlanDomainAssessmentResolver`. Les recopier dans le parcours en ferait un
  // second moteur, ce que la spec §0.4 interdit.
  final etape = journey?.current;
  final duParcours = etape == null ? null : _priorityDe(plan, etape);
  // 🛑 **Une MESURE passe devant tout le reste** — sauf quand un parcours est
  // servi : il a **déjà** appliqué la précédence (R12), et rejouer
  // `planSeanceMesure` ferait passer une mesure devant l'étape qu'il vient de
  // désigner. Deux règles de précédence pour une seule carte.
  final mesure =
      etape == null ? planSeanceMesure(plan) : _mesureDe(plan, etape);

  // 🛑 **GARDE-FOU : on ne lance JAMAIS autre chose que l'étape annoncée.**
  // Quand le parcours désigne une étape dont l'action ne se résout pas, cette
  // fonction retombait sur `plan.currentPriority` : la carte annonçait l'étape
  // du parcours et ouvrait la compétence que le Plan priorisait ce jour-là.
  if (etape != null && duParcours == null && mesure == null) {
    // 🛑 **L'exercice SERVI sur l'étape ferme le cul-de-sac** : hors de la
    // fenêtre des 5 priorités, `duParcours` est nul alors que l'étape a bel et
    // bien une action. La carte la lance, en nommant **cette étape-là** — elle
    // ne retombe toujours pas sur `plan.currentPriority`.
    final exerciceServi = etape.exercise;
    return exerciceServi == null
        ? _carteIndisponible(etape, free)
        : _carteEtapeServie(etape, exerciceServi, free);
  }

  // 🛑 **UNE ÉTAPE DE SÉRIES OUVRE SON ÉCRAN, ELLE NE LANCE PLUS RIEN**
  // (demande du propriétaire, 2026-09-20). Compréhension CO/CE et civique : le
  // candidat voit d'abord ce que l'étape demande — la compétence ou l'unité
  // travaillée, le seuil, ses deux séries — puis choisit la série qu'il lance.
  // La ligne du cycle le faisait déjà ; les cinq autres surfaces lançaient
  // encore l'exercice, faute d'avoir la règle ICI.
  //
  // ⚠️ **Les étapes d'EXPRESSION (EE/EO) ne sont PAS concernées** : elles
  // portent une tâche, [journeyEtapeASeries] les laisse de côté, et leur chemin
  // vers leurs petits sujets ne change pas.
  //
  // ⚠️ **Une MESURE ne passe jamais par cet écran** : elle n'est pas une étape
  // `TRAIN_SKILL`, donc le prédicat ne la retient pas.
  final serie = etape != null && journeyEtapeASeries(etape);
  final etapeRoute = serie ? journeyEtapeRoute(etape.id) : null;

  final priority = duParcours ?? plan.currentPriority;
  if (priority == null && mesure == null) return null;

  final exercise = priority?.recommendedExercise;
  final mesureDomaine = mesure?.assessment;

  // 🛑 **La carte de vérification est une AUTRE carte.** Elle se lit sur la
  // nature **servie**, jamais sur un compteur.
  final verifier = mesureDomaine == null &&
      priority?.nature == PlanActionNature.aVerifier &&
      exercise?.kind == PlanExerciseKind.reassessment;

  final minutes = mesure != null
      ? mesureDomaine?.estimatedMinutes ?? 0
      : exercise?.estimatedMinutes ?? 0;
  final minutesLabel = minutes <= 0
      ? null
      // « chacun » : les minutes sont celles d'UN sujet, pas de la série
      // entière — sans lui, « 5 sujets · ≈ 6 min » promettait six minutes pour
      // les cinq.
      : mesure == null &&
              !verifier &&
              (priority?.stepPromptCount ?? 0) > 0 &&
              exercise?.kind == PlanExerciseKind.microTraining
          ? '${priority?.stepPromptCount} petits sujets · ≈ $minutes min chacun'
          : '≈ $minutes min';

  if (mesureDomaine != null) {
    // 🛑 **Le geste, décidé une seule fois pour les six surfaces** (spec §7,
    // D-18) : une étape fermée ne se lance pas, elle **ouvre l'offre**.
    //
    // 🛑 **C'est ICI que tient « dans le plan, on ne travaille rien si on n'est
    // pas abonné »** : `free` court-circuite tout, avant même le `locked`
    // servi. Il n'entre **pas** dans `locked`, qui reste le verrou **servi** et
    // rien d'autre.
    final verrou = planSeanceItemLocked(mesure!);
    final offre = free || verrou;
    return PlanNowCard(
      nature: PlanNowNature.mesure,
      geste: offre
          ? PlanNowGeste.debloquer
          : serie
              ? PlanNowGeste.ouvrirEtape
              : PlanNowGeste.lancer,
      etapeRoute: etapeRoute,
      mesure: mesure,
      priority: priority,
      exercise: exercise,
      section: planDomainSection(mesureDomaine.epreuve),
      icon: planDomainIcon(mesureDomaine.epreuve),
      title: planAssessmentItemTitle(mesureDomaine),
      subtitle: planAssessmentNature(mesureDomaine),
      badge: PlanActionNature.aEvaluer.label,
      objectiveLabel: null,
      objective: null,
      minutesLabel: minutesLabel,
      kindLabel: null,
      // Sur une mesure, le constat de la priorité parlerait d'une AUTRE
      // compétence que celle que le bouton va ouvrir : c'est le motif de la
      // mesure qui se dit.
      lines: const [kPlanReasonAEvaluer],
      cta: offre
          ? kPlanNowLockedCta
          : planNowCta(priority, verifier: false, mesure: true),
      locked: verrou,
    );
  }

  // Plus de mesure et plus de priorité : il n'y a rien à annoncer, et l'écran
  // affiche son état vide.
  if (priority == null) return null;

  final epreuve = planEpreuveOfSection(priority.section);
  final task = SkillTaskCode.fromSkillCode(priority.skillCode);
  final level = planSkillTargetLevel(plan, priority.skillId);
  // 🛑 `locked` reste le verrou **servi** ; `free` ne s'y mêle pas et ne
  // gouverne que le geste.
  final verrou = priority.locked || (exercise?.locked ?? false);
  final offre = free || verrou;

  return PlanNowCard(
    nature: verifier ? PlanNowNature.verification : PlanNowNature.etape,
    geste: offre
        ? PlanNowGeste.debloquer
        : serie
            ? PlanNowGeste.ouvrirEtape
            : exercise == null
                ? PlanNowGeste.aucun
                : PlanNowGeste.lancer,
    etapeRoute: etapeRoute,
    mesure: null,
    priority: priority,
    exercise: exercise,
    section: priority.section,
    icon: verifier ? LucideIcons.badgeCheck : planDomainIcon(epreuve),
    // 🛑 **L'ÉPREUVE en titre, la compétence en sous-titre** (demande du
    // propriétaire, 2026-09-18). Les deux étaient inversés : le candidat lisait
    // d'abord « Comprendre l'implicite et les nuances à l'oral » — un intitulé
    // de référentiel, long, sur deux lignes — et devait descendre pour savoir de
    // quelle épreuve il s'agissait. Il sait maintenant **où** il travaille avant
    // de lire **quoi**.
    //
    // 🛑 **Le nom de la compétence ne se répète pas trois fois** : il vit en
    // sous-titre, et sur la vérification il passe sous le titre — qui nomme
    // alors l'ACTION, et c'est le seul cas où l'ordre s'inverse.
    title: verifier
        ? kPlanNowVerifyTitle
        : planNowIdentite(
            domaine: epreuve == null
                ? priority.section.label
                : planDomainLabel(epreuve),
            task: task,
            level: level,
          ),
    subtitle: verifier
        ? planNowVerifySubtitle(priority.title, task)
        : priority.title,
    badge: planPriorityRankTag(1),
    objectiveLabel: verifier ? kPlanNowVerifyObjectiveLabel : null,
    objective: verifier ? kPlanNowVerifyText : null,
    minutesLabel: minutesLabel,
    kindLabel: planExerciseKindLabel(
      exercise?.kind,
      questionCount: exercise?.questionCount,
    ),
    // ⚠️ **Plus de constat ni de compteur ici** (2026-09-20) : cf. la note
    // à [kPlanNowUnavailableText].
    lines: const <String>[],
    cta: offre
        ? kPlanNowLockedCta
        : planNowCta(priority, verifier: verifier, mesure: false),
    locked: verrou,
  );
}

/// La priorité du Plan qui porte la compétence de cette étape — **son action**.
///
/// 🛑 Le rapprochement se fait sur `skillCode`, pas sur `skillId` : c'est le
/// code qui est stable et lisible des deux côtés, et c'est lui que le parcours
/// sert.
///
/// `null` est un cas **normal** : étape d'examen (elle n'a pas de compétence),
/// ou compétence que le Plan ne priorise plus.
LearningPlanPriority? _priorityDe(LearningPlan plan, JourneyStep etape) {
  if (etape.type != JourneyStepType.trainSkill || etape.skillCode == null) {
    return null;
  }
  final toutes = <LearningPlanPriority>[
    if (plan.currentPriority != null) plan.currentPriority!,
    ...plan.nextPriorities,
  ];
  for (final item in toutes) {
    if (item.skillCode == etape.skillCode) return item;
  }
  return null;
}

/// La mesure que lance une étape d'examen — **cherchée d'abord dans la séance**,
/// puis dans « ce qu'il reste à mesurer ».
///
/// 🛑 Les deux viennent du **même** resolver serveur
/// (`PlanDomainAssessmentResolver`) : on ne compose aucune action, on retrouve
/// celle qui est déjà servie. Le second chemin existe parce que le parcours peut
/// nommer une épreuve que la séance du jour n'a pas retenue — la séance est une
/// vue bornée, la file ne l'est pas.
PlanSeanceItem? _mesureDe(LearningPlan plan, JourneyStep etape) {
  // 🛑 La séance du Plan est TCF : ses `assessment.epreuve` sont des épreuves.
  // Un bloc civique n'y a aucun équivalent — le cycle civique a son propre
  // écran (P8.7). On sort, et c'est correct, pas un trou.
  if (etape.type != JourneyStepType.sectionExam ||
      etape.bloc?.kind != JourneyBlocKind.epreuve) {
    return null;
  }
  for (final item in plan.seance.items) {
    if (item.assessment?.epreuve.name == _epreuveDuBloc(etape)?.name) return item;
  }
  final assessment = etape.assessment;
  if (assessment == null) return null;
  // Une mesure n'a ni compétence, ni palier, ni état de maîtrise, ni étape :
  // tous ces champs sont **structurellement** nuls sur une ligne de mesure,
  // exactement comme le serveur les sert dans la séance. Rien n'est inventé
  // ici — seule l'enveloppe est reconstituée.
  return PlanSeanceItem(
    nature: PlanActionNature.aEvaluer,
    assessment: assessment,
    stepPromptCount: 0,
    stepAttemptedCount: 0,
    stepValidatedCount: 0,
    stepCompleted: false,
    readyForReassessment: false,
    // 🛑 Une mesure n'est **jamais** verrouillée : le slot offert est ouvert à
    // tout compte inscrit, et `PlanDomainAssessmentResolver` ne sert aucun
    // `locked` pour cette raison exacte.
    locked: false,
  );
}

/// **La carte d'une étape dont l'action est SERVIE mais que le Plan ne priorise
/// pas** — hors de la fenêtre des 5 priorités.
///
/// 🛑 Elle nomme **l'étape que le parcours a désignée**, exactement comme
/// [_carteIndisponible] et comme la ligne de la timeline : aucun repli sur
/// `plan.currentPriority`, qui annoncerait une autre compétence que celle que le
/// bouton ouvre (A25).
///
/// 🛑 **Rien n'est inventé de ce qui n'est pas servi.** La nature d'une priorité
/// (`A_RENFORCER` / `A_VERIFIER` / `A_ACQUERIR`) est un **fait pédagogique** que
/// l'étape ne porte pas : la carte n'a donc ni pastille, ni constat, ni
/// objectif, et son bouton dit « Commencer ». Elle a ce qu'elle sait :
/// l'identité de l'étape, la nature de l'exercice, sa durée et le verrou servi.
///
/// ⚠️ Miroir mot pour mot du web (`carteEtapeServie`, `lib/plan-domain.ts`).
PlanNowCard _carteEtapeServie(
  JourneyStep etape,
  PlanRecommendedExercise exercise,
  bool free,
) {
  final epreuve = _epreuveDuBloc(etape);
  final verrou = etape.locked || exercise.locked;
  final offre = free || verrou;
  final sujets = etape.progress?.quota ?? 0;
  final minutes = exercise.estimatedMinutes;
  // 🛑 **Une étape de SÉRIES ouvre son écran, elle ne lance plus rien** — la
  // même règle que la ligne du cycle, décidée ici pour les cinq surfaces.
  final serie = journeyEtapeASeries(etape);
  return PlanNowCard(
    nature: PlanNowNature.etape,
    geste: offre
        ? PlanNowGeste.debloquer
        : serie
            ? PlanNowGeste.ouvrirEtape
            : PlanNowGeste.lancer,
    etapeRoute: serie ? journeyEtapeRoute(etape.id) : null,
    mesure: null,
    priority: null,
    exercise: exercise,
    section: etape.section,
    icon: epreuve == null ? LucideIcons.target : planDomainIcon(epreuve),
    title: journeyStepTitle(etape),
    subtitle: journeyStepSubtitle(etape),
    badge: null,
    objectiveLabel: null,
    objective: null,
    minutesLabel: minutes <= 0
        ? null
        : sujets > 0 && exercise.kind == PlanExerciseKind.microTraining
            ? '$sujets petits sujets · ≈ $minutes min chacun'
            : '≈ $minutes min',
    kindLabel: planExerciseKindLabel(
      exercise.kind,
      questionCount: exercise.questionCount,
    ),
    lines: const <String>[],
    cta: offre
        ? kPlanNowLockedCta
        : planNowCta(null, verifier: false, mesure: false),
    locked: verrou,
  );
}

/// **La carte d'une étape dont l'action ne se résout pas.**
///
/// 🛑 Elle nomme **l'étape que le parcours a désignée**, et rien d'autre : c'est
/// tout son objet. Pas de bouton, pas de repli sur la priorité du Plan — lancer
/// une autre compétence que celle qu'on affiche est exactement la contradiction
/// que le parcours a été écrit pour fermer.
///
/// Le titre et le sous-titre viennent des **libellés du parcours**
/// (`journey_labels.dart`), la même autorité que la timeline : la carte et la
/// ligne de la timeline disent donc mot pour mot la même chose.
PlanNowCard _carteIndisponible(JourneyStep etape, bool free) {
  final epreuve = _epreuveDuBloc(etape);
  // 🛑 Un compte **sans accès** n'a rien à lancer de toute façon : le geste est
  // l'offre, même quand l'action de l'étape ne se résout pas. Sinon, une étape
  // ouverte mais sans action reste **sans geste** — on ne lui fait pas ouvrir
  // un paywall qui ne la débloquerait pas.
  final offre = free || etape.locked;
  return PlanNowCard(
    nature: PlanNowNature.indisponible,
    // ⚠️ **`ouvrirEtape` ne s'applique PAS ici** : rien ne se résout, la carte
    // nomme l'étape et s'arrête là (garde-fou A25). Lui poser un bouton
    // contredirait sa propre ligne « action indisponible ».
    geste: offre ? PlanNowGeste.debloquer : PlanNowGeste.aucun,
    etapeRoute: null,
    mesure: null,
    priority: null,
    exercise: null,
    section: etape.section,
    icon: epreuve == null ? LucideIcons.target : planDomainIcon(epreuve),
    title: journeyStepTitle(etape),
    subtitle: journeyStepSubtitle(etape),
    badge: null,
    objectiveLabel: null,
    objective: null,
    minutesLabel: null,
    kindLabel: null,
    lines: const [kPlanNowUnavailableText],
    cta: offre ? kPlanNowLockedCta : kPlanNowStartCta,
    // Le verrou **servi** de l'étape, pas une déduction : une étape
    // indisponible peut être verrouillée par ailleurs, et l'écran doit
    // continuer à le dire.
    locked: etape.locked,
  );
}

/// L'`EpreuveType` d'une étape, quand son bloc **est** une épreuve.
///
/// 🛑 `null` pour une étape civique : son bloc est une thématique, et aucune
/// `EpreuveType` ne lui correspond (D-47, D-48 côté PROGRAMME).
EpreuveType? _epreuveDuBloc(JourneyStep etape) {
  final bloc = etape.bloc;
  if (bloc == null || !bloc.estEpreuve) return null;
  // 🛑 Rapprochement par `wire`, l'autorité du code d'épreuve — pas par un
  // bricolage sur `name`, qui marcherait par coïncidence.
  return EpreuveType.values.where((e) => e.wire == bloc.code).firstOrNull;
}

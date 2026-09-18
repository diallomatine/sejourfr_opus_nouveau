import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/diagnostic_models.dart';
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
/// ⚠️ Miroir mot pour mot du web (`planNowCard`, `lib/plan-domain.ts`). Le web
/// y prend en plus un drapeau `free` parce que sa carte de plan **gratuit** est
/// rendue par la même fonction ; ici, cette carte est un widget à part
/// (`_freeStepCard`), donc rien à passer.
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
  debloquer,

  /// Rien ne se résout : la carte **nomme** l'étape et s'arrête là.
  aucun,
}

/// L'identité **complète** de la carte : ce qu'elle montre, et ce qu'elle lance.
class PlanNowCard {
  const PlanNowCard({
    required this.nature,
    required this.geste,
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

  /// **La mesure que le bouton LANCE**, `null` dès que la carte porte une étape.
  /// C'est elle qui décide du verrou comme du démarrage
  /// ([startPlanSeanceItem]).
  final PlanSeanceItem? mesure;

  /// `null` sur la seule nature [PlanNowNature.indisponible] : il n'y a **rien**
  /// à lancer, et nommer la priorité du Plan désignerait une autre compétence.
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
  final String badge;

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
  /// d'audience du lanceur. `null` sur une mesure.
  final LearningPlanPriority? priority;
}

PlanStepAction? planStepAction(LearningPlan plan, JourneyStep etape) {
  final mesure = _mesureDe(plan, etape);
  if (mesure != null) return PlanStepAction(mesure: mesure);
  final priority = _priorityDe(plan, etape);
  final exercise = priority?.recommendedExercise;
  if (priority == null || exercise == null) return null;
  return PlanStepAction(exercise: exercise, priority: priority);
}

/// **La carte « À faire maintenant » d'un plan TCF**, ou `null` quand le serveur
/// n'a désigné aucune priorité (l'écran affiche alors son état vide).
///
/// 🛑 **Rien n'est décidé ici** : la précédence de la mesure, la nature de
/// l'action, les minutes et le verrou sont tous **servis**. Cette fonction ne
/// fait que choisir *laquelle* des deux identités la carte porte, et le dire une
/// seule fois pour les deux écrans.
PlanNowCard? planNowCard(LearningPlan plan, {Journey? journey}) {
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
    return _carteIndisponible(etape);
  }

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
    final verrou = planSeanceItemLocked(mesure!);
    return PlanNowCard(
      nature: PlanNowNature.mesure,
      geste: verrou ? PlanNowGeste.debloquer : PlanNowGeste.lancer,
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
      cta: verrou
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
  final verrou = priority.locked || (exercise?.locked ?? false);

  return PlanNowCard(
    nature: verifier ? PlanNowNature.verification : PlanNowNature.etape,
    geste: verrou
        ? PlanNowGeste.debloquer
        : exercise == null
            ? PlanNowGeste.aucun
            : PlanNowGeste.lancer,
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
    lines: planNowLines(priority),
    cta: verrou
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
  if (etape.type != JourneyStepType.sectionExam || etape.examType == null) {
    return null;
  }
  for (final item in plan.seance.items) {
    if (item.assessment?.epreuve == etape.examType) return item;
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
PlanNowCard _carteIndisponible(JourneyStep etape) {
  final epreuve = etape.examType;
  return PlanNowCard(
    nature: PlanNowNature.indisponible,
    // 🛑 Une étape **fermée** garde son geste, même quand son action ne se
    // résout pas : c'est l'offre. Ouverte mais sans action, elle reste sans
    // geste — on ne lui fait pas ouvrir un paywall qui ne la débloquerait pas.
    geste: etape.locked ? PlanNowGeste.debloquer : PlanNowGeste.aucun,
    mesure: null,
    priority: null,
    exercise: null,
    section: etape.section,
    icon: epreuve == null ? LucideIcons.target : planDomainIcon(epreuve),
    title: journeyStepTitle(etape),
    subtitle: journeyStepSubtitle(etape),
    badge: '',
    objectiveLabel: null,
    objective: null,
    minutesLabel: null,
    kindLabel: null,
    lines: const [kPlanNowUnavailableText],
    cta: etape.locked ? kPlanNowLockedCta : kPlanNowStartCta,
    // Le verrou **servi** de l'étape, pas une déduction : une étape
    // indisponible peut être verrouillée par ailleurs, et l'écran doit
    // continuer à le dire.
    locked: etape.locked,
  );
}

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/diagnostic_models.dart';
import '../../core/models/journey_models.dart';
import '../../core/models/skill_models.dart';
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
}

/// L'identité **complète** de la carte : ce qu'elle montre, et ce qu'elle lance.
class PlanNowCard {
  const PlanNowCard({
    required this.nature,
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

  /// **La mesure que le bouton LANCE**, `null` dès que la carte porte une étape.
  /// C'est elle qui décide du verrou comme du démarrage
  /// ([startPlanSeanceItem]).
  final PlanSeanceItem? mesure;

  final LearningPlanPriority priority;

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
  // ⚠️ **Repli assumé** quand le parcours nomme une compétence que le Plan ne
  // priorise plus (cas normal : son transfert vient d'être prouvé). Montrer la
  // carte du Plan vaut mieux que ne rien montrer, et l'écart est transitoire.
  final priority = (etape == null ? null : _priorityDe(plan, etape)) ??
      plan.currentPriority;
  if (priority == null) return null;

  final exercise = priority.recommendedExercise;
  // 🛑 **Une MESURE passe devant tout le reste** — sauf quand un parcours est
  // servi : il a **déjà** appliqué la précédence (R12), et rejouer
  // `planSeanceMesure` ferait passer une mesure devant l'étape qu'il vient de
  // désigner. Deux règles de précédence pour une seule carte.
  final mesure =
      etape == null ? planSeanceMesure(plan) : _mesureDe(plan, etape);
  final mesureDomaine = mesure?.assessment;

  // 🛑 **La carte de vérification est une AUTRE carte.** Elle se lit sur la
  // nature **servie**, jamais sur un compteur.
  final verifier = mesureDomaine == null &&
      priority.nature == PlanActionNature.aVerifier &&
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
              priority.stepPromptCount > 0 &&
              exercise?.kind == PlanExerciseKind.microTraining
          ? '${priority.stepPromptCount} petits sujets · ≈ $minutes min chacun'
          : '≈ $minutes min';

  if (mesureDomaine != null) {
    return PlanNowCard(
      nature: PlanNowNature.mesure,
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
      cta: planNowCta(priority, verifier: false, mesure: true),
      locked: planSeanceItemLocked(mesure!),
    );
  }

  final epreuve = planEpreuveOfSection(priority.section);
  final task = SkillTaskCode.fromSkillCode(priority.skillCode);
  final level = planSkillTargetLevel(plan, priority.skillId);

  return PlanNowCard(
    nature: verifier ? PlanNowNature.verification : PlanNowNature.etape,
    mesure: null,
    priority: priority,
    exercise: exercise,
    section: priority.section,
    icon: verifier ? LucideIcons.badgeCheck : planDomainIcon(epreuve),
    // 🛑 **Le nom de la compétence ne se répète pas trois fois.** Il vit en
    // titre avant 5/5 et en sous-titre sur la vérification, dont le titre nomme
    // l'ACTION.
    title: verifier ? kPlanNowVerifyTitle : priority.title,
    subtitle: verifier
        ? planNowVerifySubtitle(priority.title, task)
        : planNowSubtitle(
            domaine: epreuve == null
                ? priority.section.label
                : planDomainLabel(epreuve),
            task: task,
            level: level,
          ),
    badge: planPriorityRankTag(1),
    objectiveLabel: verifier ? kPlanNowVerifyObjectiveLabel : null,
    objective: verifier ? kPlanNowVerifyText : null,
    minutesLabel: minutesLabel,
    kindLabel: planExerciseKindLabel(
      exercise?.kind,
      questionCount: exercise?.questionCount,
    ),
    lines: planNowLines(priority),
    cta: planNowCta(priority, verifier: verifier, mesure: false),
    locked: priority.locked || (exercise?.locked ?? false),
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
  for (final assessment in plan.domainesAEvaluer) {
    if (assessment.epreuve != etape.examType) continue;
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
  return null;
}

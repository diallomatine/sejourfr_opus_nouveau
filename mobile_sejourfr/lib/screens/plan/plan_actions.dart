import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/skill_models.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/premium_lock.dart';
import '../module_detail/production_exam_briefing_sheet.dart';
import '../module_detail/tcf_module_exam_briefing_screen.dart';
import '../module_detail/tcf_qcm_detail_screen.dart' show TcfQcmModule;
import '../tcf_production/competences/competences_nav.dart';
import '../tcf_production/production_exam_launcher.dart';
import '../tcf_production/recommended_exercise_launcher.dart';
import '../tcf_production/tcf_production_module.dart';
import 'plan_labels.dart';
import 'plan_milestone_launcher.dart';
import 'plan_seance_state.dart';

/// **Où mènent les gestes du Plan**, en un seul endroit.
///
/// Les blocs de l'écran sont des widgets sans état ; ils ne recollent pas
/// chacun leur chemin de navigation, sinon deux cartes qui désignent la même
/// compétence finiraient par ouvrir deux écrans différents.

/// Lance l'exercice désigné par le Plan.
///
/// Un exercice **verrouillé n'est jamais « démarré »** (l'événement d'audience
/// mentirait) : c'est le lanceur partagé qui tranche et ouvre l'offre — ici
/// comme sur le résultat du diagnostic.
Future<void> openPlanExercise(
  BuildContext context,
  WidgetRef ref,
  PlanRecommendedExercise exercise, {
  SkillMasteryState? masteryBefore,
  VoidCallback? onVerrou,
}) async {
  if (!exercise.locked) {
    ref.read(analyticsServiceProvider).track(
          AnalyticsEvent.planExerciseStarted,
          path: AnalyticsPath.plan,
          exerciseKind: exercise.kind.wire,
        );
  }
  await openRecommendedExercise(
    onVerrou: onVerrou,
    context,
    ref,
    exercise,
    masteryBefore: masteryBefore,
  );
}

/// **Ouvre une ligne de la séance** — le geste de la *liste*.
///
/// 🛑 **Un petit sujet ciblé ouvre la FICHE DE SA COMPÉTENCE**, jamais le sujet
/// directement : c'est là que le candidat voit ses cinq sujets et lesquels sont
/// faits. C'est exactement ce que fait déjà la ligne correspondante de « Mes
/// priorités » — la même compétence ne peut pas mener à deux écrans selon
/// l'endroit où on la touche.
///
/// Les autres natures gardent leur lancement direct, parce qu'elles n'ont pas
/// de fiche à ouvrir : une **série ciblée** de compréhension part dans le
/// runner QCM, un **jalon** ouvre son examen blanc, une **mesure de domaine**
/// ouvre son parcours d'évaluation. Une **vérification en situation** aussi :
/// son sujet est une tâche de production qui ne fait pas partie des cinq de la
/// fiche — l'y envoyer laisserait le candidat sans aucun moyen de la faire.
///
/// ⚠️ Une compétence **à acquérir** est un micro-sujet comme un autre : elle
/// ouvre sa fiche. Sa nature change ce que la carte **dit**, pas où elle mène.
///
/// ⚠ Le verrou est **lu** ([planSeanceItemLocked]), jamais déduit du rang de la
/// ligne : une action verrouillée ouvre l'offre au lieu d'être masquée.
Future<void> openPlanSeanceItem(
  BuildContext context,
  WidgetRef ref,
  PlanSeanceItem item, {
  VoidCallback? onVerrou,
}) async {
  if (planSeanceItemLocked(item)) {
    // 🛑 A145 : depuis le Plan, un geste d'achat passe par l'écran de
    // transition. Ailleurs, le paywall direct reste le comportement.
    if (onVerrou != null) {
      onVerrou();
      return;
    }
    await showTcfLockPaywall(
      context,
      ref: ref,
      ctaLocation: AnalyticsCtaLocation.lockedPlan,
    );
    return;
  }
  final skillId = item.skillId;
  final section = item.section;
  if (item.kind == PlanExerciseKind.microTraining &&
      skillId != null &&
      section != null &&
      section.isProduction) {
    openPlanSkill(context, skillId, section);
    return;
  }
  await startPlanSeanceItem(context, ref, item);
}

/// **Lance une ligne de la séance**, quelle que soit sa nature.
///
/// Extrait à la deuxième occurrence : la carte de séance et le bouton
/// principal de l'écran ouvraient le même item par deux chemins, et l'un des
/// deux avait oublié les **jalons** — taper le bouton principal sur un examen
/// blanc ne faisait alors rien du tout.
///
/// C'est **le geste du bouton principal** : « Commencer ma séance » démarre
/// l'entraînement, il n'ouvre pas une fiche.
///
/// 🛑 **Une ligne peut ne pas être un entraînement.** Un item
/// [PlanActionNature.aEvaluer] porte une **mesure de domaine** et aucun
/// exercice : il repart vers le parcours d'évaluation existant
/// ([openPlanAssessment], l'autorité unique), jamais vers un second chemin
/// écrit ici.
Future<void> startPlanSeanceItem(
  BuildContext context,
  WidgetRef ref,
  PlanSeanceItem item, {
  VoidCallback? onVerrou,
}) async {
  if (planSeanceItemLocked(item)) {
    // 🛑 A145 : depuis le Plan, un geste d'achat passe par l'écran de
    // transition. Ailleurs, le paywall direct reste le comportement.
    if (onVerrou != null) {
      onVerrou();
      return;
    }
    await showTcfLockPaywall(
      context,
      ref: ref,
      ctaLocation: AnalyticsCtaLocation.lockedPlan,
    );
    return;
  }
  final assessment = item.assessment;
  if (item.nature.isAssessment && assessment != null) {
    openPlanAssessment(context, ref, assessment);
    return;
  }
  final exercise = item.exercise;
  final milestone = item.milestone;
  if (exercise != null) {
    await openPlanExercise(
      context,
      ref,
      exercise,
      masteryBefore: item.masteryState,
    );
  } else if (milestone != null) {
    await startPlanMilestone(context, ref, milestone);
  }
}

/// Ouvre une compétence.
///
/// 🛑 **Une compétence de compréhension n'a pas d'écran de compétence** : la
/// voie des petits sujets est celle de l'expression. On ouvre alors la fiche de
/// son domaine, qui porte ses paliers et ses séries ciblées — pas une fiche
/// d'expression construite avec un module deviné.
///
/// En expression, ouverte **depuis le Plan**, la compétence s'affiche à
/// l'échelle de son **étape** (les 5 sujets, « 2/5 ») : c'est le marqueur
/// `?etape=1`, relu sur le Plan déjà chargé.
void openPlanSkill(
  BuildContext context,
  String skillId,
  SkillSection section,
) {
  if (section.isComprehension) {
    final domain = planEpreuveOfSection(section);
    if (domain != null) openPlanDomain(context, domain);
    return;
  }
  final module =
      section.isEo ? TcfProductionModule.eo : TcfProductionModule.ee;
  context.push(competenceDetailPath(module, skillId, planStep: true));
}

/// La fiche d'un domaine du TCF. Aucun identifiant ne voyage : la fiche relit
/// le Plan déjà chargé.
void openPlanDomain(BuildContext context, EpreuveType epreuve) {
  context.push(
    AppRoutes.planDomain.replaceFirst(':domainKey', planDomainKey(epreuve)),
  );
}

/// **Mesurer un domaine** : la seule traduction de `PlanDomainAssessmentKind`
/// en écran, pour les cinq surfaces qui la demandent — la carte d'épreuve de
/// l'Accueil (« Où vous en êtes »), l'écran Progrès, la fiche d'un domaine, la
/// ligne `A_EVALUER` de la séance et le bilan du diagnostic.
///
/// 🛑 **Aucun parcours n'est créé ici.** Le briefing d'examen blanc de module et
/// celui de l'examen blanc de production existent déjà, sont verrouillés côté
/// serveur, et c'est vers eux qu'on renvoie. Ce qui est centralisé, c'est **le
/// choix**, pas le contenu.
///
/// 🛑 **Les quatre épreuves lancent un EXAMEN BLANC** (arbitrage du
/// propriétaire, 2026-09-16) : examen de module en CO/CE, examen de production
/// (les 3 tâches) en EE/EO. L'expression partait auparavant vers l'ancien
/// diagnostic (1 EE + 1 EO) ou vers l'entraînement libre — **aucun des deux ne
/// lançait un examen blanc**, et « mesurer ce domaine » ne voulait donc pas dire
/// la même chose selon l'épreuve.
///
/// ⚠️ **Le sas est celui de l'épreuve, dans les deux cas** : CO/CE ouvrent
/// `ModuleExamBriefingSheet`, EE/EO `ProductionExamBriefingSheet`. Le lancement
/// réel vit dans `startProductionExam`, **partagé avec le jalon du Plan** — on
/// ne recopie pas son corps ici.
///
/// 🛑 **`slotNumber` est SERVI** : c'est lui qui pilote le démarrage, jamais un
/// `1` décidé ici (le repli ne couvre qu'un client servi par un backend qui ne
/// le publierait pas).
///
/// ⚠️ **Ce n'est jamais une série ciblée** : une série est un `TRAINING`, elle
/// ne rend jamais un domaine « évalué ». Le lanceur de séries reste
/// `plan_series_launcher.dart`, il répond à une autre question.
void openPlanAssessment(
  BuildContext context,
  WidgetRef ref,
  PlanDomainAssessment assessment,
) {
  switch (assessment.kind) {
    case PlanDomainAssessmentKind.moduleMockExam:
      // `moduleExamQuestionType` est ce que `StartAttemptRequest` attend ; le
      // repli sur CO vaut pour un type absent, jamais pour un type inconnu de
      // la grille QCM.
      final module = switch (assessment.moduleExamQuestionType) {
        QuestionType.ce => TcfQcmModule.ce,
        QuestionType.structure => TcfQcmModule.structure,
        _ => TcfQcmModule.co,
      };
      showModuleExamBriefingSheet(
        context,
        module,
        slotNumber: assessment.slotNumber,
      );
    case PlanDomainAssessmentKind.productionMockExam:
      final module = assessment.epreuve == EpreuveType.tcfEo
          ? TcfProductionModule.eo
          : TcfProductionModule.ee;
      showProductionExamBriefingSheet(
        context,
        module: module,
        starting: false,
        onStart: () => startProductionExam(
          context,
          ref,
          epreuve: assessment.epreuve,
          slotNumber: assessment.slotNumber ?? 1,
        ),
      );
  }
}


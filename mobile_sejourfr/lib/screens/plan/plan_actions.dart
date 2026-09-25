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
import 'learning_plan_provider.dart' show journeyProvider;
import 'plan_cta.dart';
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
///
/// 🛑 [origine] est **requise** (contrôle F) : l'Accueil et Réviser relaient
/// l'exercice du Plan ([PlanOrigine.relais]), le Plan le lance
/// ([PlanOrigine.plan]). Ce lanceur n'impose plus `LOCKED_PLAN`.
Future<void> openPlanExercise(
  BuildContext context,
  WidgetRef ref,
  PlanRecommendedExercise exercise, {
  required PlanOrigine origine,
  SkillMasteryState? masteryBefore,
  VoidCallback? onVerrou,
}) async {
  if (!exercise.locked) {
    ref.read(analyticsServiceProvider).track(
          AnalyticsEvent.planExerciseStarted,
          path: AnalyticsPath.plan,
          exerciseKind: exercise.kind.wire,
          journeyId: ref.read(journeyProvider).valueOrNull?.journeyId,
        );
  }
  // 🛑 **Un petit sujet ciblé ouvre la FICHE DE SA COMPÉTENCE**, jamais le
  // sujet directement (demande du propriétaire, 2026-09-20) : c'est là que le
  // candidat voit ses cinq sujets et lesquels sont faits.
  //
  // ⚠️ **Révoque** « le bouton principal démarre l'entraînement, il n'ouvre pas
  // une fiche » : les lignes du cycle et la carte « À faire maintenant »
  // passaient par ici et sautaient donc à un sujet, pendant que la ligne de
  // séance ouvrait la fiche. La même compétence menait à
  // deux écrans selon l'endroit où on la touchait.
  //
  // 🛑 **La VÉRIFICATION garde son lancement direct** : son sujet est une tâche
  // de production qui ne fait pas partie des cinq — l'y envoyer laisserait le
  // candidat sans aucun moyen de la faire.
  final section = exercise.section;
  if (exercise.kind == PlanExerciseKind.microTraining && section.isProduction) {
    openPlanSkill(context, exercise.skillId, section);
    return;
  }
  final cta = planCta(ref, origine, horsPlan: AnalyticsCtaLocation.other);
  await openRecommendedExercise(
    onVerrou: onVerrou,
    context,
    ref,
    exercise,
    masteryBefore: masteryBefore,
    ctaLocation: cta.ctaLocation,
    journeyId: cta.journeyId,
  );
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
///
/// [origine] : cf. [openPlanExercise].
Future<void> startPlanSeanceItem(
  BuildContext context,
  WidgetRef ref,
  PlanSeanceItem item, {
  required PlanOrigine origine,
  VoidCallback? onVerrou,
}) async {
  if (planSeanceItemLocked(item)) {
    // 🛑 A145 : depuis le Plan, un geste d'achat passe par l'écran de
    // transition. Ailleurs, le paywall direct reste le comportement.
    if (onVerrou != null) {
      onVerrou();
      return;
    }
    final cta = planCta(ref, origine, horsPlan: AnalyticsCtaLocation.other);
    await showTcfLockPaywall(
      context,
      ref: ref,
      ctaLocation: cta.ctaLocation,
      journeyId: cta.journeyId,
    );
    return;
  }
  final assessment = item.assessment;
  if (item.nature.isAssessment && assessment != null) {
    openPlanAssessment(context, ref, assessment, origine: origine);
    return;
  }
  final exercise = item.exercise;
  final milestone = item.milestone;
  if (exercise != null) {
    await openPlanExercise(
      context,
      ref,
      exercise,
      origine: origine,
      masteryBefore: item.masteryState,
    );
  } else if (milestone != null) {
    await startPlanMilestone(context, ref, milestone, origine: origine);
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
///
/// 🛑 [origine] est **requise** (contrôle F) : la carte d'épreuve de l'Accueil
/// n'est pas le Plan ([PlanOrigine.horsPlan] → `MOCK_EXAM`, le CTA des grilles
/// d'examens).
void openPlanAssessment(
  BuildContext context,
  WidgetRef ref,
  PlanDomainAssessment assessment, {
  required PlanOrigine origine,
}) {
  final cta = planCta(ref, origine, horsPlan: AnalyticsCtaLocation.mockExam);
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
        ctaLocation: cta.ctaLocation,
        journeyId: cta.journeyId,
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
          ctaLocation: cta.ctaLocation,
          journeyId: cta.journeyId,
        ),
      );
  }
}


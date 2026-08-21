import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/audience_repository.dart';
import '../../core/api/repositories.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/skill_models.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/premium_lock.dart';
import '../module_detail/tcf_module_exam_briefing_screen.dart';
import '../module_detail/tcf_qcm_detail_screen.dart' show TcfQcmModule;
import '../tcf_production/competences/competences_nav.dart';
import '../tcf_production/production_nav.dart';
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

/// Mesure agrégée — jamais bloquante, jamais un identifiant.
Future<void> trackPlan(WidgetRef ref, AudienceEvent event) async {
  try {
    await ref
        .read(audienceRepositoryProvider)
        .track(path: '/plan', event: event);
  } catch (_) {
    // Une statistique agrégée ne doit jamais bloquer le plan.
  }
}

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
}) async {
  if (!exercise.locked) {
    unawaited(trackPlan(ref, AudienceEvent.planRecommendedExerciseStarted));
  }
  await openRecommendedExercise(
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
  PlanSeanceItem item,
) async {
  if (planSeanceItemLocked(item)) {
    await showTcfLockPaywall(context);
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
  PlanSeanceItem item,
) async {
  if (planSeanceItemLocked(item)) {
    await showTcfLockPaywall(context);
    return;
  }
  final assessment = item.assessment;
  if (item.nature.isAssessment && assessment != null) {
    openPlanAssessment(context, assessment);
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
/// en écran, pour les trois surfaces qui la demandent — la liste « Compléter
/// mon profil », la fiche d'un domaine et le bilan du diagnostic.
///
/// 🛑 **Aucun parcours n'est créé ici.** Le diagnostic, le briefing d'examen
/// blanc de module et l'entrée du parcours d'expression existent déjà, sont
/// verrouillés côté serveur, et c'est vers eux qu'on renvoie. Ce qui est
/// centralisé, c'est **le choix**, pas le contenu.
///
/// Cette fonction a été extraite à la **3ᵉ occurrence** : deux copies vivaient
/// déjà côté Plan et une troisième s'apprêtait à naître sur le bilan. Trois
/// copies auraient fini par ouvrir trois écrans différents pour le même
/// domaine. Ne pas la réinliner.
///
/// ⚠️ **Ce n'est jamais une série ciblée** : une série est un `TRAINING`, elle
/// ne rend jamais un domaine « évalué ». Le lanceur de séries reste
/// `plan_series_launcher.dart`, il répond à une autre question.
void openPlanAssessment(
  BuildContext context,
  PlanDomainAssessment assessment,
) {
  switch (assessment.kind) {
    case PlanDomainAssessmentKind.diagnostic:
      context.push(AppRoutes.diagnostic);
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
    case PlanDomainAssessmentKind.production:
      // Un jalon de production, c'est un **examen blanc d'épreuve** : on ouvre
      // sa grille, pas la liste des tâches — il n'y a rien à choisir.
      context.push(
        productionExamsPath(
          assessment.epreuve == EpreuveType.tcfEo
              ? TcfProductionModule.eo
              : TcfProductionModule.ee,
        ),
      );
  }
}

/// L'écran « Votre programme évolue » — le détail de ce qui a bougé.
void openPlanEvolution(BuildContext context) =>
    context.push(AppRoutes.planEvolution);

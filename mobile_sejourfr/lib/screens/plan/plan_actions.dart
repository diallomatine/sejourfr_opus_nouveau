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
import '../module_detail/tcf_module_exam_briefing_screen.dart';
import '../module_detail/tcf_qcm_detail_screen.dart' show TcfQcmModule;
import '../tcf_production/competences/competences_nav.dart';
import '../tcf_production/recommended_exercise_launcher.dart';
import '../tcf_production/tcf_production_module.dart';
import 'plan_labels.dart';

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
      context.push(
        assessment.epreuve == EpreuveType.tcfEo
            ? AppRoutes.tcfEoEntry
            : AppRoutes.tcfEeEntry,
      );
  }
}

/// L'écran « Votre programme évolue » — le détail de ce qui a bougé.
void openPlanEvolution(BuildContext context) =>
    context.push(AppRoutes.planEvolution);

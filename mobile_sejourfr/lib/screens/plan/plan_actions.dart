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

/// L'écran « Votre programme évolue » — le détail de ce qui a bougé.
void openPlanEvolution(BuildContext context) =>
    context.push(AppRoutes.planEvolution);

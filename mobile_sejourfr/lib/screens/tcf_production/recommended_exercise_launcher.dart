import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/skill_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../../core/widgets/premium_lock.dart';
import 'competences/competences_nav.dart';
import 'ee_session_controller.dart';
import 'eo_session_controller.dart';
import 'production_nav.dart';
import 'tcf_production_module.dart';

/// Ouvre l'exercice recommandé par le Plan — **le seul endroit** qui sait où
/// mènent ses deux natures.
///
/// * [PlanExerciseKind.microTraining] → l'écran d'un petit sujet du module
///   Compétences, comme depuis « Réviser → Compétences ».
/// * [PlanExerciseKind.reassessment] → l'écran de production d'une **vraie
///   tâche TCF**, atteint exactement comme depuis le mode « Sujets » : on
///   charge le sujet, on démarre la session, puis on ouvre `t/0`. Le sujet ne
///   voyage jamais dans l'URL — c'est la session qui le porte.
///
/// Le Plan et le résultat du diagnostic l'appellent tous les deux : deux copies
/// auraient fini par router différemment la même recommandation.
Future<void> openRecommendedExercise(
  BuildContext context,
  WidgetRef ref,
  PlanRecommendedExercise exercise,
) async {
  // Garde de dernier recours : le serveur décide du verrou, l'app ne le devine
  // pas. Les cartes ouvrent déjà le paywall d'elles-mêmes.
  if (exercise.locked) {
    await showTcfLockPaywall(context);
    return;
  }
  final module = exercise.section == SkillSection.eo
      ? TcfProductionModule.eo
      : TcfProductionModule.ee;

  if (exercise.kind == PlanExerciseKind.reassessment) {
    await _openReassessment(context, ref, exercise, module);
    return;
  }

  final promptId = exercise.skillPromptId;
  // Micro-exercice sans sujet : la fiche de la compétence, jamais une adresse
  // fabriquée avec un identifiant nul.
  context.push(promptId == null
      ? competenceDetailPath(module, exercise.skillId)
      : competencePromptPath(module, exercise.skillId, promptId));
}

Future<void> _openReassessment(
  BuildContext context,
  WidgetRef ref,
  PlanRecommendedExercise exercise,
  TcfProductionModule module,
) async {
  final taskId = exercise.productionTaskId;
  // Vérification sans sujet : on ouvre la liste des sujets de sa tâche plutôt
  // que de démarrer une session vide.
  if (taskId == null) {
    context.push(productionCompetencesPath(module, exercise.tacheNumero ?? 1));
    return;
  }
  ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
  try {
    final task = await ref.read(productionRepositoryProvider).getTask(taskId);
    if (module.isEo) {
      await ref.read(eoSessionProvider.notifier).startSingle(task: task);
    } else {
      await ref.read(eeSessionProvider.notifier).startSingle(task: task);
    }
    if (!context.mounted) return;
    context.push(productionSessionPath(module));
  } catch (error) {
    if (!context.mounted) return;
    final err = ApiClient.toApiException(error);
    if (err.isForbidden) {
      showPaywallSheet(context);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err.message), backgroundColor: AppColors.red),
    );
  }
}

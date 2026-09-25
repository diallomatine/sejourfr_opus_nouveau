import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics_events.dart';
import '../../core/api/repositories.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/selected_module.dart';
import '../../core/utils/start_failure.dart';
import '../module_detail/tcf_full_exams_screen.dart' show fullExamsHistoryProvider;
import '../tcf_production/production_exam_launcher.dart';
import 'learning_plan_provider.dart' show planJourneyId;

/// Démarre le **jalon** du Plan — extrait de `PlanMilestoneCard` quand la
/// séance a eu besoin de lancer le même examen depuis une ligne de liste.
///
/// ⚠️ **Rien n'est décidé ici** : quelle épreuve, quel slot, verrouillé ou non,
/// tout vient de [PlanMilestone] (`PlanMilestoneSelector` côté serveur). On
/// n'apporte que le **chemin de démarrage**, et c'est celui des écrans
/// d'examen blanc existants, réutilisé tel quel — aucune route n'est créée,
/// aucun appel n'est réinventé.
Future<void> startPlanMilestone(
  BuildContext context,
  WidgetRef ref,
  PlanMilestone milestone,
) async {
  if (!milestone.isFullExam) {
    // ⚠️ Le démarrage d'un examen de production vit dans `startProductionExam`,
    // partagé avec la mesure d'un domaine d'expression et avec la grille
    // d'examens de l'épreuve : il pose déjà le module actif, ouvre la session
    // avant de pousser l'écran, et route le 403 vers l'offre.
    await startProductionExam(
      context,
      ref,
      epreuve: milestone.epreuve,
      slotNumber: milestone.slotNumber,
      ctaLocation: AnalyticsCtaLocation.lockedPlan,
      journeyId: planJourneyId(ref),
    );
    return;
  }

  ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
  try {
    final exam = await ref
        .read(fullTcfExamRepositoryProvider)
        .start(slotNumber: milestone.slotNumber);
    if (!context.mounted) return;
    ref.invalidate(fullExamsHistoryProvider);
    context.go(
      AppRoutes.tcfFullExamProgress.replaceFirst(':parentId', exam.id),
    );
  } catch (error) {
    if (!context.mounted) return;
    showPaywallOrError(
      context,
      error,
      ctaLocation: AnalyticsCtaLocation.lockedPlan,
      journeyId: planJourneyId(ref),
    );
  }
}

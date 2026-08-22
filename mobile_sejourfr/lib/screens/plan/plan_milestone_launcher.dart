import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/repositories.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/selected_module.dart';
import '../../core/utils/start_failure.dart';
import '../module_detail/tcf_full_exams_screen.dart' show fullExamsHistoryProvider;
import '../tcf_production/ee_session_controller.dart';
import '../tcf_production/eo_session_controller.dart';
import '../tcf_production/production_nav.dart';
import '../tcf_production/tcf_production_module.dart';

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
  ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
  try {
    if (milestone.isFullExam) {
      final exam = await ref
          .read(fullTcfExamRepositoryProvider)
          .start(slotNumber: milestone.slotNumber);
      if (!context.mounted) return;
      ref.invalidate(fullExamsHistoryProvider);
      context.go(
        AppRoutes.tcfFullExamProgress.replaceFirst(':parentId', exam.id),
      );
      return;
    }

    final module = milestone.epreuve == EpreuveType.tcfEo
        ? TcfProductionModule.eo
        : TcfProductionModule.ee;
    // Le sujet ne voyage jamais dans l'URL : la session Riverpod doit être
    // démarrée avant le push, comme dans l'onglet « Examens ».
    if (module.isEo) {
      await ref
          .read(eoSessionProvider.notifier)
          .startExam(slotNumber: milestone.slotNumber);
    } else {
      await ref
          .read(eeSessionProvider.notifier)
          .startExam(slotNumber: milestone.slotNumber);
    }
    if (!context.mounted) return;
    context.push(productionSessionPath(module));
  } catch (error) {
    if (!context.mounted) return;
    showPaywallOrError(context, error);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics_events.dart';
import '../../core/models/enums.dart';
import '../../core/utils/selected_module.dart';
import '../../core/utils/start_failure.dart';
import '../module_detail/production_exam_briefing_sheet.dart';
import 'ee_session_controller.dart';
import 'eo_session_controller.dart';
import 'production_nav.dart';
import 'tcf_production_module.dart';

/// **LE point de lancement d'un examen blanc EE/EO de l'app** — miroir de
/// `useMockExamLauncher` côté web.
///
/// Tous les points d'entrée passent par lui — la grille « Examens blancs » de
/// l'épreuve, le jalon du Plan, l'étape « Examen blanc » du cycle, la mesure
/// d'un domaine (Accueil, Réviser, Progrès, fiche d'un domaine) — et il fait
/// toujours la même chose : **la feuille d'information d'abord**
/// ([ProductionExamBriefingSheet]), puis, au tap « Commencer maintenant », le
/// démarrage de la session et la tâche 1.
///
/// 🛑 **Le chrono ne part qu'au tap.** L'EE est chronométrée sur
/// `startedAt + timeLimitSeconds` de l'attempt : le créer à l'ouverture de la
/// feuille ferait courir le temps pendant la lecture.
///
/// ⚠️ **Rien n'est décidé ici** : l'épreuve et le slot viennent de l'appelant,
/// qui les tient d'un descripteur **servi** (`PlanMilestone.slotNumber`,
/// `PlanDomainAssessment.slotNumber`, la grille). Un **403** n'est pas une
/// panne : c'est le verrou freemium que le serveur oppose — il ouvre l'offre
/// ([showPaywallOrError]), jamais un message d'erreur technique.
///
/// [onBusy] : l'écran appelant peut poser son voile pendant le démarrage.
Future<void> launchProductionExam(
  BuildContext context,
  WidgetRef ref, {
  required EpreuveType epreuve,
  required int slotNumber,
  required AnalyticsCtaLocation? ctaLocation,
  String? journeyId,
  ValueChanged<bool>? onBusy,
}) {
  final module = epreuve == EpreuveType.tcfEo
      ? TcfProductionModule.eo
      : TcfProductionModule.ee;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => ProductionExamBriefingSheet(
      module: module,
      onStart: () => _startProductionExam(
        context,
        sheetContext,
        ref,
        module: module,
        slotNumber: slotNumber,
        ctaLocation: ctaLocation,
        journeyId: journeyId,
        onBusy: onBusy,
      ),
    ),
  );
}

/// 🛑 **La session Riverpod est démarrée AVANT le push** : le sujet ne voyage
/// jamais dans l'URL (cf. [productionSessionPath]). La feuille se ferme une
/// fois le démarrage tranché — jamais avant, pour qu'un échec s'y lise.
Future<void> _startProductionExam(
  BuildContext context,
  BuildContext sheetContext,
  WidgetRef ref, {
  required TcfProductionModule module,
  required int slotNumber,
  required AnalyticsCtaLocation? ctaLocation,
  required String? journeyId,
  required ValueChanged<bool>? onBusy,
}) async {
  onBusy?.call(true);
  ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
  try {
    if (module.isEo) {
      await ref.read(eoSessionProvider.notifier).startExam(slotNumber: slotNumber);
    } else {
      await ref.read(eeSessionProvider.notifier).startExam(slotNumber: slotNumber);
    }
    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
    if (!context.mounted) return;
    context.push(productionSessionPath(module));
  } catch (error) {
    // Une seule feuille à la fois : la nôtre se ferme avant l'offre.
    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
    if (!context.mounted) return;
    showPaywallOrError(
      context,
      error,
      ctaLocation: ctaLocation,
      journeyId: journeyId,
    );
  } finally {
    onBusy?.call(false);
  }
}

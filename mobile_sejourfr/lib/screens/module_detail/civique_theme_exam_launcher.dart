import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics.dart';
import '../../core/api/repositories.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/selected_module.dart';
import '../../core/utils/start_failure.dart';
import 'civique_exam_briefing_sheet.dart';
import 'civique_hub_data.dart';

/// **LE point de lancement d'un examen blanc de THÈME civique de l'app** —
/// miroir de `useMockExamLauncher` (`kind: "CIVIQUE"`) côté web.
///
/// Deux points d'entrée, un seul chemin : la grille « Examens blancs » du thème
/// et l'étape « Examen blanc » d'un bloc du Plan civique. Toujours **la feuille
/// d'information d'abord** ([showCiviqueThemeExamBriefingSheet]), puis, au tap,
/// la création de l'attempt et la première question.
///
/// ⚠️ **Rien n'est décidé ici** : le thème et le créneau viennent de l'appelant,
/// qui les tient de la grille ou d'un descripteur **servi**
/// (`JourneyStep.examenTheme`). Un **403** est le verrou freemium : il ouvre
/// l'offre ([showPaywallOrError]), jamais une erreur technique.
///
/// [onBusy] : l'écran appelant peut poser son voile pendant le démarrage.
Future<void> launchCiviqueThemeExam(
  BuildContext context,
  WidgetRef ref, {
  required String themeId,
  required String themeName,
  required int slotNumber,
  ValueChanged<bool>? onBusy,
}) {
  return showCiviqueThemeExamBriefingSheet(
    context,
    themeName: themeName,
    onStart: () => _demarrer(
      context,
      ref,
      themeId: themeId,
      slotNumber: slotNumber,
      onBusy: onBusy,
    ),
  );
}

Future<void> _demarrer(
  BuildContext context,
  WidgetRef ref, {
  required String themeId,
  required int slotNumber,
  required ValueChanged<bool>? onBusy,
}) async {
  onBusy?.call(true);
  ref.read(selectedModuleProvider.notifier).state = AppModule.civique;
  try {
    final attempt = await ref.read(attemptsRepositoryProvider).start(
          StartAttemptRequest(
            type: AttemptType.mockExam,
            module: AppModule.civique,
            themeId: themeId,
            slotNumber: slotNumber,
          ),
        );
    ref.invalidate(civiqueThemeExamsHistoryProvider(themeId));
    if (!context.mounted) return;
    context.push(AppRoutes.runner.replaceFirst(':attemptId', attempt.id));
  } catch (e) {
    if (!context.mounted) return;
    showPaywallOrError(context, e, ctaLocation: AnalyticsCtaLocation.mockExam);
  } finally {
    onBusy?.call(false);
  }
}

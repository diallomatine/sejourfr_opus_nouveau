import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/skill_models.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/selected_module.dart';
import '../../core/utils/start_failure.dart';

/// Démarre une **série ciblée de compréhension** (CO / CE) — le seul endroit
/// qui le fasse.
///
/// 🛑 **Aucun runner n'est créé pour ça.** La série est un `TRAINING` de QCM
/// ordinaire : on démarre l'attempt puis on ouvre le runner existant, avec un
/// contexte `from=planSerie` que sa fin lit pour pousser le bilan dédié —
/// exactement le montage des lots TCF (`from=tcfLot`) et civiques.
///
/// **Seul le `skillId` part** : l'épreuve, le palier et le nombre de questions
/// sont dérivés serveur de la compétence. Ne jamais y ajouter un
/// `questionType` ou une `difficulty` « pour aider ».
///
/// [masteryBefore] n'est **pas** une donnée de démarrage : c'est l'état que le
/// Plan affichait au moment du lancement, repassé au bilan pour qu'il puisse
/// dire « avant → après » sans le deviner. Absent, le bilan n'affiche que
/// l'après.
Future<void> startTargetedSeries(
  BuildContext context,
  WidgetRef ref, {
  required String skillId,
  SkillMasteryState? masteryBefore,
}) async {
  ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
  try {
    final attempt =
        await ref.read(attemptsRepositoryProvider).startComprehensionSeries(
              skillId,
            );
    if (!context.mounted) return;
    final runner = AppRoutes.runner.replaceFirst(':attemptId', attempt.id);
    final before = masteryBefore == null ? '' : '&avant=${masteryBefore.wire}';
    context.push('$runner?from=planSerie&skillId=$skillId$before');
  } catch (error) {
    if (!context.mounted) return;
    // 403 = verrou freemium appliqué par le backend ; le reste est un message.
    // La règle vit dans `start_failure.dart`, jamais recopiée ici.
    showPaywallOrError(context, error);
  }
}

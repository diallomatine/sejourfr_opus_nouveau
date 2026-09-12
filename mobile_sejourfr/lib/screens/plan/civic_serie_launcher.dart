import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/repositories.dart';
import '../../core/models/billing_models.dart';
import '../../core/models/civic_plan_models.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/start_failure.dart';
import '../../core/widgets/paywall_context.dart';
import '../../core/widgets/paywall_sheet.dart';
import 'learning_plan_provider.dart';

/// **Où mène « travailler cette cible » côté civique**, en un seul endroit.
///
/// ⚠️ Extrait à sa **deuxième** surface : le Plan civique et l'écran Réviser
/// ouvrent la même série sur la même cible. Deux copies auraient fini par
/// oublier l'une des trois choses qui comptent ici — le verrou, le signal
/// d'avancement, ou le 403.
///
/// 🛑 Le **403** est un refus attendu — le verrou du serveur et le `locked`
/// servi sont la même règle — et il ouvre l'offre, jamais un message d'erreur
/// technique ([showPaywallOrError]).
Future<void> startCivicSerie(
  BuildContext context,
  WidgetRef ref,
  CivicPlanCible cible,
) async {
  if (cible.locked) {
    await openCivicOffer(context);
    return;
  }
  try {
    final attempt =
        await ref.read(civicPlanRepositoryProvider).serie(cible.id, cible.grain);
    if (!context.mounted) return;
    // La série déplace la cible dans la boîte Leitner : le plan lu après elle
    // doit être recalculé.
    ref.read(learningPlanRevisionProvider.notifier).state++;
    context.push(AppRoutes.runner.replaceFirst(':attemptId', attempt.id));
  } catch (e) {
    if (!context.mounted) return;
    showPaywallOrError(context, e);
  }
}

/// **La seule porte d'achat du civique** : l'écran d'offre, qui porte les vrais
/// passes et leurs prix du store.
Future<void> openCivicOffer(BuildContext context) => showPaywallSheet(
      context,
      initialTarget: PlanModuleTarget.civique,
      origin: PaywallOrigin.plan,
    );

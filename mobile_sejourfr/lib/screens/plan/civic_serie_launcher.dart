import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics_events.dart';
import '../../core/api/repositories.dart';
import '../../core/models/civic_plan_models.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/start_failure.dart';
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
/// 🛑 [onVerrou] — **la porte de déblocage de l'appelant**, quand il en a une.
/// Depuis le Plan, tout geste d'achat passe par l'écran de transition (A145) ;
/// ailleurs, le paywall direct reste le comportement. ⚠️ Ne vaut que pour un
/// `locked` **servi** : un 403 reste un refus, et il ouvre l'offre.
Future<void> startCivicSerie(
  BuildContext context,
  WidgetRef ref,
  CivicPlanCible cible, {
  VoidCallback? onVerrou,
  AnalyticsCtaLocation? ctaLocation,
  String? journeyId,
}) async {
  if (cible.locked) {
    if (onVerrou != null) {
      onVerrou();
      return;
    }
    await openCivicOffer(context, ctaLocation: ctaLocation, journeyId: journeyId);
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
    showPaywallOrError(
      context,
      e,
      ctaLocation: ctaLocation,
      journeyId: journeyId,
    );
  }
}

/// **Ouvrir la série d'une UNITÉ OFFICIELLE** — l'action d'une étape du cycle
/// civique (D-48, P8.7).
///
/// 🛑 **Un seul lanceur pour un seul geste.** Le plan dérivé a le sien
/// ([startCivicSerie], sur une **cible**) ; celui-ci porte le grain du
/// **cycle**, une **unité de l'arrêté**. Deux grains, deux routes — mais **un
/// seul endroit par grain**, pour qu'une même unité ne s'ouvre jamais de deux
/// façons.
///
/// 🛑 Le **403** n'est pas une panne : c'est le verrou freemium que le serveur
/// oppose (D-33), et il ouvre l'offre — jamais un message technique.
Future<void> startCivicUniteSerie(
  BuildContext context,
  WidgetRef ref,
  String uniteCode, {
  AnalyticsCtaLocation? ctaLocation,
  String? journeyId,
}) async {
  try {
    final attempt =
        await ref.read(civicPlanRepositoryProvider).serieSurUnite(uniteCode);
    if (!context.mounted) return;
    // La série déplace l'unité dans le cycle ET la cible dans la boîte Leitner :
    // les deux lectures se rafraîchissent ensemble, jamais l'une sans l'autre.
    signalerMesureEcrite(ref);
    context.push(AppRoutes.runner.replaceFirst(':attemptId', attempt.id));
  } catch (e) {
    if (!context.mounted) return;
    showPaywallOrError(
      context,
      e,
      ctaLocation: ctaLocation,
      journeyId: journeyId,
    );
  }
}

/// **La seule porte d'achat du civique** : l'écran d'offre, qui porte les vrais
/// passes et leurs prix du store.
///
/// [ctaLocation] / [journeyId] : `LOCKED_PLAN` + le parcours quand le geste
/// part du Plan civique (Q12) ; absents depuis « Réviser ».
Future<void> openCivicOffer(
  BuildContext context, {
  AnalyticsCtaLocation? ctaLocation,
  String? journeyId,
}) =>
    showPaywallSheet(context, ctaLocation: ctaLocation, journeyId: journeyId);

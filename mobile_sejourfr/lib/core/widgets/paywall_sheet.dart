import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics.dart';
import '../models/billing_models.dart';
import 'paywall_context.dart';
import '../../screens/paywall/paywall_screen.dart';

/// Pousse l'écran paywall plein écran (IAP natif Apple/Google).
///
/// Avant le lot 4d, ce helper ouvrait un bottom sheet qui redirigeait vers
/// le web pour le paiement. Depuis le lot 4d, le paiement se fait par IAP
/// natif (obligatoire d'après les guidelines Apple/Google quand on vend du
/// contenu digital), donc on push directement l'écran paywall avec son
/// toggle de périodicité.
///
/// [initialTarget] permet de focus un module spécifique (ex: INTÉGRAL si le
/// paywall pop sur une feature TCF). Si null, on montre les deux cards.
/// Renvoie un `Future` qui se complète au pop du paywall — utile pour
/// rafraîchir un écran (ex: « Mon accès ») au retour. Les appelants qui
/// n'en ont pas besoin peuvent ignorer le retour.
///
/// **Mesure — [ref] + [ctaLocation] vont ensemble, et seulement sur un vrai
/// clic.** `PREMIUM_CTA_CLICKED` compte un **geste du candidat** sur un appel
/// à l'abonnement, à l'endroit où il l'a touché. Les ouvertures **subies** —
/// un 403 du serveur relayé par `showPaywallOrError`, un abonnement expiré en
/// cours de session — n'en passent aucun : ce n'est pas un clic, et le compter
/// gonflerait l'étape du funnel avec des refus techniques. L'affichage de
/// l'écran, lui, est mesuré à l'arrivée (`PAYWALL_VIEWED` / `PRICING_VIEWED`),
/// donc rien n'est perdu.
Future<void> showPaywallSheet(
  BuildContext context, {
  PlanModuleTarget? initialTarget,
  WidgetRef? ref,
  AnalyticsCtaLocation? ctaLocation,
  PaywallOrigin origin = PaywallOrigin.ailleurs,
}) {
  if (ref != null && ctaLocation != null) {
    ref.read(analyticsServiceProvider).track(
          AnalyticsEvent.premiumCtaClicked,
          ctaLocation: ctaLocation,
        );
  }
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          PaywallScreen(initialTarget: initialTarget, origin: origin),
      fullscreenDialog: true,
    ),
  );
}

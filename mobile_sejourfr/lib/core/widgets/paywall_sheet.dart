import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics.dart';
import '../../screens/paywall/paywall_screen.dart';

/// Pousse l'écran paywall plein écran (IAP natif Apple/Google).
///
/// Avant le lot 4d, ce helper ouvrait un bottom sheet qui redirigeait vers
/// le web pour le paiement. Depuis le lot 4d, le paiement se fait par IAP
/// natif (obligatoire d'après les guidelines Apple/Google quand on vend du
/// contenu digital), donc on push directement l'écran paywall avec son
/// toggle de périodicité.
///
/// 🛑 **Aucun module à mettre en avant** : l'ordre des cartes est FIXE
/// (`kPassModulesInOrder`, Intégral d'abord — demande du propriétaire,
/// 2026-09-20), et les deux sont toujours affichées. L'ancien `initialTarget`
/// ne faisait plus qu'ordonner : il est parti avec la règle qu'il portait.
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
///
/// **Attribution de l'achat (Q12) — [ctaLocation] + [journeyId] suivent
/// l'écran jusqu'à l'achat**, qu'il y ait eu clic mesuré ou non : ils forment
/// l'intention d'achat créée avant la feuille Apple / Google. `LOCKED_PLAN`
/// est le CTA « du Plan » ; avec le `journeyId` du parcours affiché, c'est ce
/// qui permet au serveur de rattacher l'achat au tunnel. 🛑 Sans CTA connu,
/// **aucune intention** n'est créée : l'achat sera `UNKNOWN` côté serveur —
/// un `OTHER` fabriqué rangerait à tort un achat du Plan en `OTHER_CTA`
/// (« inconnu plutôt que faux »). Un geste réellement connu passe sa valeur.
///
/// 🛑 **[ctaLocation] est REQUIS** (contrôle F, 2026-09-25) : chaque appel
/// choisit, un `null` explicite dit « origine inconnue ». Un défaut aurait
/// laissé des offres partir sans CTA — ou, côté web, avec un `OTHER` fabriqué.
Future<void> showPaywallSheet(
  BuildContext context, {
  WidgetRef? ref,
  required AnalyticsCtaLocation? ctaLocation,
  String? journeyId,
}) {
  if (ref != null && ctaLocation != null) {
    ref.read(analyticsServiceProvider).track(
          AnalyticsEvent.premiumCtaClicked,
          ctaLocation: ctaLocation,
        );
  }
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => PaywallScreen(
        ctaLocation: ctaLocation,
        journeyId: journeyId,
      ),
      fullscreenDialog: true,
    ),
  );
}

import 'package:flutter/material.dart';

import '../models/billing_models.dart';
import '../../screens/paywall/paywall_screen.dart';

/// Nombre de questions en mode démo (sans abonnement) — partagé entre les
/// différents écrans qui démarrent un attempt d'entraînement.
const int kDemoBatchSize = 20;

/// Nombre de questions par session premium.
const int kInitialBatchSize = 30;

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
void showPaywallSheet(BuildContext context, {PlanModuleTarget? initialTarget}) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => PaywallScreen(initialTarget: initialTarget),
      fullscreenDialog: true,
    ),
  );
}

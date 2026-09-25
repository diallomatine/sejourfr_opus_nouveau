import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme/app_theme.dart';
import '../analytics/analytics_events.dart';
import '../widgets/paywall_sheet.dart';

/// Réaction attendue à l'échec du démarrage d'un attempt (série, examen blanc
/// QCM, session d'examen EE/EO).
enum StartFailure {
  /// Verrou freemium appliqué par le backend (403) → on montre l'offre.
  paywall,

  /// Tout le reste (validation, réseau, serveur) → message lisible.
  message,
}

/// Classifie l'erreur d'un démarrage d'attempt. Le backend applique lui-même
/// le paywall des examens blancs : un écran dont le statut premium en cache
/// est périmé (abonnement expiré en cours de session, refresh raté) reçoit un
/// 403 là où son UI croyait le slot ouvert. Ce 403 est un refus **attendu**,
/// pas une panne — il ne doit jamais s'afficher en erreur technique.
StartFailure classifyStartFailure(Object error) =>
    ApiClient.toApiException(error).isForbidden
        ? StartFailure.paywall
        : StartFailure.message;

/// Applique [classifyStartFailure] : ouvre le paywall sur un 403, sinon
/// affiche le message du backend en SnackBar. [onForbidden] est exécuté juste
/// avant l'ouverture du paywall (ex. fermer le briefing pour ne pas empiler
/// deux feuilles). Retourne `true` si le paywall a été ouvert.
///
/// [ctaLocation] / [journeyId] : l'origine de l'achat qui pourrait partir de
/// l'offre ouverte (Q12). 🛑 **Requis** (contrôle F) : hors Plan, le CTA que
/// l'écran passe déjà sur son verrou avant démarrage (`MOCK_EXAM`, `OTHER`…) ;
/// écran ouvert depuis le Plan (marqueur de route explicite), `LOCKED_PLAN` +
/// le parcours. `null` explicite = origine inconnue : **aucune intention**
/// n'est créée et l'achat sera `UNKNOWN` — jamais un `OTHER` fabriqué.
bool showPaywallOrError(
  BuildContext context,
  Object error, {
  VoidCallback? onForbidden,
  required AnalyticsCtaLocation? ctaLocation,
  String? journeyId,
}) {
  if (classifyStartFailure(error) == StartFailure.paywall) {
    onForbidden?.call();
    showPaywallSheet(context, ctaLocation: ctaLocation, journeyId: journeyId);
    return true;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(ApiClient.toApiException(error).message),
      backgroundColor: AppColors.red,
    ),
  );
  return false;
}

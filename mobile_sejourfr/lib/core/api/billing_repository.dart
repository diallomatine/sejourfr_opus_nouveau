import 'package:dio/dio.dart';

import '../models/billing_models.dart';
import 'api_client.dart';

/// Repository des endpoints `/api/billing/*`.
///
/// - `listPlans()` : public, retourne la liste des Plans actifs (lus depuis
///   `plans` en DB).
/// - `getSubscriptionStatus()` : authentifié, statut Premium agrégé toutes
///   sources (Stripe + Apple + Google). L'app le lit au boot et après chaque
///   verify-receipt pour mettre à jour `AuthUser.hasCivique/hasTcf`.
/// - `verifyReceipt()` : authentifié, envoie un reçu IAP (Apple JWS ou Google
///   purchaseToken). Le backend re-valide côté store puis renvoie le statut
///   Premium mis à jour.
class BillingRepository {
  BillingRepository(this._client);

  final ApiClient _client;

  Future<List<PlanPublicResponse>> listPlans() async {
    final Response res = await _client.dio.get('/api/billing/plans');
    final list = res.data as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(PlanPublicResponse.fromJson)
        .toList(growable: false);
  }

  Future<SubscriptionStatusResponse> getSubscriptionStatus() async {
    final Response res = await _client.dio.get('/api/billing/subscription-status');
    return SubscriptionStatusResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SubscriptionStatusResponse> verifyReceipt(VerifyReceiptRequest req) async {
    final Response res = await _client.dio.post(
      '/api/billing/verify-receipt',
      data: req.toJson(),
    );
    return SubscriptionStatusResponse.fromJson(res.data as Map<String, dynamic>);
  }

  /// Résilie l'abonnement Premium en cours. Le backend route selon la source :
  /// - Stripe : annulation à la fin de période, Premium reste ouvert jusqu'à
  ///   `endsAt` puis bascule EXPIRED (réponse `action=DONE`).
  /// - Apple/Google : pas d'annulation serveur possible, réponse
  ///   `action=REDIRECT` avec l'URL de gestion d'abonnement du store. C'est
  ///   le webhook du store qui mettra à jour le statut quand / si l'user
  ///   confirme.
  Future<CancelSubscriptionResponse> cancel() async {
    final Response res = await _client.dio.post('/api/billing/cancel');
    return CancelSubscriptionResponse.fromJson(res.data as Map<String, dynamic>);
  }
}

import 'package:dio/dio.dart';

import 'api_client.dart';

/// Les deux étapes du funnel d'acquisition que **seule l'application** peut
/// constater : l'écran Premium affiché, et le clic qui engage l'achat.
///
/// 🛑 **`CHECKOUT_STARTED` n'est pas ici et ne doit jamais l'être** : le
/// serveur le pose lui-même après création réelle du paiement, et le refuse en
/// **422** s'il vient d'un client — venant d'un client ce serait une intention,
/// pas un fait.
///
/// Tout le reste du funnel (compte créé, diagnostic commencé/terminé, paiement)
/// se déduit serveur des vraies tables : il n'y a rien à instrumenter ici.
enum FunnelEvent {
  /// Un écran Premium a été **affiché**.
  paywallViewed('PAYWALL_VIEWED'),

  /// Un CTA qui **engage l'achat** a été touché — jamais un simple lien de
  /// navigation vers l'offre.
  subscribeClicked('SUBSCRIBE_CLICKED');

  const FunnelEvent(this.wire);

  final String wire;
}

/// `POST /api/me/funnel-events` — **authentifié**, réponse 204, idempotent côté
/// serveur (première occurrence par compte).
class FunnelRepository {
  FunnelRepository(this._client);

  final ApiClient _client;

  Future<void> record(FunnelEvent event) async {
    await _client.dio.post<void>(
      '/api/me/funnel-events',
      data: {'event': event.wire},
      // Une étape de funnel ne doit jamais déclencher la déconnexion globale :
      // c'est une mesure, pas un parcours.
      options: Options(extra: const {'skipRefresh': true}),
    );
  }
}

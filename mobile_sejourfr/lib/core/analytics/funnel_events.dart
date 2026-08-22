import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/funnel_repository.dart';
import '../api/repositories.dart';
import '../auth/auth_controller.dart';

export '../api/funnel_repository.dart' show FunnelEvent;

/// Miroir mobile de `web_sejoufr/lib/funnel-events.ts`.
///
/// Trois règles, identiques au web :
///
/// - **rien n'est écrit sur l'appareil** : la déduplication ci-dessous vit en
///   mémoire et meurt avec le processus ; le serveur, lui, est idempotent
///   (première occurrence par compte), donc un doublon ne coûte rien ;
/// - **best-effort, jamais bloquant** : aucune erreur remontée, aucun état
///   d'attente, un événement perdu est sans conséquence ;
/// - **rien n'est émis pour un visiteur anonyme** : l'endpoint est
///   authentifié, un appel sans jeton serait un 401 garanti. On regarde donc
///   l'état d'authentification avant d'appeler.
final _sent = <FunnelEvent>{};

void _post(WidgetRef ref, FunnelEvent event) {
  if (ref.read(authControllerProvider) is! AuthAuthenticated) return;
  unawaited(
    ref.read(funnelRepositoryProvider).record(event).catchError((_) {
      // Une étape de funnel perdue ne doit jamais casser un parcours d'achat.
    }),
  );
}

/// Écran Premium réellement affiché. Une fois par lancement : l'écran peut se
/// reconstruire (changement d'onglet, retour de l'arrière-plan) sans que la
/// mesure se dédouble.
void trackPaywallViewed(WidgetRef ref) {
  if (!_sent.add(FunnelEvent.paywallViewed)) return;
  _post(ref, FunnelEvent.paywallViewed);
}

/// Clic sur un CTA qui **engage l'achat** — l'ouverture du paiement natif du
/// store. Un lien de navigation vers l'écran d'offre n'en est pas un : celui-là
/// est mesuré à l'arrivée par [trackPaywallViewed].
void trackSubscribeClicked(WidgetRef ref) {
  _post(ref, FunnelEvent.subscribeClicked);
}

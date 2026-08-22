import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/analytics_repository.dart';
import '../api/repositories.dart';
import 'analytics_events.dart';
import 'analytics_identity.dart';
import 'traffic_source.dart';

export 'analytics_events.dart';

/// **Le seul point d'émission analytics de l'application.**
///
/// Trois règles, dans le prolongement de ce que le web tient déjà :
///
/// - **best-effort, jamais bloquant** : aucune erreur n'est remontée, aucun
///   état d'attente n'est affiché, un événement perdu est sans conséquence ;
/// - **rien qui identifie une personne** ne part d'ici : deux UUID anonymes,
///   un nom d'événement de l'allowlist, et des propriétés dont les clés **et**
///   les valeurs sont bornées par des énumérations ;
/// - **une propriété hors allowlist est filtrée, pas envoyée** : le serveur
///   refuserait l'événement entier en 400, on perdrait la mesure au lieu de la
///   dégrader.
class AnalyticsService {
  AnalyticsService({
    required AnalyticsRepository repository,
    AnalyticsIdentity? identity,
  })  : _repository = repository,
        _identity = identity ?? AnalyticsIdentity();

  final AnalyticsRepository _repository;
  final AnalyticsIdentity _identity;

  /// Événements à n'émettre qu'une fois par lancement (affichage d'écran).
  /// Vit en mémoire : rien de plus n'est écrit sur l'appareil pour ça.
  final Set<AnalyticsEvent> _once = <AnalyticsEvent>{};

  /// Émet un événement. **Ne lève jamais et ne s'attend pas** : les appelants
  /// peuvent l'appeler sans `await`.
  void track(
    AnalyticsEvent event, {
    String? path,
    AnalyticsCtaLocation? ctaLocation,
    AnalyticsDiagnosticType? diagnosticType,
    AnalyticsRegistrationContext? registrationContext,
    String? planCode,
    String? screen,
    String? landingPath,
    String? landingVariant,
    // Valeur brute : `PlanExerciseKind.wire` produit déjà exactement les
    // libellés de l'allowlist serveur (MICRO_TRAINING, REASSESSMENT, …), pas
    // besoin d'un second enum ici.
    String? exerciseKind,
    bool once = false,
  }) {
    if (once && !_once.add(event)) return;
    unawaited(_send(
      event,
      path: path,
      properties: {
        if (ctaLocation != null) 'ctaLocation': ctaLocation.wire,
        if (diagnosticType != null) 'diagnosticType': diagnosticType.wire,
        if (registrationContext != null)
          'registrationContext': registrationContext.wire,
        if (planCode != null) 'planCode': planCode,
        if (screen != null) 'screen': screen,
        if (landingPath != null) 'landingPath': landingPath,
        if (landingVariant != null) 'landingVariant': landingVariant,
        if (exerciseKind != null) 'exerciseKind': exerciseKind,
      },
    ));
  }

  Future<void> _send(
    AnalyticsEvent event, {
    String? path,
    required Map<String, String> properties,
  }) async {
    try {
      final allowed = kAnalyticsPropertyKeys[event] ?? const <String>{};
      final filtered = <String, String>{
        for (final entry in properties.entries)
          if (allowed.contains(entry.key)) entry.key: entry.value,
      };
      final ids = await _identity.resolve();
      await _repository.send(
        anonymousId: ids.anonymousId,
        sessionId: ids.sessionId,
        event: event.wire,
        path: path,
        properties: filtered,
        firstTouch: await _firstTouch(),
      );
    } catch (_) {
      // Une mesure d'audience ne casse jamais un écran.
    }
  }

  /// La première touche d'un visiteur — envoyée **une seule fois**, et
  /// seulement si on a réellement observé quelque chose. Aucune provenance
  /// connue ⇒ pas de bloc : le serveur rendra « inconnu », qui est vrai, plutôt
  /// que « direct », qui serait fabriqué.
  Future<Map<String, String>?> _firstTouch() async {
    final source = AnalyticsTrafficSource.current;
    if (source == null) return null;
    if (!await _identity.claimFirstTouch()) return null;
    return {'source': source.wire};
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(
    repository: ref.watch(analyticsRepositoryProvider),
  ),
);

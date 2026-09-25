import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/repositories.dart';
import '../models/diagnostic_run_models.dart';
import '../utils/submission_key.dart';
import 'analytics_events.dart';
import 'analytics_identity.dart';
import 'analytics_queue.dart';
import 'diagnostic_run_tracker.dart';
import 'traffic_source.dart';

export 'analytics_events.dart';

/// **Le seul point d'émission analytics de l'application.**
///
/// Trois règles, dans le prolongement de ce que le web tient déjà :
///
/// - **best-effort, jamais bloquant** : aucune erreur n'est remontée, aucun
///   état d'attente n'est affiché, un événement perdu est sans conséquence ;
/// - **rien qui identifie une personne** ne part d'ici : deux UUID anonymes,
///   un nom d'événement de l'allowlist, des propriétés dont les clés **et**
///   les valeurs sont bornées, et des identifiants de contexte (run, parcours)
///   — 🛑 **jamais le `claimToken`** ;
/// - **une propriété ou un contexte hors allowlist est filtré, pas envoyé** :
///   le serveur rejetterait l'événement, on perdrait la mesure au lieu de la
///   dégrader.
///
/// Depuis le lot 3 du chantier « Suivi », l'événement n'est plus posté : il
/// est **mis en file** ([AnalyticsQueue]) avec son `eventId` et son heure de
/// création, puis envoyé en lot.
class AnalyticsService {
  AnalyticsService({
    required AnalyticsQueue queue,
    required AnalyticsIdentity identity,
    required DiagnosticRunTracker runs,
  })  : _queue = queue,
        _identity = identity,
        _runs = runs;

  final AnalyticsQueue _queue;
  final AnalyticsIdentity _identity;
  final DiagnosticRunTracker _runs;

  /// Événements à n'émettre qu'une fois par lancement (affichage d'écran).
  /// Vit en mémoire : rien de plus n'est écrit sur l'appareil pour ça.
  final Set<AnalyticsEvent> _once = <AnalyticsEvent>{};

  /// Émet un événement. **Ne lève jamais et ne s'attend pas** : les appelants
  /// peuvent l'appeler sans `await`.
  ///
  /// [diagnosticRun] désigne la run à attacher : elle est lue **sur
  /// l'appareil** (`DiagnosticRunTracker`), et seulement si elle appartient au
  /// compte connecté. [journeyId] est le `journey.id` servi du Plan affiché.
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
    // Valeur brute : `EpreuveType.wire` produit deja exactement les libelles de
    // l'allowlist serveur (TCF_EE, TCF_EO, …), pas besoin d'un second enum ici.
    String? epreuve,
    // Compteurs du rideau : une TAILLE d'affichage, jamais une donnee du
    // candidat. Le serveur les borne a quatre chiffres.
    int? visibleCount,
    int? totalCount,
    // Prix AFFICHÉ en centimes (six chiffres au plus) — jamais un encaissement.
    int? displayedPriceCents,
    DiagnosticRunType? diagnosticRun,
    String? journeyId,
    bool once = false,
  }) {
    if (once && !_once.add(event)) return;
    // L'identité et l'heure de l'événement sont figées MAINTENANT, pas à
    // l'envoi : un renvoi après coupure reste le même événement.
    final eventId = SubmissionKeys.newKey();
    final occurredAt = DateTime.now().toUtc();
    unawaited(_enqueue(
      event,
      eventId: eventId,
      occurredAt: occurredAt,
      path: path,
      diagnosticRun: diagnosticRun,
      journeyId: journeyId,
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
        if (epreuve != null) 'epreuve': epreuve,
        if (visibleCount != null) 'visibleCount': '$visibleCount',
        if (totalCount != null) 'totalCount': '$totalCount',
        if (displayedPriceCents != null && displayedPriceCents > 0)
          'displayedPriceCents': '$displayedPriceCents',
      },
    ));
  }

  Future<void> _enqueue(
    AnalyticsEvent event, {
    required String eventId,
    required DateTime occurredAt,
    required Map<String, String> properties,
    String? path,
    DiagnosticRunType? diagnosticRun,
    String? journeyId,
  }) async {
    try {
      final allowed = kAnalyticsPropertyKeys[event] ?? const <String>{};
      final context = kAnalyticsEventContext[event];
      final runId = context != null && context.run && diagnosticRun != null
          ? await _runs.runIdFor(diagnosticRun)
          : null;
      final ids = await _identity.resolve();
      await _queue.enqueue(QueuedAnalyticsEvent(
        eventId: eventId,
        event: event.wire,
        occurredAt: occurredAt,
        anonymousId: ids.anonymousId,
        sessionId: ids.sessionId,
        path: path,
        properties: {
          for (final entry in properties.entries)
            if (allowed.contains(entry.key)) entry.key: entry.value,
        },
        diagnosticRunId: runId,
        diagnosticType: runId == null ? null : diagnosticRun?.wire,
        journeyId: context != null && context.journey ? journeyId : null,
        firstTouch: await _firstTouch(),
      ));
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

/// La file, **vivante toute la session** : elle est démarrée (lancement,
/// reprise, minuterie) dès sa première lecture — `SejourFrApp` l'observe.
final Provider<AnalyticsQueue> analyticsQueueProvider =
    Provider<AnalyticsQueue>((ref) {
  final queue = AnalyticsQueue(
    repository: ref.watch(analyticsRepositoryProvider),
  )..start();
  ref.onDispose(queue.dispose);
  return queue;
});

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(
    queue: ref.watch(analyticsQueueProvider),
    identity: ref.watch(analyticsIdentityProvider),
    runs: ref.watch(diagnosticRunTrackerProvider),
  ),
);

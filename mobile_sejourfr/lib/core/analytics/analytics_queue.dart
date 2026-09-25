import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/analytics_repository.dart';
import '../api/api_client.dart';
import 'client_context.dart';

/// Un événement **tel qu'il a été créé** : son identifiant, son heure et ses
/// identifiants de visite sont figés à la création, jamais à l'envoi — c'est
/// ce qui rend un renvoi après coupure idempotent (`eventId`) et exact dans le
/// temps (`occurredAt`).
@immutable
class QueuedAnalyticsEvent {
  const QueuedAnalyticsEvent({
    required this.eventId,
    required this.event,
    required this.occurredAt,
    required this.anonymousId,
    required this.sessionId,
    this.path,
    this.properties = const {},
    this.diagnosticRunId,
    this.diagnosticType,
    this.journeyId,
    this.firstTouch,
    this.refusals = 0,
  });

  final String eventId;
  final String event;
  final DateTime occurredAt;
  final String anonymousId;
  final String sessionId;
  final String? path;
  final Map<String, String> properties;

  /// Contexte en colonnes (lot 1b) : la run et son type, le parcours. 🛑 Jamais
  /// le `claimToken`.
  final String? diagnosticRunId;
  final String? diagnosticType;
  final String? journeyId;

  /// La première touche du visiteur, portée par l'événement qui l'a réclamée.
  final Map<String, String>? firstTouch;

  /// Nombre de lots refusés en bloc (400) qui contenaient cet événement.
  final int refusals;

  QueuedAnalyticsEvent withRefusal() => QueuedAnalyticsEvent(
        eventId: eventId,
        event: event,
        occurredAt: occurredAt,
        anonymousId: anonymousId,
        sessionId: sessionId,
        path: path,
        properties: properties,
        diagnosticRunId: diagnosticRunId,
        diagnosticType: diagnosticType,
        journeyId: journeyId,
        firstTouch: firstTouch,
        refusals: refusals + 1,
      );

  /// La forme d'un événement dans le lot.
  Map<String, Object?> toWire() => {
        'eventId': eventId,
        'event': event,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        if (path != null) 'path': path,
        if (properties.isNotEmpty) 'properties': properties,
        if (diagnosticRunId != null) 'diagnosticRunId': diagnosticRunId,
        if (diagnosticRunId != null && diagnosticType != null)
          'diagnosticType': diagnosticType,
        if (journeyId != null) 'journeyId': journeyId,
      };

  Map<String, Object?> toJson() => {
        'eventId': eventId,
        'event': event,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        'anonymousId': anonymousId,
        'sessionId': sessionId,
        'path': path,
        'properties': properties,
        'diagnosticRunId': diagnosticRunId,
        'diagnosticType': diagnosticType,
        'journeyId': journeyId,
        'firstTouch': firstTouch,
        'refusals': refusals,
      };

  static QueuedAnalyticsEvent? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final eventId = json['eventId'] as String?;
    final event = json['event'] as String?;
    final occurredAt = DateTime.tryParse(json['occurredAt'] as String? ?? '');
    final anonymousId = json['anonymousId'] as String?;
    final sessionId = json['sessionId'] as String?;
    if (eventId == null ||
        event == null ||
        occurredAt == null ||
        anonymousId == null ||
        sessionId == null) {
      return null;
    }
    Map<String, String>? strings(Object? raw) => raw is Map<String, dynamic>
        ? {
            for (final e in raw.entries)
              if (e.value is String) e.key: e.value as String,
          }
        : null;
    return QueuedAnalyticsEvent(
      eventId: eventId,
      event: event,
      occurredAt: occurredAt,
      anonymousId: anonymousId,
      sessionId: sessionId,
      path: json['path'] as String?,
      properties: strings(json['properties']) ?? const {},
      diagnosticRunId: json['diagnosticRunId'] as String?,
      diagnosticType: json['diagnosticType'] as String?,
      journeyId: json['journeyId'] as String?,
      firstTouch: strings(json['firstTouch']),
      refusals: (json['refusals'] as num?)?.toInt() ?? 0,
    );
  }
}

/// **La file d'événements d'analytics** — persistante, bornée, envoyée en lot
/// (arbitrages Q15 et Q17 du chantier « Suivi »).
///
/// - **Persistante** en `SharedPreferences` (pas de base locale, Q15) : un
///   événement créé hors ligne, ou juste avant un kill de l'app, part au
///   lancement suivant.
/// - **Bornée** : [maxEvents] au plus (les plus anciens sautent), et rien de
///   plus vieux que [maxAge] — le serveur refuserait au-delà de 168 h.
/// - **Envoyée** au retour réseau (toute réponse du serveur, `onReachable`), à
///   la reprise de l'app, périodiquement, et peu après chaque ajout ; par lots
///   de [batchSize] au plus, regroupés par `(anonymousId, sessionId)`.
/// - **Purgée seulement après un 202**, rejets individuels compris (renvoyés,
///   ils seraient refusés encore). Réseau, 429, 5xx : on garde et on réessaie
///   avec un délai croissant. Un lot refusé en bloc (400) est réessayé
///   [maxRefusals] fois, puis abandonné : ce refus-là ne se répare pas seul.
///
/// Best-effort de bout en bout : rien ici ne lève vers un écran.
class AnalyticsQueue {
  AnalyticsQueue({required AnalyticsRepository repository})
      : _repository = repository;

  final AnalyticsRepository _repository;

  static const String _key = 'sejourfr.analytics.queue';
  static const int maxEvents = 200;
  static const int batchSize = 50;
  static const int maxRefusals = 3;

  /// Marge sous les 168 h du serveur : un événement plus vieux serait rejeté.
  static const Duration maxAge = Duration(hours: 160);

  static const Duration _debounce = Duration(seconds: 2);
  static const Duration _period = Duration(seconds: 60);
  static const Duration _backoffBase = Duration(seconds: 5);
  static const Duration _backoffMax = Duration(minutes: 5);

  List<QueuedAnalyticsEvent>? _events;
  Future<void>? _flushing;
  Timer? _debounceTimer;
  Timer? _periodic;
  Timer? _retryTimer;
  AppLifecycleListener? _lifecycle;
  int _failures = 0;
  DateTime? _nextAttemptAt;
  bool _lastFailureWasNetwork = false;

  /// Arme les déclencheurs d'envoi et vide ce qui reste du lancement précédent.
  void start() {
    _lifecycle ??= AppLifecycleListener(
      onResume: () => unawaited(flush(force: true)),
      // L'app passe en arrière-plan : dernière chance avant un éventuel kill.
      onHide: () => unawaited(flush()),
    );
    _periodic ??= Timer.periodic(_period, (_) => unawaited(flush()));
    unawaited(flush(force: true));
  }

  void dispose() {
    _lifecycle?.dispose();
    _periodic?.cancel();
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
  }

  /// Ajoute un événement et programme un envoi. Ne lève jamais.
  Future<void> enqueue(QueuedAnalyticsEvent event) async {
    try {
      final events = await _load();
      events.add(event);
      _trim(events);
      await _persist(events);
    } catch (_) {
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () => unawaited(flush()));
  }

  /// Le serveur vient de répondre à une autre requête : si le dernier envoi
  /// avait échoué faute de réseau, on n'attend pas la fin du délai.
  void notifyNetworkUp() {
    if (!_lastFailureWasNetwork || _flushing != null) return;
    _lastFailureWasNetwork = false;
    unawaited(flush(force: true));
  }

  /// Envoie tout ce qui peut l'être. Un seul envoi à la fois.
  Future<void> flush({bool force = false}) {
    if (_flushing != null) return _flushing!;
    final next = _nextAttemptAt;
    if (!force && next != null && DateTime.now().isBefore(next)) {
      return Future<void>.value();
    }
    return _flushing = _flush().whenComplete(() => _flushing = null);
  }

  Future<void> _flush() async {
    try {
      while (true) {
        final events = await _load();
        final before = events.length;
        _dropStale(events);
        if (events.length != before) await _persist(events);
        if (events.isEmpty) {
          _succeeded();
          return;
        }
        final batch = _nextBatch(events);
        final ok = await _send(batch);
        if (!ok) return;
      }
    } catch (_) {
      // Best-effort.
    }
  }

  /// Le plus ancien événement, et ceux de la même visite qui le suivent.
  List<QueuedAnalyticsEvent> _nextBatch(List<QueuedAnalyticsEvent> events) {
    final head = events.first;
    return events
        .where((e) =>
            e.anonymousId == head.anonymousId && e.sessionId == head.sessionId)
        .take(batchSize)
        .toList(growable: false);
  }

  /// `true` si la file a avancé (lot purgé), `false` pour arrêter là.
  Future<bool> _send(List<QueuedAnalyticsEvent> batch) async {
    final head = batch.first;
    final firstTouch = batch
        .map((e) => e.firstTouch)
        .firstWhere((t) => t != null && t.isNotEmpty, orElse: () => null);
    final platform = ClientContext.platform;
    final version = await ClientContext.appVersion();
    // `client` / `appVersion` ne servent au serveur que si les en-têtes
    // manquent : on les joint quand même, l'enveloppe se suffit à elle-même.
    final envelope = <String, Object?>{
      'anonymousId': head.anonymousId,
      'sessionId': head.sessionId,
      if (platform != null) 'client': platform,
      if (version != null) 'appVersion': version,
      if (firstTouch != null) 'firstTouch': firstTouch,
      'events': [for (final e in batch) e.toWire()],
    };
    final sent = {for (final e in batch) e.eventId};
    try {
      final report = await _repository.sendBatch(envelope);
      if (kDebugMode && report.rejected.isNotEmpty) {
        debugPrint('Analytics : ${report.rejected.length} événement(s) '
            'rejeté(s) — ${report.rejected.map((r) => r.reason).join(' | ')}');
      }
      await _remove(sent);
      return true;
    } catch (error) {
      final status = ApiClient.toApiException(error).statusCode;
      if (status == 0 || status == 429 || status >= 500 || status < 0) {
        _failed(network: status == 0 || status < 0);
        return false;
      }
      // Lot refusé en bloc : ce n'est pas une panne, rejouer à l'infini ne
      // réparerait rien. Quelques essais, puis on abandonne ces événements.
      await _refuse(sent);
      _failed(network: false);
      return false;
    }
  }

  void _succeeded() {
    _failures = 0;
    _nextAttemptAt = null;
    _lastFailureWasNetwork = false;
    _retryTimer?.cancel();
  }

  void _failed({required bool network}) {
    _failures++;
    _lastFailureWasNetwork = network;
    final factor = pow(2, min(_failures - 1, 10)).toInt();
    var delay = _backoffBase * factor;
    if (delay > _backoffMax) delay = _backoffMax;
    _nextAttemptAt = DateTime.now().add(delay);
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () => unawaited(flush()));
  }

  Future<void> _remove(Set<String> ids) async {
    final events = await _load();
    events.removeWhere((e) => ids.contains(e.eventId));
    await _persist(events);
  }

  Future<void> _refuse(Set<String> ids) async {
    final events = await _load();
    for (var i = 0; i < events.length; i++) {
      if (ids.contains(events[i].eventId)) events[i] = events[i].withRefusal();
    }
    events.removeWhere((e) => e.refusals >= maxRefusals);
    await _persist(events);
  }

  void _trim(List<QueuedAnalyticsEvent> events) {
    if (events.length > maxEvents) {
      events.removeRange(0, events.length - maxEvents);
    }
  }

  void _dropStale(List<QueuedAnalyticsEvent> events) {
    final limit = DateTime.now().subtract(maxAge);
    events.removeWhere((e) => e.occurredAt.isBefore(limit));
  }

  Future<List<QueuedAnalyticsEvent>> _load() async {
    final cached = _events;
    if (cached != null) return cached;
    final loaded = <QueuedAnalyticsEvent>[];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            final event = QueuedAnalyticsEvent.fromJson(item);
            if (event != null) loaded.add(event);
          }
        }
      }
    } catch (_) {
      // File illisible : on repart d'une file vide plutôt que de bloquer.
    }
    return _events ??= loaded;
  }

  Future<void> _persist(List<QueuedAnalyticsEvent> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (events.isEmpty) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(
          _key,
          jsonEncode([for (final e in events) e.toJson()]),
        );
      }
    } catch (_) {
      // La file reste en mémoire pour ce lancement.
    }
  }
}

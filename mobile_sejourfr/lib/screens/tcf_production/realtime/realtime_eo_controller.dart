import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/realtime_repository.dart';
import '../../../core/api/repositories.dart';
import '../../../core/models/production_models.dart';
import '../../../core/models/realtime_models.dart';
import '../../../core/realtime/gemini_live_client.dart';
import '../../../core/realtime/realtime_conduct.dart';
import '../../plan/learning_plan_provider.dart';
import 'realtime_finish.dart';

/// Arguments d'une session realtime. Sert aussi de clé de family Riverpod :
/// l'égalité porte sur [descriptor.sessionId] (stable pour une session donnée).
class RealtimeRunnerArgs {
  RealtimeRunnerArgs({
    required this.descriptor,
    required this.task,
    required this.attemptId,
    this.popOnDone = false,
  });

  final RealtimeSessionDescriptor descriptor;
  final ProductionTaskDto task;
  final String attemptId;

  /// True dans le parcours d'examen 3 tâches : à la clôture, l'écran REND la
  /// main (pop avec `true`) pour que le briefing enchaîne la tâche suivante, au
  /// lieu de naviguer vers le bilan standalone (cas entraînement isolé).
  final bool popOnDone;

  String get sessionId => descriptor.sessionId ?? '';

  @override
  bool operator ==(Object other) =>
      other is RealtimeRunnerArgs && other.sessionId == sessionId;

  @override
  int get hashCode => sessionId.hashCode;
}

enum RealtimePhase { connecting, welcoming, live, finishing, done, failed }

/// Un tour de dialogue affiché dans la transcription (une ligne complète).
class RealtimeLine {
  const RealtimeLine(this.speaker, this.text);
  final RealtimeSpeaker speaker;
  final String text;
}

class RealtimeEoState {
  const RealtimeEoState({
    required this.phase,
    required this.targetSec,
    this.elapsedSec = 0,
    this.examinerSpeaking = false,
    this.error,
    this.sessionsRemaining,
    this.transcript = const [],
    this.finishResult,
    this.retryingFinish = false,
    this.reconnecting = false,
    this.conductPhase = ConductPhase.live,
  });

  final RealtimePhase phase;
  final int targetSec;
  final int elapsedSec;
  final bool examinerSpeaking;
  final String? error;
  final int? sessionsRemaining;

  /// Le WebSocket est tombé et une reprise est en cours. La phase, le chrono et
  /// la transcription sont CONSERVÉS : l'écran affiche un bandeau discret, il
  /// ne repart pas de zéro et ne bloque rien.
  final bool reconnecting;

  /// Phase de fin de temps (le candidat finit sa phrase, l'examinateur conclut).
  final ConductPhase conductPhase;

  /// Issue de la clôture, renseignée uniquement en phase `done`. Remplace
  /// l'ancien booléen `evaluated`, qui valait `true` même quand l'appel de
  /// clôture avait échoué : un envoi raté était alors indistinguable d'un
  /// succès et la production du candidat disparaissait sans trace.
  final RealtimeFinishResult? finishResult;

  /// Une relance de la clôture est en vol (bouton « Réessayer l'envoi »).
  final bool retryingFinish;

  /// Dialogue candidat/examinateur, un élément par tour terminé (pour affichage
  /// à la demande — bouton « Voir ma transcription »).
  final List<RealtimeLine> transcript;

  int get remainingSec =>
      (targetSec - elapsedSec).clamp(0, targetSec).toInt();

  RealtimeEoState copyWith({
    RealtimePhase? phase,
    int? elapsedSec,
    bool? examinerSpeaking,
    String? error,
    int? sessionsRemaining,
    List<RealtimeLine>? transcript,
    RealtimeFinishResult? finishResult,
    bool? retryingFinish,
    bool? reconnecting,
    ConductPhase? conductPhase,
  }) {
    return RealtimeEoState(
      phase: phase ?? this.phase,
      targetSec: targetSec,
      elapsedSec: elapsedSec ?? this.elapsedSec,
      examinerSpeaking: examinerSpeaking ?? this.examinerSpeaking,
      error: error ?? this.error,
      sessionsRemaining: sessionsRemaining ?? this.sessionsRemaining,
      transcript: transcript ?? this.transcript,
      finishResult: finishResult ?? this.finishResult,
      retryingFinish: retryingFinish ?? this.retryingFinish,
      reconnecting: reconnecting ?? this.reconnecting,
      conductPhase: conductPhase ?? this.conductPhase,
    );
  }
}

/// Pilote une session EO temps réel : ouvre le client Gemini, relaie le
/// transcript dialogué au backend (batché), tient le minuteur, et clôture
/// (le backend crée la submission + lance la notation à la clôture).
class RealtimeEoController extends StateNotifier<RealtimeEoState> {
  RealtimeEoController(this._repo, this._args, {void Function()? onPlanChanged})
      : _onPlanChanged = onPlanChanged ?? _noop,
        super(RealtimeEoState(
          phase: RealtimePhase.connecting,
          targetSec: _args.descriptor.targetDurationSec ?? _defaultTargetSec,
        ));

  final RealtimeRepository _repo;
  final RealtimeRunnerArgs _args;

  /// La clôture crée la soumission côté serveur : le Plan et l'Accueil sont à
  /// relire. Pendant web : `realtimeApi.finishSession`.
  final void Function() _onPlanChanged;

  GeminiLiveClient? _client;
  Timer? _ticker;
  Timer? _flushTimer;
  bool _finishing = false;

  /// Conduite servie : fin de temps douce, relance sur silence, reprise. Toute
  /// la logique vit dans [ConductController] (`realtime_conduct.dart`), pure ;
  /// ce contrôleur ne fait que lui transmettre les faits et exécuter ses
  /// demandes.
  RealtimeConductConfig get _conduct => _args.descriptor.conduct;
  ConductController? _conductor;

  /// Repli de DERNIER RECOURS quand le backend n'envoie pas
  /// `targetDurationSec`. La valeur canonique est
  /// `production_tasks.duree_max_sec`, servie sur le descripteur — elle vaut
  /// 180 s (EO tâche 1) et 210 s (EO tâche 2), les deux seules tâches ouvertes
  /// au temps réel. On prend la plus COURTE : un repli ne doit jamais accorder
  /// plus de temps que la tâche réelle. Valeur commune web ⇄ mobile (le web
  /// repliait sur 210 s, le mobile sur 200 s).
  static const _defaultTargetSec = 180;

  /// Période de relais du transcript vers le backend. Valeur commune
  /// web ⇄ mobile (le mobile relayait toutes les 1500 ms, deux cadences pour un
  /// même artefact de notation).
  static const _transcriptRelayMs = 1200;

  /// Essais d'envoi d'un MÊME fragment de transcript. Le tour garde son
  /// `turnIndex` d'un essai à l'autre, donc le serveur ignore un doublon : le
  /// renvoi ne peut plus fabriquer de parole, ce qui l'interdisait avant.
  static const _transcriptMaxAttempts = 3;

  /// Attente entre deux essais d'un fragment (ms) : assez pour laisser passer
  /// une micro-coupure, assez court pour ne pas retarder la clôture, qui attend
  /// la chaîne d'envoi.
  static const _transcriptRetryDelayMs = 600;

  /// Tentatives de reprise pour UNE coupure : 3 essais espacés couvrent un
  /// tunnel court ou une bascule wifi→4G sans transformer une panne durable en
  /// boucle de reconnexion infinie.
  static const _resumeMaxAttempts = 3;

  /// Backoff entre deux tentatives de reprise (ms). Le premier essai part
  /// IMMÉDIATEMENT : la fenêtre de reprise du token est comptée, on ne l'entame
  /// pas en attendant que le candidat revienne devant son écran.
  static const _resumeBackoffMs = [0, 1000, 3000];

  /// Budget total d'une reprise (s). Au-delà on cesse de faire patienter le
  /// candidat devant un écran figé. Borné aussi par `connectWindowSec` : passé
  /// cette fenêtre le token de reprise ne peut plus ouvrir de connexion.
  static const _resumeBudgetSec = 15;

  final List<({RealtimeSpeaker speaker, String text, TurnTiming timing})>
      _pending = [];

  // Mesure (V090) : cause de fin déclarée à la clôture (la première posée
  // l'emporte, une relance de l'envoi la reprend telle quelle) et événements de
  // conduite accumulés pendant la session.
  RealtimeEndCause? _endCause;
  final List<RealtimeConductEvent> _conductEvents = [];

  // Comptage du relais de transcript, qui est best-effort : sans lui, un
  // fragment perdu rétrécissait silencieusement la production notée. Ce sont
  // ces trois compteurs qui rendent la perte DÉTECTABLE et permettent de
  // distinguer « le candidat s'est tu » de « sa parole ne nous est pas
  // parvenue » — deux messages opposés à ne jamais confondre.
  int _candidateTurnsSpoken = 0;
  int _candidateTurnsRelayed = 0;
  int _droppedTurns = 0;
  int? _sessionsRemaining;

  // --- État de REPRISE. Ce contrôleur en est le seul propriétaire : le client
  // WS remonte le handle et signale la chute, il ne décide rien. ---------------

  /// Numéro du prochain tour relayé (`0, 1, 2…`, strictement croissant sur la
  /// session). Attribué UNE SEULE FOIS par segment, à la construction du lot, et
  /// CONSERVÉ pendant les réessais : c'est lui qui rend l'envoi idempotent et
  /// protège le quota du candidat.
  int _turnIndex = 0;

  /// Dernier handle reçu du fournisseur, et dernier handle déjà transmis au
  /// serveur — pour ne le joindre au `POST /transcript` que s'il est plus récent.
  String? _resumptionHandle;
  String? _handleRelayed;

  late bool _resumable = _args.descriptor.resumable;
  late int? _resumptionsRemaining = _args.descriptor.resumptionsRemaining;
  late int? _connectWindowSec = _args.descriptor.connectWindowSec;
  bool _reconnecting = false;

  // Tous les envois de transcript passent par cette chaîne : l'ordre des lignes
  // est garanti côté backend, et `finish()` peut ATTENDRE que tout soit parti
  // (y compris un tick périodique encore en vol) avant `finishSession` — le
  // backend ignore silencieusement tout fragment arrivé après la clôture.
  Future<void> _sendChain = Future.value();

  String get attemptId => _args.attemptId;

  Future<void> start() async {
    final client = GeminiLiveClient(
      descriptor: _args.descriptor,
      onCandidateTranscript: (t, timing) =>
          _enqueue(RealtimeSpeaker.candidate, t, timing),
      onExaminerTranscript: (t, timing) =>
          _enqueue(RealtimeSpeaker.examiner, t, timing),
      onSpeakingChange: (speaking) {
        if (!mounted) return;
        state = state.copyWith(examinerSpeaking: speaking);
        _conductor?.examinerSpeakingChanged(speaking);
      },
      onCandidateVoice: (active) => _conductor?.candidateVoiceChanged(active),
      // L'examinateur a commencé (1er audio) ou garde-fou 8 s : fin de l'accueil,
      // le micro du candidat s'ouvre → on passe en conversation. C'est ICI que
      // le chrono de la tâche démarre : le temps ne compte QU'À partir du premier
      // mot de l'examinateur, jamais pendant la connexion/accueil.
      onListeningStart: () {
        if (mounted && state.phase == RealtimePhase.welcoming) {
          state = state.copyWith(phase: RealtimePhase.live);
        }
        _startTicker();
      },
      onResumptionHandle: (handle) {
        // Mémorisé ici, relayé gratuitement sur le prochain POST /transcript.
        _resumptionHandle = handle;
      },
      onError: (msg) => _failAndClose(msg, RealtimeEndCause.error),
      onConnectionLost: _onConnectionLost,
    );
    _client = client;
    _conductor = ConductController(
      conduct: _conduct,
      clock: const _RealClock(),
      actions: ConductActions(
        sendText: client.sendTextTurn,
        muteCandidate: client.muteInput,
        close: () => finish(cause: RealtimeEndCause.timeUp),
        recordEvent: _conductEvents.add,
        onPhaseChange: (phase) {
          if (mounted) state = state.copyWith(conductPhase: phase);
        },
      ),
      targetSec: state.targetSec,
      elapsedMs: client.elapsedMs,
      candidateEnergyNow: client.candidateEnergyNow,
    );
    try {
      await client.start();
      if (!mounted) return;
      // Phase d'accueil : micro coupé tant que l'examinateur n'a pas parlé. Le
      // chrono (_ticker) ne démarre QU'À la 1re parole de l'examinateur, dans
      // onListeningStart — pas ici. Le relais du transcript, lui, tourne dès la
      // connexion.
      state = state.copyWith(phase: RealtimePhase.welcoming);
      _flushTimer = Timer.periodic(
          const Duration(milliseconds: _transcriptRelayMs), (_) => _flush());
    } catch (e) {
      _failAndClose(e.toString(), RealtimeEndCause.error);
    }
  }

  /// Démarre (ou relance après une coupure) le décompte. `elapsedSec` n'est
  /// jamais remis à zéro : le chrono REPREND là où il s'était arrêté.
  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer t) {
    if (!mounted) return;
    final next = state.elapsedSec + 1;
    state = state.copyWith(elapsedSec: next);
    _conductor?.tick(state.targetSec - next);
    if (next >= state.targetSec &&
        (state.phase == RealtimePhase.live ||
            state.phase == RealtimePhase.welcoming)) {
      state = state.copyWith(phase: RealtimePhase.finishing);
      // La conduite prend la main : fin de temps douce (phrase du candidat,
      // puis `[FIN]`, puis clôture quand l'examinateur se tait).
      _ticker?.cancel();
      _conductor?.timeUp();
    }
  }

  // ---------------------------------------------------------------------------
  // Reprise après coupure du WebSocket
  // ---------------------------------------------------------------------------

  /// Le transport est tombé. Trois issues, dans cet ordre :
  ///   1. le temps est écoulé (ou la clôture est engagée) → on clôture, il n'y
  ///      a plus d'échange à reprendre ;
  ///   2. la reprise est armée et il reste des reprises → on la demande TOUT DE
  ///      SUITE (la fenêtre du token est comptée) ;
  ///   3. sinon → repli.
  ///
  /// 🛑 On ne rappelle JAMAIS `POST /sessions` ici : cela créerait une seconde
  /// session et débiterait un second slot de simulation au candidat.
  Future<void> _onConnectionLost() async {
    if (!mounted || _finishing || _reconnecting) return;
    final phase = state.phase;
    final resumablePhase = phase == RealtimePhase.connecting ||
        phase == RealtimePhase.welcoming ||
        phase == RealtimePhase.live;
    if (!resumablePhase) {
      finish(cause: RealtimeEndCause.timeUp);
      return;
    }
    if (!_resumable || (_resumptionsRemaining ?? 0) <= 0) {
      _giveUpRealtime();
      return;
    }
    _reconnecting = true;
    _conductor?.setSuspended(true);
    // Le chrono s'ARRÊTE pendant la coupure : le candidat ne doit pas perdre du
    // temps de parole à cause de notre réseau. Il ne repart pas de zéro non plus
    // — `elapsedSec` est conservé et le décompte reprend à la reconnexion.
    _ticker?.cancel();
    _ticker = null;
    state = state.copyWith(reconnecting: true);

    final resumed = await _attemptResume();
    if (!mounted) return;
    _reconnecting = false;
    _conductor?.setSuspended(false);
    state = state.copyWith(reconnecting: false);
    if (!resumed) {
      _giveUpRealtime();
      return;
    }
    // Reprise réussie : l'UI, la transcription et le chrono n'ont pas bougé.
    if (state.phase == RealtimePhase.live) _startTicker();
  }

  /// Demande un nouveau token de reprise et rouvre le WebSocket avec. Réessaie
  /// sur une erreur réseau (backoff court et borné) ; un refus explicite du
  /// serveur (422 session terminée / plafond atteint / reprise désactivée, 404
  /// session d'autrui) ou un `ASYNC_FALLBACK` arrête tout de suite : réessayer
  /// ne changerait rien.
  Future<bool> _attemptResume() async {
    final budget = Duration(
      seconds: _connectWindowSec == null
          ? _resumeBudgetSec
          : (_connectWindowSec! < _resumeBudgetSec
              ? _connectWindowSec!
              : _resumeBudgetSec),
    );
    final clock = Stopwatch()..start();
    for (var attempt = 0; attempt < _resumeMaxAttempts; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(
            Duration(milliseconds: _resumeBackoffMs[attempt]));
      }
      if (!mounted || _finishing || clock.elapsed > budget) return false;
      try {
        final next = await _repo.resumeSession(
          _args.sessionId,
          resumptionHandle: _resumptionHandle,
        );
        // ASYNC_FALLBACK (mint impossible côté serveur) ou descripteur
        // inexploitable : rien à rouvrir, on bascule sans réessayer.
        if (!next.isRealtime ||
            next.wsEndpoint == null ||
            next.ephemeralToken == null) {
          return false;
        }
        _resumable = next.resumable;
        _resumptionsRemaining = next.resumptionsRemaining;
        _connectWindowSec = next.connectWindowSec ?? _connectWindowSec;
        // Pas de handle verrouillé : la conversation repart sans contexte côté
        // fournisseur, on lui redonne la fin de l'échange.
        final primer = next.contextRestored == false
            ? resumePrimer(_conduct, [
                for (final l in state.transcript) (speaker: l.speaker, text: l.text)
              ])
            : null;
        await _client?.reconnect(next, primer: primer);
        return true;
      } catch (e) {
        final api = ApiClient.toApiException(e);
        if (api.statusCode >= 400 && api.statusCode < 500) return false;
        // Réseau / 5xx : on retente avec le même handle.
      }
    }
    return false;
  }

  /// La reprise n'est pas (ou plus) possible. Ce qui est déjà arrivé au serveur
  /// est évaluable : on CLÔTURE plutôt que de le jeter, et `resolveRealtimeFinish`
  /// dira honnêtement ce qui s'est passé. Si rien n'est parti, il n'y a rien à
  /// sauver : on bascule sur l'enregistrement classique (chemin de repli existant).
  void _giveUpRealtime() {
    if (_candidateTurnsRelayed > 0) {
      finish(cause: RealtimeEndCause.connectionLost);
    } else {
      _failAndClose(kRtResumeFailedMessage, RealtimeEndCause.connectionLost);
    }
  }

  void _enqueue(RealtimeSpeaker speaker, String text,
      [TurnTiming timing = const TurnTiming()]) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (speaker == RealtimeSpeaker.candidate) _candidateTurnsSpoken++;
    _pending.add((speaker: speaker, text: trimmed, timing: timing));
    // Chaque tour terminé = une ligne affichable (bouton « Voir ma transcription »).
    if (mounted) {
      state = state.copyWith(
        transcript: [...state.transcript, RealtimeLine(speaker, trimmed)],
      );
    }
  }

  /// Injecte un tour de dialogue comme le ferait le transcripteur : c'est le
  /// seul moyen de vérifier en test que « le candidat a parlé » et « sa parole
  /// est arrivée au serveur » restent deux faits distincts.
  @visibleForTesting
  void debugEnqueueTurn(RealtimeSpeaker speaker, String text) =>
      _enqueue(speaker, text);

  /// Envoie les fragments accumulés, en fusionnant les tours consécutifs d'un
  /// même locuteur (un appel backend par segment). Les envois sont chaînés sur
  /// [_sendChain] ; attendre la Future retournée = attendre TOUS les envois
  /// déjà engagés (ceux de ce flush ET les précédents encore en vol).
  Future<void> _flush() {
    if (_pending.isEmpty) return _sendChain;
    final batch = List.of(_pending);
    _pending.clear();

    // Le numéro de tour est attribué ICI, une seule fois par segment et de façon
    // strictement croissante : c'est ce que le serveur déduplique.
    // Un segment fusionné court du début de son premier tour à la fin du
    // dernier.
    final segments = <({
      RealtimeSpeaker speaker,
      String text,
      int turns,
      int index,
      int? startedAtMs,
      int? endedAtMs,
    })>[];
    for (final frag in batch) {
      if (segments.isNotEmpty && segments.last.speaker == frag.speaker) {
        final last = segments.last;
        segments[segments.length - 1] = (
          speaker: frag.speaker,
          text: '${last.text} ${frag.text}',
          turns: last.turns + 1,
          index: last.index,
          startedAtMs: last.startedAtMs ?? frag.timing.startedAtMs,
          endedAtMs: frag.timing.endedAtMs ?? last.endedAtMs,
        );
      } else {
        segments.add((
          speaker: frag.speaker,
          text: frag.text,
          turns: 1,
          index: _turnIndex++,
          startedAtMs: frag.timing.startedAtMs,
          endedAtMs: frag.timing.endedAtMs,
        ));
      }
    }

    final sessionId = _args.sessionId;
    _sendChain = _sendChain.then((_) async {
      for (final seg in segments) {
        var sent = false;
        for (var attempt = 0;
            attempt < _transcriptMaxAttempts && !sent;
            attempt++) {
          if (attempt > 0) {
            await Future<void>.delayed(
                const Duration(milliseconds: _transcriptRetryDelayMs));
          }
          // Le handle voyage sur un appel qui a déjà lieu : pas d'aller-retour
          // dédié. Seulement s'il est plus récent que le dernier transmis.
          final handle =
              _resumptionHandle != _handleRelayed ? _resumptionHandle : null;
          try {
            await _repo.appendTranscript(
              sessionId: sessionId,
              speaker: seg.speaker,
              text: seg.text,
              // MÊME index à chaque essai : un tour déjà appliqué est ignoré
              // par le serveur, donc un réessai ne peut plus dupliquer de
              // parole ni rendre une citation ambiguë. C'est ce qui a remplacé
              // l'ancien « on ne renvoie jamais ».
              turnIndex: seg.index,
              resumptionHandle: handle,
              startedAtMs: seg.startedAtMs,
              endedAtMs: seg.endedAtMs,
            );
            if (handle != null) _handleRelayed = handle;
            sent = true;
          } catch (_) {
            // Réessai avec le même index ; si tout échoue, la perte est comptée.
          }
        }
        if (sent) {
          if (seg.speaker == RealtimeSpeaker.candidate) {
            _candidateTurnsRelayed += seg.turns;
          }
        } else {
          // Perte RÉELLE : les tours suivants portent un index plus haut, donc
          // celui-ci ne pourra plus être appliqué. On la compte au lieu de la
          // maquiller, et on l'annonce au candidat.
          _droppedTurns += seg.turns;
        }
      }
    });
    return _sendChain;
  }

  /// Clôture demandée par l'utilisateur (« Terminer l'oral », [cause] par
  /// défaut) ou par le minuteur / une coupure (cause explicite).
  Future<void> finish(
      {RealtimeEndCause cause = RealtimeEndCause.userFinish}) async {
    if (_finishing) return;
    _finishing = true;
    _endCause ??= cause;
    _ticker?.cancel();
    _conductor?.dispose();
    if (mounted) {
      state = state.copyWith(
          phase: RealtimePhase.finishing, reconnecting: false);
    }

    _flushTimer?.cancel();
    await _flush();
    await _client?.dispose();
    // `dispose()` vide les derniers tours encore en tampon (une prise de parole
    // non close par un `turnComplete` — typiquement la réponse du candidat juste
    // avant la fin du temps) via les callbacks → `_pending`. On les RENVOIE avant
    // de clôturer : le backend passe la session en COMPLETED au `finish` et
    // ignore tout fragment arrivé après (« tardif »). Sans ce 2ᵉ flush, un échange
    // court perdait son unique tour candidat → aucune submission créée → tâche
    // « non évaluée » (constaté en examen complet). Le web fait déjà ce flush
    // après `stop()`.
    await _flush();

    final result = await _resolveFinish();
    if (mounted) {
      state = state.copyWith(
        phase: RealtimePhase.done,
        sessionsRemaining: _sessionsRemaining,
        finishResult: result,
      );
    }
  }

  /// Relance demandée par le candidat après un échec de clôture. `finish` est
  /// idempotent côté backend et le transcript est déjà en base : c'est bien
  /// l'ENVOI qu'on rejoue, pas l'oral. On repasse d'abord les fragments encore
  /// en attente pour que la relance porte sur l'échange le plus complet.
  Future<void> retryFinish() async {
    if (!mounted || state.retryingFinish) return;
    state = state.copyWith(retryingFinish: true);
    await _flush();
    final result = await _resolveFinish();
    if (!mounted) return;
    state = state.copyWith(
      retryingFinish: false,
      sessionsRemaining: _sessionsRemaining,
      finishResult: result,
    );
  }

  /// Appelle la clôture (une relance automatique : une coupure passagère ne
  /// doit pas coûter une production, et `finish` est idempotent), puis traduit
  /// le tout en issue honnête.
  Future<RealtimeFinishResult> _resolveFinish() async {
    var finishOk = false;
    var serverEvaluated = false;
    for (var attempt = 0; attempt < 2 && !finishOk; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
      }
      try {
        final res = await _repo.finishSession(
          _args.sessionId,
          endCause: _endCause,
          events: List.of(_conductEvents),
        );
        serverEvaluated = res.evaluated;
        _sessionsRemaining = res.sessionsRemaining;
        finishOk = true;
        if (serverEvaluated) _onPlanChanged();
      } catch (_) {
        // Rejoué une fois ; l'issue dira la vérité si ça ne passe toujours pas.
      }
    }
    return resolveRealtimeFinish(
      finishOk: finishOk,
      serverEvaluated: serverEvaluated,
      candidateTurnsSpoken: _candidateTurnsSpoken,
      candidateTurnsRelayed: _candidateTurnsRelayed,
      droppedTurns: _droppedTurns,
    );
  }

  /// Échec sans clôture évaluable : le serveur clôt quand même la session (sans
  /// notation pour une erreur) pour qu'elle soit comptée — sans attendre la
  /// réponse, le candidat repasse tout de suite sur l'enregistrement classique.
  void _failAndClose(String message, RealtimeEndCause cause) {
    if (!_finishing && _args.sessionId.isNotEmpty) {
      _finishing = true;
      _endCause ??= cause;
      unawaited(_repo
          .finishSession(_args.sessionId,
              endCause: cause, events: List.of(_conductEvents))
          .then((_) {}, onError: (Object _) {}));
    }
    _fail(message);
  }

  void _fail(String message) {
    if (!mounted || state.phase == RealtimePhase.done) return;
    state = state.copyWith(
        phase: RealtimePhase.failed, error: message, reconnecting: false);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _flushTimer?.cancel();
    _conductor?.dispose();
    _client?.dispose();
    super.dispose();
  }
}

/// Horloge réelle de la conduite (minuteurs `Timer`, temps monotone).
class _RealClock implements ConductClock {
  const _RealClock();

  static final Stopwatch _watch = Stopwatch()..start();

  @override
  int nowMs() => _watch.elapsedMilliseconds;

  @override
  Object setTimeout(void Function() fn, int ms) =>
      Timer(Duration(milliseconds: ms), fn);

  @override
  void clearTimeout(Object handle) => (handle as Timer).cancel();
}

final realtimeEoControllerProvider = StateNotifierProvider.autoDispose
    .family<RealtimeEoController, RealtimeEoState, RealtimeRunnerArgs>(
  (ref, args) {
    // Lu à la construction : le contrôleur est `autoDispose`, son `ref` ne se
    // lit plus une fois l'écran quitté.
    final revision = ref.read(learningPlanRevisionProvider.notifier);
    return RealtimeEoController(
      ref.read(realtimeRepositoryProvider),
      args,
      onPlanChanged: () => revision.state++,
    )..start();
  },
);

void _noop() {}

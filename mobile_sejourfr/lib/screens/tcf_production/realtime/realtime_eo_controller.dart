import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/realtime_repository.dart';
import '../../../core/api/repositories.dart';
import '../../../core/models/production_models.dart';
import '../../../core/models/realtime_models.dart';
import '../../../core/realtime/gemini_live_client.dart';
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
  });

  final RealtimePhase phase;
  final int targetSec;
  final int elapsedSec;
  final bool examinerSpeaking;
  final String? error;
  final int? sessionsRemaining;

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
    );
  }
}

/// Pilote une session EO temps réel : ouvre le client Gemini, relaie le
/// transcript dialogué au backend (batché), tient le minuteur, et clôture
/// (le backend crée la submission + lance la notation à la clôture).
class RealtimeEoController extends StateNotifier<RealtimeEoState> {
  RealtimeEoController(this._repo, this._args)
      : super(RealtimeEoState(
          phase: RealtimePhase.connecting,
          targetSec: _args.descriptor.targetDurationSec ?? 200,
        ));

  final RealtimeRepository _repo;
  final RealtimeRunnerArgs _args;

  GeminiLiveClient? _client;
  Timer? _ticker;
  Timer? _flushTimer;
  Timer? _capTimer;
  Timer? _settleTimer;
  bool _finishing = false;
  // Après 0:00, l'examinateur a-t-il commencé sa conclusion (parlé au moins une
  // fois) ? La clôture attend qu'il ait parlé PUIS se taise (repos), pas un
  // délai fixe — sinon silence mort ou coupure en plein mot.
  bool _heardClose = false;

  /// Repos de silence après la conclusion avant de couper (ms).
  static const _settleMs = 1200;

  /// Plafond de sécurité après 0:00 : borne le cas où l'examinateur ne conclut
  /// jamais ou divague.
  static const _capSeconds = 12;

  final List<({RealtimeSpeaker speaker, String text})> _pending = [];

  // Comptage du relais de transcript, qui est best-effort : sans lui, un
  // fragment perdu rétrécissait silencieusement la production notée. Ce sont
  // ces trois compteurs qui rendent la perte DÉTECTABLE et permettent de
  // distinguer « le candidat s'est tu » de « sa parole ne nous est pas
  // parvenue » — deux messages opposés à ne jamais confondre.
  int _candidateTurnsSpoken = 0;
  int _candidateTurnsRelayed = 0;
  int _droppedTurns = 0;
  int? _sessionsRemaining;

  // Tous les envois de transcript passent par cette chaîne : l'ordre des lignes
  // est garanti côté backend, et `finish()` peut ATTENDRE que tout soit parti
  // (y compris un tick périodique encore en vol) avant `finishSession` — le
  // backend ignore silencieusement tout fragment arrivé après la clôture.
  Future<void> _sendChain = Future.value();

  String get attemptId => _args.attemptId;

  Future<void> start() async {
    final client = GeminiLiveClient(
      descriptor: _args.descriptor,
      onCandidateTranscript: (t) => _enqueue(RealtimeSpeaker.candidate, t),
      onExaminerTranscript: (t) => _enqueue(RealtimeSpeaker.examiner, t),
      onSpeakingChange: (speaking) {
        if (!mounted) return;
        state = state.copyWith(examinerSpeaking: speaking);
        // Fenêtre de clôture (temps écoulé, clôture pas encore lancée) : on
        // attend que l'examinateur ait prononcé sa conclusion PUIS se taise.
        if (state.phase != RealtimePhase.finishing || _finishing) return;
        if (speaking) {
          _heardClose = true;
          _settleTimer?.cancel();
          _settleTimer = null;
        } else if (_heardClose && _settleTimer == null) {
          _settleTimer =
              Timer(const Duration(milliseconds: _settleMs), finish);
        }
      },
      // L'examinateur a commencé (1er audio) ou garde-fou 8 s : fin de l'accueil,
      // le micro du candidat s'ouvre → on passe en conversation. C'est ICI que
      // le chrono de la tâche démarre : le temps ne compte QU'À partir du premier
      // mot de l'examinateur, jamais pendant la connexion/accueil.
      onListeningStart: () {
        if (mounted && state.phase == RealtimePhase.welcoming) {
          state = state.copyWith(phase: RealtimePhase.live);
        }
        _ticker ??= Timer.periodic(const Duration(seconds: 1), _onTick);
      },
      onError: (msg) => _fail(msg),
      onClosed: () {
        // Fermeture côté serveur (token expiré, fin de session) : on clôture.
        if (state.phase == RealtimePhase.live ||
            state.phase == RealtimePhase.welcoming) {
          finish();
        }
      },
    );
    _client = client;
    try {
      await client.start();
      if (!mounted) return;
      // Phase d'accueil : micro coupé tant que l'examinateur n'a pas parlé. Le
      // chrono (_ticker) ne démarre QU'À la 1re parole de l'examinateur, dans
      // onListeningStart — pas ici. Le relais du transcript, lui, tourne dès la
      // connexion.
      state = state.copyWith(phase: RealtimePhase.welcoming);
      _flushTimer =
          Timer.periodic(const Duration(milliseconds: 1500), (_) => _flush());
    } catch (e) {
      _fail(e.toString());
    }
  }

  void _onTick(Timer t) {
    if (!mounted) return;
    final next = state.elapsedSec + 1;
    state = state.copyWith(elapsedSec: next);
    if (next >= state.targetSec &&
        (state.phase == RealtimePhase.live ||
            state.phase == RealtimePhase.welcoming)) {
      state = state.copyWith(phase: RealtimePhase.finishing);
      // Signale la fin (coupe le micro + demande la conclusion). La clôture réelle
      // est pilotée par la fin de parole (onSpeakingChange) ; le plafond borne le
      // cas où l'examinateur ne conclut pas.
      _ticker?.cancel();
      _client?.notifyTimeUp();
      _capTimer = Timer(const Duration(seconds: _capSeconds), finish);
    }
  }

  void _enqueue(RealtimeSpeaker speaker, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (speaker == RealtimeSpeaker.candidate) _candidateTurnsSpoken++;
    _pending.add((speaker: speaker, text: trimmed));
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

    final segments = <({RealtimeSpeaker speaker, String text, int turns})>[];
    for (final frag in batch) {
      if (segments.isNotEmpty && segments.last.speaker == frag.speaker) {
        final last = segments.last;
        segments[segments.length - 1] = (
          speaker: frag.speaker,
          text: '${last.text} ${frag.text}',
          turns: last.turns + 1,
        );
      } else {
        segments.add((speaker: frag.speaker, text: frag.text, turns: 1));
      }
    }

    final sessionId = _args.sessionId;
    _sendChain = _sendChain.then((_) async {
      for (final seg in segments) {
        try {
          await _repo.appendTranscript(
            sessionId: sessionId,
            speaker: seg.speaker,
            text: seg.text,
          );
          if (seg.speaker == RealtimeSpeaker.candidate) {
            _candidateTurnsRelayed += seg.turns;
          }
        } catch (_) {
          // Best-effort assumé : on NE renvoie PAS. Un `appendTranscript` n'est
          // pas idempotent — un renvoi après un succès dont la réponse s'est
          // perdue dupliquerait un tour, donc fabriquerait de la parole et
          // rendrait une citation ambiguë (le contrôle de preuve littérale
          // exige un match unique). Une fusion douteuse est pire qu'un manque :
          // on compte la perte au lieu de la maquiller, et on l'annonce.
          _droppedTurns += seg.turns;
        }
      }
    });
    return _sendChain;
  }

  /// Clôture demandée par l'utilisateur ou par le minuteur.
  Future<void> finish() async {
    if (_finishing) return;
    _finishing = true;
    _ticker?.cancel();
    _capTimer?.cancel();
    _settleTimer?.cancel();
    if (mounted) state = state.copyWith(phase: RealtimePhase.finishing);

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
        final res = await _repo.finishSession(_args.sessionId);
        serverEvaluated = res.evaluated;
        _sessionsRemaining = res.sessionsRemaining;
        finishOk = true;
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

  void _fail(String message) {
    if (!mounted || state.phase == RealtimePhase.done) return;
    state = state.copyWith(phase: RealtimePhase.failed, error: message);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _flushTimer?.cancel();
    _capTimer?.cancel();
    _settleTimer?.cancel();
    _client?.dispose();
    super.dispose();
  }
}

final realtimeEoControllerProvider = StateNotifierProvider.autoDispose
    .family<RealtimeEoController, RealtimeEoState, RealtimeRunnerArgs>(
  (ref, args) => RealtimeEoController(
    ref.read(realtimeRepositoryProvider),
    args,
  )..start(),
);

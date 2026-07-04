import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/realtime_repository.dart';
import '../../../core/api/repositories.dart';
import '../../../core/models/production_models.dart';
import '../../../core/models/realtime_models.dart';
import '../../../core/realtime/gemini_live_client.dart';

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
  });

  final RealtimePhase phase;
  final int targetSec;
  final int elapsedSec;
  final bool examinerSpeaking;
  final String? error;
  final int? sessionsRemaining;

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
  }) {
    return RealtimeEoState(
      phase: phase ?? this.phase,
      targetSec: targetSec,
      elapsedSec: elapsedSec ?? this.elapsedSec,
      examinerSpeaking: examinerSpeaking ?? this.examinerSpeaking,
      error: error ?? this.error,
      sessionsRemaining: sessionsRemaining ?? this.sessionsRemaining,
      transcript: transcript ?? this.transcript,
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
    _pending.add((speaker: speaker, text: trimmed));
    // Chaque tour terminé = une ligne affichable (bouton « Voir ma transcription »).
    if (mounted) {
      state = state.copyWith(
        transcript: [...state.transcript, RealtimeLine(speaker, trimmed)],
      );
    }
  }

  /// Envoie les fragments accumulés, en fusionnant les tours consécutifs d'un
  /// même locuteur (un appel backend par segment).
  Future<void> _flush() async {
    if (_pending.isEmpty) return;
    final batch = List.of(_pending);
    _pending.clear();

    final segments = <({RealtimeSpeaker speaker, String text})>[];
    for (final frag in batch) {
      if (segments.isNotEmpty && segments.last.speaker == frag.speaker) {
        final merged = '${segments.last.text} ${frag.text}';
        segments[segments.length - 1] = (speaker: frag.speaker, text: merged);
      } else {
        segments.add(frag);
      }
    }

    final sessionId = _args.sessionId;
    for (final seg in segments) {
      try {
        await _repo.appendTranscript(
          sessionId: sessionId,
          speaker: seg.speaker,
          text: seg.text,
        );
      } catch (_) {
        // Best-effort : un fragment perdu ne doit pas casser la session.
      }
    }
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

    try {
      final res = await _repo.finishSession(_args.sessionId);
      if (mounted) {
        state = state.copyWith(
          phase: RealtimePhase.done,
          sessionsRemaining: res.sessionsRemaining,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(phase: RealtimePhase.done);
      }
    }
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

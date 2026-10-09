// Conduite de l'examinateur temps réel côté client — logique PURE : aucune
// dépendance au réseau, à l'audio ou à l'horloge réelle (horloge et minuteurs
// injectés). Trois mécanismes, réglés par la conduite servie
// (`RealtimeConductConfig`, `prompts/realtime-conduct-<v>.json`) :
//
//  1. FIN DE TEMPS DOUCE (audit F03) : à l'échéance, si l'examinateur parle on
//     attend la fin de sa lecture ; si le candidat parle on le laisse finir sa
//     phrase (au plus `timeUpGraceMaxMs`) ; ENSUITE seulement on coupe le micro
//     et on envoie `[FIN]`, puis on clôt après `timeUpCloseIdleMs` de silence de
//     l'examinateur, au plus `timeUpCloseMaxMs`.
//  2. RELANCE SUR SILENCE (F02) : minuteur armé à la fin de la lecture de
//     l'examinateur, annulé dès que le candidat parle ; à `silenceAfterMs` sans
//     parole, `[SILENCE]` ; au plus `silenceMaxConsecutive` relances sans parole
//     entre elles, aucune dans les `silenceDisabledLastSec` dernières secondes ni
//     pendant la fin de temps.
//  3. REPRISE SANS CONTEXTE (F13) : `[REPRISE]` + les `resumeContextTurns`
//     derniers tours, pour que l'examinateur ne rejoue pas l'ouverture.
//
// Le signal « le candidat parle » vient d'une détection LOCALE d'énergie du
// micro (après annulation d'écho, [VoiceActivityDetector]), jamais de la
// transcription, qui arrive en retard. Biais assumé : un bruit peut passer pour
// de la parole — sans gravité pour la relance (elle est seulement annulée),
// borné par `timeUpGraceMaxMs` pour la fin de temps.
//
// Miroir TypeScript, cas pour cas : `web_sejoufr/lib/realtime/conduct.ts`.

import 'dart:math' as math;
import 'dart:typed_data';

import '../models/realtime_models.dart';

/// Horloge et minuteurs injectés (réels en production, simulés en vérification).
abstract class ConductClock {
  int nowMs();
  Object setTimeout(void Function() fn, int ms);
  void clearTimeout(Object handle);
}

/// Ce que la conduite demande à la session et à l'écran.
class ConductActions {
  const ConductActions({
    required this.sendText,
    required this.muteCandidate,
    required this.close,
    required this.recordEvent,
    this.onPhaseChange,
  });

  /// Envoie un tour texte au modèle (message entre crochets).
  final void Function(String text) sendText;

  /// Coupe le micro du candidat (il ne parle plus après la fin de temps).
  final void Function() muteCandidate;

  /// Clôt la session, cause `TIME_UP`.
  final void Function() close;

  /// Trace un événement de conduite (mesure).
  final void Function(RealtimeConductEvent event) recordEvent;

  /// Phase de fin de temps, pour l'écran.
  final void Function(ConductPhase phase)? onPhaseChange;
}

/// `live` : échange en cours · `waitExaminer` : échéance atteinte, l'examinateur
/// finit sa phrase · `grace` : le candidat finit la sienne · `closing` : `[FIN]`
/// envoyé, l'examinateur conclut.
enum ConductPhase { live, waitExaminer, grace, closing }

class ConductController {
  ConductController({
    required RealtimeConductConfig conduct,
    required ConductClock clock,
    required ConductActions actions,
    required int targetSec,
    required int? Function() elapsedMs,
    bool Function()? candidateEnergyNow,
  })  : _conduct = conduct,
        _clock = clock,
        _actions = actions,
        _remainingSec = targetSec.toDouble(),
        _elapsedMs = elapsedMs,
        _candidateEnergyNow = candidateEnergyNow ?? (() => false);

  final RealtimeConductConfig _conduct;
  final ConductClock _clock;
  final ConductActions _actions;

  /// ms depuis l'établissement de la connexion, pour horodater un événement.
  final int? Function() _elapsedMs;

  /// Énergie du micro au-dessus du seuil EN CE MOMENT (début de parole pas encore
  /// confirmé).
  final bool Function() _candidateEnergyNow;

  ConductPhase _phase = ConductPhase.live;
  bool _examinerSpeaking = false;
  bool _candidateActive = false;
  bool _suspended = false;
  double _remainingSec;
  // Instant du dernier tic du chrono : le reste se lit à l'instant voulu, pas
  // seulement au tic (un minuteur peut expirer entre deux tics).
  int? _tickAt;
  int _consecutiveRelances = 0;
  Object? _silenceTimer;
  Object? _waitTimer;
  Object? _graceTimer;
  int _graceStartedAt = 0;
  Object? _capTimer;
  Object? _idleTimer;
  bool _heardClose = false;
  bool _closed = false;

  ConductPhase get phase => _phase;

  /// Secondes restantes au chrono de la tâche (appelé à chaque tic).
  void tick(int remainingSec) {
    _remainingSec = remainingSec.toDouble();
    _tickAt = _clock.nowMs();
  }

  /// Coupure réseau en cours : aucune relance ne part.
  void setSuspended(bool suspended) {
    _suspended = suspended;
    if (suspended) _silenceTimer = _cancel(_silenceTimer);
  }

  void examinerSpeakingChanged(bool speaking) {
    if (_closed || speaking == _examinerSpeaking) return;
    _examinerSpeaking = speaking;
    if (speaking) {
      _silenceTimer = _cancel(_silenceTimer);
      if (_phase == ConductPhase.closing) {
        _heardClose = true;
        _idleTimer = _cancel(_idleTimer);
      }
      return;
    }
    switch (_phase) {
      case ConductPhase.live:
        _armSilence();
      case ConductPhase.waitExaminer:
        _waitTimer = _cancel(_waitTimer);
        _afterExaminer();
      case ConductPhase.closing:
        if (_heardClose) {
          _idleTimer = _cancel(_idleTimer);
          _idleTimer =
              _clock.setTimeout(_finish, _conduct.timeUpCloseIdleMs);
        }
      case ConductPhase.grace:
        break;
    }
  }

  void candidateVoiceChanged(bool active) {
    if (_closed || active == _candidateActive) return;
    _candidateActive = active;
    if (active) {
      _silenceTimer = _cancel(_silenceTimer);
      _consecutiveRelances = 0;
      return;
    }
    if (_phase == ConductPhase.grace) _endGrace();
  }

  /// Le chrono de la tâche vient d'atteindre l'échéance.
  void timeUp() {
    if (_closed || _phase != ConductPhase.live) return;
    _silenceTimer = _cancel(_silenceTimer);
    if (_conduct.timeUpGraceMaxMs <= 0) {
      // Conduite sans fin de temps douce (v0) : coupure immédiate, comme avant.
      _sendFin();
      return;
    }
    if (_examinerSpeaking) {
      _setPhase(ConductPhase.waitExaminer);
      // Borne : une lecture qui ne finit jamais ne retient pas la clôture.
      _waitTimer =
          _clock.setTimeout(_afterExaminer, _conduct.timeUpGraceMaxMs);
      return;
    }
    _afterExaminer();
  }

  void dispose() {
    _closed = true;
    _silenceTimer = _cancel(_silenceTimer);
    _waitTimer = _cancel(_waitTimer);
    _graceTimer = _cancel(_graceTimer);
    _capTimer = _cancel(_capTimer);
    _idleTimer = _cancel(_idleTimer);
  }

  // --- Fin de temps ----------------------------------------------------------

  void _afterExaminer() {
    if (_closed ||
        (_phase != ConductPhase.live && _phase != ConductPhase.waitExaminer)) {
      return;
    }
    if (_candidateActive || _candidateEnergyNow()) {
      _setPhase(ConductPhase.grace);
      _graceStartedAt = _clock.nowMs();
      _graceTimer = _clock.setTimeout(_endGrace, _conduct.timeUpGraceMaxMs);
      return;
    }
    _sendFin();
  }

  void _endGrace() {
    if (_phase != ConductPhase.grace) return;
    _graceTimer = _cancel(_graceTimer);
    _actions.recordEvent(RealtimeConductEvent(
      RealtimeConductEventType.timeUpGrace,
      atMs: _elapsedMs(),
      valueMs: math.max(0, _clock.nowMs() - _graceStartedAt),
    ));
    _sendFin();
  }

  void _sendFin() {
    _setPhase(ConductPhase.closing);
    _actions.muteCandidate();
    _actions.sendText(_conduct.timeUpMessage);
    _heardClose = false;
    _capTimer = _clock.setTimeout(_finish, _conduct.timeUpCloseMaxMs);
  }

  void _finish() {
    if (_closed) return;
    dispose();
    _actions.close();
  }

  // --- Relance sur silence ---------------------------------------------------

  void _armSilence() {
    _silenceTimer = _cancel(_silenceTimer);
    final c = _conduct;
    if (c.silenceMessage.isEmpty ||
        _suspended ||
        _consecutiveRelances >= c.silenceMaxConsecutive) {
      return;
    }
    // Une relance qui tomberait dans les dernières secondes n'est pas armée.
    if (_remainingNowSec() - c.silenceAfterMs / 1000 <=
        c.silenceDisabledLastSec) {
      return;
    }
    _silenceTimer = _clock.setTimeout(_fireSilence, c.silenceAfterMs);
  }

  void _fireSilence() {
    _silenceTimer = null;
    final c = _conduct;
    if (_closed ||
        _phase != ConductPhase.live ||
        _suspended ||
        _examinerSpeaking) {
      return;
    }
    if (_remainingNowSec() <= c.silenceDisabledLastSec) return;
    // Course : le candidat commence à parler à l'instant où le minuteur expire.
    if (_candidateActive || _candidateEnergyNow()) return;
    if (_consecutiveRelances >= c.silenceMaxConsecutive) return;
    _consecutiveRelances += 1;
    _actions.recordEvent(RealtimeConductEvent(
        RealtimeConductEventType.silenceRelance,
        atMs: _elapsedMs()));
    _actions.sendText(c.silenceMessage);
  }

  // --- Outils ----------------------------------------------------------------

  /// Secondes restantes au chrono à cet instant (le chrono ne court qu'une fois
  /// lancé).
  double _remainingNowSec() {
    final at = _tickAt;
    if (at == null) return _remainingSec;
    return _remainingSec - (_clock.nowMs() - at) / 1000;
  }

  void _setPhase(ConductPhase phase) {
    if (phase == _phase) return;
    _phase = phase;
    _actions.onPhaseChange?.call(phase);
  }

  Object? _cancel(Object? handle) {
    if (handle != null) _clock.clearTimeout(handle);
    return null;
  }
}

/// Détection LOCALE de voix sur l'énergie RMS du micro (après annulation
/// d'écho). Début confirmé après `voiceMinSpeechMs` au-dessus du seuil ; fin
/// après `voiceHangoverMs` en dessous. Un seul détecteur par session, réutilisé
/// par la fin de temps et la relance.
class VoiceActivityDetector {
  VoiceActivityDetector(this._conduct, this._onChange);

  final RealtimeConductConfig _conduct;
  final void Function(bool active) _onChange;

  bool _active = false;
  double _aboveMs = 0;
  double _belowMs = 0;
  bool _lastAbove = false;

  /// Un paquet micro : son énergie RMS (0..1) et sa durée.
  void feed(double rms, double frameMs) {
    _lastAbove = rms >= _conduct.voiceEnergyThreshold;
    if (_lastAbove) {
      _aboveMs += frameMs;
      _belowMs = 0;
      if (!_active && _aboveMs >= _conduct.voiceMinSpeechMs) {
        _active = true;
        _onChange(true);
      }
    } else {
      _belowMs += frameMs;
      _aboveMs = 0;
      if (_active && _belowMs >= _conduct.voiceHangoverMs) {
        _active = false;
        _onChange(false);
      }
    }
  }

  /// Énergie au-dessus du seuil sur le dernier paquet (début pas encore confirmé
  /// compris).
  bool energyNow() => _lastAbove;

  /// Remet à zéro (l'examinateur parle : ce que capte le micro n'est pas le
  /// candidat).
  void reset() {
    final wasActive = _active;
    _active = false;
    _aboveMs = 0;
    _belowMs = 0;
    _lastAbove = false;
    if (wasActive) _onChange(false);
  }
}

/// Énergie RMS d'un paquet PCM 16 bits mono little-endian, ramenée à 0..1.
double rmsOfPcm16(Uint8List bytes) {
  final samples = ByteData.sublistView(bytes);
  final count = samples.lengthInBytes ~/ 2;
  if (count == 0) return 0;
  var sum = 0.0;
  for (var i = 0; i < count; i++) {
    final v = samples.getInt16(i * 2, Endian.little) / 32768;
    sum += v * v;
  }
  return math.sqrt(sum / count);
}

/// Tour texte d'une reprise SANS contexte restauré : `[REPRISE]` puis les
/// `resumeContextTurns` derniers tours du transcript, pour que l'examinateur
/// reprenne l'échange au lieu de rejouer l'ouverture. Vide si la conduite le
/// désactive.
String resumePrimer(
  RealtimeConductConfig conduct,
  List<({RealtimeSpeaker speaker, String text})> lines,
) {
  if (conduct.resumeMessage.isEmpty) return '';
  final n = conduct.resumeContextTurns;
  final derniers =
      n > 0 ? lines.sublist(math.max(0, lines.length - n)) : const [];
  return [
    conduct.resumeMessage,
    for (final l in derniers)
      '${l.speaker == RealtimeSpeaker.examiner ? 'Examinateur' : 'Candidat'} : ${l.text}',
  ].join('\n');
}

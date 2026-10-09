/// Miroirs mobiles des DTOs realtime EO (examinateur vocal temps réel).
/// Alignés à la main sur le backend : `RealtimeSessionDescriptor.java`,
/// `RealtimeSessionStateResponse.java`, endpoint `/api/realtime/eo/quota`.
library;

enum RealtimeMode { realtime, asyncFallback }

extension RealtimeModeParse on RealtimeMode {
  static RealtimeMode fromString(String? raw) =>
      raw == 'REALTIME' ? RealtimeMode.realtime : RealtimeMode.asyncFallback;
}

/// Qui parle, pour le relais du transcript dialogué au backend.
enum RealtimeSpeaker { candidate, examiner }

extension RealtimeSpeakerX on RealtimeSpeaker {
  String get wire =>
      this == RealtimeSpeaker.candidate ? 'CANDIDATE' : 'EXAMINER';
}

/// Qui a clos une session temps réel (mesure, V090). Miroir de
/// `RealtimeEndCause.java` et de `RealtimeEndCause` (web `lib/types.ts`).
enum RealtimeEndCause { timeUp, userFinish, connectionLost, error }

extension RealtimeEndCauseX on RealtimeEndCause {
  String get wire => switch (this) {
        RealtimeEndCause.timeUp => 'TIME_UP',
        RealtimeEndCause.userFinish => 'USER_FINISH',
        RealtimeEndCause.connectionLost => 'CONNECTION_LOST',
        RealtimeEndCause.error => 'ERROR',
      };
}

/// Type d'événement de conduite déclaré par le client à la clôture (V090).
enum RealtimeConductEventType { silenceRelance, timeUpGrace }

/// Événement de conduite (mesure, V090). Miroir de `RealtimeConductEvent`
/// (web `lib/types.ts`).
class RealtimeConductEvent {
  const RealtimeConductEvent(this.type, {this.atMs, this.valueMs});

  final RealtimeConductEventType type;

  /// ms depuis l'établissement de la connexion (`setupComplete`).
  final int? atMs;

  /// Durée associée (grâce de fin de temps utilisée).
  final int? valueMs;

  Map<String, dynamic> toJson() => {
        'type': type == RealtimeConductEventType.silenceRelance
            ? 'SILENCE_RELANCE'
            : 'TIMEUP_GRACE',
        if (atMs != null) 'atMs': atMs,
        if (valueMs != null) 'valueMs': valueMs,
      };
}

/// Réponse au démarrage d'une session. En mode [RealtimeMode.realtime] le client
/// ouvre lui-même le WebSocket [wsEndpoint] avec [ephemeralToken]. En
/// [RealtimeMode.asyncFallback] les champs de connexion sont nuls → on bascule
/// vers l'enregistrement classique (jamais bloquant).
class RealtimeSessionDescriptor {
  RealtimeSessionDescriptor({
    required this.mode,
    required this.tacheNumero,
    required this.sessionsRemaining,
    this.sessionId,
    this.provider,
    this.model,
    this.wsEndpoint,
    this.ephemeralToken,
    this.inputAudioMimeType,
    this.inputSampleRate,
    this.outputSampleRate,
    this.voice,
    this.targetDurationSec,
    this.resumable = false,
    this.resumptionsRemaining,
    this.connectWindowSec,
    this.contextRestored,
    RealtimeConductConfig? conduct,
  }) : conduct = conduct ?? RealtimeConductConfig.fallback;

  final RealtimeMode mode;
  final int tacheNumero;
  final int sessionsRemaining;
  final String? sessionId;
  final String? provider;
  final String? model;
  final String? wsEndpoint;
  final String? ephemeralToken;
  final String? inputAudioMimeType;
  final int? inputSampleRate;
  final int? outputSampleRate;
  final String? voice;
  final int? targetDurationSec;

  /// La reprise après coupure est armée côté serveur : le client DOIT mémoriser
  /// le dernier handle reçu du fournisseur et le renvoyer (avec ses fragments de
  /// transcript, puis à la reprise) pour rouvrir la MÊME conversation. Toujours
  /// faux en [RealtimeMode.asyncFallback].
  final bool resumable;

  /// Reprises encore accordées à cette session (`0` = plus de reprise possible,
  /// `null` = information absente, cas du repli asynchrone). ⚠️ Absent du JSON
  /// quand nul (`@JsonInclude(NON_NULL)` côté backend).
  final int? resumptionsRemaining;

  /// Durée (s) pendant laquelle ce token peut encore ouvrir une connexion. Passé
  /// ce délai il faut redemander une reprise au serveur. ⚠️ Absent du JSON quand
  /// nul.
  final int? connectWindowSec;

  /// Reprise seulement : `false` = le serveur n'avait aucun handle à verrouiller,
  /// la conversation repart SANS contexte côté fournisseur — le client lui
  /// redonne la fin de l'échange (`[REPRISE]`). `null` à l'ouverture.
  final bool? contextRestored;

  /// Paramètres de conduite servis par le backend (lot 1 examinateur IA) ;
  /// [RealtimeConductConfig.fallback] sur un backend qui ne les sert pas.
  final RealtimeConductConfig conduct;

  bool get isRealtime => mode == RealtimeMode.realtime && sessionId != null;

  factory RealtimeSessionDescriptor.fromJson(Map<String, dynamic> json) {
    return RealtimeSessionDescriptor(
      mode: RealtimeModeParse.fromString(json['mode'] as String?),
      tacheNumero: (json['tacheNumero'] as num?)?.toInt() ?? 0,
      sessionsRemaining: (json['sessionsRemaining'] as num?)?.toInt() ?? 0,
      sessionId: json['sessionId'] as String?,
      provider: json['provider'] as String?,
      model: json['model'] as String?,
      wsEndpoint: json['wsEndpoint'] as String?,
      ephemeralToken: json['ephemeralToken'] as String?,
      inputAudioMimeType: json['inputAudioMimeType'] as String?,
      inputSampleRate: (json['inputSampleRate'] as num?)?.toInt(),
      outputSampleRate: (json['outputSampleRate'] as num?)?.toInt(),
      voice: json['voice'] as String?,
      targetDurationSec: (json['targetDurationSec'] as num?)?.toInt(),
      resumable: json['resumable'] as bool? ?? false,
      resumptionsRemaining: (json['resumptionsRemaining'] as num?)?.toInt(),
      connectWindowSec: (json['connectWindowSec'] as num?)?.toInt(),
      contextRestored: json['contextRestored'] as bool?,
      conduct: json['conduct'] is Map<String, dynamic>
          ? RealtimeConductConfig.fromJson(json['conduct'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Paramètres de CONDUITE côté client de l'examinateur temps réel, servis tels
/// quels par le backend (`prompts/realtime-conduct-<v>.json`). Un `message`
/// vide désactive le mécanisme correspondant (conduite v0). Miroir de
/// `RealtimeConductConfig` (web `lib/types.ts`).
class RealtimeConductConfig {
  const RealtimeConductConfig({
    required this.version,
    required this.welcomePrimer,
    required this.welcomeGuardMs,
    required this.halfDuplexHoldMs,
    required this.voiceEnergyThreshold,
    required this.voiceMinSpeechMs,
    required this.voiceHangoverMs,
    required this.silenceAfterMs,
    required this.silenceMaxConsecutive,
    required this.silenceDisabledLastSec,
    required this.silenceMessage,
    required this.timeUpGraceMaxMs,
    required this.timeUpMessage,
    required this.timeUpCloseIdleMs,
    required this.timeUpCloseMaxMs,
    required this.resumeMessage,
    required this.resumeContextTurns,
  });

  /// Repli, SEULEMENT si le serveur ne sert pas le bloc : identique au JSON v1.
  /// Miroir : `FALLBACK_CONDUCT` (web `lib/realtime/conduct-config.ts`).
  static const fallback = RealtimeConductConfig(
    version: 'v1',
    welcomePrimer: 'Bonjour.',
    welcomeGuardMs: 8000,
    halfDuplexHoldMs: 120,
    voiceEnergyThreshold: 0.02,
    voiceMinSpeechMs: 200,
    voiceHangoverMs: 600,
    silenceAfterMs: 7000,
    silenceMaxConsecutive: 2,
    silenceDisabledLastSec: 15,
    silenceMessage: '[SILENCE]',
    timeUpGraceMaxMs: 10000,
    timeUpMessage: '[FIN]',
    timeUpCloseIdleMs: 1200,
    timeUpCloseMaxMs: 15000,
    resumeMessage: '[REPRISE]',
    resumeContextTurns: 3,
  );

  final String version;

  /// Tour texte qui amorce l'accueil de l'examinateur.
  final String welcomePrimer;

  /// Micro ouvert quand même si l'examinateur n'a rien dit passé ce délai.
  final int welcomeGuardMs;

  /// Micro tenu fermé après la fin de lecture de l'examinateur (anti-écho).
  final int halfDuplexHoldMs;

  /// Détection LOCALE de voix sur l'énergie du micro (après annulation d'écho).
  final double voiceEnergyThreshold;
  final int voiceMinSpeechMs;
  final int voiceHangoverMs;

  final int silenceAfterMs;
  final int silenceMaxConsecutive;
  final int silenceDisabledLastSec;
  final String silenceMessage;

  final int timeUpGraceMaxMs;
  final String timeUpMessage;
  final int timeUpCloseIdleMs;
  final int timeUpCloseMaxMs;

  final String resumeMessage;
  final int resumeContextTurns;

  factory RealtimeConductConfig.fromJson(Map<String, dynamic> json) {
    const f = fallback;
    Map<String, dynamic> bloc(String key) =>
        json[key] is Map<String, dynamic> ? json[key] as Map<String, dynamic> : const {};
    int entier(Map<String, dynamic> m, String key, int repli) =>
        (m[key] as num?)?.toInt() ?? repli;
    String texte(Map<String, dynamic> m, String key, String repli) =>
        m[key] as String? ?? repli;
    final voix = bloc('voiceActivity');
    final silence = bloc('silenceRelance');
    final fin = bloc('timeUp');
    final reprise = bloc('resume');
    return RealtimeConductConfig(
      version: texte(json, 'version', f.version),
      welcomePrimer: texte(json, 'welcomePrimer', f.welcomePrimer),
      welcomeGuardMs: entier(json, 'welcomeGuardMs', f.welcomeGuardMs),
      halfDuplexHoldMs: entier(json, 'halfDuplexHoldMs', f.halfDuplexHoldMs),
      voiceEnergyThreshold:
          (voix['energyThreshold'] as num?)?.toDouble() ?? f.voiceEnergyThreshold,
      voiceMinSpeechMs: entier(voix, 'minSpeechMs', f.voiceMinSpeechMs),
      voiceHangoverMs: entier(voix, 'hangoverMs', f.voiceHangoverMs),
      silenceAfterMs: entier(silence, 'afterMs', f.silenceAfterMs),
      silenceMaxConsecutive:
          entier(silence, 'maxConsecutive', f.silenceMaxConsecutive),
      silenceDisabledLastSec:
          entier(silence, 'disabledLastSec', f.silenceDisabledLastSec),
      silenceMessage: texte(silence, 'message', f.silenceMessage),
      timeUpGraceMaxMs: entier(fin, 'graceMaxMs', f.timeUpGraceMaxMs),
      timeUpMessage: texte(fin, 'message', f.timeUpMessage),
      timeUpCloseIdleMs: entier(fin, 'closeIdleMs', f.timeUpCloseIdleMs),
      timeUpCloseMaxMs: entier(fin, 'closeMaxMs', f.timeUpCloseMaxMs),
      resumeMessage: texte(reprise, 'message', f.resumeMessage),
      resumeContextTurns: entier(reprise, 'contextTurns', f.resumeContextTurns),
    );
  }
}

/// `GET /api/realtime/eo/quota`.
class RealtimeQuota {
  RealtimeQuota({required this.remaining, required this.cap});

  final int remaining;
  final int cap;

  factory RealtimeQuota.fromJson(Map<String, dynamic> json) => RealtimeQuota(
        remaining: (json['remaining'] as num?)?.toInt() ?? 0,
        cap: (json['cap'] as num?)?.toInt() ?? 0,
      );
}

/// Réponse de `POST /api/realtime/eo/sessions/{id}/finish`.
class RealtimeSessionStateResponse {
  RealtimeSessionStateResponse({
    required this.sessionId,
    required this.status,
    required this.tacheNumero,
    required this.sessionsRemaining,
    required this.evaluated,
  });

  final String sessionId;
  final String status;
  final int tacheNumero;
  final int sessionsRemaining;

  /// Vrai si le candidat a parlé → une submission a été créée (résultat à
  /// afficher). Faux si seul l'examinateur a parlé (accueil sans réponse) :
  /// rien à évaluer, on l'annonce clairement au lieu d'ouvrir un bilan vide.
  final bool evaluated;

  factory RealtimeSessionStateResponse.fromJson(Map<String, dynamic> json) =>
      RealtimeSessionStateResponse(
        sessionId: json['sessionId'] as String,
        status: json['status'] as String? ?? '',
        tacheNumero: (json['tacheNumero'] as num?)?.toInt() ?? 0,
        sessionsRemaining: (json['sessionsRemaining'] as num?)?.toInt() ?? 0,
        // Défensif (anciens backends) : par défaut évalué → on tente le résultat.
        evaluated: json['evaluated'] as bool? ?? true,
      );
}

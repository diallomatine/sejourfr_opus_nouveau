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
  });

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

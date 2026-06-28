import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
// `record` réexporte aussi un IosAudioCategory : on le masque pour garder
// celui de flutter_pcm_sound (utilisé pour la lecture PCM).
import 'package:record/record.dart' hide IosAudioCategory;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import '../models/realtime_models.dart';

/// Encapsule TOUT le protocole WebSocket Gemini Live pour une session EO temps
/// réel (schéma A : client ↔ Gemini en direct via token éphémère). Un seul
/// fichier porte le protocole fournisseur — un changement de fournisseur n'en
/// touche qu'un.
///
/// Capture micro PCM 16 kHz mono (`record.startStream`) → base64 → WS. Lecture
/// de l'audio examinateur 24 kHz via `flutter_pcm_sound` (sink PCM bas niveau,
/// pas de fichier temporaire). La persona/system instruction est verrouillée
/// côté serveur dans le token : jamais envoyée ni reçue ici.
class GeminiLiveClient {
  GeminiLiveClient({
    required this.descriptor,
    this.onCandidateTranscript,
    this.onExaminerTranscript,
    this.onSpeakingChange,
    this.onListeningStart,
    this.onError,
    this.onClosed,
  });

  final RealtimeSessionDescriptor descriptor;

  /// Texte transcrit du candidat (entrée micro).
  final void Function(String text)? onCandidateTranscript;

  /// Texte transcrit de l'examinateur (sortie audio du modèle).
  final void Function(String text)? onExaminerTranscript;

  /// true quand l'examinateur est en train de parler (audio en cours).
  final void Function(bool speaking)? onSpeakingChange;

  /// Fin de la phase d'accueil : l'examinateur a commencé (1er audio) ou le
  /// garde-fou a expiré → le micro du candidat s'ouvre.
  final void Function()? onListeningStart;

  final void Function(String message)? onError;
  final void Function()? onClosed;

  final AudioRecorder _recorder = AudioRecorder();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _wsSub;
  StreamSubscription<Uint8List>? _micSub;

  final Queue<int> _pcmQueue = Queue<int>();
  bool _pcmReady = false;
  bool _started = false;
  bool _closed = false;
  bool _speaking = false;
  // Phase d'accueil : tant que l'examinateur n'a pas parlé, on coupe le micro
  // du candidat. Libéré au 1er audio examinateur, ou par garde-fou ~8 s.
  bool _awaitingFirstExaminer = true;
  Timer? _welcomeTimer;

  int get _outRate => descriptor.outputSampleRate ?? 24000;
  String get _inMime => descriptor.inputAudioMimeType ?? 'audio/pcm;rate=16000';
  int get _inRate => descriptor.inputSampleRate ?? 16000;

  /// Ouvre le WS, configure l'audio, démarre capture + lecture.
  Future<void> start() async {
    final endpoint = descriptor.wsEndpoint;
    final token = descriptor.ephemeralToken;
    if (endpoint == null || token == null) {
      throw StateError('Descripteur realtime incomplet (endpoint/token).');
    }

    await _configureAudioSession();
    await _setupPlayback();

    final uri = Uri.parse('$endpoint?access_token=$token');
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    _wsSub = channel.stream.listen(
      _onWsMessage,
      onError: (Object e) => _fail('Connexion examinateur interrompue : $e'),
      onDone: _onWsDone,
      cancelOnError: true,
    );

    // Setup : le modèle + la persona sont verrouillés dans le token (endpoint
    // "...Constrained"). On (re)déclare la transcription in/out pour maximiser
    // la remontée des events de transcription (cf. caveat token éphémère).
    _send({
      'setup': {
        if (descriptor.model != null) 'model': descriptor.model,
        'inputAudioTranscription': <String, dynamic>{},
        'outputAudioTranscription': <String, dynamic>{},
      }
    });

    await _startMic();

    // Garde-fou : si l'examinateur ne dit rien sous ~8 s, on ouvre le micro
    // quand même (un greeting audio manquant ne doit pas bloquer le candidat).
    _welcomeTimer = Timer(const Duration(seconds: 8), _beginConversation);
  }

  /// Fin de la phase d'accueil : ouvre le micro et notifie le contrôleur.
  void _beginConversation() {
    if (_closed || !_awaitingFirstExaminer) return;
    _awaitingFirstExaminer = false;
    _welcomeTimer?.cancel();
    _welcomeTimer = null;
    onListeningStart?.call();
  }

  /// Signale au modèle que le temps est écoulé pour qu'il prononce sa clôture.
  void notifyTimeUp() {
    _send({
      'clientContent': {
        'turns': [
          {
            'role': 'user',
            'parts': [
              {'text': '[TEMPS_ECOULE] Le temps de la tâche est écoulé.'}
            ]
          }
        ],
        'turnComplete': true,
      }
    });
  }

  Future<void> dispose() async {
    if (_closed) return;
    _closed = true;
    _welcomeTimer?.cancel();
    _welcomeTimer = null;
    await _micSub?.cancel();
    _micSub = null;
    try {
      if (await _recorder.isRecording()) await _recorder.stop();
    } catch (_) {/* no-op */}
    await _recorder.dispose();
    await _wsSub?.cancel();
    _wsSub = null;
    try {
      await _channel?.sink.close(ws_status.normalClosure);
    } catch (_) {/* no-op */}
    _channel = null;
    _pcmQueue.clear();
    try {
      await FlutterPcmSound.release();
    } catch (_) {/* no-op */}
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (_) {/* no-op */}
  }

  // ---------------------------------------------------------------------------
  // Audio out (examinateur) — flutter_pcm_sound
  // ---------------------------------------------------------------------------

  Future<void> _setupPlayback() async {
    await FlutterPcmSound.setLogLevel(LogLevel.error);
    await FlutterPcmSound.setup(
      sampleRate: _outRate,
      channelCount: 1,
      iosAudioCategory: IosAudioCategory.playAndRecord,
    );
    await FlutterPcmSound.setFeedThreshold(_outRate ~/ 2);
    FlutterPcmSound.setFeedCallback(_onFeed);
    _pcmReady = true;
  }

  void _onFeed(int remainingFrames) {
    if (_pcmQueue.isEmpty) {
      if (remainingFrames == 0) _setSpeaking(false);
      return;
    }
    const batch = 8000;
    final take = _pcmQueue.length < batch ? _pcmQueue.length : batch;
    final list = List<int>.generate(take, (_) => _pcmQueue.removeFirst());
    FlutterPcmSound.feed(PcmArrayInt16.fromList(list));
  }

  void _enqueueAudio(Uint8List bytes) {
    if (_closed || !_pcmReady) return;
    // 1er audio de l'examinateur : fin de l'accueil, on ouvre le micro.
    _beginConversation();
    final samples = bytes.buffer.asByteData();
    final count = bytes.lengthInBytes ~/ 2;
    for (var i = 0; i < count; i++) {
      _pcmQueue.add(samples.getInt16(i * 2, Endian.little));
    }
    _setSpeaking(true);
    // Relance la lecture si le buffer natif était drainé.
    FlutterPcmSound.start();
  }

  void _setSpeaking(bool value) {
    if (_speaking == value) return;
    _speaking = value;
    onSpeakingChange?.call(value);
  }

  // ---------------------------------------------------------------------------
  // Audio in (candidat) — record.startStream PCM16 16 kHz mono
  // ---------------------------------------------------------------------------

  Future<void> _startMic() async {
    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) {
      _fail('Permission micro refusée.');
      return;
    }
    final stream = await _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _inRate,
        numChannels: 1,
        // Annule l'écho du haut-parleur (la voix de l'examinateur) capté par le
        // micro et renvoyé à Gemini comme parole candidat.
        echoCancel: true,
        noiseSuppress: true,
        autoGain: true,
      ),
    );
    _micSub = stream.listen(
      (chunk) {
        // Accueil : micro coupé tant que l'examinateur n'a pas parlé. Puis
        // half-duplex : on n'émet pas pendant qu'il parle (anti-écho ; le
        // candidat attend la fin de la question — pas de barge-in).
        if (_closed || _awaitingFirstExaminer || _speaking) return;
        _send({
          'realtimeInput': {
            'audio': {'mimeType': _inMime, 'data': base64Encode(chunk)}
          }
        });
      },
      onError: (Object e) => _fail('Capture micro interrompue : $e'),
    );
  }

  // ---------------------------------------------------------------------------
  // WS messages
  // ---------------------------------------------------------------------------

  void _onWsMessage(dynamic raw) {
    // Après dispose(), des messages déjà en file peuvent encore arriver : on les
    // ignore, sinon l'examinateur « repartirait » (audio rejoué) après la clôture.
    if (_closed) return;
    Map<String, dynamic>? msg;
    try {
      if (raw is String) {
        msg = jsonDecode(raw) as Map<String, dynamic>;
      } else if (raw is List<int>) {
        msg = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
      }
    } catch (e) {
      dev.log('Message WS non-JSON ignoré: $e', name: 'GeminiLiveClient');
      return;
    }
    if (msg == null) return;

    final server = msg['serverContent'];
    if (server is! Map<String, dynamic>) return;

    final input = server['inputTranscription'];
    if (input is Map<String, dynamic>) {
      final t = input['text'] as String?;
      if (t != null && t.isNotEmpty) onCandidateTranscript?.call(t);
    }
    final output = server['outputTranscription'];
    if (output is Map<String, dynamic>) {
      final t = output['text'] as String?;
      if (t != null && t.isNotEmpty) onExaminerTranscript?.call(t);
    }

    if (server['interrupted'] == true) {
      _pcmQueue.clear();
      _setSpeaking(false);
    }

    final modelTurn = server['modelTurn'];
    if (modelTurn is Map<String, dynamic>) {
      final parts = modelTurn['parts'];
      if (parts is List) {
        for (final p in parts) {
          if (p is Map<String, dynamic>) {
            final inline = p['inlineData'];
            if (inline is Map<String, dynamic>) {
              final data = inline['data'] as String?;
              if (data != null && data.isNotEmpty) {
                _enqueueAudio(base64Decode(data));
              }
            }
          }
        }
      }
    }

    if (server['turnComplete'] == true && _pcmQueue.isEmpty) {
      _setSpeaking(false);
    }
  }

  void _onWsDone() {
    if (_closed) return;
    onClosed?.call();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.voiceChat,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
    await session.setActive(true);
  }

  void _send(Map<String, dynamic> payload) {
    final channel = _channel;
    if (channel == null || _closed) return;
    if (!_started) _started = true;
    try {
      channel.sink.add(jsonEncode(payload));
    } catch (e) {
      _fail('Envoi WS impossible : $e');
    }
  }

  void _fail(String message) {
    if (_closed) return;
    onError?.call(message);
  }
}

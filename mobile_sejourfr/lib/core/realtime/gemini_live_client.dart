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

  // Transcription : on accumule les fragments Gemini VERBATIM (ils portent leur
  // propre espacement) et on n'émet une ligne qu'à la fin du tour (turnComplete /
  // interrupted). Ajouter un espace entre fragments coupait les mots.
  final StringBuffer _candidateBuf = StringBuffer();
  final StringBuffer _examinerBuf = StringBuffer();

  final AudioRecorder _recorder = AudioRecorder();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _wsSub;
  StreamSubscription<Uint8List>? _micSub;

  final Queue<int> _pcmQueue = Queue<int>();
  bool _pcmReady = false;
  bool _started = false;
  bool _closed = false;
  bool _speaking = false;
  // Garde-fou anti-blocage : fin de lecture ESTIMÉE (durée cumulée des
  // échantillons reçus). Si le moteur natif meurt en silence, l'événement de
  // drain (_onFeed remainingFrames == 0) n'arrive jamais et `_speaking`
  // resterait true → micro verrouillé à vie (half-duplex). Ce timer force
  // speaking=false peu après la fin théorique de la lecture.
  DateTime _speakUntil = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _speakGuard;
  // Tenue du micro ~300 ms après la fin de parole de l'examinateur : un trou
  // entre deux lots audio rouvrait le micro en pleine phrase → l'écho résiduel
  // du haut-parleur partait à Gemini (VAD start=HIGH) → faux barge-in →
  // réponse coupée (« l'examinateur se perd en cours d'entretien »).
  DateTime _micHoldUntil = DateTime.fromMillisecondsSinceEpoch(0);
  // Reprise après incident audio (interruption AVAudioSession — appel, Siri,
  // notification, changement d'écouteurs — ou échec natif de feed) : sans elle,
  // le moteur de lecture reste mort jusqu'à la fin de la session.
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  bool _recovering = false;
  DateTime _lastRecover = DateTime.fromMillisecondsSinceEpoch(0);
  // Micro coupé (temps écoulé) : le candidat ne parle plus, on garde le WS
  // ouvert pour laisser l'examinateur prononcer sa phrase de clôture.
  bool _inputMuted = false;
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

    // Micro D'ABORD, WS ENSUITE. On exige l'autorisation micro AVANT d'ouvrir le
    // WebSocket : sinon l'examinateur (audio d'accueil) démarrerait malgré un
    // refus de permission — le candidat entendrait l'agent parler alors que son
    // micro n'est pas ouvert. On sort sans jamais ouvrir la session si refus.
    if (!await _recorder.hasPermission()) {
      _fail('Permission micro refusée.');
      return;
    }
    if (_closed) return;

    // Init audio locale (doit être prête AVANT le 1er audio examinateur :
    // _enqueueAudio ignore l'audio tant que _pcmReady est faux).
    //
    // ORDRE CRITIQUE (bug 2ᵉ session : plus aucun son ni micro, alors que le WS
    // et la transcription marchent — donc c'est l'AVAudioSession partagée qui est
    // morte, pas Gemini). `FlutterPcmSound.setup()` RECONFIGURE l'AVAudioSession
    // sur iOS et, après le `release()` de la session précédente, peut la laisser
    // inactive ou routée sur l'écouteur (sans defaultToSpeaker) → lecture muette
    // ET micro qui ne capte rien. On encadre donc son setup par notre config :
    //   1. _configureAudioSession() : session active + playAndRecord (FlutterPcmSound
    //      construit son moteur sur une session déjà active) ;
    //   2. _setupPlayback() : FlutterPcmSound.setup (peut re-toucher la session) ;
    //   3. _configureAudioSession() À NOUVEAU : notre setActive(true) +
    //      defaultToSpeaker a le DERNIER mot (comme l'enregistreur classique juste
    //      avant record.start, cf. AudioRecorderService.start) ;
    //   4. _startMic() sur une session active + playAndRecord.
    await _configureAudioSession();
    await _setupPlayback();
    await _configureAudioSession();
    await _startMic();
    if (_closed) return;

    // Reprise après interruption système (appel entrant, Siri, alarme…) : la
    // fin d'interruption laisse l'AVAudioSession désactivée et le moteur de
    // lecture natif mort — on reconfigure tout pour que l'examinateur reste
    // audible et le micro capté jusqu'à la fin de la session.
    final session = await AudioSession.instance;
    _interruptionSub = session.interruptionEventStream.listen((event) {
      if (!event.begin) _recoverAudio();
    });

    // WS + setup une fois le micro prêt. Le handshake + la génération de
    // l'accueil par le modèle (le plus long) se déroulent ensuite ; le micro
    // n'émet rien avant la 1re phrase de l'examinateur (half-duplex), donc
    // ouvrir le WS après le micro ne coûte pas de parole candidat.
    final uri = Uri.parse('$endpoint?access_token=$token');
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    _wsSub = channel.stream.listen(
      _onWsMessage,
      onError: (Object e) => _fail('Connexion examinateur interrompue : $e'),
      onDone: _onWsDone,
      cancelOnError: true,
    );

    // Endpoint "...Constrained" : TOUT le setup (modèle, persona, transcription
    // in/out, VAD, generationConfig) est verrouillé dans le token éphémère côté
    // serveur. Le client n'envoie qu'un setup MINIMAL (juste le modèle) —
    // réenvoyer les champs verrouillés fait rejeter la connexion.
    _send({
      'setup': {
        if (descriptor.model != null) 'model': descriptor.model,
      }
    });

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
  /// Coupe aussi le micro candidat : le seul tour restant est la conclusion de
  /// l'examinateur (évite qu'un dernier mot du candidat relance un échange).
  void notifyTimeUp() {
    _inputMuted = true;
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
    // Clôture en plein tour : on émet le dernier buffer (sinon la fin de la
    // dernière réponse du candidat serait perdue).
    _flushLine('candidate');
    _flushLine('examiner');
    _closed = true;
    _welcomeTimer?.cancel();
    _welcomeTimer = null;
    _speakGuard?.cancel();
    _speakGuard = null;
    await _interruptionSub?.cancel();
    _interruptionSub = null;
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
      // `notifyOthersOnDeactivation` : libère proprement l'AVAudioSession pour
      // que la session suivante (ou un autre lecteur) la réacquière sans hériter
      // d'un état verrouillé (cf. bug 2ᵉ session muette).
      await session.setActive(
        false,
        avAudioSessionSetActiveOptions:
            AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
      );
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
    // Un échec natif (AudioOutputUnitStart…) rejette la Future : sans ce catch,
    // l'erreur serait avalée par la zone async et la lecture mourrait sans
    // trace. On tente une reprise (session + moteur) ; en dernier recours, le
    // garde-fou _speakGuard rend le micro au candidat.
    unawaited(
      FlutterPcmSound.feed(PcmArrayInt16.fromList(list)).catchError((Object e) {
        dev.log('feed lecture échoué: $e', name: 'GeminiLiveClient');
        _recoverAudio();
      }),
    );
  }

  /// Reconfigure la chaîne audio complète (session + lecture + micro si tombé)
  /// après un incident. Idempotent, garde anti-rafale (2 s).
  Future<void> _recoverAudio() async {
    if (_closed || _recovering) return;
    final now = DateTime.now();
    if (now.difference(_lastRecover) < const Duration(seconds: 2)) return;
    _lastRecover = now;
    _recovering = true;
    try {
      await _configureAudioSession();
      await _setupPlayback();
      await _configureAudioSession();
      if (!await _recorder.isRecording()) {
        await _micSub?.cancel();
        _micSub = null;
        await _startMic();
      }
      if (_closed) return;
      // Relance la pompe si de l'audio attendait pendant l'incident.
      if (_pcmQueue.isNotEmpty) _onFeed(0);
      dev.log('Chaîne audio reprise après incident', name: 'GeminiLiveClient');
    } catch (e) {
      dev.log('Reprise audio échouée: $e', name: 'GeminiLiveClient');
    } finally {
      _recovering = false;
    }
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
    _armSpeakGuard(count);
    // Pompe le lot NOUS-MÊMES. Surtout pas FlutterPcmSound.start() : il repose
    // sur un flag STATIQUE (_needsStart) partagé par tout le process, remis à
    // true uniquement par l'événement natif « buffer à zéro ». Une session
    // précédente fermée en pleine lecture (plafond 12 s, Terminer, barge-in)
    // fait release() sans jamais recevoir cet événement → le flag reste false
    // et start() ne relance plus RIEN : 2ᵉ session muette, file jamais drainée,
    // _speaking bloqué à true → micro verrouillé (bug tâche 2 en examen).
    // Appel direct idempotent : les lots sont prélevés séquentiellement de la
    // même file et le canal natif préserve l'ordre des feed().
    _onFeed(0);
  }

  /// (Ré)arme la fin de lecture estimée : maintenant (ou la fin déjà prévue)
  /// + la durée du lot reçu. Marge 900 ms avant de forcer speaking=false.
  void _armSpeakGuard(int sampleCount) {
    final now = DateTime.now();
    final base = _speakUntil.isAfter(now) ? _speakUntil : now;
    _speakUntil =
        base.add(Duration(microseconds: sampleCount * 1000000 ~/ _outRate));
    _speakGuard?.cancel();
    _speakGuard = Timer(
      _speakUntil.difference(now) + const Duration(milliseconds: 900),
      () {
        if (_closed) return;
        // Lecture jamais drainée (moteur natif mort) : on rend la parole au
        // candidat plutôt que de bloquer la session — au pire l'échange
        // continue sans le son de l'examinateur, mais reste évaluable.
        _setSpeaking(false);
      },
    );
  }

  void _setSpeaking(bool value) {
    if (_speaking == value) return;
    _speaking = value;
    if (!value) {
      // Fin de parole : tenue du micro ~300 ms (anti faux barge-in par écho —
      // un trou de jitter entre deux lots ne doit pas rouvrir le micro en
      // pleine phrase de l'examinateur).
      _micHoldUntil = DateTime.now().add(const Duration(milliseconds: 300));
    }
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
        // candidat attend la fin de la question — pas de barge-in). `_inputMuted`
        // : temps écoulé → on écoute la clôture, plus d'émission candidat.
        if (_closed || _awaitingFirstExaminer || _speaking || _inputMuted) {
          return;
        }
        // Tenue post-parole : fenêtre courte après la fin de l'examinateur
        // pendant laquelle on n'émet pas (anti faux barge-in par écho).
        if (DateTime.now().isBefore(_micHoldUntil)) return;
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

    // Gemini ne parle pas spontanément : à l'ack du setup, on déclenche l'accueil
    // par un premier tour utilisateur « Bonjour. » → l'examinateur enchaîne tout
    // de suite (fin de l'attente « il met du temps à arriver »).
    if (msg['setupComplete'] != null) {
      _sendOpeningTrigger();
      return;
    }

    final server = msg['serverContent'];
    if (server is! Map<String, dynamic>) return;

    // Accumulation VERBATIM (les fragments Gemini portent leur espacement).
    final input = server['inputTranscription'];
    if (input is Map<String, dynamic>) {
      final t = input['text'] as String?;
      if (t != null && t.isNotEmpty) _candidateBuf.write(t);
    }
    final output = server['outputTranscription'];
    if (output is Map<String, dynamic>) {
      final t = output['text'] as String?;
      if (t != null && t.isNotEmpty) _examinerBuf.write(t);
    }

    if (server['interrupted'] == true) {
      _pcmQueue.clear();
      _speakGuard?.cancel();
      _speakUntil = DateTime.fromMillisecondsSinceEpoch(0);
      _setSpeaking(false);
      _flushLine('examiner'); // barge-in : le tour examinateur est clos
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

    if (server['turnComplete'] == true) {
      // Fin de tour : on émet les lignes complètes (candidat puis examinateur).
      _flushLine('candidate');
      _flushLine('examiner');
      if (_pcmQueue.isEmpty) _setSpeaking(false);
    }
  }

  /// Émet une ligne de transcription complète (tour terminé), puis vide le buffer.
  void _flushLine(String speaker) {
    final buf = speaker == 'examiner' ? _examinerBuf : _candidateBuf;
    final text = buf.toString().trim();
    buf.clear();
    if (text.isEmpty) return;
    if (speaker == 'examiner') {
      onExaminerTranscript?.call(text);
    } else {
      onCandidateTranscript?.call(text);
    }
  }

  /// Amorce l'entretien : Gemini ne prend pas la parole seul après le setup. On
  /// envoie un vrai tour utilisateur « Bonjour. » ; l'examinateur enchaîne son
  /// accueil (dicté par la persona verrouillée dans le token). Ce tour texte
  /// n'est PAS de l'audio micro → il n'apparaît pas dans la transcription candidat.
  void _sendOpeningTrigger() {
    _send({
      'clientContent': {
        'turns': [
          {
            'role': 'user',
            'parts': [
              {'text': 'Bonjour.'}
            ]
          }
        ],
        'turnComplete': true,
      }
    });
  }

  void _onWsDone() {
    if (_closed) return;
    // Code/raison utiles au diagnostic (1007 = setup invalide, 1008 = auth…).
    final code = _channel?.closeCode;
    if (code != null && code != ws_status.normalClosure && code != 1005) {
      dev.log('WS fermé code=$code raison=${_channel?.closeReason ?? "—"}',
          name: 'GeminiLiveClient');
    }
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

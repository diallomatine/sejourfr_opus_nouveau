import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
// `record` réexporte aussi un IosAudioCategory : on le masque pour garder
// celui de flutter_pcm_sound (utilisé pour la lecture PCM).
import 'package:record/record.dart' hide IosAudioCategory;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import '../models/realtime_models.dart';

// --- Réglages temps réel (déclarés une fois, lus par tout le fichier) --------

/// Taille du tampon de capture micro. ⚠️ **L'unité dépend de la plateforme**
/// (vérifié dans le code du paquet `record` installé) : Android le lit en
/// OCTETS (`AudioRecord`, un chunk émis = `streamBufferSize` octets), iOS/macOS
/// en FRAMES du format matériel (`installTap(bufferSize:)`).
/// 1280 → Android : 640 frames PCM16 mono à 16 kHz = **40 ms** ; iOS : 1280
/// frames à 48 kHz ≈ **27 ms**. Les deux tombent dans la fourchette 20–40 ms
/// recommandée par Gemini Live. Sans valeur explicite, Android prenait
/// `getMinBufferSize × 2`, soit 80 à 128 ms par chunk.
const int _micStreamBufferSize = 1280;

/// Pré-roll de lecture : on n'amorce la pompe audio qu'une fois ~150 ms
/// d'examinateur en file (~3 chunks Gemini). Sans lui, le moindre hoquet
/// réseau produit un trou puis un clic, l'horloge de lecture repartant sans
/// lissage. Un tour plus court que ce seuil est amorcé par sa fin de tour.
const int _playbackPrerollMs = 150;

/// Lot remis au moteur natif à chaque appel de feed, en échantillons
/// (24 kHz → ~333 ms). Valeur historique, conservée.
const int _feedBatchSamples = 8000;

/// Marge du garde-fou AU-DESSUS de la fin de lecture réelle. Remplace
/// l'ancienne marge fixe de 900 ms posée sur une fin ESTIMÉE (durée cumulée
/// des échantillons reçus) : trop tôt le micro rouvrait sur la voix de
/// l'examinateur (écho → faux tour candidat), trop tard les premiers mots du
/// candidat étaient jetés.
const int _speakGuardMarginMs = 100;

/// Tenue du micro après la fin de parole de l'examinateur. 120 ms (et non 300)
/// depuis que la fin de parole suit la position de lecture RÉELLE : les 300 ms
/// compensaient l'imprécision de l'estimation qu'on vient de supprimer.
const int _micHoldAfterSpeechMs = 120;

/// Garde-fou d'accueil : si l'examinateur ne dit rien passé ce délai APRÈS
/// `setupComplete`, on ouvre quand même le micro. Armé à `setupComplete` (et
/// non à l'appel de `start()`, comme le web) : c'est le seul instant où la
/// session est réellement établie — l'armer plus tôt faisait courir le délai
/// pendant le handshake.
const Duration _welcomeTimeout = Duration(seconds: 8);

/// Signal de fin de tâche envoyé au modèle. Texte ACTIONNABLE (il dit au modèle
/// quoi faire) : c'est lui qui déclenche la phrase de clôture de la persona.
/// Doit rester identique au web — deux textes = deux fins d'entretien selon le
/// front.
const String _timeUpPrompt =
    '[Le temps de cette partie est écoulé. Remerciez brièvement le candidat '
    'et concluez maintenant.]';

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
    this.onResumptionHandle,
    this.onError,
    this.onConnectionLost,
  });

  /// Paramètres de la connexion courante. **Non final** : une reprise
  /// ([reconnect]) remplace endpoint/token/modèle par ceux du descripteur émis
  /// par `POST /sessions/{id}/resume`. Les réglages audio, eux, ne changent pas.
  RealtimeSessionDescriptor descriptor;

  /// Texte transcrit du candidat (entrée micro).
  final void Function(String text)? onCandidateTranscript;

  /// Texte transcrit de l'examinateur (sortie audio du modèle).
  final void Function(String text)? onExaminerTranscript;

  /// true quand l'examinateur est en train de parler (audio en cours).
  final void Function(bool speaking)? onSpeakingChange;

  /// Fin de la phase d'accueil : l'examinateur a commencé (1er audio) ou le
  /// garde-fou a expiré → le micro du candidat s'ouvre.
  final void Function()? onListeningStart;

  /// Dernier `sessionResumptionUpdate.newHandle` reçu du fournisseur. Le client
  /// WS ne le stocke PAS : l'état de reprise a un seul propriétaire, le
  /// contrôleur, qui le relaie au serveur et le renvoie à la reprise.
  final void Function(String handle)? onResumptionHandle;

  /// Erreur FATALE, non rattrapable par une reprise (permission micro refusée,
  /// capture impossible, connexion jamais établie).
  final void Function(String message)? onError;

  /// Le WebSocket est tombé alors que l'entretien avait commencé. Le client ne
  /// décide rien : c'est le contrôleur qui arbitre reprise ou repli.
  final void Function()? onConnectionLost;

  // Transcription : on accumule les fragments Gemini VERBATIM (ils portent leur
  // propre espacement) et on n'émet une ligne qu'à la fin du tour (turnComplete /
  // interrupted). Ajouter un espace entre fragments coupait les mots.
  final StringBuffer _candidateBuf = StringBuffer();
  final StringBuffer _examinerBuf = StringBuffer();

  final AudioRecorder _recorder = AudioRecorder();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _wsSub;
  StreamSubscription<Uint8List>? _micSub;

  // Horloge MONOTONE pour tous les délais audio (tenue micro, garde-fou,
  // anti-rafale de reprise). `DateTime.now()` est une horloge murale : un
  // recalage NTP ou un changement de fuseau en pleine session décalait la
  // fenêtre anti-écho.
  final Stopwatch _clock = Stopwatch()..start();

  // File de lecture en blocs TYPÉS (`Int16List`) : une `Queue<int>` boxait un
  // objet Dart par échantillon, soit 24 000 allocations par seconde de parole,
  // et chaque lot reconstruisait une `List<int>` de 8 000 entrées. Pression GC
  // permanente au cœur de la boucle temps réel.
  final Queue<Int16List> _pcmChunks = Queue<Int16List>();
  int _pcmHeadOffset = 0;
  int _queuedSamples = 0;
  // Pompe amorcée : faux tant que le pré-roll n'est pas atteint (début d'un
  // tour), remis à faux quand la lecture est entièrement drainée.
  bool _pumpPrimed = false;
  bool _pcmReady = false;
  bool _started = false;
  bool _closed = false;
  bool _speaking = false;
  // Position de lecture RÉELLE, ré-ancrée à chaque callback de feed : le moteur
  // natif nous dit combien de frames il lui reste (`remainingFrames`), on y
  // ajoute ce qu'on vient de lui donner. Tout le reste (fin de parole,
  // garde-fou) se déduit de cet ancrage — jamais d'une durée cumulée en
  // horloge murale, qui ignorait le retard réel de la file et les trous réseau.
  int _nativeRemainingAtAnchor = 0;
  int _anchorMs = 0;
  // Garde-fou anti-blocage : si le moteur natif meurt en silence, l'événement
  // de drain (_onFeed remainingFrames == 0) n'arrive jamais et `_speaking`
  // resterait true → micro verrouillé à vie (half-duplex). Le timer ne peut
  // plus tirer avant la fin réelle : il se ré-arme tant qu'il reste de l'audio
  // à jouer, et ne conclut que si ce reste ne décroît plus.
  Timer? _speakGuard;
  int _guardRemainingRef = -1;
  // Tenue du micro après la fin de parole de l'examinateur : un trou entre deux
  // lots audio rouvrait le micro en pleine phrase → l'écho résiduel du
  // haut-parleur partait à Gemini (VAD start=HIGH) → faux barge-in → réponse
  // coupée (« l'examinateur se perd en cours d'entretien »).
  int _micHoldUntilMs = 0;
  // Reprise après incident audio (interruption AVAudioSession — appel, Siri,
  // notification, changement d'écouteurs — ou échec natif de feed) : sans elle,
  // le moteur de lecture reste mort jusqu'à la fin de la session.
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  bool _recovering = false;
  int _lastRecoverMs = -3000;
  // Micro coupé (temps écoulé) : le candidat ne parle plus, on garde le WS
  // ouvert pour laisser l'examinateur prononcer sa phrase de clôture.
  bool _inputMuted = false;
  // Phase d'accueil : tant que l'examinateur n'a pas parlé, on coupe le micro
  // du candidat. Libéré au 1er audio examinateur, ou par garde-fou ~8 s.
  bool _awaitingFirstExaminer = true;
  Timer? _welcomeTimer;
  // La session a-t-elle été établie au moins une fois (`setupComplete`) ? Ce qui
  // tombe AVANT n'est pas une coupure rattrapable mais un échec de connexion :
  // reprendre une conversation qui n'a jamais commencé n'a aucun sens.
  bool _everConnected = false;
  // Une chute de socket ne se signale qu'UNE fois : `onError` et `onDone` du
  // même flux peuvent tirer coup sur coup.
  bool _socketDownNotified = false;

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
    _openSocket(endpoint, token);
    // Le garde-fou d'accueil est armé à `setupComplete`, pas ici : cf.
    // `_welcomeTimeout`.
  }

  /// Rouvre le WebSocket avec le descripteur d'une REPRISE
  /// (`POST /sessions/{id}/resume`) : nouveau token, même conversation. La
  /// chaîne audio (micro, moteur de lecture, session iOS) reste EN PLACE — on
  /// ne redemande pas la permission, on ne recrée pas le moteur : seul le
  /// transport change.
  ///
  /// ⚠️ Le handle de reprise est verrouillé dans le setup du token côté serveur
  /// (endpoint contraint) : on ne peut ni le poser ici, ni réutiliser l'ancien
  /// token, d'où le passage obligé par le serveur.
  Future<void> reconnect(RealtimeSessionDescriptor next) async {
    if (_closed) return;
    final endpoint = next.wsEndpoint;
    final token = next.ephemeralToken;
    if (endpoint == null || token == null) {
      throw StateError('Descripteur de reprise incomplet (endpoint/token).');
    }
    descriptor = next;
    await _wsSub?.cancel();
    _wsSub = null;
    try {
      await _channel?.sink.close(ws_status.normalClosure);
    } catch (_) {/* no-op */}
    _channel = null;
    // Le tour de l'examinateur est mort avec le socket : on jette ce qui
    // restait en file (sinon un bout de phrase se rejouerait à la reprise) et
    // on rend la parole au candidat.
    _clearPcmQueue();
    _setSpeaking(false);
    _socketDownNotified = false;
    _openSocket(endpoint, token);
  }

  void _openSocket(String endpoint, String token) {
    final uri = Uri.parse('$endpoint?access_token=$token');
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    _wsSub = channel.stream.listen(
      _onWsMessage,
      onError: (Object e) => _handleSocketDown('erreur WS : $e'),
      onDone: _onWsDone,
      cancelOnError: true,
    );

    // Endpoint "...Constrained" : TOUT le setup (modèle, persona, transcription
    // in/out, VAD, generationConfig, reprise de session) est verrouillé dans le
    // token éphémère côté serveur. Le client n'envoie qu'un setup MINIMAL
    // (juste le modèle) — réenvoyer les champs verrouillés fait rejeter la
    // connexion.
    _send({
      'setup': {
        if (descriptor.model != null) 'model': descriptor.model,
      }
    });
  }

  /// Chute du transport. Avant `setupComplete` c'est un échec de connexion
  /// (fatal) ; après, c'est une coupure que le contrôleur peut reprendre.
  void _handleSocketDown(String reason) {
    if (_closed || _socketDownNotified) return;
    _socketDownNotified = true;
    dev.log('WS tombé ($reason)', name: 'GeminiLiveClient');
    if (!_everConnected) {
      _fail('Connexion à l\'examinateur impossible.');
      return;
    }
    // Ce qui restait à jouer est perdu avec le socket : on rend le micro au
    // candidat au lieu de le laisser verrouillé en half-duplex.
    _clearPcmQueue();
    _setSpeaking(false);
    onConnectionLost?.call();
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
              {'text': _timeUpPrompt}
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
    _clearPcmQueue();
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
    // Ancrage de la position de lecture réelle : à cet instant précis, le
    // moteur natif a `remainingFrames` frames en réserve.
    _nativeRemainingAtAnchor = remainingFrames;
    _anchorMs = _clock.elapsedMilliseconds;
    if (_queuedSamples == 0) {
      if (remainingFrames == 0) {
        // Lecture entièrement drainée : fin RÉELLE du tour, et la pompe devra
        // se ré-amorcer (pré-roll) au prochain tour.
        _pumpPrimed = false;
        _setSpeaking(false);
      }
      return;
    }
    final take = math.min(_queuedSamples, _feedBatchSamples);
    final out = Int16List(take);
    var written = 0;
    while (written < take) {
      final head = _pcmChunks.first;
      final available = head.length - _pcmHeadOffset;
      final n = math.min(available, take - written);
      out.setRange(written, written + n, head, _pcmHeadOffset);
      written += n;
      _pcmHeadOffset += n;
      if (_pcmHeadOffset == head.length) {
        _pcmChunks.removeFirst();
        _pcmHeadOffset = 0;
      }
    }
    _queuedSamples -= take;
    // Ce qu'on remet au moteur s'ajoute à sa réserve.
    _nativeRemainingAtAnchor += take;
    // `PcmArrayInt16` est passé tel quel au canal natif via
    // `bytes.buffer.asUint8List()`, qui ignore l'offset de la vue : le
    // ByteBuffer doit donc couvrir EXACTEMENT le lot (d'où l'`Int16List(take)`
    // dédiée, jamais une vue dans un tampon plus grand).
    final payload = PcmArrayInt16(bytes: ByteData.view(out.buffer));
    // Un échec natif (AudioOutputUnitStart…) rejette la Future : sans ce catch,
    // l'erreur serait avalée par la zone async et la lecture mourrait sans
    // trace. On tente une reprise (session + moteur) ; en dernier recours, le
    // garde-fou _speakGuard rend le micro au candidat.
    unawaited(
      FlutterPcmSound.feed(payload).catchError((Object e) {
        dev.log('feed lecture échoué: $e', name: 'GeminiLiveClient');
        _recoverAudio();
      }),
    );
  }

  /// Réserve du moteur natif MAINTENANT : la valeur ancrée au dernier callback
  /// de feed, moins ce qui a dû être consommé depuis. Ré-ancrée à chaque
  /// callback, donc la dérive de cette extrapolation ne s'accumule pas.
  int get _nativeRemainingNow {
    final since = _clock.elapsedMilliseconds - _anchorMs;
    final left = _nativeRemainingAtAnchor - (since * _outRate ~/ 1000);
    return left > 0 ? left : 0;
  }

  /// Millisecondes d'audio examinateur qu'il reste RÉELLEMENT à jouer : la
  /// réserve du moteur natif + ce qui attend dans notre file.
  int get _playbackRemainingMs =>
      (_nativeRemainingNow + _queuedSamples) * 1000 ~/ _outRate;

  void _clearPcmQueue() {
    _pcmChunks.clear();
    _pcmHeadOffset = 0;
    _queuedSamples = 0;
    _pumpPrimed = false;
    _nativeRemainingAtAnchor = 0;
    _anchorMs = _clock.elapsedMilliseconds;
  }

  /// Reconfigure la chaîne audio complète (session + lecture + micro si tombé)
  /// après un incident. Idempotent, garde anti-rafale (2 s).
  Future<void> _recoverAudio() async {
    if (_closed || _recovering) return;
    final now = _clock.elapsedMilliseconds;
    if (now - _lastRecoverMs < 2000) return;
    _lastRecoverMs = now;
    _recovering = true;
    try {
      await _configureAudioSession();
      // Le moteur natif précédent est peut-être encore vivant (échec de feed
      // isolé) : sans ce `release()`, `setup()` en construit un second et les
      // deux se disputent la sortie audio.
      try {
        await FlutterPcmSound.release();
      } catch (_) {/* no-op */}
      _pcmReady = false;
      await _setupPlayback();
      await _configureAudioSession();
      if (!await _recorder.isRecording()) {
        await _micSub?.cancel();
        _micSub = null;
        await _startMic();
      }
      if (_closed) return;
      // Relance la pompe si de l'audio attendait pendant l'incident : on
      // court-circuite le pré-roll, c'est une reprise, pas un début de tour.
      if (_queuedSamples > 0) {
        _pumpPrimed = true;
        _onFeed(0);
      }
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
    // `sublistView` respecte l'offset et la longueur de la vue reçue ;
    // `bytes.buffer.asByteData()` prenait le ByteBuffer entier et aurait lu à
    // côté sur un Uint8List qui n'est pas à l'offset 0.
    final samples = ByteData.sublistView(bytes);
    final count = samples.lengthInBytes ~/ 2;
    if (count == 0) return;
    final chunk = Int16List(count);
    for (var i = 0; i < count; i++) {
      chunk[i] = samples.getInt16(i * 2, Endian.little);
    }
    _pcmChunks.add(chunk);
    _queuedSamples += count;
    _setSpeaking(true);
    _guardRemainingRef = -1;
    _armSpeakGuard();
    // Pré-roll : on n'amorce la pompe qu'une fois assez d'audio en file, pour
    // absorber la gigue réseau. Une fois amorcée, elle reste amorcée jusqu'au
    // drain complet du tour.
    if (!_pumpPrimed &&
        _queuedSamples < _outRate * _playbackPrerollMs ~/ 1000) {
      return;
    }
    _pumpPrimed = true;
    // Pompe le lot NOUS-MÊMES. Surtout pas FlutterPcmSound.start() : il repose
    // sur un flag STATIQUE (_needsStart) partagé par tout le process, remis à
    // true uniquement par l'événement natif « buffer à zéro ». Une session
    // précédente fermée en pleine lecture (plafond 12 s, Terminer, barge-in)
    // fait release() sans jamais recevoir cet événement → le flag reste false
    // et start() ne relance plus RIEN : 2ᵉ session muette, file jamais drainée,
    // _speaking bloqué à true → micro verrouillé (bug tâche 2 en examen).
    // Appel direct idempotent : les lots sont prélevés séquentiellement de la
    // même file et le canal natif préserve l'ordre des feed().
    _onFeed(_nativeRemainingNow);
  }

  /// Amorce la pompe même si le pré-roll n'est pas atteint : un tour très court
  /// (« Oui. ») tient dans moins de [_playbackPrerollMs] et ne doit pas rester
  /// coincé en file jusqu'au tour suivant.
  void _primePlaybackNow() {
    if (_closed || _pumpPrimed || _queuedSamples == 0) return;
    _pumpPrimed = true;
    _onFeed(_nativeRemainingNow);
  }

  /// (Ré)arme le garde-fou sur la fin de lecture RÉELLE ([_playbackRemainingMs]),
  /// jamais sur une durée théorique : il ne peut plus tirer avant que le moteur
  /// natif et notre file soient vides. Le réveil est repoussé tant qu'il reste
  /// de l'audio à jouer ; la seule échappatoire est une lecture qui n'avance
  /// plus (moteur mort), détectée au fait que ce reste ne décroît pas d'un
  /// réveil à l'autre.
  void _armSpeakGuard() {
    _speakGuard?.cancel();
    _speakGuard = Timer(
      Duration(milliseconds: _playbackRemainingMs + _speakGuardMarginMs),
      () {
        if (_closed || !_speaking) return;
        final left = _playbackRemainingMs;
        final progressing = _guardRemainingRef < 0 || left < _guardRemainingRef;
        if (left > 0 && progressing) {
          _guardRemainingRef = left;
          _armSpeakGuard();
          return;
        }
        // Fin atteinte, ou lecture jamais drainée (moteur natif mort) : on rend
        // la parole au candidat plutôt que de bloquer la session — au pire
        // l'échange continue sans le son de l'examinateur, mais reste évaluable.
        _setSpeaking(false);
      },
    );
  }

  void _setSpeaking(bool value) {
    if (_speaking == value) return;
    _speaking = value;
    if (!value) {
      // Fin de parole : tenue courte du micro (anti faux barge-in par écho —
      // un trou de jitter entre deux lots ne doit pas rouvrir le micro en
      // pleine phrase de l'examinateur).
      _micHoldUntilMs = _clock.elapsedMilliseconds + _micHoldAfterSpeechMs;
      _speakGuard?.cancel();
      _speakGuard = null;
      _guardRemainingRef = -1;
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
        // Cale le chunk micro dans la fourchette 20–40 ms recommandée par
        // Gemini Live (cf. _micStreamBufferSize et son unité par plateforme).
        streamBufferSize: _micStreamBufferSize,
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
        if (_clock.elapsedMilliseconds < _micHoldUntilMs) return;
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
      _everConnected = true;
      // Après une REPRISE, l'entretien a déjà commencé : le contexte est
      // restauré côté fournisseur et renvoyer « Bonjour. » ferait rejouer un
      // accueil. On ne réamorce que si l'examinateur n'a jamais parlé.
      if (_awaitingFirstExaminer) {
        _sendOpeningTrigger();
        // Garde-fou d'accueil armé ICI, à l'instant où la session est réellement
        // établie (aligné sur le web) : un greeting audio manquant ne doit pas
        // bloquer le candidat, mais le handshake ne doit pas consommer le délai.
        _welcomeTimer?.cancel();
        _welcomeTimer = Timer(_welcomeTimeout, _beginConversation);
      }
      return;
    }

    // Handle de reprise : on le remonte tel quel, sans le stocker (le
    // contrôleur est le seul propriétaire de l'état de reprise).
    final resumption = msg['sessionResumptionUpdate'];
    if (resumption is Map<String, dynamic>) {
      final handle = resumption['newHandle'] as String?;
      if (handle != null && handle.isNotEmpty) {
        onResumptionHandle?.call(handle);
      }
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
      _clearPcmQueue();
      _speakGuard?.cancel();
      _speakGuard = null;
      _guardRemainingRef = -1;
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
      // Tour trop court pour atteindre le pré-roll : on le lance quand même,
      // sinon il resterait en file jusqu'au tour suivant.
      _primePlaybackNow();
      // Fin de tour ≠ fin de lecture : on ne rouvre le micro que si le moteur
      // natif n'a plus rien à jouer. L'ancienne condition ne regardait que
      // notre file, donc rouvrait le micro alors que l'examinateur parlait
      // encore — écho renvoyé à Gemini, faux tour candidat.
      if (_playbackRemainingMs <= 0) _setSpeaking(false);
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
    _handleSocketDown(
        'fermeture code=$code raison=${_channel?.closeReason ?? "—"}');
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
      // Un envoi qui échoue, c'est le transport qui est tombé : même chemin que
      // la fermeture du socket, donc reprise possible plutôt qu'échec sec.
      _handleSocketDown('envoi impossible : $e');
    }
  }

  void _fail(String message) {
    if (_closed) return;
    onError?.call(message);
  }
}

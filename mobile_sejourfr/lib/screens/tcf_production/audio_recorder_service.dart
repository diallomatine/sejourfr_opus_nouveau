import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Etat haut-niveau de la phase d'enregistrement EO.
enum RecordingPhase { idle, requestingPermission, recording, paused, finished, failed }

class RecordingState {
  const RecordingState({
    required this.phase,
    this.elapsed = Duration.zero,
    this.maxDuration = const Duration(minutes: 3),
    this.filePath,
    this.fileMime,
    this.lastAmplitude,
    this.errorMessage,
  });

  final RecordingPhase phase;
  final Duration elapsed;
  final Duration maxDuration;

  /// Chemin du fichier audio sur disque (dispo apres stop).
  final String? filePath;

  /// MIME du fichier (depend de l'encoder utilise).
  final String? fileMime;

  /// Derniere amplitude lue (dB convertis en 0..1), pour la waveform live.
  final double? lastAmplitude;

  final String? errorMessage;

  bool get isRecording => phase == RecordingPhase.recording;
  bool get isFinished => phase == RecordingPhase.finished && filePath != null;
  bool get canStop => phase == RecordingPhase.recording || phase == RecordingPhase.paused;

  RecordingState copyWith({
    RecordingPhase? phase,
    Duration? elapsed,
    Duration? maxDuration,
    String? filePath,
    String? fileMime,
    double? lastAmplitude,
    String? errorMessage,
    bool clearError = false,
    bool clearFile = false,
  }) {
    return RecordingState(
      phase: phase ?? this.phase,
      elapsed: elapsed ?? this.elapsed,
      maxDuration: maxDuration ?? this.maxDuration,
      filePath: clearFile ? null : (filePath ?? this.filePath),
      fileMime: clearFile ? null : (fileMime ?? this.fileMime),
      lastAmplitude: lastAmplitude ?? this.lastAmplitude,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Encapsule l'API `record` + `permission_handler` + `path_provider`.
/// Une instance par session (auto-disposed via Riverpod).
class AudioRecorderService {
  AudioRecorderService();

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _ampSub;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  Duration _maxDuration = const Duration(minutes: 3);
  String? _currentPath;
  String? _currentMime;

  Stream<RecordingState>? _stateStream;
  final _stateController = StreamController<RecordingState>.broadcast();

  Stream<RecordingState> get stateStream => _stateStream ??= _stateController.stream;

  /// Demande la permission micro. On utilise en priorite `_recorder.hasPermission()`
  /// du package `record` qui declenche l'auth native (AVAudioSession sur iOS,
  /// RECORD_AUDIO sur Android) -- c'est l'API officielle du package et elle
  /// ne souffre pas des bugs de cache de `permission_handler` sur iOS.
  ///
  /// Si record retourne false, on retombe sur `permission_handler` pour pouvoir
  /// distinguer "refus simple" / "permanently denied" et proposer le detour
  /// par les Reglages systeme.
  Future<PermissionStatus> ensurePermission() async {
    // 1. Tente la voie native (pop le dialog iOS la 1re fois).
    final recordOk = await _recorder.hasPermission();
    if (recordOk) return PermissionStatus.granted;

    // 2. Reprend via permission_handler pour distinguer denied / permanentlyDenied
    //    et offrir le bouton "Ouvrir les Reglages".
    final status = await Permission.microphone.status;
    return status;
  }

  /// Ouvre les Reglages systeme de l'app (utilisateur peut activer le micro
  /// manuellement quand il a refuse une fois sur iOS).
  Future<bool> openSystemSettings() => openAppSettings();

  Future<String> _resolveTempPath() async {
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/eo_$ts.wav';
  }

  /// Demarre l'enregistrement. Retourne le path du fichier en cours d'ecriture.
  /// Le caller doit deja avoir verifie la permission via [ensurePermission].
  Future<void> start({required Duration maxDuration}) async {
    // Configuration explicite AVAudioSession : sans ca, sur iOS, si just_audio
    // a deja saisi la session en mode .playback, `record` ecrit un fichier
    // silencieux. On force playAndRecord avant chaque enregistrement.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
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

    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    final path = await _resolveTempPath();
    _currentPath = path;
    // WAV PCM 16 kHz mono : format non compresse, universellement supporte.
    // ~32 KB/s -> ~2 Mo pour 1 min. Whisper accepte .wav directement.
    //
    // Pourquoi pas AAC ? L'encoder AAC-LC de record_ios 1.2.0 produit un
    // fichier vide (28 B, juste un header MP4) sur iOS 26 -- bug confirme
    // en mai 2026 sur device physique. WAV est le seul format fiable
    // jusqu'a la prochaine version de record_ios.
    _currentMime = 'audio/wav';
    _elapsed = Duration.zero;
    _maxDuration = maxDuration;
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    _stateController.add(RecordingState(
      phase: RecordingPhase.recording,
      elapsed: Duration.zero,
      maxDuration: maxDuration,
      filePath: path,
      fileMime: 'audio/mp4',
    ));
    _startTicker(maxDuration);
    _startAmplitudeStream();
  }

  void _startTicker(Duration maxDuration) {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (t) async {
      _elapsed += const Duration(milliseconds: 200);
      _stateController.add(RecordingState(
        phase: RecordingPhase.recording,
        elapsed: _elapsed,
        maxDuration: maxDuration,
        filePath: _currentPath,
        fileMime: _currentMime,
      ));
      if (_elapsed >= maxDuration) {
        await stop();
      }
    });
  }

  void _startAmplitudeStream() {
    _ampSub?.cancel();
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
      // dBFS typique : -60 (silence) a 0 (saturation). On normalise sur 0..1.
      final norm = ((amp.current + 60) / 60).clamp(0.0, 1.0);
      _stateController.add(RecordingState(
        phase: RecordingPhase.recording,
        elapsed: _elapsed,
        maxDuration: _maxDuration,
        filePath: _currentPath,
        fileMime: _currentMime,
        lastAmplitude: norm,
      ));
    });
  }

  Future<String?> stop() async {
    _ticker?.cancel();
    _ticker = null;
    await _ampSub?.cancel();
    _ampSub = null;
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {
      path = _currentPath;
    }
    if (path != null) _currentPath = path;
    // Log de diagnostic : taille du fichier produit. < 1 KB = enregistrement
    // silencieux/vide (AVAudioSession mal configuree, micro non capture, etc.).
    if (_currentPath != null) {
      try {
        final size = await File(_currentPath!).length();
        dev.log(
          'Recording stopped -> path=$_currentPath sizeBytes=$size elapsed=${_elapsed.inMilliseconds}ms',
          name: 'AudioRecorderService',
        );
      } catch (e) {
        dev.log('Recording stopped but file inaccessible: $e',
            name: 'AudioRecorderService');
      }
    }
    // Libere la session audio iOS pour permettre au mini-player just_audio
    // (ecran finished) de prendre la main proprement.
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (_) {/* no-op */}
    _stateController.add(RecordingState(
      phase: RecordingPhase.finished,
      elapsed: _elapsed,
      maxDuration: _maxDuration,
      filePath: _currentPath,
      fileMime: _currentMime,
    ));
    return _currentPath;
  }

  Future<void> cancel() async {
    _ticker?.cancel();
    _ticker = null;
    await _ampSub?.cancel();
    _ampSub = null;
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {/* no-op */}
    if (_currentPath != null) {
      try {
        final f = File(_currentPath!);
        if (await f.exists()) await f.delete();
      } catch (_) {/* no-op */}
    }
    _currentPath = null;
    _currentMime = null;
    _elapsed = Duration.zero;
    _stateController.add(const RecordingState(phase: RecordingPhase.idle));
  }

  Future<void> dispose() async {
    _ticker?.cancel();
    await _ampSub?.cancel();
    await _stateController.close();
    await _recorder.dispose();
  }
}

// PAS autoDispose : le controller doit vivre toute la session EO (briefing ->
// recording -> finished -> resultats) ; les awaits natifs (dialog permission
// iOS, enregistrement long) faisaient sauter le provider entre les frames.
// Le service est leger en idle (juste un AudioRecorder dormant), ok de le
// garder vivant jusqu'a la fin de l'app -- on rappelle `cancel()` manuellement
// quand l'utilisateur quitte la session.
final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  final svc = AudioRecorderService();
  ref.onDispose(svc.dispose);
  return svc;
});

class RecordingController extends StateNotifier<RecordingState> {
  RecordingController(this._svc) : super(const RecordingState(phase: RecordingPhase.idle)) {
    _sub = _svc.stateStream.listen((s) {
      if (mounted) state = s;
    });
  }

  final AudioRecorderService _svc;
  StreamSubscription<RecordingState>? _sub;

  /// Mute le state seulement si le notifier est encore mounted (sinon no-op).
  /// Sert de garde apres chaque await -- evite les crashes "_debugIsMounted".
  void _safeSet(RecordingState next) {
    if (mounted) state = next;
  }

  /// Retourne le PermissionStatus final apres tentative de demande. Le caller
  /// distingue 3 cas :
  ///   - isGranted -> on peut enregistrer
  ///   - isPermanentlyDenied / isDenied apres refus -> proposer Reglages
  ///   - isDenied (1re fois sans clef Info.plist) -> bug d'installation
  Future<PermissionStatus> requestPermission() async {
    _safeSet(state.copyWith(phase: RecordingPhase.requestingPermission));
    final status = await _svc.ensurePermission();
    if (!status.isGranted) {
      _safeSet(state.copyWith(
        phase: RecordingPhase.failed,
        errorMessage:
            'Permission micro refusee. Vous pouvez l\'activer dans les Reglages.',
      ));
    } else {
      _safeSet(state.copyWith(
        phase: RecordingPhase.idle,
        clearError: true,
      ));
    }
    return status;
  }

  Future<bool> openSystemSettings() => _svc.openSystemSettings();

  Future<void> start({required Duration maxDuration}) async {
    try {
      await _svc.start(maxDuration: maxDuration);
    } catch (e) {
      _safeSet(state.copyWith(
        phase: RecordingPhase.failed,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<String?> stop() => _svc.stop();

  Future<void> cancel() => _svc.cancel();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final recordingControllerProvider =
    StateNotifierProvider<RecordingController, RecordingState>((ref) {
  final svc = ref.watch(audioRecorderServiceProvider);
  return RecordingController(svc);
});

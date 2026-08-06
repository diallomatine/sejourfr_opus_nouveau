import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:just_audio/just_audio.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

/// Player audio d'une source distante. Servait d'abord la compréhension orale
/// (TCF), il est aussi le lecteur des productions orales du candidat : d'où sa
/// place ici plutôt que dans le runner.
///
/// Compte le nombre de lectures pour pouvoir limiter à 2 écoutes côté UI
/// si on veut imiter les conditions réelles.
///
/// `examMode` active les conditions strictes de l'examen réel :
///   - démarrage automatique 2s après chargement
///   - le bouton play ne peut pas être utilisé pour mettre en pause
///   - les rejouages manuels restent bloqués par `maxPlays`
///
/// `label`, `icon`, `accent` et `background` habillent le lecteur sans le
/// forker : un document d'examen reste bleu, une production orale prend
/// l'accent de son épreuve.
class SejourAudioPlayer extends StatefulWidget {
  const SejourAudioPlayer({
    super.key,
    required this.url,
    this.maxPlays,
    this.examMode = false,
    this.label = 'Document audio',
    this.icon = LucideIcons.headphones,
    this.accent = AppColors.blue,
    this.background = AppColors.blueSoft,
  });

  final String url;
  final int? maxPlays;
  final bool examMode;
  final String label;
  final IconData icon;
  final Color accent;
  final Color background;

  @override
  State<SejourAudioPlayer> createState() => _SejourAudioPlayerState();
}

class _SejourAudioPlayerState extends State<SejourAudioPlayer> {
  static const _examAutoStartDelay = Duration(milliseconds: 500);

  final _player = AudioPlayer();
  bool _ready = false;
  String? _error;
  int _playCount = 0;
  bool _started = false;
  Timer? _autoStartTimer;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    // just_audio garde `playing == true` quand le document est fini
    // (`completed`) : le bouton resterait sur ⏸ (et désactivé en examen) et la
    // barre pleine. On remet le lecteur au repos dès la fin de lecture.
    _stateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        _onPlaybackComplete();
      }
    });
    _load();
  }

  Future<void> _onPlaybackComplete() async {
    await _player.pause();
    await _player.seek(Duration.zero);
    if (!mounted) return;
    // Prochaine écoute recomptée (dans la limite de `maxPlays`).
    setState(() => _started = false);
  }

  @override
  void didUpdateWidget(covariant SejourAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la question change (url differente), on coupe l'audio en cours,
    // on reinitialise les compteurs et on recharge la nouvelle source.
    if (oldWidget.url != widget.url) {
      _resetForNewSource();
    }
  }

  Future<void> _resetForNewSource() async {
    _autoStartTimer?.cancel();
    try {
      await _player.stop();
    } catch (_) {
      // l'arret peut throw si le player est deja inactif : on ignore
    }
    if (!mounted) return;
    setState(() {
      _ready = false;
      _error = null;
      _playCount = 0;
      _started = false;
    });
    await _load();
  }

  Future<void> _load() async {
    try {
      await _player.setUrl(widget.url);
      if (!mounted) return;
      setState(() => _ready = true);
      // Examen module : on déclenche la lecture automatique 0,5s après le
      // chargement, pour reproduire les conditions du TCF officiel.
      if (widget.examMode) {
        _autoStartTimer?.cancel();
        _autoStartTimer = Timer(_examAutoStartDelay, _autoStart);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Impossible de charger l\'audio.');
    }
  }

  Future<void> _autoStart() async {
    if (!mounted || !_ready || _started) return;
    if (widget.maxPlays != null && _playCount >= widget.maxPlays!) return;
    _started = true;
    setState(() => _playCount++);
    try {
      await _player.play();
    } catch (_) {
      // L'auto-play peut être refusé sur certaines plateformes — fallback
      // sur le bouton manuel (qui reste utilisable pour démarrer).
    }
  }

  @override
  void dispose() {
    _autoStartTimer?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (!_ready) return;
    if (_player.playing) {
      // Examen module : pas de pause possible — on ignore les tap pendant
      // la lecture. La sortie naturelle est la fin du document audio.
      if (widget.examMode) return;
      await _player.pause();
    } else {
      if (widget.maxPlays != null && _playCount >= widget.maxPlays!) return;
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      if (!_started) {
        _started = true;
        if (!mounted) return;
        setState(() => _playCount++);
      }
      await _player.play();
    }
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.maxPlays == null
        ? null
        : (widget.maxPlays! - _playCount).clamp(0, widget.maxPlays!);

    return AppCard(
      padding: const EdgeInsets.all(16),
      color: widget.background,
      border: Border.all(color: widget.accent.withValues(alpha: 0.15)),
      boxShadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, color: widget.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: AppFonts.mono(
                  size: 10,
                  color: widget.accent,
                  letterSpacing: 1.8,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (remaining != null)
                Text(
                  remaining == 0
                      ? 'écoutes épuisées'
                      : '$remaining écoute${remaining > 1 ? 's' : ''} restante${remaining > 1 ? 's' : ''}',
                  style: AppFonts.mono(
                    size: 10,
                    color: AppColors.muted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _error!,
                style: AppFonts.ui(color: AppColors.red, size: 13),
              ),
            )
          else
            Row(
              children: [
                StreamBuilder<PlayerState>(
                  stream: _player.playerStateStream,
                  builder: (context, snapshot) {
                    final state = snapshot.data;
                    final playing = state?.playing ?? false;
                    final processing =
                        state?.processingState ?? ProcessingState.idle;
                    final buffering =
                        processing == ProcessingState.loading ||
                            processing == ProcessingState.buffering;
                    final showLoading = !_ready || buffering;
                    return _PlayButton(
                      playing: playing,
                      loading: showLoading,
                      // En examen module : impossible de mettre en pause
                      // (le bouton reste affiché mais désactivé pendant la
                      // lecture). Le bouton reste désactivé aussi quand la
                      // limite d'écoutes est atteinte.
                      disabled: !_ready ||
                          (remaining != null &&
                              remaining == 0 &&
                              !playing) ||
                          (widget.examMode && playing),
                      accent: widget.accent,
                      onTap: _togglePlay,
                    );
                  },
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: StreamBuilder<Duration>(
                    stream: _player.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final total = _player.duration ?? Duration.zero;
                      final progress = total.inMilliseconds == 0
                          ? 0.0
                          : (position.inMilliseconds / total.inMilliseconds)
                              .clamp(0.0, 1.0);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 5,
                              backgroundColor: AppColors.line,
                              valueColor:
                                  AlwaysStoppedAnimation(widget.accent),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fmt(position),
                                style: AppFonts.mono(
                                  size: 10,
                                  color: AppColors.muted,
                                ),
                              ),
                              Text(
                                _fmt(total),
                                style: AppFonts.mono(
                                  size: 10,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.playing,
    required this.loading,
    required this.onTap,
    required this.disabled,
    required this.accent,
  });

  final bool playing;
  final bool loading;
  final VoidCallback onTap;
  final bool disabled;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: disabled ? AppColors.muted2.withValues(alpha: 0.3) : accent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: (disabled || loading) ? null : onTap,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
              : Icon(
                  playing ? LucideIcons.pause : LucideIcons.play,
                  color: AppColors.white,
                  size: 26,
                ),
        ),
      ),
    );
  }
}

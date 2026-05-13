import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';

/// Player audio pour les questions de compréhension orale (TCF).
/// Compte le nombre de lectures pour pouvoir limiter à 2 écoutes côté UI
/// si on veut imiter les conditions réelles.
class SejourAudioPlayer extends StatefulWidget {
  const SejourAudioPlayer({
    super.key,
    required this.url,
    this.maxPlays,
  });

  final String url;
  final int? maxPlays;

  @override
  State<SejourAudioPlayer> createState() => _SejourAudioPlayerState();
}

class _SejourAudioPlayerState extends State<SejourAudioPlayer> {
  final _player = AudioPlayer();
  bool _ready = false;
  String? _error;
  int _playCount = 0;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _player.setUrl(widget.url);
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Impossible de charger l\'audio.');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (!_ready) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      if (widget.maxPlays != null && _playCount >= widget.maxPlays!) return;
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      if (!_started) {
        _started = true;
        setState(() => _playCount++);
      }
      await _player.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.maxPlays == null
        ? null
        : (widget.maxPlays! - _playCount).clamp(0, widget.maxPlays!);

    return AppCard(
      padding: const EdgeInsets.all(16),
      color: AppColors.blueSoft,
      border: Border.all(color: AppColors.blue.withValues(alpha: 0.15)),
      boxShadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.headphones, color: AppColors.blue, size: 18),
              const SizedBox(width: 8),
              Text(
                'Document audio',
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.blue,
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
                style: AppFonts.jakarta(color: AppColors.red, size: 13),
              ),
            )
          else
            Row(
              children: [
                _PlayButton(
                  playing: _player.playing,
                  disabled: !_ready ||
                      (remaining != null && remaining == 0 && !_player.playing),
                  onTap: _togglePlay,
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
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.blue,
                              ),
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
    required this.onTap,
    required this.disabled,
  });

  final bool playing;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: disabled
          ? AppColors.muted2.withValues(alpha: 0.3)
          : AppColors.blue,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: disabled ? null : onTap,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            playing ? Icons.pause : Icons.play_arrow,
            color: AppColors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

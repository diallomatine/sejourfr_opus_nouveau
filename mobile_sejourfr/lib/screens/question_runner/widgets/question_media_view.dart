import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/question_models.dart';
import '../../../core/theme/app_theme.dart';
import 'audio_player.dart';

/// Affiche le média associé à une question selon son type (audio, image, vidéo).
class QuestionMediaView extends StatelessWidget {
  const QuestionMediaView({super.key, required this.media});

  final MediaDto media;

  @override
  Widget build(BuildContext context) {
    switch (media.type) {
      case MediaType.audio:
        return SejourAudioPlayer(url: media.url);
      case MediaType.image:
        return _ImageMedia(url: media.url);
      case MediaType.video:
        return _VideoMedia(url: media.url);
    }
  }
}

class _ImageMedia extends StatelessWidget {
  const _ImageMedia({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullscreen(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 240),
          width: double.infinity,
          color: AppColors.line2,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image_outlined,
                      color: AppColors.muted),
                  const SizedBox(height: 6),
                  Text(
                    'Image indisponible',
                    style: AppFonts.jakarta(color: AppColors.muted, size: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _openFullscreen(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _VideoMedia extends StatefulWidget {
  const _VideoMedia({required this.url});
  final String url;

  @override
  State<_VideoMedia> createState() => _VideoMediaState();
}

class _VideoMediaState extends State<_VideoMedia> {
  late VideoPlayerController _ctrl;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _init();
  }

  Future<void> _init() async {
    try {
      await _ctrl.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Vidéo indisponible');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.line2,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          _error!,
          style: AppFonts.jakarta(color: AppColors.muted),
        ),
      );
    }
    if (!_ready) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: _ctrl.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_ctrl),
            _VideoControls(controller: _ctrl),
          ],
        ),
      ),
    );
  }
}

class _VideoControls extends StatefulWidget {
  const _VideoControls({required this.controller});
  final VideoPlayerController controller;

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.controller.value.isPlaying
              ? widget.controller.pause()
              : widget.controller.play();
        });
      },
      child: Container(
        color: Colors.black.withValues(alpha: 0.1),
        alignment: Alignment.center,
        child: AnimatedOpacity(
          opacity: widget.controller.value.isPlaying ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }
}

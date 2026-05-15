import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

import '../../../core/api/api_config.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/question_models.dart';
import '../../../core/theme/app_theme.dart';
import 'audio_player.dart';

/// Affiche le média associé à une question. Trois sources possibles :
///   1. media.inlineSvg → SVG dessiné en migration (TCF compréhension écrite)
///   2. media.url + IMAGE/AUDIO/VIDEO → URL distante
class QuestionMediaView extends StatelessWidget {
  const QuestionMediaView({super.key, required this.media});

  final MediaDto media;

  @override
  Widget build(BuildContext context) {
    if (media.hasInlineSvg) {
      return _InlineSvgMedia(svg: media.inlineSvg!);
    }
    final url = ApiConfig.resolveMediaUrl(media.url);
    switch (media.type) {
      case MediaType.audio:
        return SejourAudioPlayer(url: url);
      case MediaType.image:
        return _ImageMedia(url: url);
      case MediaType.video:
        return _VideoMedia(url: url);
    }
  }
}

class _InlineSvgMedia extends StatelessWidget {
  const _InlineSvgMedia({required this.svg});
  final String svg;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullscreen(context, svg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SvgPicture.string(
            svg,
            fit: BoxFit.contain,
            placeholderBuilder: (_) => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ),
    );
  }

  static void _openFullscreen(BuildContext context, String svg) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4,
          child: Container(
            color: Colors.white,
            child: SvgPicture.string(svg, fit: BoxFit.contain),
          ),
        ),
      ),
    );
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
              final value = progress.expectedTotalBytes == null
                  ? null
                  : progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!;
              return SizedBox(
                height: 200,
                child: Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      value: value,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.blue,
                      ),
                    ),
                  ),
                ),
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
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              final value = progress.expectedTotalBytes == null
                  ? null
                  : progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!;
              return Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    value: value,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.white,
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Colors.white70,
                size: 40,
              ),
            ),
          ),
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

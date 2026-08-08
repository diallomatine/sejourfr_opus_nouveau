import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

import '../../../core/api/api_config.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/question_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/audio_player.dart';

/// Affiche le média associé à une question TCF.
///
/// Sources gérées :
///   1. `media.inlineSvg` → SVG rendu en place (questions TCF dessinées en
///      migration Flyway).
///   2. `media.url` + `type` ∈ {AUDIO, IMAGE, VIDEO} → contenu distant.
class QuestionMediaView extends StatelessWidget {
  const QuestionMediaView({
    super.key,
    required this.media,
    this.examMode = false,
    this.maxPlays,
  });

  final MediaDto media;

  /// Active les conditions strictes d'un examen module sur le player audio
  /// (auto-play 0,5s, pas de pause). Ignoré pour image / vidéo.
  final bool examMode;

  /// Nombre maximum d'écoutes pour les audios (typiquement 1 en examen).
  /// Null = lectures illimitées.
  final int? maxPlays;

  @override
  Widget build(BuildContext context) {
    final hasUrl = media.url.isNotEmpty;
    // Priorité url > inlineSvg : le backend ne pose normalement que l'un des
    // deux, mais si les deux sont présents on rend l'image distante (cas
    // CO_IMAGE où l'image est servie depuis R2).
    if (media.hasInlineSvg && !hasUrl) {
      return _InlineSvgMedia(svg: media.inlineSvg!);
    }
    final url = ApiConfig.resolveMediaUrl(media.url);
    switch (media.type) {
      case MediaType.audio:
        return SejourAudioPlayer(
          url: url,
          examMode: examMode,
          maxPlays: maxPlays,
        );
      case MediaType.image:
        return _ImageMedia(url: url);
      case MediaType.video:
        return _VideoMedia(url: url);
    }
  }
}

// ---------------------------------------------------------------------------
// SVG inline (TCF compréhension écrite)
// ---------------------------------------------------------------------------

class _InlineSvgMedia extends StatelessWidget {
  const _InlineSvgMedia({required this.svg});
  final String svg;

  @override
  Widget build(BuildContext context) {
    final tag = identityHashCode(svg).toString();
    return _MediaFrame(
      heroTag: tag,
      onTap: () => Navigator.of(context).push(
        _MediaViewerRoute(child: _ZoomableSvg(svg: svg), heroTag: tag),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 360),
        child: SvgPicture.string(
          svg,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => const _MediaLoading(height: 220),
        ),
      ),
    );
  }
}

class _ZoomableSvg extends StatelessWidget {
  const _ZoomableSvg({required this.svg});
  final String svg;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      panEnabled: true,
      minScale: 1,
      maxScale: 5,
      child: Center(
        child: SvgPicture.string(svg, fit: BoxFit.contain),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Image distante
// ---------------------------------------------------------------------------

class _ImageMedia extends StatelessWidget {
  const _ImageMedia({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return _MediaFrame(
      heroTag: url,
      onTap: () => Navigator.of(context).push(
        _MediaViewerRoute(
          child: _ZoomableImage(url: url),
          heroTag: url,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 360, minHeight: 180),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            final value = progress.expectedTotalBytes == null
                ? null
                : progress.cumulativeBytesLoaded /
                    progress.expectedTotalBytes!;
            return _MediaLoading(value: value, height: 220);
          },
          errorBuilder: (_, __, ___) => const _MediaError(
            message: 'Image indisponible',
            icon: LucideIcons.imageOff,
          ),
        ),
      ),
    );
  }
}

class _ZoomableImage extends StatelessWidget {
  const _ZoomableImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      panEnabled: true,
      minScale: 1,
      maxScale: 5,
      child: Center(
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
                width: 36,
                height: 36,
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
              LucideIcons.imageOff,
              color: Colors.white70,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Container générique (cadre + tap "Agrandir")
// ---------------------------------------------------------------------------

class _MediaFrame extends StatelessWidget {
  const _MediaFrame({
    required this.child,
    required this.onTap,
    required this.heroTag,
  });

  final Widget child;
  final VoidCallback onTap;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Hero(
              tag: heroTag,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: child,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.zoomIn,
                        size: 12, color: AppColors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Agrandir',
                      style: AppFonts.mono(
                        size: 9,
                        color: AppColors.white,
                        letterSpacing: 1.4,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Viewer plein écran (image / SVG)
// ---------------------------------------------------------------------------

class _MediaViewerRoute<T> extends PageRoute<T> {
  _MediaViewerRoute({required this.child, required this.heroTag});

  final Widget child;
  final String heroTag;

  @override
  Color? get barrierColor => Colors.black;

  @override
  String? get barrierLabel => 'Fermer';

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return FadeTransition(
      opacity: animation,
      child: _FullscreenMediaViewer(heroTag: heroTag, child: child),
    );
  }
}

class _FullscreenMediaViewer extends StatelessWidget {
  const _FullscreenMediaViewer({required this.heroTag, required this.child});

  final String heroTag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Hero(tag: heroTag, child: child),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.white24,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(LucideIcons.x, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vidéo
// ---------------------------------------------------------------------------

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
      return const _MediaError(
        message: 'Vidéo indisponible',
        icon: LucideIcons.videoOff,
      );
    }
    if (!_ready) {
      return const _MediaLoading(height: 220);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: _ctrl.value.aspectRatio == 0
            ? 16 / 9
            : _ctrl.value.aspectRatio,
        child: _VideoSurface(
          controller: _ctrl,
          onFullscreen: () => _openFullscreen(context),
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenVideoPage(controller: _ctrl),
        fullscreenDialog: true,
      ),
    );
  }
}

class _VideoSurface extends StatefulWidget {
  const _VideoSurface({
    required this.controller,
    required this.onFullscreen,
    this.dark = false,
  });

  final VideoPlayerController controller;
  final VoidCallback onFullscreen;
  final bool dark;

  @override
  State<_VideoSurface> createState() => _VideoSurfaceState();
}

class _VideoSurfaceState extends State<_VideoSurface> {
  bool _controlsVisible = true;

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
  }

  void _togglePlay() {
    final c = widget.controller;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      if (c.value.position >= c.value.duration) {
        c.seekTo(Duration.zero);
      }
      c.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.black,
            child: Center(child: VideoPlayer(widget.controller)),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _controlsVisible ? 1 : 0,
            child: IgnorePointer(
              ignoring: !_controlsVisible,
              child: _VideoControlsOverlay(
                controller: widget.controller,
                onPlayPause: _togglePlay,
                onFullscreen: widget.onFullscreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoControlsOverlay extends StatelessWidget {
  const _VideoControlsOverlay({
    required this.controller,
    required this.onPlayPause,
    required this.onFullscreen,
  });

  final VideoPlayerController controller;
  final VoidCallback onPlayPause;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.05),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.55),
              ],
              stops: const [0, 0.55, 1],
            ),
          ),
        ),
        Center(
          child: ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              return Material(
                color: Colors.black.withValues(alpha: 0.55),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPlayPause,
                  child: Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    child: Icon(
                      value.isPlaying ? LucideIcons.pause : LucideIcons.play,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 8,
          child: ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12),
                      activeTrackColor: AppColors.red,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: AppColors.red,
                      overlayColor: AppColors.red.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      min: 0,
                      max: value.duration.inMilliseconds.toDouble().clamp(
                            1,
                            double.infinity,
                          ),
                      value: value.position.inMilliseconds
                          .clamp(0, value.duration.inMilliseconds)
                          .toDouble(),
                      onChanged: (v) {
                        controller.seekTo(Duration(milliseconds: v.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Text(
                          _fmt(value.position),
                          style: AppFonts.mono(
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _fmt(value.duration),
                          style: AppFonts.mono(
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: onFullscreen,
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              LucideIcons.maximize,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _FullscreenVideoPage extends StatefulWidget {
  const _FullscreenVideoPage({required this.controller});
  final VideoPlayerController controller;

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = widget.controller.value.aspectRatio == 0
        ? 16 / 9
        : widget.controller.value.aspectRatio;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: ratio,
                child: _VideoSurface(
                  controller: widget.controller,
                  onFullscreen: () => Navigator.of(context).pop(),
                  dark: true,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.white24,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(LucideIcons.x, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading / Error
// ---------------------------------------------------------------------------

class _MediaLoading extends StatelessWidget {
  const _MediaLoading({this.value, this.height = 200});
  final double? value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.line2,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          value: value,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
        ),
      ),
    );
  }
}

class _MediaError extends StatelessWidget {
  const _MediaError({required this.message, required this.icon});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.line2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.muted),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppFonts.ui(color: AppColors.muted, size: 12),
          ),
        ],
      ),
    );
  }
}

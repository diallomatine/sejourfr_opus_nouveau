import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';
import '../tcf_production_module.dart';
import 'production_blocks.dart';
import 'production_common.dart';
import 'preparation_points.dart';

/// Onglet « Exemples » de l'écran d'une tâche : les **modèles** corrigés, plus
/// la fiche de méthode.
///
/// Tout y prend l'accent du module (bleu à l'écrit, rouge à l'oral) : ces
/// cartes étaient rouges des deux côtés, y compris sur l'épreuve écrite.

/// Carte d'un modèle corrigé. Quand le modèle porte un audio (oral), la carte
/// intègre un lecteur inline ; sinon elle ouvre le corrigé rédigé.
class FeaturedExampleCard extends StatefulWidget {
  const FeaturedExampleCard({
    super.key,
    required this.example,
    required this.accent,
    required this.locked,
    required this.onOpen,
  });

  final ProductionExampleDto example;
  final Color accent;
  final bool locked;
  final VoidCallback onOpen;

  @override
  State<FeaturedExampleCard> createState() => _FeaturedExampleCardState();
}

class _FeaturedExampleCardState extends State<FeaturedExampleCard> {
  AudioPlayer? _player;
  bool _ready = false;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Exemple cadenassé (non-abonné, au-delà du 1er) : on ne charge même pas
    // l'audio — la carte affiche un état verrouillé qui ouvre le paywall.
    if (widget.locked) return;
    final url = widget.example.audioUrl;
    if (widget.example.hasAudio && url != null && url.isNotEmpty) {
      final player = AudioPlayer();
      _player = player;
      player.setUrl(url).then((d) {
        if (!mounted) return;
        setState(() {
          _ready = true;
          if (d != null) _dur = d;
        });
      }).catchError((_) {});
      player.durationStream.listen((d) {
        if (mounted && d != null) setState(() => _dur = d);
      });
      player.positionStream.listen((p) {
        if (mounted) setState(() => _pos = p);
      });
      player.playerStateStream.listen((state) {
        if (!mounted) return;
        // Fin de lecture : just_audio garde `playing == true` sur l'état
        // `completed` → on remet le lecteur au repos (bouton ▶ + barre à 0).
        if (state.processingState == ProcessingState.completed) {
          player.pause();
          player.seek(Duration.zero);
        }
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final player = _player;
    if (player == null) return;
    if (player.playing) {
      await player.pause();
    } else {
      if (player.processingState == ProcessingState.completed) {
        await player.seek(Duration.zero);
      }
      await player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final example = widget.example;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: AppColors.line),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.sparkles, size: 14, color: widget.accent),
                const SizedBox(width: 6),
                Text(
                  'EXEMPLE CORRIGÉ',
                  style: AppFonts.label(size: 10, color: widget.accent),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              example.titre,
              style: AppFonts.ui(size: 15, weight: FontWeight.w700, height: 1.3),
            ),
            const SizedBox(height: 11),
            if (widget.locked)
              _LockedExampleBar(isOral: example.hasAudio, onTap: widget.onOpen)
            else if (example.hasAudio)
              _buildPlayer()
            else
              _OutlineButton(
                icon: LucideIcons.fileText,
                label: 'Voir le corrigé',
                onTap: widget.onOpen,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    final playing = _player?.playing ?? false;
    final progress = _dur.inMilliseconds > 0
        ? (_pos.inMilliseconds / _dur.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _ready ? _toggle : null,
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _ready ? widget.accent : AppColors.muted2,
                shape: BoxShape.circle,
              ),
              child: _ready
                  ? Icon(
                      playing ? LucideIcons.pause : LucideIcons.play,
                      color: AppColors.white,
                      size: 20,
                    )
                  : const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: AppColors.line,
                    valueColor: AlwaysStoppedAnimation<Color>(widget.accent),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatClock(_pos),
                      style: AppFonts.ui(
                        size: 11,
                        color: AppColors.inkSoft,
                        weight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _formatClock(_dur),
                      style: AppFonts.ui(
                        size: 11,
                        color: AppColors.inkSoft,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatClock(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.ink),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.ui(size: 12, weight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barre « exemple réservé » affichée à la place du lecteur / du bouton
/// corrigé quand l'exemple est cadenassé. Tap → paywall.
class _LockedExampleBar extends StatelessWidget {
  const _LockedExampleBar({required this.isOral, required this.onTap});

  final bool isOral;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.surface3,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.lock,
                size: 17,
                color: AppColors.inkFaint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isOral
                    ? "Écoute réservée à l'abonnement Intégral"
                    : "Corrigé réservé à l'abonnement Intégral",
                style: AppFonts.ui(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.inkSoft,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const ProductionChevron(),
          ],
        ),
      ),
    );
  }
}

/// Carte « Méthode & formules-clés » → ouvre la fiche de méthode.
class StrategyCard extends StatelessWidget {
  const StrategyCard({super.key, required this.accent, required this.onTap});

  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onTap: onTap,
      borderColor: accent.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(LucideIcons.lightbulb, size: 23, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Méthode & formules-clés',
                    style: AppFonts.ui(size: 15, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Le plan en 3 points, à réutiliser sur tous les sujets.',
                    style: AppFonts.ui(
                      size: 12,
                      color: AppColors.inkSoft,
                      height: 1.38,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const ProductionChevron(),
          ],
        ),
      ),
    );
  }
}

/// Fiche de méthode : le plan d'aide en points (source `PreparationPoints`).
class PlanSheet extends StatelessWidget {
  const PlanSheet({super.key, required this.module, required this.tache});

  final TcfProductionModule module;
  final int tache;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SheetHandle(),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(
                    'Méthode & formules-clés',
                    style: AppFonts.display(size: 20),
                  ),
                  const SizedBox(height: 14),
                  PreparationPoints(isEo: module.isEo, tache: tache),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Détail d'un modèle : texte (écrit), audio (oral), explications, plan.
class ExampleDetailSheet extends StatefulWidget {
  const ExampleDetailSheet({
    super.key,
    required this.module,
    required this.example,
  });

  final TcfProductionModule module;
  final ProductionExampleDto example;

  @override
  State<ExampleDetailSheet> createState() => _ExampleDetailSheetState();
}

class _ExampleDetailSheetState extends State<ExampleDetailSheet> {
  final AudioPlayer _player = AudioPlayer();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final url = widget.example.audioUrl;
    if (url != null && url.isNotEmpty) {
      _player.setUrl(url).then((_) {
        if (mounted) setState(() => _ready = true);
      }).catchError((_) {});
      _player.playerStateStream.listen((state) {
        if (!mounted) return;
        // Fin de lecture : repasse le bouton sur « Écouter » au lieu de rester
        // bloqué sur « Pause » (just_audio garde `playing` à true en completed).
        if (state.processingState == ProcessingState.completed) {
          _player.pause();
          _player.seek(Duration.zero);
        }
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.example;
    final accent = widget.module.accent;
    final playing = _player.playing;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SheetHandle(),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                children: [
                  Text(ex.titre, style: AppFonts.display(size: 20)),
                  if (ex.resume != null) ...[
                    const SizedBox(height: 7),
                    Text(
                      ex.resume!,
                      style: AppFonts.ui(
                        size: 13,
                        color: AppColors.inkSoft,
                        height: 1.45,
                      ),
                    ),
                  ],
                  if (ex.hasAudio) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _ready ? _toggle : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _ready ? accent : AppColors.muted2,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              playing ? LucideIcons.pause : LucideIcons.play,
                              color: AppColors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              playing ? 'Pause' : 'Écouter le modèle',
                              style: AppFonts.ui(
                                size: 14,
                                weight: FontWeight.w900,
                                color: AppColors.white,
                              ),
                            ),
                            const Spacer(),
                            if (!_ready)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  // Oral : on n'affiche pas la transcription du dialogue, le
                  // candidat doit s'entraîner à l'écoute seule. Écrit : le
                  // texte EST le modèle, on le montre.
                  if (!widget.module.isEo) ...[
                    const SizedBox(height: 18),
                    Text(
                      'TEXTE DU MODÈLE',
                      style: AppFonts.label(size: 10, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(17),
                        border: Border(
                          left: BorderSide(color: accent, width: 4),
                        ),
                      ),
                      child: Text(
                        ex.contenu,
                        style: AppFonts.ui(
                          size: 14,
                          color: AppColors.ink2,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                  if (ex.explications != null &&
                      ex.explications!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ProductionNotice(
                      title: 'Ce qui fait la différence',
                      body: ex.explications!,
                      icon: LucideIcons.lightbulb,
                    ),
                  ],
                  if (ex.planPoints.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text('Plan rapide', style: AppFonts.display(size: 18)),
                    const SizedBox(height: 11),
                    for (final p in ex.planPoints) _PlanRow(text: p),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: const Icon(
              LucideIcons.check,
              size: 13,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppFonts.ui(size: 13, color: AppColors.ink2, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

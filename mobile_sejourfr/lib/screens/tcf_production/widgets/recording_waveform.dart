import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';

/// Seuil sous lequel une amplitude normalisée est du **bruit de fond**, pas de
/// la voix. `AudioRecorderService` normalise des dBFS de −60 (silence) à 0
/// (saturation) : une pièce calme se pose vers 0,15-0,25, une voix parlée
/// au-delà de 0,45.
const double _kNoiseFloor = 0.25;

/// Au-dessus de ce niveau, la forme d'onde est à son amplitude maximale.
const double _kVoiceCeiling = 0.80;

/// Ramène une amplitude brute 0..1 en **niveau de voix** 0..1, le bruit de fond
/// ramené à zéro.
///
/// Public parce qu'un écran peut avoir besoin du **même** verdict que la forme
/// d'onde (« est-ce qu'on entend quelqu'un ? ») : deux seuils divergents
/// diraient deux choses contradictoires sur le même instant.
double recordingVoiceLevel(double amplitude) =>
    ((amplitude - _kNoiseFloor) / (_kVoiceCeiling - _kNoiseFloor))
        .clamp(0.0, 1.0);

/// Waveform animee (33 barres) calquee sur `.waveform` du mockup HTML.
///
/// ⚠️ **Le mouvement suit la voix, il ne la simule pas.** La version d'origine
/// ajoutait une sinusoïde d'amplitude **fixe** : les barres ondulaient
/// exactement pareil qu'on parle ou qu'on se taise, et un micro muet (session
/// audio saisie par un lecteur, permission révoquée, casque mal branché) était
/// indiscernable d'un enregistrement qui marche. Le candidat parlait sans
/// savoir s'il était capté. La sinusoïde reste — elle donne la texture — mais
/// **son amplitude est pilotée par le niveau d'entrée réel** : silence ⇒ barres
/// quasi plates, voix ⇒ barres hautes et vivantes.
///
/// Un plancher de mouvement de quelques pixels est conservé : une forme d'onde
/// **figée** se lit comme une application plantée, pas comme un silence.
///
/// Sans donnée d'amplitude ([amplitude] `null`), on retombe sur l'ancien
/// mouvement décoratif : on n'a alors rien de plus honnête à montrer.
class RecordingWaveform extends StatefulWidget {
  const RecordingWaveform({
    super.key,
    this.amplitude,
    this.barCount = 33,
    this.color = AppColors.blue,
  });

  /// Amplitude normalisee 0..1. Si null, juste un mouvement decoratif.
  final double? amplitude;
  final int barCount;

  /// Couleur des barres (rouge pour l'EO, bleu par défaut).
  final Color color;

  @override
  State<RecordingWaveform> createState() => _RecordingWaveformState();
}

class _RecordingWaveformState extends State<RecordingWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  /// Mouvement réduit demandé par le système : la sinusoïde s'arrête, **pas la
  /// forme d'onde**. Les barres continuent de suivre l'amplitude réelle (elle
  /// arrive dix fois par seconde), donc le candidat voit toujours sa voix
  /// bouger — on retire l'ondulation décorative, jamais la preuve de capture.
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyMotionPreference(MediaQuery.disableAnimationsOf(context));
  }

  void _applyMotionPreference(bool reduce) {
    _reduceMotion = reduce;
    if (reduce) {
      if (_ctrl.isAnimating) _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _ctrl.value * 2 * math.pi;
          final raw = widget.amplitude;
          // Sans amplitude : mouvement décoratif d'origine, au bit près.
          final level = raw == null ? 0.35 : recordingVoiceLevel(raw);
          // Amplitude de la sinusoïde : fixe faute de mieux, sinon pilotée par
          // la voix, avec un plancher pour que la forme d'onde ne gèle jamais.
          final swing =
              _reduceMotion ? 0.0 : (raw == null ? 18.0 : 4.0 + level * 22.0);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (i) {
              // Hauteur = base + niveau de voix + variation sinusoidale.
              const base = 8.0;
              final wave = (math.sin(t + i * 0.55).abs()) * swing;
              final h = (base + level * 30.0 + wave).clamp(6.0, 62.0).toDouble();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  width: 3,
                  height: h,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Libellé gelé de la pastille d'état d'enregistrement.
const String kRecordingPillLabel = 'Enregistrement…';

/// La pastille « Enregistrement… », **point pulsant** : c'est elle qui dit au
/// candidat que la capture tourne vraiment.
///
/// Promue depuis `eo_briefing_screen` à sa **troisième** occurrence (briefing
/// EO, panneau de micro-exercice, oral du diagnostic). Les deux copies
/// tardives portaient un point **fixe** — donc muet : sur une image figée, rien
/// ne distingue « en cours » de « prêt à démarrer ». Ne pas en refaire une
/// quatrième.
class RecordingPill extends StatefulWidget {
  const RecordingPill({
    super.key,
    this.color = AppColors.red,
    this.background,
    this.label = kRecordingPillLabel,
  });

  /// Teinte du point et du texte.
  final Color color;

  /// Fond de la pastille ; par défaut une teinte à 12 % de [color], ce qui suit
  /// l'accent du module sans imposer un token de plus.
  final Color? background;

  final String label;

  @override
  State<RecordingPill> createState() => _RecordingPillState();
}

class _RecordingPillState extends State<RecordingPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  /// Sous mouvement réduit, le point reste **plein** au lieu de pulser : une
  /// pastille qui clignote en continu trois minutes durant est pénible, et
  /// c'est exactement ce que le réglage système demande d'éviter.
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      if (_ctrl.isAnimating) _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // C'est la pastille qui **annonce l'état** aux lecteurs d'écran, et elle le
    // fait avec un libellé constant : une `liveRegion` dont le texte porterait
    // le chrono serait relue cinq fois par seconde.
    return Semantics(
      liveRegion: true,
      label: kRecordingSemanticsLabel,
      excludeSemantics: true,
      child: _pill(),
    );
  }

  Widget _pill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: widget.background ?? widget.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: widget.color.withValues(
                  alpha: _reduceMotion ? 1.0 : 0.4 + _ctrl.value * 0.6,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: AppFonts.ui(
              size: 13,
              weight: FontWeight.w700,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ce que les lecteurs d'écran annoncent quand la capture démarre.
///
/// **Constant par construction** : porté par [RecordingPill] en `liveRegion`,
/// il est relu à chaque changement de texte. Y glisser le chrono le ferait
/// répéter cinq fois par seconde.
const String kRecordingSemanticsLabel = 'Enregistrement en cours';

/// Une durée dite à voix haute (« 1 minute 12 secondes »), pour les libellés
/// d'accessibilité — un lecteur d'écran lit « 1:12 » comme un nombre.
String recordingSpokenDuration(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds.remainder(60);
  final parts = <String>[];
  if (minutes > 0) parts.add('$minutes minute${minutes > 1 ? 's' : ''}');
  if (seconds > 0 || minutes == 0) {
    parts.add('$seconds seconde${seconds > 1 ? 's' : ''}');
  }
  return parts.join(' ');
}

/// Libellé d'accessibilité par défaut du cadran : ce qui est enregistré, sur
/// quel plafond.
String recordingTimeSemantics(Duration elapsed, Duration total) =>
    '${recordingSpokenDuration(elapsed)} enregistrées sur '
    '${recordingSpokenDuration(total)}';

/// Le cadran d'enregistrement : **un micro qui vit, entouré d'un chrono qui
/// avance**.
///
/// Motif, rapporté sur le diagnostic oral : « il faut que la personne se rende
/// compte qu'elle enregistre bien ». Rien n'était en panne — le ticker du
/// service tourne bel et bien — mais l'écran ne le **montrait** pas :
/// - le micro **disparaissait** au moment précis où l'on commence à parler (il
///   n'existait qu'à l'état de repos, en gros bouton bleu) ;
/// - le chrono s'affichait à la seconde alors que l'état est émis toutes les
///   200 ms : quatre tics sur cinq ne changeaient **rien** à l'écran, et un
///   compteur qui ne bouge pas se lit comme une application figée.
///
/// D'où les deux réponses, ensemble : le micro **reste** et **pulse**, et le
/// temps est doublé d'un **arc continu** qui progresse à chaque tic — donc
/// visiblement, cinq fois par seconde, sans ajouter un seul chiffre à lire.
/// Barre de qualité : si l'écran se fige, l'arc se fige avec lui, et ça se voit.
///
/// Le cadran ne formate rien : chaque surface passe son propre [timeLabel]
/// (l'oral en examen décompte, le diagnostic affiche « 0:12 / 3:00 »). Il ne
/// possède que la géométrie, la pulsation et l'accessibilité.
class RecordingGauge extends StatefulWidget {
  const RecordingGauge({
    super.key,
    required this.elapsed,
    required this.total,
    required this.timeLabel,
    this.sub,
    this.color = AppColors.red,
    this.timeColor = AppColors.ink,
    this.size = 132,
    this.depleting = false,
    this.timeSemantics,
  });

  /// Temps déjà capturé — pilote l'arc, jamais le texte.
  final Duration elapsed;

  /// Plafond de la capture (`RecordingState.maxDuration` ou la durée de la
  /// tâche). Nul ou négatif ⇒ aucun arc, le micro et le texte suffisent.
  final Duration total;

  /// Le chrono tel que la surface veut l'écrire (« 0:12 », « 02:47 »).
  final String timeLabel;

  /// Seconde ligne sous le chrono (« / 3:00 », « Temps restant »).
  final String? sub;

  /// Teinte du micro et de l'arc. Rouge par défaut : c'est la couleur
  /// d'enregistrement du produit, et elle le reste (cf. CLAUDE.md).
  final Color color;

  /// Couleur du chrono seul — l'oral libre la fait virer au vert une fois la
  /// durée minimale atteinte.
  final Color timeColor;

  final double size;

  /// En examen, le chrono décompte : l'arc **se vide** au lieu de se remplir,
  /// pour raconter la même chose que les chiffres.
  final bool depleting;

  /// Ce que le lecteur d'écran doit dire du temps. Par défaut
  /// [recordingTimeSemantics] ; le décompte d'examen passe le sien.
  final String? timeSemantics;

  @override
  State<RecordingGauge> createState() => _RecordingGaugeState();
}

class _RecordingGaugeState extends State<RecordingGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  /// Sous mouvement réduit, le halo cesse de battre. **L'arc, lui, continue** :
  /// il n'est pas une animation, c'est la donnée elle-même — l'éteindre
  /// reviendrait à masquer l'information qu'on est venu montrer.
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      if (_pulse.isAnimating) _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  double get _progress {
    final total = widget.total.inMilliseconds;
    if (total <= 0) return 0;
    final done = (widget.elapsed.inMilliseconds / total).clamp(0.0, 1.0);
    return widget.depleting ? 1.0 - done : done;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final stroke = (size * 0.05).clamp(5.0, 8.0).toDouble();
    final micSize = size * 0.26;

    return Semantics(
      label: widget.timeSemantics ??
          recordingTimeSemantics(widget.elapsed, widget.total),
      excludeSemantics: true,
      child: RepaintBoundary(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Le halo bat **derrière** l'arc et n'est reconstruit que lui :
              // trois minutes de capture ne doivent pas rebâtir le cadran à
              // chaque frame.
              Positioned.fill(
                child: _reduceMotion
                    ? _halo(0.18, 1.06)
                    : AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, __) {
                          final t = _pulse.value;
                          return _halo(0.22 * (1 - t), 1.0 + t * 0.16);
                        },
                      ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _RecordingGaugePainter(
                    progress: _progress,
                    color: widget.color,
                    stroke: stroke,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: micSize,
                    height: micSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.mic,
                      size: micSize * 0.52,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: size * 0.05),
                  Text(
                    widget.timeLabel,
                    style: AppFonts.display(
                      size: size * 0.24,
                      height: 1.0,
                      color: widget.timeColor,
                    ),
                  ),
                  if (widget.sub != null)
                    Padding(
                      padding: EdgeInsets.only(top: size * 0.02),
                      child: Text(
                        widget.sub!,
                        style: AppFonts.ui(
                          size: 12,
                          color: AppColors.inkFaint,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _halo(double alpha, double scale) => Transform.scale(
        scale: scale,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: alpha),
          ),
        ),
      );
}

class _RecordingGaugePainter extends CustomPainter {
  const _RecordingGaugePainter({
    required this.progress,
    required this.color,
    required this.stroke,
  });

  final double progress;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color.withValues(alpha: 0.16),
    );

    if (progress <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RecordingGaugePainter old) =>
      old.progress != progress || old.color != color || old.stroke != stroke;
}

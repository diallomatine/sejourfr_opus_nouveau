import 'dart:math' as math;

import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
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
          final swing = raw == null ? 18.0 : 4.0 + level * 22.0;
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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                color: widget.color.withValues(alpha: 0.4 + _ctrl.value * 0.6),
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

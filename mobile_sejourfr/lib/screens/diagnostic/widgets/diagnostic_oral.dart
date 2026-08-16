import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/audio_player.dart';
import '../../../core/widgets/fixed_action_bar.dart';
import '../../tcf_production/audio_recorder_service.dart';
import '../../tcf_production/widgets/recording_waveform.dart';
import 'diagnostic_common.dart';

class DiagnosticOralStep extends StatelessWidget {
  const DiagnosticOralStep({
    super.key,
    required this.exercise,
    required this.recording,
    required this.isSubmitting,
    required this.onStart,
    required this.onStop,
    required this.onReset,
    required this.onOpenSettings,
    required this.onSubmit,
    this.errorMessage,
    this.submitLabel = 'Envoyer mon oral',
  });

  final DiagnosticExerciseView exercise;
  final RecordingState recording;
  final bool isSubmitting;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;
  final VoidCallback onOpenSettings;
  final VoidCallback onSubmit;
  final String? errorMessage;

  /// En régime invité rien n'est envoyé : la production reste sur le
  /// téléphone jusqu'à la création du compte, le bouton ne doit donc pas
  /// promettre un envoi.
  final String submitLabel;

  int get _maxSeconds => exercise.durationMaxSeconds ?? 180;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const DiagnosticProgress(activeStep: 2, completedSteps: 1),
              const SizedBox(height: 14),
              DiagnosticExerciseCard(exercise: exercise),
              if (exercise.instructionAudioUrl != null) ...[
                const SizedBox(height: 14),
                SejourAudioPlayer(
                  url: exercise.instructionAudioUrl!,
                  label: 'Écouter la consigne',
                  icon: LucideIcons.volume2,
                ),
              ],
              const SizedBox(height: 16),
              _RecorderCard(
                recording: recording,
                maxSeconds: _maxSeconds,
                onReset: onReset,
              ),
              if (recording.errorMessage != null) ...[
                const SizedBox(height: 12),
                DiagnosticErrorBanner(message: recording.errorMessage!),
              ],
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                DiagnosticErrorBanner(message: errorMessage!),
              ],
            ],
          ),
        ),
        FixedActionBar(child: _action()),
      ],
    );
  }

  Widget _action() => switch (recording.phase) {
        RecordingPhase.requestingPermission => AppButton(
            label: 'Autorisation du micro…',
            isLoading: true,
            onPressed: null,
          ),
        RecordingPhase.recording || RecordingPhase.paused => AppButton(
            label: 'Terminer l’enregistrement',
            variant: AppButtonVariant.accent,
            icon: LucideIcons.square,
            onPressed: onStop,
          ),
        RecordingPhase.finished => AppButton(
            label: submitLabel,
            iconRight: LucideIcons.arrowRight,
            isLoading: isSubmitting,
            onPressed:
                recording.filePath != null && !isSubmitting ? onSubmit : null,
          ),
        RecordingPhase.failed => Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Réessayer',
                  variant: AppButtonVariant.soft,
                  height: 48,
                  onPressed: onStart,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'Réglages',
                  variant: AppButtonVariant.outline,
                  height: 48,
                  onPressed: onOpenSettings,
                ),
              ),
            ],
          ),
        RecordingPhase.idle => AppButton(
            label: 'Commencer l’enregistrement',
            icon: LucideIcons.mic,
            onPressed: onStart,
          ),
      };
}

class _RecorderCard extends StatelessWidget {
  const _RecorderCard({
    required this.recording,
    required this.maxSeconds,
    required this.onReset,
  });

  final RecordingState recording;
  final int maxSeconds;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: AppRadii.xl,
      padding: const EdgeInsets.all(18),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: switch (recording.phase) {
          RecordingPhase.recording || RecordingPhase.paused => Semantics(
              key: const ValueKey('recording'),
              liveRegion: true,
              label: 'Enregistrement en cours, ${_format(recording.elapsed)}',
              child: Column(
                children: [
                  const RecordingPill(
                    color: AppColors.red,
                    background: AppColors.redLight,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_format(recording.elapsed)} / ${_format(Duration(seconds: maxSeconds))}',
                    style: AppFonts.display(size: 26),
                  ),
                  RecordingWaveform(
                    amplitude: recording.lastAmplitude,
                    color: AppColors.blue,
                  ),
                  _VoiceHint(amplitude: recording.lastAmplitude),
                ],
              ),
            ),
          RecordingPhase.finished when recording.filePath != null => Column(
              key: const ValueKey('finished'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.greenLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.check,
                        size: 20,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Votre réponse est prête',
                        style: AppFonts.ui(
                          size: 15,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onReset,
                      child: Text(
                        'Refaire',
                        style: AppFonts.ui(
                          size: 13,
                          color: AppColors.blue,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SejourAudioPlayer(
                  url: recording.filePath!,
                  label: 'Réécouter ma réponse',
                  icon: LucideIcons.headphones,
                ),
              ],
            ),
          _ => Column(
              key: const ValueKey('idle'),
              children: [
                Semantics(
                  label: 'Microphone prêt',
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.md,
                    ),
                    child: const Icon(
                      LucideIcons.mic,
                      size: 34,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '2 à 3 minutes',
                  style: AppFonts.display(size: 20),
                ),
                const SizedBox(height: 5),
                Text(
                  'La prononciation fine n’est pas évaluée à partir de la transcription. '
                  'Ton enregistrement n’est pas conservé : il sert à produire la '
                  'transcription, puis il est supprimé.',
                  textAlign: TextAlign.center,
                  style: AppFonts.ui(
                    size: 12.5,
                    color: AppColors.inkFaint,
                    height: 1.4,
                  ),
                ),
              ],
            ),
        },
      ),
    );
  }

  static String _format(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// La ligne sous la forme d'onde : elle **dit franchement si on entend le
/// candidat**.
///
/// C'est la réponse au vrai symptôme rapporté — « j'ai l'impression de parler
/// sans m'en rendre compte ». Un chronomètre qui défile prouve qu'un compteur
/// tourne, pas qu'une voix est captée : micro saisi par un lecteur audio,
/// permission révoquée en cours de route, casque mal branché, et la capture
/// s'enregistre muette jusqu'au bout. Ici on le dit **pendant**, quand c'est
/// encore rattrapable, plutôt qu'après analyse.
///
/// Le verdict vient de [recordingVoiceLevel], le **même** seuil que celui qui
/// pilote la forme d'onde : la phrase ne peut pas contredire les barres.
/// Horloge **monotone** ([Stopwatch]), jamais `DateTime.now()`.
class _VoiceHint extends StatefulWidget {
  const _VoiceHint({required this.amplitude});

  /// Amplitude brute 0..1 remontée par le service, `null` tant qu'aucune mesure
  /// n'est arrivée — auquel cas on n'affirme rien.
  final double? amplitude;

  @override
  State<_VoiceHint> createState() => _VoiceHintState();
}

class _VoiceHintState extends State<_VoiceHint> {
  /// Le silence n'est signalé qu'au bout de ce délai : une pause pour réfléchir
  /// est normale à l'oral, et le public de l'app cherche ses mots.
  static const Duration _silenceGrace = Duration(seconds: 3);

  /// Au-dessus de ce niveau de voix, on considère que quelqu'un parle.
  static const double _audibleLevel = 0.06;

  final Stopwatch _sinceVoice = Stopwatch()..start();
  bool _unheard = false;

  @override
  void didUpdateWidget(covariant _VoiceHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    final amplitude = widget.amplitude;
    if (amplitude == null || recordingVoiceLevel(amplitude) > _audibleLevel) {
      _sinceVoice.reset();
    }
    final unheard = amplitude != null && _sinceVoice.elapsed >= _silenceGrace;
    // On ne reconstruit que quand le verdict bascule : l'amplitude arrive dix
    // fois par seconde.
    if (unheard != _unheard) setState(() => _unheard = unheard);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _unheard
          ? 'On ne vous entend pas. Rapprochez-vous du micro ou parlez plus '
              'fort.'
          : 'Parlez naturellement. Vous pourrez vous réécouter avant l’envoi.',
      textAlign: TextAlign.center,
      style: AppFonts.ui(
        size: 12.5,
        height: 1.35,
        color: _unheard ? AppColors.amberDark : AppColors.inkFaint,
        weight: _unheard ? FontWeight.w700 : FontWeight.w400,
      ),
    );
  }
}

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
  });

  final DiagnosticExercise exercise;
  final RecordingState recording;
  final bool isSubmitting;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;
  final VoidCallback onOpenSettings;
  final VoidCallback onSubmit;
  final String? errorMessage;

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
            label: 'Envoyer mon oral',
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.redLight,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      'ENREGISTREMENT',
                      style: AppFonts.label(color: AppColors.red),
                    ),
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
                  Text(
                    'Parlez naturellement. Vous pourrez vous réécouter avant l’envoi.',
                    textAlign: TextAlign.center,
                    style: AppFonts.ui(
                      size: 12.5,
                      color: AppColors.inkFaint,
                      height: 1.35,
                    ),
                  ),
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
                  'La prononciation fine n’est pas évaluée à partir de la transcription.',
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

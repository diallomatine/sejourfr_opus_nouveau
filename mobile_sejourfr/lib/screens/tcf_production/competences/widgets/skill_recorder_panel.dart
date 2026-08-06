import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../audio_recorder_service.dart';
import '../../widgets/recording_waveform.dart';

/// Zone de production **orale** d'un petit sujet : micro au repos, capture en
/// cours (chrono + onde), puis état terminé avec possibilité de refaire.
///
/// Le panneau ne décide de rien : la permission, le démarrage et l'arrêt sont
/// pilotés par l'écran, qui possède le `RecordingController`.
class SkillRecorderPanel extends StatelessWidget {
  const SkillRecorderPanel({
    super.key,
    required this.state,
    required this.accent,
    required this.recommendedSeconds,
    required this.onStart,
    required this.onStop,
    required this.onReset,
  });

  final RecordingState state;
  final Color accent;
  final int? recommendedSeconds;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;

  static String formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: switch (state.phase) {
        RecordingPhase.recording || RecordingPhase.paused => _recording(),
        RecordingPhase.finished when state.filePath != null => _finished(),
        RecordingPhase.requestingPermission => const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          ),
        _ => _idle(),
      },
    );
  }

  Widget _idle() {
    return Column(
      children: [
        Material(
          color: accent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onStart,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 88,
              height: 88,
              child: Icon(LucideIcons.mic, size: 34, color: AppColors.white),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Appuie pour t\'enregistrer',
          style: AppFonts.ui(size: 14.5, weight: FontWeight.w700),
        ),
        if (recommendedSeconds != null) ...[
          const SizedBox(height: 4),
          Text(
            'Durée conseillée : environ $recommendedSeconds secondes',
            style: AppFonts.ui(size: 12.5, color: AppColors.inkSoft),
          ),
        ],
        if (state.errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            state.errorMessage!,
            textAlign: TextAlign.center,
            style: AppFonts.ui(size: 12.5, color: AppColors.red),
          ),
        ],
      ],
    );
  }

  Widget _recording() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Text(
                'ENREGISTREMENT',
                style: AppFonts.label(size: 10.5, color: accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          formatDuration(state.elapsed),
          style: AppFonts.display(size: 40, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        RecordingWaveform(amplitude: state.lastAmplitude, color: accent),
        const SizedBox(height: 14),
        Material(
          color: accent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onStop,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 72,
              height: 72,
              child: Icon(LucideIcons.square, size: 26, color: AppColors.white),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Appuie sur stop quand tu as terminé',
          style: AppFonts.ui(size: 12.5, color: AppColors.inkSoft),
        ),
      ],
    );
  }

  Widget _finished() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.greenLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.check, size: 28, color: AppColors.green),
        ),
        const SizedBox(height: 12),
        Text(
          'Réponse enregistrée',
          style: AppFonts.ui(size: 15, weight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Durée : ${formatDuration(state.elapsed)}',
          style: AppFonts.ui(size: 12.5, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 14),
        AppButton(
          label: 'Réenregistrer',
          icon: LucideIcons.refreshCw,
          variant: AppButtonVariant.outline,
          height: 44,
          fullWidth: false,
          onPressed: onReset,
        ),
      ],
    );
  }
}

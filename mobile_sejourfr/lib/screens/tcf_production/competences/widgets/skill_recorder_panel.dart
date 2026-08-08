import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/audio_player.dart';
import '../../audio_recorder_service.dart';
import '../../widgets/production_blocks.dart';
import '../../widgets/recording_waveform.dart';

/// Zone de production **orale** d'un petit sujet : micro au repos, capture en
/// cours (chrono + onde), puis état terminé avec possibilité de refaire.
///
/// Le panneau ne décide de rien : la permission, le démarrage et l'arrêt sont
/// pilotés par l'écran, qui possède le `RecordingController`.
///
/// ⚠ **Il ne porte pas son propre cadre** : il vit dans la carte « Votre
/// réponse » (`SkillAnswerCard`), exactement là où l'écrit met son champ de
/// saisie. Lui redonner une bordure blanche referait une carte dans une carte.
class SkillRecorderPanel extends StatelessWidget {
  const SkillRecorderPanel({
    super.key,
    required this.state,
    required this.accent,
    required this.onStart,
    required this.onStop,
    required this.onReset,
  });

  final RecordingState state;
  final Color accent;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;

  /// `0:12` — **même format que le web** (`fmtTimer`) : minutes sans zéro de
  /// tête, secondes sur deux chiffres. Sert le gros chrono de la capture et le
  /// compteur du pied de la carte de réponse, qui affiche en plus la cible.
  static String formatDuration(Duration d) =>
      formatSeconds(d.inSeconds < 0 ? 0 : d.inSeconds);

  static String formatSeconds(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: switch (state.phase) {
        RecordingPhase.recording || RecordingPhase.paused => _recording(),
        RecordingPhase.finished when state.filePath != null =>
          _finished(state.filePath!),
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
              width: 76,
              height: 76,
              child: Icon(LucideIcons.mic, size: 30, color: AppColors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Appuie pour t\'enregistrer',
          style: AppFonts.ui(size: 14, weight: FontWeight.w700),
        ),
        // La durée conseillée n'est plus répétée ici : elle est déjà dans la
        // puce de longueur, au-dessus de la carte. La redire poussait la zone
        // de production sous la ligne de flottaison.
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

  /// Capture terminée : on **réécoute avant de valider**.
  ///
  /// Une coche et un bouton « Réenregistrer » ne suffisaient pas — sans
  /// réécoute, le candidat envoie à l'évaluation une production qu'il n'a pas
  /// entendue. Le lecteur est le `SejourAudioPlayer` partagé, monté sur le
  /// fichier **local** encore sur l'appareil (rien n'est envoyé à ce stade).
  Widget _finished(String filePath) {
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
        // La durée est affichée par le pied de la carte, à la place exacte du
        // compteur de mots de l'écrit — parité, et pas de doublon.
        const SizedBox(height: 12),
        SejourAudioPlayer(
          key: ValueKey(filePath),
          url: filePath,
          label: 'TA RÉPONSE',
          icon: LucideIcons.headphones,
          accent: accent,
          background: accent.withValues(alpha: 0.06),
        ),
        const SizedBox(height: 10),
        Text(
          'Réécoute ta réponse, refais-la ou envoie-la à l\'évaluation.',
          textAlign: TextAlign.center,
          style: AppFonts.ui(size: 12, height: 1.4, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 12),
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

/// L'avertissement de transcription de l'oral (spec §15), rendu **sous** le
/// panneau d'enregistrement pour ne pas repousser le micro.
///
/// C'est le garde-fou central de l'oral dans ce projet : la note se fonde sur
/// ce que la transcription contient, et le correcteur a interdiction d'évaluer
/// la prononciation, l'accent ou l'intonation. Le dire ici évite qu'un candidat
/// lise un retour « sur sa langue » en croyant qu'on a jugé sa voix.
class SkillTranscriptNotice extends StatelessWidget {
  const SkillTranscriptNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProductionNotice(
      title: 'Évaluation basée sur la transcription',
      body: 'La note porte sur le contenu et la langue (organisation, '
          'vocabulaire, grammaire) de ce que tu dis. La prononciation, '
          'l\'accent et l\'intonation ne sont pas évalués ici — ils compteront '
          'le jour de l\'examen, face à un examinateur.',
      tone: AppColors.blue,
      toneSoft: AppColors.blueLight,
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sejourfr_logo.dart';

/// Vue "Analyse en cours" affichee pendant qu'on attend la reponse du backend
/// (10-20 s en synchrone). Anime 4 etapes textuelles independamment de l'avance
/// reelle du serveur (cf. PRODUCTION_TASKS_SPEC_V2.md section 9).
///
/// Quand le backend repond plus vite, l'animation se met a jour des l'unmount.
/// Quand il met plus de temps, on reste bloque sur la derniere etape avec un
/// texte rassurant -> evite le syndrome du spinner sans feedback.
class EvaluationLoadingView extends StatefulWidget {
  const EvaluationLoadingView({super.key, this.includeTranscription = false});

  /// EO -> true (etape "Transcription" visible) ; EE -> false (on saute).
  final bool includeTranscription;

  @override
  State<EvaluationLoadingView> createState() => _EvaluationLoadingViewState();
}

class _EvaluationLoadingViewState extends State<EvaluationLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cocardeAnim;
  late final List<_Step> _steps;
  late final List<int> _durations;
  Timer? _ticker;
  int _stepIndex = 0;

  @override
  void initState() {
    super.initState();
    _cocardeAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _steps = [
      const _Step(label: 'Envoi de votre production', icon: LucideIcons.cloudUpload),
      if (widget.includeTranscription)
        const _Step(label: 'Transcription audio', icon: LucideIcons.audioLines),
      const _Step(label: 'Analyse pédagogique', icon: LucideIcons.brain),
      const _Step(label: 'Préparation de votre bilan', icon: LucideIcons.clipboardCheck),
    ];
    // Cadences indicatives (en secondes), recalibrees selon la vitesse reelle
    // si jamais on bascule en async un jour. Total ~18 s avec transcription,
    // ~12 s sans.
    _durations = widget.includeTranscription
        ? const [2, 6, 6, 4]
        : const [2, 6, 4];
    _startTicker();
  }

  void _startTicker() {
    int elapsed = 0;
    int cumul = _durations[0];
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed += 1;
      if (elapsed >= cumul && _stepIndex < _steps.length - 1) {
        _stepIndex += 1;
        cumul += _durations[_stepIndex];
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _cocardeAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _cocardeAnim,
                child: const Cocarde(size: 96),
              ),
              const SizedBox(height: 28),
              Text(
                'Analyse en cours',
                style: AppFonts.display(size: 22, weight: FontWeight.w700, color: AppColors.ink),
              ),
              const SizedBox(height: 6),
              Text(
                _stepIndex == _steps.length - 1
                    ? 'Encore quelques secondes…'
                    : 'Votre évaluation arrive juste après.',
                style: AppFonts.ui(size: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 28),
              ..._steps.asMap().entries.map((entry) {
                final i = entry.key;
                final step = entry.value;
                final status = i < _stepIndex
                    ? _StepStatus.done
                    : i == _stepIndex
                        ? _StepStatus.active
                        : _StepStatus.pending;
                return _StepTile(step: step, status: status);
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step {
  const _Step({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

enum _StepStatus { pending, active, done }

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step, required this.status});

  final _Step step;
  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == _StepStatus.active;
    final isDone = status == _StepStatus.done;
    final color = isDone
        ? AppColors.green
        : isActive
            ? AppColors.blue
            : AppColors.muted2;
    final bg = isDone
        ? AppColors.green.withValues(alpha: 0.10)
        : isActive
            ? AppColors.blueLight
            : AppColors.line2;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: isDone
                ? const Icon(LucideIcons.check, size: 18, color: AppColors.green)
                : isActive
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(step.icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.label,
              style: AppFonts.ui(
                size: 13,
                weight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
                color: isActive || isDone ? AppColors.ink : AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

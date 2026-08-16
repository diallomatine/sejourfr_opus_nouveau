import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';

/// Avancement d'une étape d'attente.
enum DiagnosticWaitState { done, active, pending }

class DiagnosticWaitStep {
  const DiagnosticWaitStep(this.label, this.state);

  final String label;
  final DiagnosticWaitState state;
}

/// Les étapes franchies pendant une attente longue (transfert des productions,
/// puis analyse). Sans elles le candidat ne voit qu'un rond qui tourne et ne
/// sait pas ce qui avance — c'est exactement le défaut corrigé côté web.
class DiagnosticWaitSteps extends StatelessWidget {
  const DiagnosticWaitSteps({super.key, required this.steps});

  final List<DiagnosticWaitStep> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            if (index != 0) const SizedBox(height: 12),
            _WaitStepRow(step: steps[index]),
          ],
        ],
      ),
    );
  }
}

class _WaitStepRow extends StatelessWidget {
  const _WaitStepRow({required this.step});

  final DiagnosticWaitStep step;

  @override
  Widget build(BuildContext context) {
    final label = switch (step.state) {
      DiagnosticWaitState.done => 'terminé',
      DiagnosticWaitState.active => 'en cours',
      DiagnosticWaitState.pending => 'à venir',
    };
    return Semantics(
      label: '${step.label}, $label',
      excludeSemantics: true,
      child: Row(
        children: [
          SizedBox(width: 22, height: 22, child: _marker()),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              step.label,
              style: AppFonts.ui(
                size: 13.5,
                weight: step.state == DiagnosticWaitState.active
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: step.state == DiagnosticWaitState.pending
                    ? AppColors.inkFaint
                    : AppColors.ink,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _marker() => switch (step.state) {
        DiagnosticWaitState.done => Container(
            decoration: const BoxDecoration(
              color: AppColors.greenLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.check,
              size: 13,
              color: AppColors.green,
            ),
          ),
        DiagnosticWaitState.active => const Padding(
            padding: EdgeInsets.all(3),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.blue,
            ),
          ),
        DiagnosticWaitState.pending => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line, width: 2),
            ),
          ),
      };
}

/// Construit les états d'une liste d'étapes à partir de l'index de celle qui
/// est en cours.
List<DiagnosticWaitStep> diagnosticWaitStepsFrom(
  List<String> labels,
  int activeIndex,
) =>
    [
      for (var index = 0; index < labels.length; index++)
        DiagnosticWaitStep(
          labels[index],
          index < activeIndex
              ? DiagnosticWaitState.done
              : index == activeIndex
                  ? DiagnosticWaitState.active
                  : DiagnosticWaitState.pending,
        ),
    ];

/// Compteur de temps écoulé, démarré à l'entrée dans l'état d'attente.
/// Horloge **monotone** (`Stopwatch`), jamais `DateTime.now()`.
class DiagnosticElapsed extends StatefulWidget {
  const DiagnosticElapsed({super.key, required this.builder});

  final Widget Function(BuildContext context, Duration elapsed) builder;

  @override
  State<DiagnosticElapsed> createState() => _DiagnosticElapsedState();
}

class _DiagnosticElapsedState extends State<DiagnosticElapsed> {
  final _stopwatch = Stopwatch()..start();
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = _stopwatch.elapsed);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _elapsed);
}

String formatDiagnosticElapsed(Duration elapsed) {
  final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
  final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class DiagnosticElapsedPill extends StatelessWidget {
  const DiagnosticElapsedPill({super.key, required this.elapsed});

  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Temps écoulé : ${elapsed.inMinutes} minutes '
          '${elapsed.inSeconds % 60} secondes',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.blueSoft,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: AppColors.line),
        ),
        child: Text(
          'TEMPS ÉCOULÉ · ${formatDiagnosticElapsed(elapsed)}',
          style: AppFonts.label(size: 11.5, color: AppColors.inkSoft),
        ),
      ),
    );
  }
}

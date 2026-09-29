import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import 'diagnostic_analysis_labels.dart';

/// Avancement d'une étape d'attente.
enum DiagnosticWaitState { done, active, pending }

class DiagnosticWaitStep {
  const DiagnosticWaitStep(this.label, this.state);

  final String label;
  final DiagnosticWaitState state;
}

/// La carte d'attente partagée par l'envoi des productions et par l'analyse :
/// sur-titre, titre, une phrase, les étapes RÉELLES, le temps écoulé en
/// discret, puis ce que l'appelant ajoute (réassurance, panneau, actions).
/// Miroir de `WaitCard` (`DiagnosticView.tsx`).
///
/// Le compteur démarre à l'ENTRÉE dans cette carte : horloge monotone
/// (`Stopwatch`), jamais `DateTime.now()`.
class DiagnosticWaitCard extends StatelessWidget {
  const DiagnosticWaitCard({
    super.key,
    required this.title,
    required this.lead,
    required this.steps,
    this.kicker,
    this.footer,
  });

  final String? kicker;
  final InlineSpan title;
  final String lead;
  final List<DiagnosticWaitStep> steps;

  /// Rendu sous le temps écoulé, reconstruit à chaque seconde.
  final List<Widget> Function(Duration elapsed)? footer;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: AppRadii.xl,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      child: _DiagnosticElapsed(
        builder: (context, elapsed) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (kicker != null) ...[
              Text(
                kicker!.toUpperCase(),
                style: AppFonts.label(size: 11, color: AppColors.blue),
              ),
              const SizedBox(height: 10),
            ],
            Text.rich(
              title,
              style: AppFonts.display(size: 26, height: 1.15),
            ),
            const SizedBox(height: 10),
            Text(
              lead,
              style: AppFonts.ui(
                size: 14.5,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            for (var index = 0; index < steps.length; index++) ...[
              if (index != 0) const SizedBox(height: 12),
              _WaitStepRow(step: steps[index]),
            ],
            const SizedBox(height: 18),
            _ElapsedLine(elapsed: elapsed),
            if (footer != null) ...footer!(elapsed),
          ],
        ),
      ),
    );
  }
}

/// Le titre de la carte avec son mot en emphase (rouge), comme le `<em>` des
/// titres du web.
InlineSpan diagnosticWaitTitle(String lead, String em, String tail) =>
    TextSpan(
      children: [
        TextSpan(text: '$lead '),
        TextSpan(text: em, style: const TextStyle(color: AppColors.red)),
        TextSpan(text: ' $tail'),
      ],
    );

class _WaitStepRow extends StatelessWidget {
  const _WaitStepRow({required this.step});

  final DiagnosticWaitStep step;

  @override
  Widget build(BuildContext context) {
    final state = switch (step.state) {
      DiagnosticWaitState.done => 'terminé',
      DiagnosticWaitState.active => 'en cours',
      DiagnosticWaitState.pending => 'à venir',
    };
    return Semantics(
      label: '${step.label}, $state',
      excludeSemantics: true,
      child: Row(
        children: [
          SizedBox(width: 22, height: 22, child: _marker()),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.label,
              style: AppFonts.ui(
                size: 14.5,
                weight: step.state == DiagnosticWaitState.active
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: step.state == DiagnosticWaitState.pending
                    ? AppColors.muted2
                    : AppColors.ink,
                height: 1.35,
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
              size: 12,
              color: AppColors.green,
            ),
          ),
        DiagnosticWaitState.active => const CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.blue,
            backgroundColor: AppColors.blueLight,
          ),
        DiagnosticWaitState.pending => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line, width: 2),
            ),
          ),
      };
}

class _ElapsedLine extends StatelessWidget {
  const _ElapsedLine({required this.elapsed});

  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$kDiagnosticElapsedLabel : ${elapsed.inMinutes} minutes '
          '${elapsed.inSeconds % 60} secondes',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '${kDiagnosticElapsedLabel.toUpperCase()} · '),
            TextSpan(
              text: _format(elapsed),
              style: const TextStyle(
                color: AppColors.ink,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        style: AppFonts.label(size: 11, color: AppColors.muted),
      ),
    );
  }

  static String _format(Duration elapsed) {
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _DiagnosticElapsed extends StatefulWidget {
  const _DiagnosticElapsed({required this.builder});

  final Widget Function(BuildContext context, Duration elapsed) builder;

  @override
  State<_DiagnosticElapsed> createState() => _DiagnosticElapsedState();
}

class _DiagnosticElapsedState extends State<_DiagnosticElapsed> {
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

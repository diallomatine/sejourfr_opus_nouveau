import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/query_propagation.dart';
import 'audio_recorder_service.dart';
import 'eo_session_controller.dart';
import 'widgets/production_app_header.dart';
import 'widgets/production_progress_strip.dart';
import 'widgets/recording_waveform.dart';

/// Ecran 02 du mockup : enregistrement en cours.
/// Demarre automatiquement la capture au mount, auto-stop a maxDuration,
/// stop manuel via le gros bouton rouge.
class EoRecordingScreen extends ConsumerStatefulWidget {
  const EoRecordingScreen({super.key, required this.taskIndex});

  final int taskIndex;

  @override
  ConsumerState<EoRecordingScreen> createState() => _EoRecordingScreenState();
}

class _EoRecordingScreenState extends ConsumerState<EoRecordingScreen> {
  bool _autoStarted = false;
  bool _autoFinishedNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoStart());
  }

  Future<void> _autoStart() async {
    if (_autoStarted) return;
    _autoStarted = true;
    final session = ref.read(eoSessionProvider).value;
    final task = session?.taskAt(widget.taskIndex);
    if (task == null) return;
    final maxSec = task.dureeMaxSec ?? 180;
    await ref.read(recordingControllerProvider.notifier).start(maxDuration: Duration(seconds: maxSec));
  }

  Future<void> _stopAndContinue(BuildContext context) async {
    await ref.read(recordingControllerProvider.notifier).stop();
    if (!context.mounted) return;
    context.pushReplacement(
      withCurrentQuery(
        context,
        '/tcf/expression-orale/t/${widget.taskIndex}/termine',
      ),
    );
  }

  String _fallbackRouteFor(BuildContext context) {
    final fullExamId =
        GoRouterState.of(context).uri.queryParameters['fullExamId'];
    return fullExamId != null
        ? '/tcf/examen-blanc/$fullExamId'
        : '/tcf/eo';
  }

  Future<bool> _confirmQuit(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter l\'enregistrement ?'),
        content: const Text(
          'Votre enregistrement en cours sera perdu et la session reprise depuis le briefing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Quitter',
              style: AppFonts.jakarta(weight: FontWeight.w700, color: AppColors.red),
            ),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(eoSessionProvider).value;
    final task = session?.taskAt(widget.taskIndex);
    final rec = ref.watch(recordingControllerProvider);

    // Auto-navigate vers "termine" quand l'enregistrement s'arrete tout seul
    // (cas du timer qui atteint maxDuration cote service).
    ref.listen(recordingControllerProvider, (prev, next) {
      if (!_autoFinishedNavigated &&
          (prev?.phase != RecordingPhase.finished) &&
          next.phase == RecordingPhase.finished) {
        _autoFinishedNavigated = true;
        if (context.mounted) {
          context.pushReplacement(
            withCurrentQuery(
              context,
              '/tcf/expression-orale/t/${widget.taskIndex}/termine',
            ),
          );
        }
      }
    });

    if (task == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmQuit(context)) {
          await ref.read(recordingControllerProvider.notifier).cancel();
          if (!context.mounted) return;
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(_fallbackRouteFor(context));
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: ProductionAppHeader(
          title: 'Expression orale',
          fallbackRoute: _fallbackRouteFor(context),
          rightAction: ProductionAppHeaderQuit(
            onPressed: () async {
              if (await _confirmQuit(context)) {
                await ref.read(recordingControllerProvider.notifier).cancel();
                if (!context.mounted) return;
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(_fallbackRouteFor(context));
                }
              }
            },
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              ProductionProgressStrip(
                current: widget.taskIndex + 1,
                total: session!.totalTasks,
                niveau: task.niveauCible,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Enregistrement en cours',
                        style: AppFonts.jakarta(
                          size: 18,
                          weight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _TimerBig(
                        elapsed: rec.elapsed,
                        max: rec.maxDuration,
                      ),
                      const SizedBox(height: 12),
                      RecordingWaveform(amplitude: rec.lastAmplitude),
                      const SizedBox(height: 18),
                      const _RecStatusPill(),
                      const SizedBox(height: 18),
                      const _ConseilCallout(
                        text: 'Prenez votre temps, respirez et parlez naturellement.',
                      ),
                      const Spacer(),
                      _StopButton(onPressed: () => _stopAndContinue(context)),
                      const SizedBox(height: 6),
                      Text(
                        'Terminer',
                        style: AppFonts.jakarta(
                          size: 14,
                          weight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerBig extends StatelessWidget {
  const _TimerBig({required this.elapsed, required this.max});

  final Duration elapsed;
  final Duration max;

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _fmt(elapsed),
          style: AppFonts.jakarta(
            size: 56,
            weight: FontWeight.w700,
            color: AppColors.ink,
            height: 1.0,
          ).copyWith(letterSpacing: -1.0),
        ),
        const SizedBox(height: 4),
        Text(
          '/ ${_fmt(max)}',
          style: AppFonts.jakarta(
            size: 14,
            color: AppColors.muted2,
          ),
        ),
      ],
    );
  }
}

class _RecStatusPill extends StatefulWidget {
  const _RecStatusPill();

  @override
  State<_RecStatusPill> createState() => _RecStatusPillState();
}

class _RecStatusPillState extends State<_RecStatusPill> with SingleTickerProviderStateMixin {
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
        color: AppColors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final opacity = 0.4 + (_ctrl.value * 0.6);
              return Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            'Enregistrement...',
            style: AppFonts.jakarta(
              size: 13,
              weight: FontWeight.w600,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConseilCallout extends StatelessWidget {
  const _ConseilCallout({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Conseil  ',
                    style: AppFonts.jakarta(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.blue,
                    ),
                  ),
                  TextSpan(
                    text: text,
                    style: AppFonts.jakarta(
                      size: 13,
                      color: AppColors.ink,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.red, width: 3),
          ),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.red,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}

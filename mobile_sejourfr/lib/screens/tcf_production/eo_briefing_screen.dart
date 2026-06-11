import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/production_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/query_propagation.dart';
import '../../core/widgets/app_button.dart';
import 'audio_recorder_service.dart';
import 'eo_session_controller.dart';
import 'widgets/consigne_card.dart';
import 'widgets/production_app_header.dart';
import 'widgets/production_progress_strip.dart';
import 'widgets/recording_waveform.dart';

/// Écran unique EO « briefing + enregistrement » : la consigne reste affichée,
/// le tap sur le micro lance la capture **sur place** (pas de page
/// intermédiaire). À l'arrêt (manuel ou auto-stop à `dureeMaxSec`), on pousse
/// l'écran « terminé » (réécoute + soumission → évaluation).
class EoBriefingScreen extends ConsumerStatefulWidget {
  const EoBriefingScreen({super.key, required this.taskIndex});

  final int taskIndex;

  @override
  ConsumerState<EoBriefingScreen> createState() => _EoBriefingScreenState();
}

class _EoBriefingScreenState extends ConsumerState<EoBriefingScreen> {
  bool _requestingPerm = false;
  bool _navigated = false;

  String _niveauForUser() {
    final auth = ref.read(authControllerProvider);
    if (auth is AuthAuthenticated) {
      final tp = auth.user.targetProcedure;
      if (tp != null) return tp.tcfLevel;
    }
    return 'B1';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Repart toujours d'un enregistreur au repos : évite qu'un état
      // `finished`/`recording` résiduel d'une tâche précédente ne déclenche
      // une navigation ou n'affiche l'UI d'enregistrement à l'ouverture.
      ref.read(recordingControllerProvider.notifier).cancel();

      // Contexte examen blanc complet : sous-attempt EO déjà créé par le
      // backend, on le reprend au lieu d'en créer un nouveau.
      final goState = GoRouterState.of(context);
      final fullExamId = goState.uri.queryParameters['fullExamId'];
      final subAttemptId = goState.uri.queryParameters['subAttemptId'];
      if (fullExamId != null && subAttemptId != null) {
        ref.read(eoSessionProvider.notifier).startInFullExam(
              subAttemptId: subAttemptId,
              niveau: _niveauForUser(),
            );
      } else {
        // Une session déjà en cours (ex: sujet unique lancé via startSingle
        // depuis la fiche) est respectée — on ne la remplace pas par un
        // examen 3-tâches. On ne démarre que s'il n'y a rien (deep-link).
        final current = ref.read(eoSessionProvider).value;
        if (current == null || !current.isStarted || current.isCompleted) {
          ref.read(eoSessionProvider.notifier).start(niveau: _niveauForUser());
        }
      }
    });
  }

  /// Demande la permission micro puis démarre la capture sur place.
  Future<void> _startRecording() async {
    final recorder = ref.read(recordingControllerProvider.notifier);
    setState(() => _requestingPerm = true);
    final status = await recorder.requestPermission();
    if (!mounted) return;
    setState(() => _requestingPerm = false);
    if (!status.isGranted) {
      // Refus -- 1re fois OU deja "permanently denied" : dans les deux cas on
      // propose un detour par les Reglages systeme (sur iOS, request() ne
      // re-pop jamais le dialog apres un premier refus).
      _showPermissionDeniedSheet(context, status);
      return;
    }
    final task = ref.read(eoSessionProvider).value?.taskAt(widget.taskIndex);
    final maxSec = task?.dureeMaxSec ?? 180;
    await recorder.start(maxDuration: Duration(seconds: maxSec));
  }

  Future<void> _stop() async {
    // L'arrêt fait passer le service en `finished` → le listener navigue.
    await ref.read(recordingControllerProvider.notifier).stop();
  }

  void _goToFinished() {
    if (_navigated || !mounted) return;
    _navigated = true;
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
    return fullExamId != null ? '/tcf/examen-blanc/$fullExamId' : '/tcf/eo';
  }

  Future<bool> _confirmQuit(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter l\'enregistrement ?'),
        content: const Text(
          'Votre enregistrement en cours sera perdu.',
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
              style: AppFonts.ui(weight: FontWeight.w700, color: AppColors.red),
            ),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _quitRecording(BuildContext context) async {
    if (!await _confirmQuit(context)) return;
    await ref.read(recordingControllerProvider.notifier).cancel();
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_fallbackRouteFor(context));
    }
  }

  void _showPermissionDeniedSheet(
      BuildContext context, PermissionStatus status) {
    final canOpenSettings =
        status.isPermanentlyDenied || status.isDenied || status.isRestricted;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Acces au microphone requis'),
        content: Text(
          status.isPermanentlyDenied
              ? "Vous avez refuse l'acces au microphone. "
                  'Activez-le dans les Reglages > Confidentialite > Microphone > SejourFR.'
              : "SejourFR a besoin d'acceder au microphone pour vous entrainer "
                  "a l'expression orale.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard'),
          ),
          if (canOpenSettings)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref
                    .read(recordingControllerProvider.notifier)
                    .openSystemSettings();
              },
              child: const Text('Ouvrir les Reglages'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(eoSessionProvider);
    final rec = ref.watch(recordingControllerProvider);
    final isRecording = rec.phase == RecordingPhase.recording ||
        rec.phase == RecordingPhase.paused;

    // Auto-navigation vers « terminé » dès que la capture s'arrête (stop manuel
    // ou auto-stop du timer à maxDuration côté service).
    ref.listen(recordingControllerProvider, (prev, next) {
      if (next.phase == RecordingPhase.finished &&
          prev?.phase != RecordingPhase.finished) {
        _goToFinished();
      }
    });

    final fallbackRoute = _fallbackRouteFor(context);

    return PopScope(
      canPop: !isRecording,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _quitRecording(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: ProductionAppHeader(
          title: 'Expression orale',
          fallbackRoute: fallbackRoute,
          // Pendant la capture, la flèche retour passe par la confirmation
          // d'abandon (sinon un pop direct perdrait l'enregistrement).
          onBack: isRecording ? () => _quitRecording(context) : null,
        ),
        body: sessionAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorBox(
            message: ApiClient.toApiException(e).message,
            onRetry: () {
              final goState = GoRouterState.of(context);
              final fullExamId = goState.uri.queryParameters['fullExamId'];
              final subAttemptId = goState.uri.queryParameters['subAttemptId'];
              if (fullExamId != null && subAttemptId != null) {
                ref.read(eoSessionProvider.notifier).startInFullExam(
                      subAttemptId: subAttemptId,
                      niveau: _niveauForUser(),
                    );
              } else {
                ref
                    .read(eoSessionProvider.notifier)
                    .start(niveau: _niveauForUser());
              }
            },
          ),
          data: (session) {
            final task = session.taskAt(widget.taskIndex);
            if (!session.isStarted || task == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return SafeArea(
              top: false,
              child: Column(
                children: [
                  ProductionProgressStrip(
                    current: widget.taskIndex + 1,
                    total: session.totalTasks,
                    niveau: task.niveauCible,
                  ),
                  if (isRecording)
                    Expanded(
                        child:
                            _RecordingView(task: task, rec: rec, onStop: _stop))
                  else
                    Expanded(child: _IdleView(task: task)),
                  if (!isRecording)
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        border: Border(
                          top: BorderSide(color: AppColors.line2, width: 1),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      child: SafeArea(
                        top: false,
                        child: _MicStartButton(
                          loading: _requestingPerm,
                          onPressed:
                              _requestingPerm ? null : _startRecording,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

}

String _durationLabel(int? sec) {
  if (sec == null || sec <= 0) return 'Durée libre';
  final mins = sec ~/ 60;
  final remain = sec % 60;
  if (remain == 0) return 'Durée attendue : $mins minutes';
  return 'Durée attendue : $mins min $remain s';
}

/// Phase « idle » : consigne complète + invite à parler. Le gros micro vit dans
/// le panneau bas (`_MicStartButton`).
class _IdleView extends StatelessWidget {
  const _IdleView({required this.task});

  final ProductionTaskDto task;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
      children: [
        ConsigneCard(
          consigne: task.consigne,
          subTitleHero: task.displayTitle,
          subtitle: _durationLabel(task.dureeMaxSec),
          accent: AppColors.red,
          soft: AppColors.redLight,
        ),
      ],
    );
  }
}

/// Phase « recording » : consigne compacte épinglée + timer + waveform + stop.
class _RecordingView extends StatelessWidget {
  const _RecordingView({
    required this.task,
    required this.rec,
    required this.onStop,
  });

  final ProductionTaskDto task;
  final RecordingState rec;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Consigne complète, scrollable avec le timer/waveform — le bouton stop
        // reste épinglé en bas pour rester toujours atteignable.
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ConsigneCard(
                  consigne: task.consigne,
                  accent: AppColors.red,
                  soft: AppColors.redLight,
                ),
                const SizedBox(height: 12),
                const _RecStatusPill(),
                const SizedBox(height: 20),
                _TimerBig(
                  elapsed: rec.elapsed,
                  max: rec.maxDuration,
                  minSec: task.dureeMinSec ?? 120,
                ),
                const SizedBox(height: 20),
                RecordingWaveform(
                  amplitude: rec.lastAmplitude,
                  color: AppColors.red,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StopButton(onPressed: onStop),
              const SizedBox(height: 8),
              Text(
                'Terminer',
                style: AppFonts.ui(
                  size: 14,
                  weight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// CTA "idle" calqué sur le studio d'enregistrement du template : gros bouton
/// micro rond + invite à parler. Tap → demande la permission puis démarre la
/// capture sur place.
class _MicStartButton extends StatelessWidget {
  const _MicStartButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.redLight, spreadRadius: 8),
                ],
              ),
              child: loading
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : const Icon(LucideIcons.mic,
                      size: 38, color: AppColors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Appuyez pour vous enregistrer',
          style: AppFonts.ui(
            size: 16,
            weight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Autorisez le micro, puis parlez naturellement.',
          textAlign: TextAlign.center,
          style: AppFonts.ui(size: 13, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _TimerBig extends StatelessWidget {
  const _TimerBig({
    required this.elapsed,
    required this.max,
    required this.minSec,
  });

  final Duration elapsed;
  final Duration max;

  /// Minimum conseillé en secondes (typiquement 120 = 2 min).
  final int minSec;

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _timerColor {
    final secs = elapsed.inSeconds;
    if (secs < minSec) return AppColors.red;
    if (secs < max.inSeconds) return AppColors.amber;
    return AppColors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _fmt(elapsed),
          style: AppFonts.display(size: 56, color: _timerColor, height: 1.0),
        ),
        const SizedBox(height: 4),
        Text(
          '/ ${_fmt(max)}',
          style: AppFonts.ui(
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

class _RecStatusPillState extends State<_RecStatusPill>
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
        color: AppColors.redLight,
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
                  color: AppColors.red.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            'Enregistrement…',
            style: AppFonts.ui(
              size: 13,
              weight: FontWeight.w700,
              color: AppColors.red,
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
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppColors.redLight, spreadRadius: 8),
            ],
          ),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.circleAlert, size: 32, color: AppColors.red),
          const SizedBox(height: 8),
          Text(
            'Impossible de demarrer la session.',
            style: AppFonts.ui(
              size: 14,
              weight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.ui(size: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Reessayer',
            onPressed: onRetry,
            icon: LucideIcons.refreshCw,
          ),
        ],
      ),
    );
  }
}

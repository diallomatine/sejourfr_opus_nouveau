import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/production_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/query_propagation.dart';
import '../../core/widgets/app_button.dart';
import '../tcf_full_exam/full_tcf_exam_provider.dart';
import 'audio_recorder_service.dart';
import 'eo_session_controller.dart';
import 'realtime/realtime_eo_controller.dart';
import 'realtime/realtime_launch.dart';
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
  bool _submittingExam = false;

  /// Garde : l'offre « temps réel vs classique » n'est proposée qu'une fois par
  /// tâche (par instance d'écran). `_negotiating` couvre la phase d'attente
  /// (quota + modal + démarrage de session) par un loader plein écran.
  bool _realtimeHandled = false;
  bool _negotiating = false;

  /// Examen : timer déterministe possédé par l'écran qui force l'arrêt + la
  /// soumission quand le temps imparti à la tâche est écoulé — indépendant du
  /// ticker interne du `AudioRecorderService` et du `ref.listen` (constaté : à
  /// la 3e tâche EO, l'auto-stop du service ne déclenchait pas la soumission).
  Timer? _examAutoStop;

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
        ref
            .read(eoSessionProvider.notifier)
            .startInFullExam(subAttemptId: subAttemptId);
      }
      // Sinon : la session (examen module via `startExam`, ou sujet unique via
      // `startSingle`) est déjà démarrée par l'écran appelant ; on la respecte.
      // Aucun fallback `start()` ici — un deep-link nu sur cette route sans
      // session active affiche l'erreur "session introuvable".

      // Examen : propose le mode examinateur temps réel pour T1/T2. Module exam
      // → session déjà prête ici ; full exam → via le listener au chargement.
      _ensureRealtimeOffer();
    });
  }

  @override
  void dispose() {
    _examAutoStop?.cancel();
    super.dispose();
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
    final session = ref.read(eoSessionProvider).value;
    final task = session?.taskAt(widget.taskIndex);
    final maxSec = task?.dureeMaxSec ?? 180;
    await recorder.start(maxDuration: Duration(seconds: maxSec));
    if (!mounted) return;
    // Examen : filet déterministe. Le service auto-stoppe aussi via son ticker,
    // mais on ne s'y fie pas — ce timer garantit l'auto-soumission « dès que le
    // temps d'enregistrement finit ». Idempotent (one-shot + garde `_navigated`).
    _examAutoStop?.cancel();
    if (session?.isExam ?? false) {
      _examAutoStop = Timer(Duration(seconds: maxSec), () {
        if (mounted) _forceExamSubmit();
      });
    }
  }

  Future<void> _stop() async {
    _examAutoStop?.cancel();
    // L'arrêt fait passer le service en `finished` → le listener navigue.
    await ref.read(recordingControllerProvider.notifier).stop();
  }

  /// Fin du temps imparti en examen : stoppe la capture si le service ne l'a pas
  /// déjà fait, puis déclenche la soumission via [_onCaptureFinished]. Bypasse
  /// le `ref.listen` (qui dépend du cycle de build) pour être robuste.
  Future<void> _forceExamSubmit() async {
    if (_navigated || !mounted) return;
    final rec = ref.read(recordingControllerProvider);
    if (rec.phase == RecordingPhase.recording ||
        rec.phase == RecordingPhase.paused) {
      await ref.read(recordingControllerProvider.notifier).stop();
      if (!mounted) return;
    }
    _onCaptureFinished();
  }

  /// Capture terminée (stop manuel ou auto-stop à `dureeMaxSec`).
  /// - **Entraînement libre** : push l'écran `eo_finished_screen` (réécoute +
  ///   soumission manuelle).
  /// - **Examen** (module ou complet) : pas de réécoute — on soumet
  ///   immédiatement et on passe à la tâche suivante (fidèle au vrai TCF).
  void _onCaptureFinished() {
    if (_navigated || !mounted) return;
    _examAutoStop?.cancel();
    final session = ref.read(eoSessionProvider).value;
    if (session != null && session.isExam) {
      _navigated = true;
      _submitExamAndAdvance();
      return;
    }
    _navigated = true;
    context.pushReplacement(
      withCurrentQuery(
        context,
        '/tcf/expression-orale/t/${widget.taskIndex}/termine',
      ),
    );
  }

  /// Propose le mode examinateur temps réel pour une tâche T1/T2 d'examen, une
  /// seule fois par écran. No-op hors examen / hors T1-T2 / si déjà proposé.
  void _ensureRealtimeOffer() {
    if (_realtimeHandled || !mounted) return;
    final session = ref.read(eoSessionProvider).value;
    if (session == null || !session.isStarted || !session.isExam) return;
    final task = session.taskAt(widget.taskIndex);
    if (task == null) return;
    final t = task.tacheNumero;
    if (t != 1 && t != 2) return;
    _realtimeHandled = true;
    _offerRealtime(session, task);
  }

  /// Négocie le mode (modal §2.3). En « temps réel », lance la session sur
  /// l'attempt de l'examen ; à la clôture (le backend a créé la submission), on
  /// avance comme après une soumission audio. Classique / annulé / échec →
  /// l'écran affiche l'enregistrement habituel pour cette tâche.
  Future<void> _offerRealtime(
      EoSessionState session, ProductionTaskDto task) async {
    final attemptId = session.attempt?.id;
    if (attemptId == null) return;
    setState(() => _negotiating = true);
    final negotiation = await negotiateRealtimeSession(
      context,
      ref,
      productionTaskId: task.id,
      // Examen : on réutilise l'attempt de la session (pas de création).
      resolveAttemptId: () async => attemptId,
    );
    if (!mounted) return;
    if (negotiation.decision != RealtimeDecision.realtime ||
        negotiation.descriptor == null) {
      setState(() => _negotiating = false);
      return;
    }
    final done = await context.push<bool>(
      '/tcf/expression-orale/realtime',
      extra: RealtimeRunnerArgs(
        descriptor: negotiation.descriptor!,
        task: task,
        attemptId: attemptId,
        popOnDone: true,
      ),
    );
    if (!mounted) return;
    if (done == true) {
      _navigated = true;
      setState(() => _submittingExam = true);
      await _advanceExamFlow();
    } else {
      // Temps réel échoué/abandonné → enregistrement classique pour la tâche.
      setState(() => _negotiating = false);
    }
  }

  /// Soumission immédiate de l'audio courant en mode examen + passage direct à
  /// la tâche suivante (ou bilan après T3). Pas d'écran de réécoute.
  Future<void> _submitExamAndAdvance() async {
    final rec = ref.read(recordingControllerProvider);
    final path = rec.filePath;
    if (path == null || !mounted) return;
    setState(() => _submittingExam = true);

    try {
      await ref.read(eoSessionProvider.notifier).submitTask(
            taskIndex: widget.taskIndex,
            audioFile: File(path),
            mimeType: rec.fileMime ?? 'audio/wav',
          );
    } catch (e) {
      if (!mounted) return;
      // Échec réseau : on autorise une nouvelle tentative (réécoute via le
      // flux finished standard) plutôt que de perdre l'enregistrement.
      _navigated = false;
      setState(() => _submittingExam = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiClient.toApiException(e).message),
          backgroundColor: AppColors.red,
        ),
      );
      context.pushReplacement(
        withCurrentQuery(
          context,
          '/tcf/expression-orale/t/${widget.taskIndex}/termine',
        ),
      );
      return;
    }
    if (!mounted) return;
    await _advanceExamFlow();
  }

  /// Enchaîne après qu'une tâche d'examen a été rendue — soit par soumission
  /// audio, soit par clôture d'une session temps réel (la submission est alors
  /// déjà créée côté backend). Passe à la tâche suivante, ou finalise après T3.
  Future<void> _advanceExamFlow() async {
    final goState = GoRouterState.of(context);
    final fullExamId = goState.uri.queryParameters['fullExamId'];
    final session = ref.read(eoSessionProvider).value;
    final hasNext =
        session != null && widget.taskIndex + 1 < session.totalTasks;
    if (hasNext) {
      context.pushReplacement(
        withCurrentQuery(
          context,
          '/tcf/expression-orale/t/${widget.taskIndex + 1}',
        ),
      );
      return;
    }
    // Dernière tâche EO.
    if (fullExamId != null) {
      try {
        await ref.read(fullTcfExamRepositoryProvider).markSubDone(
              parentAttemptId: fullExamId,
              epreuveWire: 'TCF_EO',
            );
      } catch (_) {/* hook auto backend fallback */}
      if (!mounted) return;
      final id = session?.attempt?.id;
      ref.read(eoSessionProvider.notifier).reset();
      if (id != null) ref.invalidate(fullTcfExamProvider(fullExamId));
      context.go('/tcf/examen-blanc/$fullExamId');
      return;
    }
    final attemptId = session!.attempt!.id;
    await ref.read(eoSessionProvider.notifier).finishAttemptIfExam();
    if (!mounted) return;
    context.pushReplacement(
      '/tcf/expression-orale/sessions/$attemptId?live=1',
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
    _examAutoStop?.cancel();
    await ref.read(recordingControllerProvider.notifier).cancel();
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_fallbackRouteFor(context));
    }
  }

  /// Abandon confirmé en cours d'examen EO → finalise (copie ramassée : les
  /// tâches non rendues sont comptées 0) puis sort vers le hub / le progress de
  /// l'examen complet.
  Future<void> _quitExam(BuildContext context, String fallbackRoute) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter l\'examen ?'),
        content: const Text(
          'Votre examen sera terminé. Les tâches non rendues seront comptées comme non faites.',
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
    if (ok != true || !context.mounted) return;
    final fullExamId =
        GoRouterState.of(context).uri.queryParameters['fullExamId'];
    _examAutoStop?.cancel();
    await ref.read(recordingControllerProvider.notifier).cancel();
    if (fullExamId != null) {
      try {
        await ref.read(fullTcfExamRepositoryProvider).markSubDone(
              parentAttemptId: fullExamId,
              epreuveWire: 'TCF_EO',
            );
      } catch (_) {/* hook auto backend fallback */}
    } else {
      await ref.read(eoSessionProvider.notifier).finishAttemptIfExam();
    }
    ref.read(eoSessionProvider.notifier).reset();
    if (!context.mounted) return;
    if (fullExamId != null) {
      ref.invalidate(fullTcfExamProvider(fullExamId));
    }
    context.go(fallbackRoute);
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

    // Capture terminée (stop manuel ou auto-stop à maxDuration) : en
    // entraînement on push l'écran de réécoute, en examen on soumet et on
    // enchaîne directement.
    ref.listen(recordingControllerProvider, (prev, next) {
      if (next.phase == RecordingPhase.finished &&
          prev?.phase != RecordingPhase.finished) {
        _onCaptureFinished();
      }
    });

    // Full exam : la session EO se charge en async (`startInFullExam`) → on
    // (re)tente l'offre temps réel dès qu'elle est prête (guard interne).
    ref.listen(eoSessionProvider, (prev, next) {
      if (next.hasValue) _ensureRealtimeOffer();
    });

    final isExam = sessionAsync.value?.isExam ?? false;
    final fallbackRoute = _fallbackRouteFor(context);

    return PopScope(
      // En examen, le retour confirme l'abandon de l'examen entier. Hors examen,
      // il confirme l'abandon de l'enregistrement en cours.
      canPop: !isRecording && !isExam,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (isExam) {
          await _quitExam(context, fallbackRoute);
        } else {
          await _quitRecording(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: ProductionAppHeader(
          title: 'Expression orale',
          fallbackRoute: fallbackRoute,
          // Pendant la capture (ou en examen), la flèche retour passe par une
          // confirmation d'abandon (sinon un pop direct perdrait l'examen /
          // l'enregistrement).
          onBack: isExam
              ? () => _quitExam(context, fallbackRoute)
              : (isRecording ? () => _quitRecording(context) : null),
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
                ref
                    .read(eoSessionProvider.notifier)
                    .startInFullExam(subAttemptId: subAttemptId);
              }
            },
          ),
          data: (session) {
            final task = session.taskAt(widget.taskIndex);
            if (!session.isStarted || task == null) {
              return const Center(child: CircularProgressIndicator());
            }
            // Loader plein écran pendant la soumission examen (après stop) OU
            // la négociation temps réel (quota + modal + démarrage de session) :
            // la navigation (tâche suivante / bilan / écran realtime) suit.
            if (_submittingExam || _negotiating) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.red),
              );
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
                        child: _RecordingView(
                            task: task,
                            rec: rec,
                            onStop: _stop,
                            isExam: session.isExam))
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
    required this.isExam,
  });

  final ProductionTaskDto task;
  final RecordingState rec;
  final VoidCallback onStop;

  /// En examen, le timer décompte (`dureeMaxSec` → 0) ; en entraînement libre,
  /// il croît (chrono indicatif).
  final bool isExam;

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
                  countdown: isExam,
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
    this.countdown = false,
  });

  final Duration elapsed;
  final Duration max;

  /// Minimum conseillé en secondes (typiquement 120 = 2 min).
  final int minSec;

  /// En examen : affiche le temps **restant** (décompte) au lieu de l'écoulé.
  final bool countdown;

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Duration get _remaining {
    final r = max - elapsed;
    return r.isNegative ? Duration.zero : r;
  }

  Color get _timerColor {
    if (countdown) {
      // Décompte : alerte rouge dans les 30 dernières secondes.
      return _remaining.inSeconds <= 30 ? AppColors.red : AppColors.ink;
    }
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
          countdown ? _fmt(_remaining) : _fmt(elapsed),
          style: AppFonts.display(size: 56, color: _timerColor, height: 1.0),
        ),
        const SizedBox(height: 4),
        Text(
          countdown ? 'Temps restant' : '/ ${_fmt(max)}',
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

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/query_propagation.dart';
import '../../core/widgets/app_button.dart';
import '../tcf_full_exam/full_exam_exit_labels.dart';
import '../tcf_full_exam/full_tcf_exam_provider.dart';
import 'audio_recorder_service.dart';
import 'eo_session_controller.dart';
import 'realtime/realtime_eo_controller.dart';
import 'realtime/realtime_launch.dart';
import 'widgets/consigne_card.dart';
import 'widgets/production_app_header.dart';
import 'widgets/production_progress_strip.dart';
import 'widgets/recording_waveform.dart';
import '../diagnostic_tcf/tcf_diagnostic_labels.dart';
import '../../core/router/app_router.dart';

/// Écran unique EO « consigne + enregistrement » : la consigne s'affiche
/// **sans aucun décompte**, le tap sur « Je suis prêt » lance la capture **sur
/// place** (pas de page intermédiaire). À l'arrêt (manuel ou auto-stop à
/// `dureeMaxSec`), on pousse l'écran « terminé » (réécoute + soumission →
/// évaluation) — ou, en examen, on soumet et on enchaîne la tâche suivante.
///
/// 🛑 **L'épreuve orale n'a PAS de chrono d'épreuve** (le backend rend
/// `timeLimitSeconds = null`, il valait 900 s). Calqué sur le vrai TCF, le temps
/// se compte **par tâche** et ne part **qu'au moment où le candidat lance la
/// tâche** : c'est `dureeMaxSec` (180 / 210 / 210 s) qui borne l'enregistrement,
/// avec auto-stop à zéro puis passage à la tâche suivante. Vaut pour l'EO d'un
/// examen blanc complet **comme** pour l'épreuve EO jouée seule.
///
/// L'auto-stop passe par le **flux d'état du service** d'enregistrement (`ref
/// .listen` sur `recordingControllerProvider`), jamais par un `stop()` posé dans
/// `start()` — c'est ce câblage qui évite une fuite du wake lock écran.
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

  /// Couvre la phase d'attente du choix de mode EO T1/T2 (quota + modal +
  /// démarrage de la session temps réel) par un loader plein écran.
  bool _negotiating = false;

  /// Examen : timer déterministe possédé par l'écran qui force l'arrêt + la
  /// soumission quand le temps imparti à la **tâche** est écoulé — indépendant
  /// du ticker interne du `AudioRecorderService` et du `ref.listen` (constaté :
  /// à la 3e tâche EO, l'auto-stop du service ne déclenchait pas la soumission).
  /// Armé **au lancement de la tâche**, sur `dureeMaxSec`.
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
      final tcfDiagnosticId = goState.uri.queryParameters[kTcfDiagnosticParam];
      if ((fullExamId != null || tcfDiagnosticId != null) &&
          subAttemptId != null) {
        // Diagnostic comme examen complet : le sous-attempt existe deja, on le
        // REPREND. Le serveur y compose 3 taches au niveau cible du candidat.
        ref
            .read(eoSessionProvider.notifier)
            .startInFullExam(subAttemptId: subAttemptId);
      }
      // Sinon : la session (examen module via `startExam`, ou sujet unique via
      // `startSingle`) est déjà démarrée par l'écran appelant ; on la respecte.
      // Aucun fallback `start()` ici — un deep-link nu sur cette route sans
      // session active affiche l'erreur "session introuvable".
      //
      // Le choix du mode EO T1/T2 (temps réel vs seul) N'EST PLUS proposé ici à
      // l'ouverture : il l'est sur « Commencer l'enregistrement » (_onStartPressed),
      // une fois le sujet lu — pour tous les contextes (isolé, module, complet).
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

  /// Tap sur « Commencer l'enregistrement ». Pour une tâche EO T1/T2 (examen
  /// module, examen complet OU entraînement isolé), on propose D'ABORD le mode
  /// (examinateur temps réel vs enregistrement seul) — MAINTENANT que le sujet a
  /// été lu sur ce briefing. T3 (ou négociation → classique) : capture directe.
  Future<void> _onStartPressed() async {
    if (_negotiating || _requestingPerm) return;
    final session = ref.read(eoSessionProvider).value;
    final task = session?.taskAt(widget.taskIndex);
    final t = task?.tacheNumero;
    if (session != null && task != null && (t == 1 || t == 2)) {
      final handled = await _negotiateRealtime(session, task);
      if (handled) return;
    }
    await _startRecording();
  }

  /// Négocie le mode (modal §2.3) sur l'attempt déjà provisionné de la session
  /// (`startSingle` / `startExam` / `startInFullExam`). Retourne `true` si le
  /// flux est pris en charge (temps réel lancé, ou modal annulé → on reste sur le
  /// briefing), `false` pour retomber sur l'enregistrement classique.
  Future<bool> _negotiateRealtime(
      EoSessionState session, ProductionTaskDto task) async {
    final attemptId = session.attempt?.id;
    if (attemptId == null) return false;
    setState(() => _negotiating = true);
    final negotiation = await negotiateRealtimeSession(
      context,
      ref,
      productionTaskId: task.id,
      resolveAttemptId: () async => attemptId,
    );
    if (!mounted) return true;
    switch (negotiation.decision) {
      case RealtimeDecision.cancelled:
        setState(() => _negotiating = false);
        return true; // modal fermé sans choix → on reste sur le briefing
      case RealtimeDecision.classic:
        setState(() => _negotiating = false);
        // Le candidat avait demandé l'examinateur et on n'a pas pu le lui
        // donner : on le DIT avant de l'envoyer sur l'enregistreur seul. Sans
        // ce message, son choix disparaissait sans trace — c'est exactement ce
        // qui a laissé quatre jours de temps réel mort passer inaperçus.
        final refus = negotiation.refusalMessage;
        if (refus != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(refus),
              backgroundColor: AppColors.ink,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return false; // → enregistrement classique (fall-through)
      case RealtimeDecision.realtime:
        final args = RealtimeRunnerArgs(
          descriptor: negotiation.descriptor!,
          task: task,
          attemptId: attemptId,
          // Examen : l'échange rend la main (pop true) pour enchaîner la tâche.
          popOnDone: session.isExam,
        );
        if (session.isExam) {
          final done = await context.push<bool>(
            '/tcf/expression-orale/realtime',
            extra: args,
          );
          if (!mounted) return true;
          if (done == true) {
            _navigated = true;
            setState(() => _submittingExam = true);
            await _advanceExamFlow();
          } else {
            // Temps réel abandonné → retour au briefing (classique possible).
            setState(() => _negotiating = false);
          }
        } else {
          // Entraînement isolé : on remplace le briefing par l'échange ; le
          // realtime screen navigue lui-même vers le résultat (popOnDone=false).
          context.pushReplacement(
            '/tcf/expression-orale/realtime',
            extra: args,
          );
        }
        return true;
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
    // 🛑 Section d'un DIAGNOSTIC : pas de markSubDone (le backend pose
    // `finishedAt` des la 3e soumission) et retour aux 4 sections, jamais au
    // bilan individuel — le candidat doit voir ce qu'il lui reste.
    if (GoRouterState.of(context).uri.queryParameters[kTcfDiagnosticParam] !=
        null) {
      ref.read(eoSessionProvider.notifier).reset();
      if (!mounted) return;
      context.go(AppRoutes.tcfDiagnostic);
      return;
    }
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
    final params = GoRouterState.of(context).uri.queryParameters;
    final fullExamId = params['fullExamId'];
    if (fullExamId != null) return '/tcf/examen-blanc/$fullExamId';
    // Quitter une section de diagnostic ramene aux 4 sections.
    if (params[kTcfDiagnosticParam] != null) return AppRoutes.tcfDiagnostic;
    return '/tcf/eo';
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

  /// Sortie confirmée d'une session d'examen EO. En **examen blanc complet**,
  /// une épreuve commencée ne se reprend jamais : quitter la **clôture**. En
  /// session d'examen module, on finalise l'attempt comme avant.
  Future<void> _quitExam(BuildContext context, String fallbackRoute) async {
    final fullExamId =
        GoRouterState.of(context).uri.queryParameters['fullExamId'];
    final isFullExam = fullExamId != null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isFullExam ? kEpreuveExitTitle : 'Quitter l\'examen ?',
        ),
        content: Text(
          isFullExam
              ? epreuveExitMessage(EpreuveType.tcfEo, perteEnregistrement: true)
              : 'Votre examen sera terminé. Les tâches non rendues seront comptées comme non faites.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isFullExam ? kEpreuveExitCancel : 'Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              isFullExam ? kEpreuveExitConfirm : 'Quitter',
              style: AppFonts.ui(weight: FontWeight.w700, color: AppColors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    _examAutoStop?.cancel();
    await ref.read(recordingControllerProvider.notifier).cancel();
    // Examen blanc complet : **quitter CLÔTURE l'épreuve**, avec ce qui a été
    // rendu (arbitrage propriétaire du 2026-08-15, qui revient sur le correctif
    // de la veille). La règle produit est « une épreuve commencée ne se reprend
    // jamais » : la laisser ouverte laissait croire à une reprise qui n'existe
    // pas. Les épreuves **jamais ouvertes**, elles, ne sont toujours touchées
    // par aucun geste de sortie — ni ici, ni depuis le hub.
    if (isFullExam) {
      try {
        await ref.read(fullTcfExamRepositoryProvider).markSubDone(
              parentAttemptId: fullExamId,
              epreuveWire: EpreuveType.tcfEo.wire,
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
        title: const Text('Accès au microphone requis'),
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

    final isExam = sessionAsync.value?.isExam ?? false;
    final fallbackRoute = _fallbackRouteFor(context);

    return PopScope(
      // En examen, le retour confirme la sortie de l'épreuve — qui la
      // **clôture**, examen complet compris. Hors examen, il confirme l'abandon
      // de l'enregistrement en cours.
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
                child: CircularProgressIndicator(color: AppColors.blue),
              );
            }
            return SafeArea(
              top: false,
              child: Column(
                children: [
                  // 🛑 Aucun décompte d'épreuve ici, ni sur la consigne : le
                  // temps de l'oral se compte **par tâche** et ne part qu'au
                  // « Je suis prêt ». Le seul chrono visible est celui de la
                  // capture en cours (`_TimerBig`), sur `dureeMaxSec`.
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
                          // Le chrono de la tâche part à CE tap, pas avant :
                          // c'est ce que le libellé annonce.
                          countdownSeconds: task.dureeMaxSec,
                          onPressed:
                              _requestingPerm ? null : _onStartPressed,
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

/// Contrainte de durée en pastille courte (« 3 min », « 3 min 30 »).
String _durationChip(int sec) {
  final mins = sec ~/ 60;
  final remain = sec % 60;
  if (mins == 0) return '$sec s';
  return remain == 0 ? '$mins min' : '$mins min $remain';
}

/// Temps de parole de la tâche. C'est un **plafond avec auto-stop**, pas une
/// « durée attendue » : le libellé le dit, et le chrono ne part qu'au
/// « Je suis prêt ».
String _durationLabel(int? sec) {
  if (sec == null || sec <= 0) return 'Durée libre';
  final mins = sec ~/ 60;
  final remain = sec % 60;
  if (remain == 0) return 'Temps de parole : $mins minutes';
  return 'Temps de parole : $mins min $remain s';
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
          accent: AppColors.blue,
          soft: AppColors.blueLight,
          contexte: task.contexte,
          requirements: [
            if (task.dureeMaxSec != null) _durationChip(task.dureeMaxSec!),
            task.niveauCible,
          ],
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
                  accent: AppColors.blue,
                  soft: AppColors.blueLight,
                ),
                const SizedBox(height: 12),
                const RecordingPill(
                  color: AppColors.red,
                  background: AppColors.redLight,
                ),
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
                  color: AppColors.blue,
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
///
/// **C'est ce tap qui lance le chrono de la tâche** — d'où « Je suis prêt ». Le
/// candidat lit la consigne aussi longtemps qu'il veut avant de le presser :
/// aucun décompte ne court tant qu'il ne l'a pas fait.
class _MicStartButton extends StatelessWidget {
  const _MicStartButton({
    required this.loading,
    required this.onPressed,
    this.countdownSeconds,
  });

  final bool loading;
  final VoidCallback? onPressed;

  /// Temps de parole de la tâche (`dureeMaxSec`), annoncé avant le départ.
  /// Null ⇒ on n'annonce aucune durée plutôt qu'un chiffre inventé.
  final int? countdownSeconds;

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
          'Je suis prêt · Commencer la tâche',
          textAlign: TextAlign.center,
          style: AppFonts.ui(
            size: 16,
            weight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          countdownSeconds == null
              ? 'Le chrono ne part qu\'à cet instant. Prends le temps de lire '
                  'la consigne.'
              : 'Le chrono de ${_durationChip(countdownSeconds!)} ne part qu\'à '
                  'cet instant. Prends le temps de lire la consigne.',
          textAlign: TextAlign.center,
          style: AppFonts.ui(size: 13, color: AppColors.muted, height: 1.4),
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
    // `AppColors.amber` est un ambre de **remplissage**, illisible en lettres :
    // un chrono ambre passe par `amberDark`.
    if (secs < max.inSeconds) return AppColors.amberDark;
    return AppColors.green;
  }

  /// Le chrono est **entouré du cadran partagé** : le nombre seul changeait une
  /// fois par seconde alors que l'état arrive toutes les 200 ms, ce qui donnait
  /// un écran d'apparence figée pendant qu'on parlait. L'arc, lui, bouge à
  /// chaque tic — et en examen il **se vide**, comme les chiffres.
  @override
  Widget build(BuildContext context) {
    return RecordingGauge(
      elapsed: elapsed,
      total: max,
      depleting: countdown,
      timeLabel: countdown ? _fmt(_remaining) : _fmt(elapsed),
      sub: countdown ? 'Temps restant' : '/ ${_fmt(max)}',
      timeColor: _timerColor,
      size: 158,
      timeSemantics: countdown
          ? 'Temps restant : ${recordingSpokenDuration(_remaining)}'
          : recordingTimeSemantics(elapsed, max),
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
            label: 'Réessayer',
            onPressed: onRetry,
            icon: LucideIcons.refreshCw,
          ),
        ],
      ),
    );
  }
}

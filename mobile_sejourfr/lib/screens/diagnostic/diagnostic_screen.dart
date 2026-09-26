import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/analytics/analytics.dart';
import '../../core/analytics/diagnostic_run_tracker.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/diagnostic_run_models.dart';
import '../../core/models/preparation_labels.dart';
import '../../core/models/enums.dart';
import '../../core/providers/target_level_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/screen_header.dart';
import '../tcf_production/audio_recorder_service.dart';
import 'diagnostic_controller.dart';
import 'widgets/diagnostic_account_gate.dart';
import 'widgets/diagnostic_analysis.dart';
import 'widgets/diagnostic_choice.dart';
import 'widgets/diagnostic_common.dart';
import 'widgets/diagnostic_intro.dart';
import 'widgets/diagnostic_oral.dart';
import 'widgets/diagnostic_report_labels.dart';
import 'widgets/diagnostic_result.dart';
import 'widgets/diagnostic_sync.dart';
import 'widgets/diagnostic_written.dart';

class DiagnosticScreen extends ConsumerStatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  ConsumerState<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends ConsumerState<DiagnosticScreen> {
  /// Fenêtre d'écriture avant sauvegarde locale : assez courte pour qu'un kill
  /// de l'app ne coûte qu'une phrase, assez longue pour ne pas écrire à chaque
  /// frappe.
  static const _autosaveDelay = Duration(seconds: 2);

  final _writingController = TextEditingController();
  late final RecordingController _recordingController;
  Timer? _autosave;
  int _wordCount = 0;
  bool _resultViewedTracked = false;
  bool _eeStartedTracked = false;
  bool _eoStartedTracked = false;
  bool _accountRequiredTracked = false;

  /// L'étape 1 du tunnel (sujet vu) n'est tracée qu'une fois par montage :
  /// l'écran se reconstruit à chaque frappe.
  bool _subjectViewedTracked = false;
  bool _writingHydrated = false;

  /// 🛑 **Le démarrage direct n'a lieu qu'UNE fois.** `build` est rappelé à
  /// chaque tic du contrôleur ; sans ce marqueur, la présentation relancerait
  /// `startOrResume` en boucle.
  bool _demarrageDirectFait = false;

  @override
  void initState() {
    super.initState();
    _recordingController = ref.read(recordingControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref.read(diagnosticControllerProvider.notifier).loadCurrent(),
      );
      unawaited(_recordingController.cancel());
    });
  }

  /// **Sauter la présentation quand le geste l'a déjà remplacée.**
  ///
  /// 🛑 Demande du propriétaire (2026-09-12) : « Faire mon diagnostic », depuis
  /// le Plan ou l'Accueil, doit **lancer** le diagnostic, pas ouvrir une page
  /// qui redemande de le lancer. Le bouton porte déjà la décision ; la
  /// présentation, elle, garde tout son sens pour qui arrive sur `/diagnostic`
  /// sans l'avoir demandé (lien profond, visiteur).
  ///
  /// Le transport est `?demarrer=1`, posé par les seules portes qui **nomment**
  /// le geste. 🛑 **Compte connecté uniquement** : en visiteur, la présentation
  /// porte aussi le choix TCF / civique et les deux diagnostics s'y valent.
  ///
  /// ⚠️ Aucun risque de double session : `POST /api/diagnostics` est
  /// idempotent, et le marqueur borne l'appel à un par montage.
  void _demarrerDirectSiDemande(DiagnosticFlowState state) {
    if (_demarrageDirectFait || state.isGuest) return;
    if (!kDiagnosticDemarrageDirect.lu(GoRouterState.of(context).uri)) return;
    final journey = state.journey;
    // Rien à sauter tant que l'état n'est pas lu, ou si le candidat est déjà
    // plus loin que la présentation : on ne réécrit jamais son avancement.
    if (journey == null ||
        journey.nextStep != DiagnosticStep.presentation ||
        state.isSubmitting) {
      return;
    }
    _demarrageDirectFait = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_startAuthenticated());
    });
  }

  @override
  void dispose() {
    _autosave?.cancel();
    _writingController.dispose();
    unawaited(_recordingController.cancel());
    super.dispose();
  }

  /// La nature du diagnostic lancé depuis cet écran.
  ///
  /// 🛑 **Toujours `rapid`**, et ce n'est pas un raccourci : depuis l'arbitrage
  /// du 2026-09-10 on n'entre plus par « rapide ou complet » mais par un
  /// **examen**, et le parcours joué ici est celui des deux productions. La
  /// profondeur se décide ensuite, sur le rapport, à partir des domaines
  /// réellement mesurés. Inventer `complete` ici mesurerait une intention que
  /// le candidat n'a jamais exprimée.
  AnalyticsDiagnosticType get _diagnosticType => AnalyticsDiagnosticType.rapid;

  /// Émission best-effort — jamais attendue, jamais bloquante.
  void _track(AnalyticsEvent event) {
    ref.read(analyticsServiceProvider).track(
          event,
          path: AnalyticsPath.diagnostic,
          diagnosticType: _diagnosticType,
          diagnosticRun: DiagnosticRunType.quickTcf,
        );
  }

  DiagnosticRunTracker get _runs => ref.read(diagnosticRunTrackerProvider);

  /// « Analyser mes réponses » : la **dernière** production attendue vient
  /// d'être validée — l'écrit seul sur le diagnostic rapide, l'oral sur la
  /// paire. C'est l'étape 2 du tunnel, posée par le client pour le TCF rapide
  /// (D23) : invité, rien n'existe encore côté serveur.
  void _markSubmittedIfComplete() {
    final state = ref.read(diagnosticControllerProvider);
    final journey = state.journey;
    final complete = state.isGuest
        ? state.guestStep == DiagnosticGuestStep.accountRequired
        : journey != null &&
            (journey.nextStep == DiagnosticStep.analysis ||
                journey.nextStep == DiagnosticStep.result ||
                journey.status == DiagnosticJourneyStatus.analyzing ||
                journey.status == DiagnosticJourneyStatus.completed);
    if (!complete) return;
    unawaited(_runs.submitted(
      sessionId: state.isGuest ? null : journey?.sessionId,
    ));
  }

  DiagnosticController get _controller =>
      ref.read(diagnosticControllerProvider.notifier);

  // ---------------------------------------------------------------------------
  // Écrit
  // ---------------------------------------------------------------------------

  /// Réinjecte la production locale dans la zone de saisie : c'est ce qui fait
  /// qu'un visiteur revenu après un kill de l'app retrouve son texte.
  void _hydrateWriting(DiagnosticFlowState state) {
    if (_writingHydrated) return;
    final text = state.draft?.writtenText;
    if (text == null || text.isEmpty || _writingController.text.isNotEmpty) {
      return;
    }
    _writingHydrated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _writingController.text = text;
      setState(() => _wordCount = _countWords(text));
    });
  }

  void _onWritingChanged(String text, {required bool isGuest}) {
    setState(() => _wordCount = _countWords(text));
    if (!isGuest) return;
    _autosave?.cancel();
    _autosave = Timer(_autosaveDelay, () {
      unawaited(_controller.autosaveGuestWritten(text));
    });
  }

  Future<void> _submitWritten({required bool isGuest}) async {
    FocusScope.of(context).unfocus();
    _autosave?.cancel();
    final editing = ref.read(diagnosticControllerProvider).isEditingWritten;
    final text = _writingController.text.trim();
    final submitted = isGuest
        ? await _controller.submitGuestWritten(text)
        : await _controller.submitWritten(text);
    if (!submitted) return;
    // Une modification depuis l'écran de compte n'est pas un second écrit :
    // aucune mesure de plus (le « soumis » de la run, lui, est idempotent).
    if (!editing) _track(AnalyticsEvent.diagnosticEeCompleted);
    _markSubmittedIfComplete();
  }

  /// Remet dans la zone de saisie la production ENREGISTRÉE — le point de
  /// départ d'une modification, et ce qu'on retrouve en l'annulant.
  void _resetWritingToDraft() {
    _autosave?.cancel();
    final text = ref.read(diagnosticControllerProvider).draft?.writtenText ?? '';
    _writingController.text = text;
    setState(() => _wordCount = _countWords(text));
  }

  /// « ← Modifier mon texte » (écran de compte) : l'écrit rouvert, pré-rempli.
  void _openWrittenEditor() {
    _resetWritingToDraft();
    _controller.editGuestWritten();
  }

  /// « ← Revenir sans modifier » : retour au compte, texte d'origine intact.
  void _cancelWrittenEdit() {
    FocusScope.of(context).unfocus();
    _resetWritingToDraft();
    _controller.cancelGuestEdit();
  }

  // ---------------------------------------------------------------------------
  // Oral
  // ---------------------------------------------------------------------------

  int _maxOralSeconds(DiagnosticFlowState state) =>
      (state.isGuest
          ? state.subjects?.oral?.durationMaxSeconds
          : state.journey?.oral?.durationMaxSeconds) ??
      180;

  Future<void> _startRecording() async {
    final status = await _recordingController.requestPermission();
    if (!mounted || status != PermissionStatus.granted) return;
    await _recordingController.start(
      maxDuration: Duration(
        seconds: _maxOralSeconds(ref.read(diagnosticControllerProvider)),
      ),
    );
  }

  Future<void> _submitOral({required bool isGuest}) async {
    final recording = ref.read(recordingControllerProvider);
    final path = recording.filePath;
    if (path == null) return;
    final submitted = isGuest
        ? await _controller.submitGuestOral(
            audioFile: File(path),
            mimeType: recording.fileMime,
          )
        : await _controller.submitOral(
            audioFile: File(path),
            mimeType: recording.fileMime,
          );
    if (!submitted) return;
    _track(AnalyticsEvent.diagnosticEoCompleted);
    _markSubmittedIfComplete();
    // En invité, l'enregistrement a déjà été recopié dans le dossier de
    // l'application : effacer le fichier temporaire ne coûte rien.
    await _recordingController.cancel();
  }

  // ---------------------------------------------------------------------------
  // Compte
  // ---------------------------------------------------------------------------

  void _openRegister() {
    context.push(authFlowLocation(AppRoutes.register, AppRoutes.diagnostic));
  }

  void _openLogin() {
    context.push(loginLocationFor(AppRoutes.diagnostic));
  }

  Future<void> _confirmDiscard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer vos réponses locales ?'),
        content: const Text(
          'Votre texte et votre enregistrement seront effacés de ce '
          'téléphone. Cette action est définitive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Conserver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Supprimer',
              style: AppFonts.ui(
                weight: FontWeight.w700,
                color: AppColors.red,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _controller.discardLocalProductions();
  }

  Future<void> _confirmBack() async {
    if (ref.read(diagnosticControllerProvider).isSubmitting) return;
    final recording = ref.read(recordingControllerProvider);
    if (recording.canStop) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Quitter l’enregistrement ?'),
          content: const Text('L’enregistrement en cours sera perdu.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Continuer'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Quitter',
                style: AppFonts.ui(
                  weight: FontWeight.w700,
                  color: AppColors.red,
                ),
              ),
            ),
          ],
        ),
      );
      if (leave != true || !mounted) return;
    }
    await _recordingController.cancel();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diagnosticControllerProvider);
    final recording = ref.watch(recordingControllerProvider);
    final objective = ref.watch(userTargetLevelProvider);
    _hydrateWriting(state);
    _demarrerDirectSiDemande(state);
    // 🛑 « Diagnostic terminé » n'est PAS un événement : il se lit sur
    // `diagnostic_sessions.status`. On ne crée jamais une seconde vérité.
    //
    // Lu ici plutôt que dans le `ref.listen` ci-dessous : celui-ci ne se
    // déclenche que sur un CHANGEMENT, donc une session reprise qui s'ouvre
    // directement sur l'écrit ne l'aurait jamais franchi.
    _trackStepReached(state);

    ref.listen<DiagnosticFlowState>(diagnosticControllerProvider,
        (previous, next) {
      _hydrateWriting(next);
      _trackStepReached(next);
      if (!_resultViewedTracked &&
          next.journey?.nextStep == DiagnosticStep.result &&
          next.journey?.result != null) {
        _resultViewedTracked = true;
        _track(AnalyticsEvent.diagnosticReportViewed);
      }
    });

    final recordingActive = recording.canStop;
    // Pendant la modification de l'écrit, le retour (système comme flèche)
    // ramène à l'écran de compte : c'est de là qu'on est venu, comme le
    // « précédent » du navigateur côté web.
    final editingWritten = state.isGuest && state.isEditingWritten;
    // Visiteur sur l'écrit : l'écran précédent est le choix d'examen.
    final writtenFromChoice = state.isGuest &&
        !editingWritten &&
        state.guestStep == DiagnosticGuestStep.written;
    return PopScope(
      canPop: !recordingActive &&
          !state.isSubmitting &&
          !state.isSyncing &&
          !editingWritten &&
          !writtenFromChoice,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (editingWritten) {
          if (!state.isSubmitting) _cancelWrittenEdit();
          return;
        }
        if (writtenFromChoice) {
          if (!state.isSubmitting) _controller.backToGuestChoice();
          return;
        }
        await _confirmBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ScreenHeader(
                // Une fois le rapport rendu, l'en-tête EST le `Top` de la
                // maquette : l'écran a cessé d'être un parcours, il est devenu
                // un document. C'est ce qui permet au corps de commencer
                // directement par la carte hero.
                // Le visiteur y choisit encore son examen : « TCF » serait faux.
                title: _showsReport(state)
                    ? kDiagnosticReportTitle
                    : state.isGuest &&
                            state.guestStep == DiagnosticGuestStep.presentation
                        ? 'Diagnostic'
                        : 'Diagnostic TCF',
                sub: _headerSub(state),
                // 🛑 Le rapport atteint au sortir du tunnel (compte créé puis
                // `go` vers le diagnostic) n'a rien en dessous : il est un
                // écran racine, sans flèche — « retour » ne ramène jamais à
                // l'écran de compte. Ouvert depuis le Plan (`push`), il garde
                // sa flèche. Miroir du `backTo` conditionnel du web.
                onBack: state.isSubmitting ||
                        state.isSyncing ||
                        (_showsReport(state) && !context.canPop())
                    ? null
                    : editingWritten
                        ? _cancelWrittenEdit
                        : writtenFromChoice
                            ? _controller.backToGuestChoice
                            : _confirmBack,
              ),
              Expanded(
                child: _content(
                  state: state,
                  recording: recording,
                  objective: objective,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content({
    required DiagnosticFlowState state,
    required RecordingState recording,
    required TargetLevel? objective,
  }) {
    if (state.isGuest) {
      return _guestContent(state: state, recording: recording);
    }

    // La forme du passage vient de la production locale : elle a été
    // enregistrée avec son exigence d'oral.
    final syncHasOral =
        state.draft != null && (state.draft!.oralRequired || state.draft!.hasOral);
    if (state.isSyncing) {
      return DiagnosticSendingView(
        stage: state.syncStage,
        hasOral: syncHasOral,
      );
    }
    if (state.canRetrySync) {
      return DiagnosticSyncFailedView(
        hasOral: syncHasOral,
        isBusy: state.isSyncing,
        errorMessage: state.errorMessage,
        onRetry: () => unawaited(_controller.syncLocalProductions()),
      );
    }
    if (state.noticeMessage != null) {
      return DiagnosticAlreadyDoneView(
        message: state.noticeMessage!,
        onContinue: _controller.dismissNotice,
        onDiscard: () => unawaited(_confirmDiscard()),
      );
    }

    final journey = state.journey;
    if (journey == null) {
      return _InitialState(
        isLoading: state.isLoading,
        errorMessage: state.errorMessage,
        onRetry: () => unawaited(_controller.loadCurrent()),
      );
    }

    if (journey.status == DiagnosticJourneyStatus.failed ||
        journey.nextStep == DiagnosticStep.analysis) {
      return DiagnosticAnalysisView(
        journey: journey,
        isBusy: state.isSubmitting || state.isLoading,
        isPolling: state.isPolling,
        errorMessage: state.errorMessage,
        onRefresh: () => unawaited(_controller.refreshDetail()),
        onRetry: () => unawaited(_controller.retryAnalysis()),
        onOpenPlan: () => context.go(AppRoutes.plan),
        onOpenHome: () => context.go(AppRoutes.home),
      );
    }
    return switch (journey.nextStep) {
      DiagnosticStep.presentation => DiagnosticIntro(
          isStarting: state.isSubmitting,
          errorMessage: state.errorMessage,
          // Sans session, le serveur n'attache aucun sujet au parcours : les
          // mesures viennent alors du catalogue public, chargé en repli.
          written: journey.written ?? state.subjects?.written,
          oral: journey.oral ?? state.subjects?.oral,
          onStart: () => unawaited(_startAuthenticated()),
        ),
      DiagnosticStep.written when journey.written != null =>
        DiagnosticWrittenStep(
          exercise: journey.written!,
          controller: _writingController,
          wordCount: _wordCount,
          isSubmitting: state.isSubmitting,
          errorMessage: state.errorMessage,
          onChanged: (text) => _onWritingChanged(text, isGuest: false),
          onSubmit: () => unawaited(_submitWritten(isGuest: false)),
          hasOral: journey.oral != null,
        ),
      DiagnosticStep.oral when journey.oral != null => DiagnosticOralStep(
          exercise: journey.oral!,
          recording: recording,
          isSubmitting: state.isSubmitting,
          errorMessage: state.errorMessage,
          onStart: () => unawaited(_startRecording()),
          onStop: () => unawaited(_recordingController.stop()),
          onReset: () => unawaited(_recordingController.cancel()),
          onOpenSettings: () =>
              unawaited(_recordingController.openSystemSettings()),
          onSubmit: () => unawaited(_submitOral(isGuest: false)),
        ),
      DiagnosticStep.result when journey.result != null => DiagnosticResultView(
          result: journey.result!,
          objective: objective,
        ),
      _ => _InitialState(
          isLoading: state.isLoading,
          errorMessage:
              state.errorMessage ?? 'Cette étape n’est pas encore disponible.',
          onRetry: () => unawaited(_controller.refreshDetail()),
        ),
    };
  }

  /// Parcours invité : les deux productions se font avant tout compte, et
  /// vivent sur le disque de l'appareil jusqu'à l'inscription.
  Widget _guestContent({
    required DiagnosticFlowState state,
    required RecordingState recording,
  }) {
    final subjects = state.subjects;
    if (subjects == null) {
      return _InitialState(
        isLoading: state.isLoading,
        errorMessage: state.errorMessage,
        onRetry: () => unawaited(_controller.loadCurrent()),
      );
    }
    return switch (state.guestStep) {
      DiagnosticGuestStep.presentation => DiagnosticChoice(
          errorMessage: state.errorMessage,
          written: subjects.written,
          oral: subjects.oral,
          onStartTcf: _startGuest,
        ),
      DiagnosticGuestStep.written => DiagnosticWrittenStep(
          exercise: subjects.written,
          controller: _writingController,
          wordCount: _wordCount,
          isSubmitting: state.isSubmitting,
          errorMessage: state.errorMessage ?? state.noticeMessage,
          onChanged: (text) => _onWritingChanged(text, isGuest: true),
          onSubmit: () => unawaited(_submitWritten(isGuest: true)),
          hasOral: subjects.oral != null,
          // L'écrit rouvert depuis l'écran de compte : pré-rempli, avec un
          // retour sans modification et un bouton qui ramène au compte.
          submitLabel: state.isEditingWritten
              ? kDiagnosticEditSubmit
              : 'Valider mon écrit',
          onCancelEdit: state.isEditingWritten ? _cancelWrittenEdit : null,
          editNote: state.isEditingWritten
              ? diagnosticEditNote(hasOral: subjects.oral != null)
              : null,
        ),
      // 🛑 L'étape orale ne se rend que si ce diagnostic en porte une (L3).
      // Sans sujet, le contrôleur a déjà envoyé le visiteur au compte : ce cas
      // n'est donc pas atteignable, et le repli le dit sans planter.
      DiagnosticGuestStep.oral when subjects.oral != null =>
        DiagnosticOralStep(
          exercise: subjects.oral!,
          recording: recording,
          isSubmitting: state.isSubmitting,
          errorMessage: state.errorMessage,
          // Rien ne part vers le serveur ici : l'enregistrement rejoint la
          // production locale, l'analyse ne démarre qu'après le compte.
          submitLabel: 'Analyser mes réponses',
          onStart: () => unawaited(_startRecording()),
          onStop: () => unawaited(_recordingController.stop()),
          onReset: () => unawaited(_recordingController.cancel()),
          onOpenSettings: () =>
              unawaited(_recordingController.openSystemSettings()),
          onSubmit: () => unawaited(_submitOral(isGuest: true)),
        ),
      // Le compte est aussi le repli de `oral` sans sujet oral : c'est là que
      // le contrôleur envoie le visiteur, et l'écran doit dire la même chose.
      DiagnosticGuestStep.accountRequired ||
      DiagnosticGuestStep.oral =>
        DiagnosticAccountGate(
          hasOral: subjects.oral != null,
          errorMessage: state.errorMessage,
          noticeMessage: state.noticeMessage,
          onRegister: _openRegister,
          onLogin: _openLogin,
          onEditWritten: _openWrittenEditor,
        ),
    };
  }

  /// Une production **commencée**, c'est son écran atteint — invité comme
  /// connecté, les deux parcours jouent les deux mêmes exercices. Une seule
  /// émission par lancement : l'écran se reconstruit à chaque frappe.
  void _trackStepReached(DiagnosticFlowState state) {
    // L'écrit rouvert depuis l'écran de compte n'est pas un écrit commencé :
    // ni « sujet vu » ni `DIAGNOSTIC_EE_STARTED` de plus.
    final onWritten = state.isGuest
        ? state.guestStep == DiagnosticGuestStep.written &&
            !state.isEditingWritten
        : state.journey?.nextStep == DiagnosticStep.written;
    final onOral = state.isGuest
        ? state.guestStep == DiagnosticGuestStep.oral
        : state.journey?.nextStep == DiagnosticStep.oral;
    // 🛑 L'étape 1 du tunnel se lit sur la RUN (Q3), jamais sur un événement :
    // pas de `DIAGNOSTIC_SUBJECT_VIEWED`. La première question du TCF rapide,
    // c'est l'écrit.
    if (onWritten && !_subjectViewedTracked) {
      _subjectViewedTracked = true;
      unawaited(_runs.subjectViewed(
        DiagnosticRunType.quickTcf,
        sessionId: state.isGuest ? null : state.journey?.sessionId,
      ));
    }
    if (onWritten && !_eeStartedTracked) {
      _eeStartedTracked = true;
      _track(AnalyticsEvent.diagnosticEeStarted);
    }
    if (onOral && !_eoStartedTracked) {
      _eoStartedTracked = true;
      _track(AnalyticsEvent.diagnosticEoStarted);
    }
    // L'écran qui demande un compte, les deux productions déjà faites —
    // **la** mesure de conversion du parcours invité. N'existe que pour un
    // visiteur : un compte déjà créé n'a plus de `guestStep` à atteindre.
    if (state.isGuest &&
        state.guestStep == DiagnosticGuestStep.accountRequired &&
        !_accountRequiredTracked) {
      _accountRequiredTracked = true;
      _track(AnalyticsEvent.diagnosticAccountRequired);
    }
  }

  Future<void> _startAuthenticated() async {
    final started = await _controller.startOrResume();
    if (started) _track(AnalyticsEvent.diagnosticStarted);
  }

  void _startGuest() {
    _controller.startGuest();
    _track(AnalyticsEvent.diagnosticStarted);
  }

  /// Le rapport est-il à l'écran ? Il ne l'est qu'une fois le parcours
  /// authentifié arrivé à son terme — jamais en invité, jamais en cours
  /// d'analyse.
  bool _showsReport(DiagnosticFlowState state) =>
      !state.isGuest &&
      !state.isSyncing &&
      state.noticeMessage == null &&
      state.journey?.nextStep == DiagnosticStep.result &&
      state.journey?.result != null;

  String _headerSub(DiagnosticFlowState state) {
    if (state.isSyncing) return 'Envoi de vos réponses';
    if (_showsReport(state)) return kDiagnosticReportKicker;
    // 🛑 La présentation ne porte plus de sous-titre : elle fait choisir un
    // EXAMEN, et un chiffre de budget au-dessus du titre ne vaudrait que pour
    // l'une des deux cartes. Chaque carte annonce le sien.
    //
    // 🛑 Le compte d'étapes suit la FORME servie : oral `null` ⇒ un seul
    // exercice, jamais « Étape 1 sur 2 » (miroir du fil d'étapes du web).
    if (state.isGuest) {
      final hasOral = state.subjects?.oral != null;
      return switch (state.guestStep) {
        DiagnosticGuestStep.presentation => '',
        DiagnosticGuestStep.written =>
          diagnosticStepHeader(step: 1, hasOral: hasOral, label: 'Écrit'),
        DiagnosticGuestStep.oral =>
          diagnosticStepHeader(step: 2, hasOral: true, label: 'Oral'),
        DiagnosticGuestStep.accountRequired => 'Analyser mes réponses',
      };
    }
    final journey = state.journey;
    if (journey == null || journey.nextStep == DiagnosticStep.presentation) {
      return '';
    }
    return _stepLabel(journey.nextStep, hasOral: journey.oral != null);
  }

  static int _countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  static String _stepLabel(DiagnosticStep step, {required bool hasOral}) =>
      switch (step) {
        DiagnosticStep.written =>
          diagnosticStepHeader(step: 1, hasOral: hasOral, label: 'Écrit'),
        DiagnosticStep.oral =>
          diagnosticStepHeader(step: 2, hasOral: true, label: 'Oral'),
        DiagnosticStep.analysis => 'Analyse personnalisée',
        // Le rapport passe par `_headerSub` ; cette entrée n'est qu'un repli.
        DiagnosticStep.result => kDiagnosticReportKicker,
        DiagnosticStep.presentation => 'Présentation',
      };
}

class _InitialState extends StatelessWidget {
  const _InitialState({
    required this.isLoading,
    required this.onRetry,
    this.errorMessage,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading && errorMessage == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blue),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            children: [
              if (errorMessage != null)
                DiagnosticErrorBanner(message: errorMessage!),
              const SizedBox(height: 14),
              AppButton(
                label: 'Réessayer',
                variant: AppButtonVariant.soft,
                isLoading: isLoading,
                onPressed: isLoading ? null : onRetry,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

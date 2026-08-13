import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/api/audience_repository.dart';
import '../../core/api/repositories.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/providers/target_level_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/screen_header.dart';
import '../tcf_production/audio_recorder_service.dart';
import '../tcf_production/recommended_exercise_launcher.dart';
import 'diagnostic_controller.dart';
import 'widgets/diagnostic_account_gate.dart';
import 'widgets/diagnostic_analysis.dart';
import 'widgets/diagnostic_common.dart';
import 'widgets/diagnostic_intro.dart';
import 'widgets/diagnostic_oral.dart';
import 'widgets/diagnostic_result.dart';
import 'widgets/diagnostic_sync.dart';
import 'widgets/diagnostic_written.dart';

bool shouldTrackDiagnosticCompletion(
  DiagnosticJourneyStatus? previous,
  DiagnosticJourneyStatus? current,
) =>
    previous != null &&
    previous != DiagnosticJourneyStatus.completed &&
    current == DiagnosticJourneyStatus.completed;

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
  bool _accountGateTracked = false;
  bool _writingHydrated = false;

  @override
  void initState() {
    super.initState();
    _recordingController = ref.read(recordingControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _track(AudienceEvent.diagnosticViewed);
      unawaited(
        ref.read(diagnosticControllerProvider.notifier).loadCurrent(),
      );
      unawaited(_recordingController.cancel());
    });
  }

  @override
  void dispose() {
    _autosave?.cancel();
    _writingController.dispose();
    unawaited(_recordingController.cancel());
    super.dispose();
  }

  void _track(AudienceEvent event) {
    unawaited(_trackBestEffort(event));
  }

  Future<void> _trackBestEffort(AudienceEvent event) async {
    try {
      await ref
          .read(audienceRepositoryProvider)
          .track(path: '/diagnostic', event: event);
    } catch (_) {
      // La mesure d'audience ne doit jamais interrompre un diagnostic.
    }
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
    final text = _writingController.text.trim();
    final submitted = isGuest
        ? await _controller.submitGuestWritten(text)
        : await _controller.submitWritten(text);
    if (submitted) _track(AudienceEvent.diagnosticWrittenCompleted);
  }

  // ---------------------------------------------------------------------------
  // Oral
  // ---------------------------------------------------------------------------

  int _maxOralSeconds(DiagnosticFlowState state) =>
      (state.isGuest
          ? state.subjects?.oral.durationMaxSeconds
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
    _track(AudienceEvent.diagnosticOralCompleted);
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

  void _openRecommended(PlanRecommendedExercise exercise) {
    // Même destination et même verrou freemium que sur le Plan : le lanceur
    // partagé décide, l'app ne recalcule rien.
    unawaited(openRecommendedExercise(context, ref, exercise));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diagnosticControllerProvider);
    final recording = ref.watch(recordingControllerProvider);
    final objective = ref.watch(userTargetLevelProvider)?.wire;

    _hydrateWriting(state);

    ref.listen<DiagnosticFlowState>(diagnosticControllerProvider,
        (previous, next) {
      _hydrateWriting(next);
      final previousStatus = previous?.journey?.status;
      // Une session déjà terminée hydratée à l'ouverture ne constitue pas une
      // nouvelle conversion. Seule la transition vécue dans cet écran compte.
      if (shouldTrackDiagnosticCompletion(
        previousStatus,
        next.journey?.status,
      )) {
        _track(AudienceEvent.diagnosticCompleted);
      }
      if (!_accountGateTracked &&
          next.isGuest &&
          next.guestStep == DiagnosticGuestStep.accountRequired) {
        _accountGateTracked = true;
        _track(AudienceEvent.diagnosticAccountRequired);
      }
      if (!_resultViewedTracked &&
          next.journey?.nextStep == DiagnosticStep.result &&
          next.journey?.result != null) {
        _resultViewedTracked = true;
        _track(AudienceEvent.diagnosticResultViewed);
      }
    });

    final recordingActive = recording.canStop;
    return PopScope(
      canPop: !recordingActive && !state.isSubmitting && !state.isSyncing,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _confirmBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ScreenHeader(
                title: 'Diagnostic TCF',
                sub: _headerSub(state),
                onBack:
                    state.isSubmitting || state.isSyncing ? null : _confirmBack,
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
    required String? objective,
  }) {
    if (state.isGuest) return _guestContent(state: state, recording: recording);

    if (state.isSyncing) return DiagnosticSendingView(stage: state.syncStage);
    if (state.canRetrySync) {
      return DiagnosticSyncFailedView(
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
        errorMessage: state.errorMessage,
        onRefresh: () => unawaited(_controller.refreshDetail()),
        onRetry: () => unawaited(_controller.retryAnalysis()),
        onOpenPlan: () => context.go(AppRoutes.plan),
      );
    }
    return switch (journey.nextStep) {
      DiagnosticStep.presentation => DiagnosticIntro(
          isStarting: state.isSubmitting,
          errorMessage: state.errorMessage,
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
          onOpenPlan: () => context.go(AppRoutes.plan),
          onOpenRecommended: _openRecommended,
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
      DiagnosticGuestStep.presentation => DiagnosticIntro(
          isStarting: false,
          errorMessage: state.errorMessage,
          onStart: _startGuest,
        ),
      DiagnosticGuestStep.written => DiagnosticWrittenStep(
          exercise: subjects.written,
          controller: _writingController,
          wordCount: _wordCount,
          isSubmitting: state.isSubmitting,
          errorMessage: state.errorMessage ?? state.noticeMessage,
          onChanged: (text) => _onWritingChanged(text, isGuest: true),
          onSubmit: () => unawaited(_submitWritten(isGuest: true)),
        ),
      DiagnosticGuestStep.oral => DiagnosticOralStep(
          exercise: subjects.oral,
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
      DiagnosticGuestStep.accountRequired => DiagnosticAccountGate(
          errorMessage: state.errorMessage,
          noticeMessage: state.noticeMessage,
          onRegister: _openRegister,
          onLogin: _openLogin,
        ),
    };
  }

  Future<void> _startAuthenticated() async {
    final started = await _controller.startOrResume();
    if (started) _track(AudienceEvent.diagnosticStarted);
  }

  void _startGuest() {
    _controller.startGuest();
    _track(AudienceEvent.diagnosticStarted);
  }

  String _headerSub(DiagnosticFlowState state) {
    if (state.isSyncing) return 'Envoi de vos réponses';
    if (state.isGuest) {
      return switch (state.guestStep) {
        DiagnosticGuestStep.presentation => '2 exercices · environ 8 à 10 min',
        DiagnosticGuestStep.written => 'Étape 1 sur 2 · Écrit',
        DiagnosticGuestStep.oral => 'Étape 2 sur 2 · Oral',
        DiagnosticGuestStep.accountRequired => 'Analyser mes réponses',
      };
    }
    final journey = state.journey;
    if (journey == null || journey.nextStep == DiagnosticStep.presentation) {
      return '2 exercices · environ 8 à 10 min';
    }
    return _stepLabel(journey.nextStep);
  }

  static int _countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  static String _stepLabel(DiagnosticStep step) => switch (step) {
        DiagnosticStep.written => 'Étape 1 sur 2 · Écrit',
        DiagnosticStep.oral => 'Étape 2 sur 2 · Oral',
        DiagnosticStep.analysis => 'Analyse personnalisée',
        DiagnosticStep.result => 'Vos priorités',
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

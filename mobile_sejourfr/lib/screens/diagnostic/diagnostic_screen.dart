import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/api/audience_repository.dart';
import '../../core/api/repositories.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/skill_models.dart';
import '../../core/providers/target_level_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/screen_header.dart';
import '../tcf_production/audio_recorder_service.dart';
import '../tcf_production/competences/competences_nav.dart';
import '../tcf_production/tcf_production_module.dart';
import 'diagnostic_controller.dart';
import 'widgets/diagnostic_analysis.dart';
import 'widgets/diagnostic_common.dart';
import 'widgets/diagnostic_intro.dart';
import 'widgets/diagnostic_oral.dart';
import 'widgets/diagnostic_result.dart';
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
  final _writingController = TextEditingController();
  late final RecordingController _recordingController;
  int _wordCount = 0;
  bool _resultViewedTracked = false;

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

  Future<void> _start() async {
    final started =
        await ref.read(diagnosticControllerProvider.notifier).startOrResume();
    if (started) _track(AudienceEvent.diagnosticStarted);
  }

  Future<void> _submitWritten() async {
    FocusScope.of(context).unfocus();
    final submitted = await ref
        .read(diagnosticControllerProvider.notifier)
        .submitWritten(_writingController.text.trim());
    if (submitted) _track(AudienceEvent.diagnosticWrittenCompleted);
  }

  Future<void> _startRecording() async {
    final status = await _recordingController.requestPermission();
    if (!mounted || status != PermissionStatus.granted) return;
    final maxSeconds = ref
            .read(diagnosticControllerProvider)
            .journey
            ?.oral
            ?.durationMaxSeconds ??
        180;
    await _recordingController.start(
      maxDuration: Duration(seconds: maxSeconds),
    );
  }

  Future<void> _submitOral() async {
    final recording = ref.read(recordingControllerProvider);
    final path = recording.filePath;
    if (path == null) return;
    final submitted =
        await ref.read(diagnosticControllerProvider.notifier).submitOral(
              audioFile: File(path),
              mimeType: recording.fileMime,
            );
    if (!submitted) return;
    _track(AudienceEvent.diagnosticOralCompleted);
    await _recordingController.cancel();
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
    final module = exercise.section == SkillSection.eo
        ? TcfProductionModule.eo
        : TcfProductionModule.ee;
    context.push(
      competencePromptPath(
        module,
        exercise.skillId,
        exercise.skillPromptId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diagnosticControllerProvider);
    final recording = ref.watch(recordingControllerProvider);
    final objective = ref.watch(userTargetLevelProvider)?.wire;

    ref.listen<DiagnosticFlowState>(diagnosticControllerProvider,
        (previous, next) {
      final previousStatus = previous?.journey?.status;
      // Une session déjà terminée hydratée à l'ouverture ne constitue pas une
      // nouvelle conversion. Seule la transition vécue dans cet écran compte.
      if (shouldTrackDiagnosticCompletion(
        previousStatus,
        next.journey?.status,
      )) {
        _track(AudienceEvent.diagnosticCompleted);
      }
      if (!_resultViewedTracked &&
          next.journey?.nextStep == DiagnosticStep.result &&
          next.journey?.result != null) {
        _resultViewedTracked = true;
        _track(AudienceEvent.diagnosticResultViewed);
      }
    });

    final journey = state.journey;
    final recordingActive = recording.canStop;
    return PopScope(
      canPop: !recordingActive && !state.isSubmitting,
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
                sub: journey == null ||
                        journey.nextStep == DiagnosticStep.presentation
                    ? '2 exercices · environ 8 à 10 min'
                    : _stepLabel(journey.nextStep),
                onBack: state.isSubmitting ? null : _confirmBack,
              ),
              Expanded(
                child: journey == null
                    ? _InitialState(
                        isLoading: state.isLoading,
                        errorMessage: state.errorMessage,
                        onRetry: () => ref
                            .read(diagnosticControllerProvider.notifier)
                            .loadCurrent(),
                      )
                    : _content(
                        state: state,
                        journey: journey,
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
    required DiagnosticJourney journey,
    required RecordingState recording,
    required String? objective,
  }) {
    if (journey.status == DiagnosticJourneyStatus.failed ||
        journey.nextStep == DiagnosticStep.analysis) {
      return DiagnosticAnalysisView(
        journey: journey,
        isBusy: state.isSubmitting || state.isLoading,
        errorMessage: state.errorMessage,
        onRefresh: () =>
            ref.read(diagnosticControllerProvider.notifier).refreshDetail(),
        onRetry: () =>
            ref.read(diagnosticControllerProvider.notifier).retryAnalysis(),
      );
    }
    return switch (journey.nextStep) {
      DiagnosticStep.presentation => DiagnosticIntro(
          isStarting: state.isSubmitting,
          errorMessage: state.errorMessage,
          onStart: _start,
        ),
      DiagnosticStep.written when journey.written != null =>
        DiagnosticWrittenStep(
          exercise: journey.written!,
          controller: _writingController,
          wordCount: _wordCount,
          isSubmitting: state.isSubmitting,
          errorMessage: state.errorMessage,
          onChanged: (text) => setState(() => _wordCount = _countWords(text)),
          onSubmit: _submitWritten,
        ),
      DiagnosticStep.oral when journey.oral != null => DiagnosticOralStep(
          exercise: journey.oral!,
          recording: recording,
          isSubmitting: state.isSubmitting,
          errorMessage: state.errorMessage,
          onStart: _startRecording,
          onStop: () {
            unawaited(_recordingController.stop());
          },
          onReset: () {
            unawaited(_recordingController.cancel());
          },
          onOpenSettings: () {
            unawaited(_recordingController.openSystemSettings());
          },
          onSubmit: _submitOral,
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
          onRetry: () =>
              ref.read(diagnosticControllerProvider.notifier).refreshDetail(),
        ),
    };
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

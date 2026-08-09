import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/diagnostic_repository.dart';
import '../../core/api/repositories.dart';
import '../../core/models/diagnostic_models.dart';
import '../plan/learning_plan_provider.dart';

typedef SubmitDiagnosticText = Future<void> Function({
  required String productionTaskId,
  required String attemptId,
  required String texte,
});

Future<void> _defaultDiagnosticDelay(Duration duration) =>
    Future<void>.delayed(duration);

typedef SubmitDiagnosticAudio = Future<void> Function({
  required String productionTaskId,
  required String attemptId,
  required File audioFile,
  String? mimeType,
});

class DiagnosticFlowState {
  const DiagnosticFlowState({
    this.journey,
    this.isLoading = false,
    this.isSubmitting = false,
    this.isPolling = false,
    this.errorMessage,
  });

  final DiagnosticJourney? journey;
  final bool isLoading;
  final bool isSubmitting;
  final bool isPolling;
  final String? errorMessage;

  DiagnosticFlowState copyWith({
    DiagnosticJourney? journey,
    bool? isLoading,
    bool? isSubmitting,
    bool? isPolling,
    String? errorMessage,
    bool clearError = false,
  }) =>
      DiagnosticFlowState(
        journey: journey ?? this.journey,
        isLoading: isLoading ?? this.isLoading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        isPolling: isPolling ?? this.isPolling,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class DiagnosticController extends StateNotifier<DiagnosticFlowState> {
  DiagnosticController({
    required DiagnosticGateway diagnosticRepository,
    required SubmitDiagnosticText submitText,
    required SubmitDiagnosticAudio submitAudio,
    required void Function() onChanged,
    Duration pollInterval = const Duration(seconds: 3),
    int maxPolls = 60,
    Duration submissionRefreshInterval = const Duration(milliseconds: 700),
    int maxSubmissionRefreshes = 6,
    Future<void> Function(Duration) delay = _defaultDiagnosticDelay,
  })  : _diagnosticRepository = diagnosticRepository,
        _submitText = submitText,
        _submitAudio = submitAudio,
        _onChanged = onChanged,
        _pollInterval = pollInterval,
        _maxPolls = maxPolls,
        _submissionRefreshInterval = submissionRefreshInterval,
        _maxSubmissionRefreshes = maxSubmissionRefreshes,
        _delay = delay,
        super(const DiagnosticFlowState());

  final DiagnosticGateway _diagnosticRepository;
  final SubmitDiagnosticText _submitText;
  final SubmitDiagnosticAudio _submitAudio;
  final void Function() _onChanged;
  final Duration _pollInterval;
  final int _maxPolls;
  final Duration _submissionRefreshInterval;
  final int _maxSubmissionRefreshes;
  final Future<void> Function(Duration) _delay;
  int _pollGeneration = 0;

  Future<void> loadCurrent() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final journey = await _diagnosticRepository.current();
      if (!mounted) return;
      state = state.copyWith(journey: journey, isLoading: false);
      _pollIfNeeded(journey);
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: ApiClient.toApiException(error).message,
      );
    }
  }

  Future<bool> startOrResume() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final journey = await _diagnosticRepository.startOrResume();
      if (!mounted) return false;
      state = state.copyWith(journey: journey, isSubmitting: false);
      _onChanged();
      _pollIfNeeded(journey);
      return true;
    } catch (error) {
      _operationFailed(error);
      return false;
    }
  }

  Future<bool> submitWritten(String text) async {
    final exercise = state.journey?.written;
    if (exercise == null) return false;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _submitText(
        productionTaskId: exercise.productionTaskId,
        attemptId: exercise.attemptId,
        texte: text,
      );
      return await _reloadAfterSubmission(DiagnosticStep.written);
    } catch (error) {
      _operationFailed(error);
      return false;
    }
  }

  Future<bool> submitOral({
    required File audioFile,
    String? mimeType,
  }) async {
    final exercise = state.journey?.oral;
    if (exercise == null) return false;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _submitAudio(
        productionTaskId: exercise.productionTaskId,
        attemptId: exercise.attemptId,
        audioFile: audioFile,
        mimeType: mimeType,
      );
      return await _reloadAfterSubmission(DiagnosticStep.oral);
    } catch (error) {
      _operationFailed(error);
      return false;
    }
  }

  Future<void> refreshDetail() async {
    final sessionId = state.journey?.sessionId;
    if (sessionId == null) {
      await loadCurrent();
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final journey = await _diagnosticRepository.detail(sessionId);
      if (!mounted) return;
      state = state.copyWith(journey: journey, isLoading: false);
      _pollIfNeeded(journey);
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: ApiClient.toApiException(error).message,
      );
    }
  }

  Future<bool> retryAnalysis() async {
    final sessionId = state.journey?.sessionId;
    if (sessionId == null) return false;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final journey = await _diagnosticRepository.retryAnalysis(sessionId);
      if (!mounted) return false;
      state = state.copyWith(journey: journey, isSubmitting: false);
      _onChanged();
      _pollIfNeeded(journey);
      return true;
    } catch (error) {
      _operationFailed(error);
      return false;
    }
  }

  Future<bool> _reloadAfterSubmission(DiagnosticStep submittedStep) async {
    final sessionId = state.journey?.sessionId;
    if (sessionId == null) return false;
    DiagnosticJourney? journey;
    for (var attempt = 0; attempt < _maxSubmissionRefreshes; attempt++) {
      journey = await _diagnosticRepository.detail(sessionId);
      final submittedExercise = submittedStep == DiagnosticStep.written
          ? journey.written
          : journey.oral;
      final acknowledged =
          journey.status != DiagnosticJourneyStatus.inProgress ||
              journey.nextStep != submittedStep ||
              submittedExercise?.submissionId != null;
      if (acknowledged) break;
      if (attempt < _maxSubmissionRefreshes - 1) {
        await _delay(_submissionRefreshInterval);
      }
    }
    if (!mounted) return false;
    if (journey == null) return false;
    state = state.copyWith(
      journey: journey,
      isSubmitting: false,
      clearError: true,
    );
    _onChanged();
    _pollIfNeeded(journey);
    return true;
  }

  void _pollIfNeeded(DiagnosticJourney journey) {
    if (journey.nextStep != DiagnosticStep.analysis || journey.status.isFinal) {
      _pollGeneration++;
      if (state.isPolling) state = state.copyWith(isPolling: false);
      return;
    }
    final generation = ++_pollGeneration;
    unawaited(_poll(generation, journey.sessionId));
  }

  Future<void> _poll(int generation, String? sessionId) async {
    if (sessionId == null) return;
    state = state.copyWith(isPolling: true, clearError: true);
    for (var attempt = 0; attempt < _maxPolls; attempt++) {
      await _delay(_pollInterval);
      if (!mounted || generation != _pollGeneration) return;
      try {
        final journey = await _diagnosticRepository.detail(sessionId);
        if (!mounted || generation != _pollGeneration) return;
        state = state.copyWith(journey: journey, clearError: true);
        if (journey.status.isFinal ||
            journey.nextStep != DiagnosticStep.analysis) {
          state = state.copyWith(isPolling: false);
          _onChanged();
          return;
        }
      } catch (_) {
        // Une coupure ponctuelle ne doit pas abandonner une analyse serveur.
      }
    }
    if (!mounted || generation != _pollGeneration) return;
    state = state.copyWith(
      isPolling: false,
      errorMessage:
          'L’analyse continue en arrière-plan. Actualisez dans quelques instants.',
    );
  }

  void _operationFailed(Object error) {
    if (!mounted) return;
    state = state.copyWith(
      isSubmitting: false,
      errorMessage: ApiClient.toApiException(error).message,
    );
  }

  @override
  void dispose() {
    _pollGeneration++;
    super.dispose();
  }
}

final diagnosticControllerProvider = StateNotifierProvider.autoDispose<
    DiagnosticController, DiagnosticFlowState>((ref) {
  final production = ref.watch(productionRepositoryProvider);
  final controller = DiagnosticController(
    diagnosticRepository: ref.watch(diagnosticRepositoryProvider),
    submitText: ({
      required String productionTaskId,
      required String attemptId,
      required String texte,
    }) async {
      await production.submitText(
        productionTaskId: productionTaskId,
        attemptId: attemptId,
        texte: texte,
      );
    },
    submitAudio: ({
      required String productionTaskId,
      required String attemptId,
      required File audioFile,
      String? mimeType,
    }) async {
      await production.submitAudio(
        productionTaskId: productionTaskId,
        attemptId: attemptId,
        audioFile: audioFile,
        mimeType: mimeType,
      );
    },
    onChanged: () => ref.read(learningPlanRevisionProvider.notifier).state++,
  );
  unawaited(controller.loadCurrent());
  return controller;
});

final diagnosticHomeDismissedProvider =
    StateProvider.family<bool, String>((ref, userId) => false);

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/diagnostic_repository.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/diagnostic_models.dart';
import '../plan/learning_plan_provider.dart';
import 'diagnostic_draft_service.dart';

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

/// Étape du parcours **invité** : tant qu'aucun compte n'existe, il n'y a pas
/// de session serveur, donc pas de `nextStep` à lire — c'est le contenu de la
/// production locale qui dit où en est le visiteur.
enum DiagnosticGuestStep { presentation, written, oral, accountRequired }

class DiagnosticFlowState {
  const DiagnosticFlowState({
    this.journey,
    this.subjects,
    this.draft,
    this.guestStep = DiagnosticGuestStep.presentation,
    this.isGuest = false,
    this.isLoading = false,
    this.isSubmitting = false,
    this.isPolling = false,
    this.isSyncing = false,
    this.canRetrySync = false,
    this.errorMessage,
    this.noticeMessage,
  });

  /// Parcours serveur (compte existant). `null` tant que le visiteur n'a pas
  /// de session.
  final DiagnosticJourney? journey;

  /// Les deux sujets servis par la route publique, en régime invité.
  final PublicDiagnostic? subjects;

  /// Production locale du visiteur. Reste posée tant que le serveur n'a pas
  /// accusé réception des deux soumissions.
  final DiagnosticDraft? draft;

  final DiagnosticGuestStep guestStep;
  final bool isGuest;
  final bool isLoading;
  final bool isSubmitting;
  final bool isPolling;

  /// Envoi de la production locale vers la session fraîchement créée.
  final bool isSyncing;

  /// L'envoi a échoué : la production est intacte sur le téléphone et peut
  /// être renvoyée.
  final bool canRetrySync;

  final String? errorMessage;

  /// Message d'information (pas une erreur) — typiquement « ce compte a déjà
  /// passé son diagnostic ».
  final String? noticeMessage;

  DiagnosticFlowState copyWith({
    DiagnosticJourney? journey,
    PublicDiagnostic? subjects,
    DiagnosticDraft? draft,
    DiagnosticGuestStep? guestStep,
    bool? isGuest,
    bool? isLoading,
    bool? isSubmitting,
    bool? isPolling,
    bool? isSyncing,
    bool? canRetrySync,
    String? errorMessage,
    String? noticeMessage,
    bool clearError = false,
    bool clearNotice = false,
    bool clearDraft = false,
  }) =>
      DiagnosticFlowState(
        journey: journey ?? this.journey,
        subjects: subjects ?? this.subjects,
        draft: clearDraft ? null : (draft ?? this.draft),
        guestStep: guestStep ?? this.guestStep,
        isGuest: isGuest ?? this.isGuest,
        isLoading: isLoading ?? this.isLoading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        isPolling: isPolling ?? this.isPolling,
        isSyncing: isSyncing ?? this.isSyncing,
        canRetrySync: canRetrySync ?? this.canRetrySync,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        noticeMessage:
            clearNotice ? null : (noticeMessage ?? this.noticeMessage),
      );
}

class DiagnosticController extends StateNotifier<DiagnosticFlowState> {
  DiagnosticController({
    required DiagnosticGateway diagnosticRepository,
    required SubmitDiagnosticText submitText,
    required SubmitDiagnosticAudio submitAudio,
    required void Function() onChanged,
    DiagnosticDraftStore? draftStore,
    bool isAuthenticated = true,
    Duration pollInterval = const Duration(seconds: 3),
    int maxPolls = 60,
    Duration submissionRefreshInterval = const Duration(milliseconds: 700),
    int maxSubmissionRefreshes = 6,
    Future<void> Function(Duration) delay = _defaultDiagnosticDelay,
  })  : _diagnosticRepository = diagnosticRepository,
        _submitText = submitText,
        _submitAudio = submitAudio,
        _onChanged = onChanged,
        _draftStore = draftStore ?? DiagnosticDraftStore(),
        _isAuthenticated = isAuthenticated,
        _pollInterval = pollInterval,
        _maxPolls = maxPolls,
        _submissionRefreshInterval = submissionRefreshInterval,
        _maxSubmissionRefreshes = maxSubmissionRefreshes,
        _delay = delay,
        super(const DiagnosticFlowState());

  static const _localSaveWarning =
      'Votre réponse n’a pas pu être enregistrée sur cet appareil. '
      'Ne fermez pas l’application avant l’analyse.';

  static const _alreadyDoneNotice =
      'Ce compte a déjà passé le diagnostic : ses réponses sont enregistrées '
      'et chaque exercice ne s’envoie qu’une fois. Celles que vous venez de '
      'faire n’ont donc pas été envoyées — elles restent sur votre téléphone '
      'tant que vous ne les supprimez pas.';

  static const _partialSyncWarning =
      'Le serveur n’a pas confirmé la réception de vos deux réponses. Elles '
      'sont conservées sur votre téléphone, vous pouvez réessayer.';

  final DiagnosticGateway _diagnosticRepository;
  final SubmitDiagnosticText _submitText;
  final SubmitDiagnosticAudio _submitAudio;
  final void Function() _onChanged;
  final DiagnosticDraftStore _draftStore;
  final bool _isAuthenticated;
  final Duration _pollInterval;
  final int _maxPolls;
  final Duration _submissionRefreshInterval;
  final int _maxSubmissionRefreshes;
  final Future<void> Function(Duration) _delay;
  int _pollGeneration = 0;

  Future<void> loadCurrent() async {
    if (state.isLoading || state.isSyncing) return;
    state = state.copyWith(isLoading: true, clearError: true);
    final draft = await _readDraft();
    if (!mounted) return;

    if (!_isAuthenticated) {
      await _loadGuest(draft);
      return;
    }

    // Compte connecté avec une production faite en invité : on l'envoie avant
    // toute chose, c'est le seul endroit où elle peut encore être perdue.
    if (draft != null && draft.isComplete) {
      state = state.copyWith(draft: draft, isLoading: false, isGuest: false);
      await syncLocalProductions();
      return;
    }

    try {
      final journey = await _diagnosticRepository.current();
      if (!mounted) return;
      state = state.copyWith(
        journey: journey,
        draft: draft,
        isLoading: false,
        isGuest: false,
      );
      _pollIfNeeded(journey);
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: ApiClient.toApiException(error).message,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Régime invité : produire d'abord, créer le compte ensuite
  // ---------------------------------------------------------------------------

  Future<void> _loadGuest(DiagnosticDraft? draft) async {
    try {
      final subjects = await _diagnosticRepository.publicCurrent();
      if (!mounted) return;
      final usable = draft != null &&
          draft.matches(subjects.diagnosticCode, subjects.diagnosticVersion);
      state = state.copyWith(
        isGuest: true,
        subjects: subjects,
        draft: draft,
        guestStep: _resumeStep(usable ? draft : null, draft),
        isLoading: false,
        noticeMessage: draft != null && !usable
            ? 'Les sujets du diagnostic ont été mis à jour. Votre texte est '
                'conservé, mais l’enregistrement est à refaire.'
            : null,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isGuest: true,
        draft: draft,
        isLoading: false,
        errorMessage: ApiClient.toApiException(error).message,
      );
    }
  }

  /// Étape de reprise. [usable] est la production rattachée aux sujets
  /// courants ; [any] sert seulement à décider si le visiteur avait déjà
  /// commencé (on ne lui réaffiche pas la présentation dans ce cas).
  static DiagnosticGuestStep _resumeStep(
    DiagnosticDraft? usable,
    DiagnosticDraft? any,
  ) {
    if (usable == null) {
      return any == null || any.isEmpty
          ? DiagnosticGuestStep.presentation
          : DiagnosticGuestStep.written;
    }
    if (usable.isComplete) return DiagnosticGuestStep.accountRequired;
    if (usable.hasWritten) return DiagnosticGuestStep.oral;
    return DiagnosticGuestStep.written;
  }

  void startGuest() {
    state = state.copyWith(
      guestStep: DiagnosticGuestStep.written,
      clearError: true,
    );
  }

  /// Sauvegarde silencieuse pendant la frappe. Jamais bloquante, jamais
  /// signalée : elle ne fait que réduire la fenêtre de perte.
  Future<void> autosaveGuestWritten(String text) async {
    final subjects = state.subjects;
    if (subjects == null || text.trim().isEmpty) return;
    try {
      final draft = await _draftStore.saveWritten(
        diagnosticCode: subjects.diagnosticCode,
        diagnosticVersion: subjects.diagnosticVersion,
        taskId: subjects.written.productionTaskId,
        text: text,
      );
      if (!mounted) return;
      state = state.copyWith(draft: draft);
    } catch (_) {
      // L'échec est signalé au moment de valider l'étape, pas pendant la frappe.
    }
  }

  Future<bool> submitGuestWritten(String text) async {
    final subjects = state.subjects;
    if (subjects == null) return false;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final draft = await _draftStore.saveWritten(
        diagnosticCode: subjects.diagnosticCode,
        diagnosticVersion: subjects.diagnosticVersion,
        taskId: subjects.written.productionTaskId,
        text: text,
      );
      if (!mounted) return false;
      state = state.copyWith(
        draft: draft,
        isSubmitting: false,
        guestStep: DiagnosticGuestStep.oral,
        clearError: true,
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      // Le disque a refusé, mais le texte est en mémoire : on avance en le
      // gardant en état plutôt que de bloquer le visiteur sur son écrit.
      state = state.copyWith(
        draft: DiagnosticDraft(
          diagnosticCode: subjects.diagnosticCode,
          diagnosticVersion: subjects.diagnosticVersion,
          writtenTaskId: subjects.written.productionTaskId,
          writtenText: text,
        ),
        isSubmitting: false,
        guestStep: DiagnosticGuestStep.oral,
        errorMessage: _localSaveWarning,
      );
      return true;
    }
  }

  Future<bool> submitGuestOral({
    required File audioFile,
    String? mimeType,
  }) async {
    final subjects = state.subjects;
    if (subjects == null) return false;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final draft = await _draftStore.saveOral(
        diagnosticCode: subjects.diagnosticCode,
        diagnosticVersion: subjects.diagnosticVersion,
        taskId: subjects.oral.productionTaskId,
        source: audioFile,
        mimeType: mimeType,
      );
      if (!mounted) return false;
      state = state.copyWith(
        draft: draft,
        isSubmitting: false,
        guestStep: DiagnosticGuestStep.accountRequired,
        clearError: true,
        clearNotice: true,
      );
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: ApiClient.toApiException(error).message,
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Bascule après authentification
  // ---------------------------------------------------------------------------

  /// Crée la session serveur puis envoie l'écrit, attend son enregistrement,
  /// envoie l'oral, attend le sien — et **seulement ensuite** efface la copie
  /// locale. Tout échec conserve la production et laisse la main.
  Future<bool> syncLocalProductions() async {
    if (state.isSyncing) return false;
    final draft = state.draft ?? await _readDraft();
    if (draft == null || !draft.isComplete) {
      await loadCurrent();
      return false;
    }
    state = state.copyWith(
      draft: draft,
      isSyncing: true,
      isLoading: false,
      canRetrySync: false,
      clearError: true,
      clearNotice: true,
    );
    try {
      var journey = await _diagnosticRepository.startOrResume();
      if (!mounted) return false;
      state = state.copyWith(journey: journey);
      _onChanged();

      if (_alreadyDone(journey)) {
        state = state.copyWith(
          journey: journey,
          isSyncing: false,
          noticeMessage: _alreadyDoneNotice,
        );
        _pollIfNeeded(journey);
        return false;
      }

      final written = journey.written;
      if (written != null && written.submissionId == null) {
        await _submitText(
          productionTaskId: written.productionTaskId,
          attemptId: written.attemptId,
          texte: draft.writtenText!,
        );
        journey = await _awaitAcknowledgement(
              journey.sessionId,
              DiagnosticStep.written,
            ) ??
            journey;
        if (!mounted) return false;
        state = state.copyWith(journey: journey);
      }

      final oral = journey.oral;
      if (oral != null && oral.submissionId == null) {
        final file = await _draftStore.audioFile(draft);
        if (file == null) {
          throw StateError('Enregistrement introuvable sur cet appareil.');
        }
        await _submitAudio(
          productionTaskId: oral.productionTaskId,
          attemptId: oral.attemptId,
          audioFile: file,
          mimeType: draft.audioMime,
        );
        journey = await _awaitAcknowledgement(
              journey.sessionId,
              DiagnosticStep.oral,
            ) ??
            journey;
        if (!mounted) return false;
      }

      if (!_serverHasBothProductions(journey)) {
        state = state.copyWith(
          journey: journey,
          isSyncing: false,
          canRetrySync: true,
          errorMessage: _partialSyncWarning,
        );
        return false;
      }

      // Accusé de réception des DEUX productions : la copie locale n'a plus
      // de raison d'être.
      await _clearDraft();
      if (!mounted) return false;
      state = state.copyWith(
        journey: journey,
        isSyncing: false,
        canRetrySync: false,
        clearDraft: true,
        clearError: true,
      );
      _onChanged();
      _pollIfNeeded(journey);
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        isSyncing: false,
        canRetrySync: true,
        errorMessage: ApiClient.toApiException(error).message,
      );
      return false;
    }
  }

  /// La session du compte a déjà consommé ses deux tâches — une tâche
  /// n'accepte qu'une soumission, il n'y a plus rien à envoyer.
  static bool _alreadyDone(DiagnosticJourney journey) {
    if (journey.status == DiagnosticJourneyStatus.completed ||
        journey.status == DiagnosticJourneyStatus.analyzing ||
        journey.status == DiagnosticJourneyStatus.failed) {
      return true;
    }
    return _serverHasBothProductions(journey);
  }

  static bool _serverHasBothProductions(DiagnosticJourney journey) {
    if (journey.status == DiagnosticJourneyStatus.analyzing ||
        journey.status == DiagnosticJourneyStatus.completed) {
      return true;
    }
    return journey.written?.submissionId != null &&
        journey.oral?.submissionId != null;
  }

  /// Efface la copie locale sur demande explicite du candidat.
  Future<void> discardLocalProductions() async {
    await _clearDraft();
    if (!mounted) return;
    state = state.copyWith(
      clearDraft: true,
      clearNotice: true,
      clearError: true,
      canRetrySync: false,
    );
  }

  void dismissNotice() {
    state = state.copyWith(clearNotice: true);
  }

  Future<DiagnosticDraft?> _readDraft() async {
    try {
      return await _draftStore.read();
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearDraft() async {
    try {
      await _draftStore.clear();
    } catch (_) {
      // Une clé résiduelle ne doit pas transformer un envoi réussi en échec.
    }
  }

  // ---------------------------------------------------------------------------
  // Régime connecté (inchangé)
  // ---------------------------------------------------------------------------

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
    final journey = await _awaitAcknowledgement(sessionId, submittedStep);
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

  /// Relit le détail jusqu'à ce que le serveur ait pris en compte la
  /// soumission de [submittedStep].
  Future<DiagnosticJourney?> _awaitAcknowledgement(
    String? sessionId,
    DiagnosticStep submittedStep,
  ) async {
    if (sessionId == null) return null;
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
    return journey;
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
  // `select` : seule la bascule connecté ⇄ invité doit recréer le contrôleur.
  // Un simple rafraîchissement du user (statut Premium, profil) ne doit pas
  // relancer le parcours.
  final isAuthenticated = ref.watch(
    authControllerProvider.select((state) => state is AuthAuthenticated),
  );
  final controller = DiagnosticController(
    diagnosticRepository: ref.watch(diagnosticRepositoryProvider),
    draftStore: ref.watch(diagnosticDraftStoreProvider),
    isAuthenticated: isAuthenticated,
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

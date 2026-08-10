import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sejourfr_mobile/core/api/diagnostic_repository.dart';
import 'package:sejourfr_mobile/core/models/diagnostic_models.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';
import 'package:sejourfr_mobile/screens/diagnostic/diagnostic_controller.dart';
import 'package:sejourfr_mobile/screens/diagnostic/diagnostic_screen.dart';

void main() {
  test('ne compte COMPLETED que sur une vraie transition vécue', () {
    expect(
      shouldTrackDiagnosticCompletion(
        null,
        DiagnosticJourneyStatus.completed,
      ),
      isFalse,
    );
    expect(
      shouldTrackDiagnosticCompletion(
        DiagnosticJourneyStatus.analyzing,
        DiagnosticJourneyStatus.completed,
      ),
      isTrue,
    );
  });

  test('reprend la session serveur et passe à l’oral après l’écrit', () async {
    final gateway = _FakeDiagnosticGateway(
      currentJourney: _journey(
        status: DiagnosticJourneyStatus.inProgress,
        step: DiagnosticStep.written,
      ),
      detailJourneys: [
        _journey(
          status: DiagnosticJourneyStatus.inProgress,
          step: DiagnosticStep.written,
        ),
        _journey(
          status: DiagnosticJourneyStatus.inProgress,
          step: DiagnosticStep.oral,
          writtenSubmitted: true,
        ),
      ],
    );
    String? submittedText;
    var changes = 0;
    final controller = DiagnosticController(
      diagnosticRepository: gateway,
      submitText: ({
        required productionTaskId,
        required attemptId,
        required texte,
      }) async {
        submittedText = texte;
      },
      submitAudio: _unusedAudioSubmit,
      onChanged: () => changes++,
      delay: (_) async {},
    );
    addTearDown(controller.dispose);

    await controller.loadCurrent();
    expect(controller.state.journey?.nextStep, DiagnosticStep.written);

    final submitted = await controller.submitWritten('Mon texte diagnostic');

    expect(submitted, isTrue);
    expect(submittedText, 'Mon texte diagnostic');
    expect(controller.state.journey?.nextStep, DiagnosticStep.oral);
    expect(controller.state.isSubmitting, isFalse);
    expect(gateway.detailCalls, 2);
    expect(changes, 1);
  });

  test('poll l’analyse jusqu’au résultat final et invalide le plan', () async {
    final completed = Completer<void>();
    final gateway = _FakeDiagnosticGateway(
      currentJourney: _journey(
        status: DiagnosticJourneyStatus.analyzing,
        step: DiagnosticStep.analysis,
        writtenSubmitted: true,
        oralSubmitted: true,
      ),
      detailJourneys: [
        _journey(
          status: DiagnosticJourneyStatus.completed,
          step: DiagnosticStep.result,
          writtenSubmitted: true,
          oralSubmitted: true,
        ),
      ],
    );
    var changes = 0;
    final controller = DiagnosticController(
      diagnosticRepository: gateway,
      submitText: _unusedTextSubmit,
      submitAudio: _unusedAudioSubmit,
      onChanged: () {
        changes++;
        completed.complete();
      },
      pollInterval: Duration.zero,
      maxPolls: 2,
      delay: (_) async {},
    );
    addTearDown(controller.dispose);

    await controller.loadCurrent();
    await completed.future.timeout(const Duration(seconds: 1));

    expect(controller.state.journey?.status, DiagnosticJourneyStatus.completed);
    expect(controller.state.isPolling, isFalse);
    expect(changes, 1);
  });
}

Future<void> _unusedTextSubmit({
  required String productionTaskId,
  required String attemptId,
  required String texte,
}) async {}

Future<void> _unusedAudioSubmit({
  required String productionTaskId,
  required String attemptId,
  required File audioFile,
  String? mimeType,
}) async {}

DiagnosticJourney _journey({
  required DiagnosticJourneyStatus status,
  required DiagnosticStep step,
  bool writtenSubmitted = false,
  bool oralSubmitted = false,
}) =>
    DiagnosticJourney(
      sessionId: 'session-1',
      diagnosticCode: 'INITIAL_TCF',
      diagnosticVersion: 1,
      status: status,
      nextStep: step,
      canRetry: status == DiagnosticJourneyStatus.failed,
      written: DiagnosticExercise(
        productionTaskId: 'written-task',
        attemptId: 'written-attempt',
        epreuve: EpreuveType.tcfEe,
        title: 'Écrit',
        instruction: 'Écrivez.',
        helperText: '',
        wordsMin: 100,
        wordsMax: 130,
        submissionId: writtenSubmitted ? 'written-submission' : null,
      ),
      oral: DiagnosticExercise(
        productionTaskId: 'oral-task',
        attemptId: 'oral-attempt',
        epreuve: EpreuveType.tcfEo,
        title: 'Oral',
        instruction: 'Parlez.',
        helperText: '',
        durationMinSeconds: 120,
        durationMaxSeconds: 180,
        submissionId: oralSubmitted ? 'oral-submission' : null,
      ),
      result: step == DiagnosticStep.result
          ? const DiagnosticResult(strengths: [], priorities: [])
          : null,
    );

class _FakeDiagnosticGateway implements DiagnosticGateway {
  _FakeDiagnosticGateway({
    required this.currentJourney,
    required List<DiagnosticJourney> detailJourneys,
  }) : _detailJourneys = detailJourneys;

  final DiagnosticJourney currentJourney;
  final List<DiagnosticJourney> _detailJourneys;
  var _detailIndex = 0;
  int get detailCalls => _detailIndex;

  @override
  Future<PublicDiagnostic> publicCurrent() =>
      throw UnimplementedError('Ces cas couvrent le parcours connecté.');

  @override
  Future<DiagnosticJourney> current() async => currentJourney;

  @override
  Future<DiagnosticJourney> startOrResume() async => currentJourney;

  @override
  Future<DiagnosticJourney> detail(String sessionId) async {
    final index = _detailIndex.clamp(0, _detailJourneys.length - 1);
    _detailIndex++;
    return _detailJourneys[index];
  }

  @override
  Future<DiagnosticJourney> retryAnalysis(String sessionId) async =>
      currentJourney;
}

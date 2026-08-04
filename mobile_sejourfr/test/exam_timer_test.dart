import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sejourfr_mobile/core/models/attempt_models.dart';
import 'package:sejourfr_mobile/screens/question_runner/widgets/exam_timer.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ExamTimer ancré sur startedAt', () {
    testWidgets('affiche le temps restant, pas la durée totale', (tester) async {
      var elapsed = false;
      await tester.pumpWidget(_host(ExamTimer(
        durationSeconds: 900,
        startedAt: DateTime.now().subtract(const Duration(minutes: 3)),
        onElapsed: () => elapsed = true,
      )));

      expect(find.text('11:59'), findsOneWidget);
      expect(elapsed, isFalse);
    });

    testWidgets('déclenche onElapsed quand le temps est déjà écoulé',
        (tester) async {
      var elapsed = false;
      await tester.pumpWidget(_host(ExamTimer(
        durationSeconds: 900,
        startedAt: DateTime.now().subtract(const Duration(seconds: 901)),
        onElapsed: () => elapsed = true,
      )));

      expect(elapsed, isTrue);
      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('ne déclenche onElapsed qu\'une fois', (tester) async {
      var calls = 0;
      await tester.pumpWidget(_host(ExamTimer(
        durationSeconds: 900,
        startedAt: DateTime.now().subtract(const Duration(seconds: 901)),
        onElapsed: () => calls++,
      )));
      await tester.pump(const Duration(seconds: 3));

      expect(calls, 1);
    });
  });

  group('Attempt.timeLimitSeconds (miroir backend)', () {
    Map<String, dynamic> productionAttemptJson({int? timeLimitSeconds}) => {
          'id': 'a1',
          'type': 'MOCK_EXAM',
          'module': 'TCF',
          'startedAt': '2026-08-04T10:00:00',
          if (timeLimitSeconds != null) 'timeLimitSeconds': timeLimitSeconds,
        };

    test('session d\'examen EO : 900 s exposées au chrono', () {
      final attempt =
          Attempt.fromJson(productionAttemptJson(timeLimitSeconds: 900));

      expect(attempt.timeLimitSeconds, 900);
      expect(attempt.type, AttemptType.mockExam);
      // Un attempt de production n'a pas de questions QCM.
      expect(attempt.totalQuestions, 0);
    });

    test('session d\'examen EE : 1800 s', () {
      expect(
        Attempt.fromJson(productionAttemptJson(timeLimitSeconds: 1800))
            .timeLimitSeconds,
        1800,
      );
    });

    test('absence de limite = null (entraînement libre, sous-attempt complet)',
        () {
      expect(Attempt.fromJson(productionAttemptJson()).timeLimitSeconds, isNull);
    });
  });
}

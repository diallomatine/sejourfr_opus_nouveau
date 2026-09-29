import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sejourfr_mobile/core/api/api_exception.dart';
import 'package:sejourfr_mobile/core/utils/start_failure.dart';

void main() {
  group('classifyStartFailure', () {
    test('403 = verrou freemium serveur → paywall', () {
      final error = ApiException(
        statusCode: 403,
        message: 'Cet examen blanc est réservé aux abonnés.',
      );
      expect(classifyStartFailure(error), StartFailure.paywall);
    });

    test('403 emballé dans une DioException → paywall', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/attempts'),
        type: DioExceptionType.badResponse,
        error: ApiException(statusCode: 403, message: 'Abonnement requis'),
      );
      expect(classifyStartFailure(error), StartFailure.paywall);
    });

    test('400 slot hors bornes → message, pas de paywall', () {
      final error = ApiException(
        statusCode: 400,
        message: 'slotNumber doit être compris entre 1 et 20.',
      );
      expect(classifyStartFailure(error), StartFailure.message);
    });

    test('401, 409, 500 et coupure réseau → message', () {
      for (final status in [401, 409, 500, 0]) {
        expect(
          classifyStartFailure(ApiException(statusCode: status, message: 'x')),
          StartFailure.message,
          reason: 'statut $status',
        );
      }
    });

    test('erreur non-HTTP → message', () {
      expect(
        classifyStartFailure(StateError('Aucune tâche EO pour cet examen.')),
        StartFailure.message,
      );
    });
  });
}

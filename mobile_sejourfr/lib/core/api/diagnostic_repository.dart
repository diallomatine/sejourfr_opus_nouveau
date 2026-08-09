import '../models/diagnostic_models.dart';
import 'api_client.dart';

abstract interface class DiagnosticGateway {
  Future<DiagnosticJourney> current();
  Future<DiagnosticJourney> startOrResume();
  Future<DiagnosticJourney> detail(String sessionId);
  Future<DiagnosticJourney> retryAnalysis(String sessionId);
}

class DiagnosticRepository implements DiagnosticGateway {
  DiagnosticRepository(this._client);

  final ApiClient _client;

  @override
  Future<DiagnosticJourney> current() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/diagnostics/current',
    );
    return DiagnosticJourney.fromJson(response.data!);
  }

  @override
  Future<DiagnosticJourney> startOrResume() async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/diagnostics',
    );
    return DiagnosticJourney.fromJson(response.data!);
  }

  @override
  Future<DiagnosticJourney> detail(String sessionId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/diagnostics/$sessionId',
    );
    return DiagnosticJourney.fromJson(response.data!);
  }

  @override
  Future<DiagnosticJourney> retryAnalysis(String sessionId) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/diagnostics/$sessionId/retry-analysis',
    );
    return DiagnosticJourney.fromJson(response.data!);
  }
}

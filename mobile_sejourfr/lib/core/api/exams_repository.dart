import '../models/enums.dart';
import '../models/exam_models.dart';
import 'api_client.dart';

/// Endpoints publics (pas d'auth requise pour consulter, mais le démarrage
/// d'un attempt sur un template premium passera par le paywall côté backend).
///   GET /api/exams[?module=CIVIQUE|TCF]
///   GET /api/exams/{slug}
class ExamsRepository {
  ExamsRepository(this._client);

  final ApiClient _client;

  Future<List<ExamTemplateSummary>> list({AppModule? module}) async {
    final res = await _client.dio.get<List<dynamic>>(
      '/api/exams',
      queryParameters: {
        if (module != null) 'module': module.wire,
      },
    );
    return (res.data ?? [])
        .map((e) => ExamTemplateSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ExamTemplateSummary> getBySlug(String slug) async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/exams/$slug',
    );
    return ExamTemplateSummary.fromJson(res.data!);
  }
}

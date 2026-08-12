import '../models/diagnostic_models.dart';
import 'api_client.dart';

class LearningPlanRepository {
  LearningPlanRepository(this._client);

  final ApiClient _client;

  Future<LearningPlan> get() async {
    final response =
        await _client.dio.get<Map<String, dynamic>>('/api/me/plan');
    return LearningPlan.fromJson(response.data!);
  }
}

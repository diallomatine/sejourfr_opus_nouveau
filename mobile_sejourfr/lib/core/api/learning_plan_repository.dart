import '../models/diagnostic_models.dart';
import '../models/journey_models.dart';
import 'api_client.dart';

class LearningPlanRepository {
  LearningPlanRepository(this._client);

  final ApiClient _client;

  Future<LearningPlan> get() async {
    final response =
        await _client.dio.get<Map<String, dynamic>>('/api/me/plan');
    return LearningPlan.fromJson(response.data!);
  }

  /// **Le parcours TCF** : la file d'étapes, l'étape courante et son verrou.
  ///
  /// 🛑 **Aucun `targetLevel` en paramètre** : le serveur connaît le niveau visé
  /// du candidat, et l'accepter d'un client laisserait demander un parcours qui
  /// n'est pas le sien.
  ///
  /// [toutesLesEtapes] rend **toutes** les étapes non obsolètes au lieu du
  /// sous-ensemble d'affichage — ce que demande « Voir les étapes suivantes ».
  Future<Journey> journey({bool toutesLesEtapes = false}) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/me/plan/journey',
      queryParameters: toutesLesEtapes ? const {'expand': 'all'} : null,
    );
    return Journey.fromJson(response.data!);
  }
}

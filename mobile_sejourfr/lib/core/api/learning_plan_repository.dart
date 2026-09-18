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
  /// ⚠️ **Plus de `?expand=all`** (2026-09-18) : il ne concernait que la file
  /// plate `steps`, remplacée par les blocs — qui portent **toujours** toutes
  /// les étapes, sans plafond d'affichage donc sans repli à déplier.
  Future<Journey> journey() async {
    final response =
        await _client.dio.get<Map<String, dynamic>>('/api/me/plan/journey');
    return Journey.fromJson(response.data!);
  }

  /// **Actualiser mon plan** — le cycle en attente devient le cycle courant
  /// (spec §6). Rend le parcours **frais**.
  ///
  /// 🛑 **Aucun corps, aucun query param** : le serveur sait quel est le cycle
  /// en cours du candidat, et accepter un identifiant laisserait historiser
  /// celui d'un autre. **409** si le cycle n'est pas terminé.
  Future<Journey> refresh() async {
    final response = await _client.dio
        .post<Map<String, dynamic>>('/api/me/plan/journey/refresh');
    return Journey.fromJson(response.data!);
  }

  /// **Passer l'examen blanc complet** — crée le **cycle de mesure**.
  ///
  /// 🛑 **Il ne démarre aucun examen** : l'examen blanc complet reste lancé par
  /// `FullTcfExamRepository.start`, son unique point d'entrée. **409** si le
  /// cycle n'est pas terminé, ou s'il est déjà un cycle de mesure.
  Future<Journey> measurementCycle() async {
    final response = await _client.dio
        .post<Map<String, dynamic>>('/api/me/plan/journey/measurement-cycle');
    return Journey.fromJson(response.data!);
  }
}

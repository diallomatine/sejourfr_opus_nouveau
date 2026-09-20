import '../models/attempt_models.dart';
import '../models/diagnostic_models.dart';
import '../models/enums.dart';
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

  /// **Le parcours** : la file d'étapes, l'étape courante et son verrou.
  ///
  /// 🛑 **`?module=` depuis P8.7** : le cycle existe pour les DEUX modules, et
  /// c'est l'appelant qui sait lequel il affiche. Le TCF reste le défaut — un
  /// appelant qui ne dit rien garde exactement le comportement d'avant.
  ///
  /// 🛑 **Aucun `targetLevel` en paramètre** : le serveur connaît le niveau visé
  /// du candidat, et l'accepter d'un client laisserait demander un parcours qui
  /// n'est pas le sien.
  ///
  /// ⚠️ **Plus de `?expand=all`** (2026-09-18) : il ne concernait que la file
  /// plate `steps`, remplacée par les blocs — qui portent **toujours** toutes
  /// les étapes, sans plafond d'affichage donc sans repli à déplier.
  Future<Journey> journey({AppModule module = AppModule.tcf}) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/me/plan/journey',
      queryParameters: {'module': module.wire},
    );
    return Journey.fromJson(response.data!);
  }

  /// **Le détail d'une étape de séries** — l'écran intermédiaire du Plan.
  ///
  /// 🛑 **Aucun query param, aucun module** : le `stepId` désigne une étape du
  /// parcours du candidat authentifié, et le serveur sait à quel module elle
  /// appartient. Un module en paramètre aurait été une seconde autorité.
  Future<JourneyStepDetail> stepDetail(String stepId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/me/plan/journey/steps/$stepId',
    );
    return JourneyStepDetail.fromJson(response.data!);
  }

  /// **Démarrer une série de l'étape.**
  ///
  /// 🛑 **L'index est SERVI** ([JourneySerie.index]) : on le repasse tel quel,
  /// on ne le compte pas. Le serveur oppose le verrou — **403** sur une série
  /// fermée comme sur une étape sans accès —, et ce refus ouvre l'offre, jamais
  /// un message technique.
  Future<Attempt> startSerie(String stepId, int index) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/me/plan/journey/steps/$stepId/series/$index',
    );
    return Attempt.fromJson(response.data!);
  }

  /// **L'historique des cycles** — l'archive derriere « Voir ma progression ».
  ///
  /// 🛑 **Le MODULE est le seul query param** : le serveur sert les cycles du
  /// candidat authentifie, et accepter un identifiant laisserait lire l'archive
  /// d'un tiers.
  Future<JourneyHistory> history({AppModule module = AppModule.tcf}) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/me/plan/journey/history',
      queryParameters: {'module': module.wire},
    );
    return JourneyHistory.fromJson(response.data!);
  }

  /// **Actualiser mon plan** — le cycle en attente devient le cycle courant
  /// (spec §6). Rend le parcours **frais**.
  ///
  /// 🛑 **Aucun corps, et le seul query param est le MODULE** : le serveur sait
  /// quel est le cycle en cours du candidat, et accepter un identifiant
  /// laisserait historiser celui d'un autre. **409** si le cycle n'est pas
  /// terminé.
  Future<Journey> refresh({AppModule module = AppModule.tcf}) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/me/plan/journey/refresh',
      queryParameters: {'module': module.wire},
    );
    return Journey.fromJson(response.data!);
  }

  /// **Passer l'examen blanc complet** — crée le **cycle de mesure**.
  ///
  /// 🛑 **Il ne démarre aucun examen** : l'examen blanc complet reste lancé par
  /// `FullTcfExamRepository.start` côté TCF et par `AttemptsRepository.start`
  /// côté civique — leurs uniques points d'entrée. **409** si le cycle n'est pas
  /// terminé, ou s'il est déjà un cycle de mesure.
  Future<Journey> measurementCycle({AppModule module = AppModule.tcf}) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/me/plan/journey/measurement-cycle',
      queryParameters: {'module': module.wire},
    );
    return Journey.fromJson(response.data!);
  }
}

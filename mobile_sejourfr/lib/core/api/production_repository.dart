import 'dart:io';

import 'package:dio/dio.dart';

import '../models/attempt_models.dart';
import '../models/enums.dart';
import '../models/production_models.dart';
import 'api_client.dart';

/// Acces aux endpoints du pipeline EO/EE :
///   GET  /api/production-tasks?epreuve=...&niveau=...
///   GET  /api/production-tasks/{id}
///   POST /api/production-submissions   (multipart audio OU JSON texte)
///   POST /api/production-submissions/{id}/retry
///   GET  /api/production-submissions/{id}
///   GET  /api/users/me/production-submissions?epreuve=...
class ProductionRepository {
  ProductionRepository(this._client);

  final ApiClient _client;

  /// Cree un attempt vide pour une epreuve productive (TCF_EO / TCF_EE / TCF_COMPLET).
  /// Le retour reutilise le DTO Attempt existant (la liste des questions est vide).
  ///
  /// En session d'examen blanc module, passer `exam: true` + `slotNumber` (1-10)
  /// pour que le backend compose les 3 sujets déterministes du slot et expose
  /// `timeLimitSeconds` (= 1800 pour l'EE module ; null pour l'EO).
  Future<Attempt> startProductionAttempt({
    required EpreuveType epreuve,
    String? parentAttemptId,
    bool exam = false,
    int? slotNumber,
  }) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/attempts/production',
      data: {
        'module': 'TCF',
        'epreuve': epreuve.wire,
        if (parentAttemptId != null) 'parentAttemptId': parentAttemptId,
        if (exam) 'exam': true,
        if (slotNumber != null) 'slotNumber': slotNumber,
      },
    );
    return Attempt.fromJson(res.data!);
  }

  /// Les **3 tâches déterministes** (T1, T2, T3) composant une session d'examen
  /// blanc EE/EO. Fonctionne pour un attempt d'examen module ET pour un
  /// sous-attempt EE/EO d'un examen TCF complet. 400 sur un attempt
  /// d'entraînement libre.
  ///   GET /api/attempts/{attemptId}/production-exam-tasks
  Future<List<ProductionTaskDto>> getExamTasks(String attemptId) async {
    final res = await _client.dio.get<List<dynamic>>(
      '/api/attempts/$attemptId/production-exam-tasks',
    );
    return (res.data ?? [])
        .map((e) => ProductionTaskDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Finalise un attempt de production (pose `finishedAt`). Après finish, toute
  /// soumission vers cet attempt est rejetée 400.
  ///   POST /api/attempts/{id}/finish
  Future<Attempt> finishAttempt(String attemptId) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/attempts/$attemptId/finish',
    );
    return Attempt.fromJson(res.data!);
  }

  /// Catalogue des taches actives pour une epreuve + un niveau cible,
  /// optionnellement filtre par numero de tache (1, 2 ou 3).
  Future<List<ProductionTaskDto>> listTasks({
    required EpreuveType epreuve,
    String? niveau,
    int? tacheNumero,
  }) async {
    final res = await _client.dio.get<List<dynamic>>(
      '/api/production-tasks',
      queryParameters: {
        'epreuve': epreuve.wire,
        if (niveau != null && niveau.isNotEmpty) 'niveau': niveau,
        if (tacheNumero != null) 'tacheNumero': tacheNumero,
      },
    );
    return (res.data ?? [])
        .map((e) => ProductionTaskDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Derniere submission de l'utilisateur pour chaque numero de tache (1..3),
  /// pour un (epreuve, niveau) donne. Renvoie 0 a 3 elements. Utilise par
  /// le hub d'entrainement pour afficher la derniere note sur chaque card.
  Future<List<ProductionSubmissionDto>> listLastPerTask({
    required EpreuveType epreuve,
    required String niveau,
  }) async {
    final res = await _client.dio.get<List<dynamic>>(
      '/api/users/me/production-submissions/last-per-task',
      queryParameters: {
        'epreuve': epreuve.wire,
        'niveau': niveau,
      },
    );
    return (res.data ?? [])
        .map((e) => ProductionSubmissionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductionTaskDto> getTask(String id) async {
    final res = await _client.dio.get<Map<String, dynamic>>('/api/production-tasks/$id');
    return ProductionTaskDto.fromJson(res.data!);
  }

  /// Exemples-modeles d'une categorie (epreuve, tacheNumero), independants du
  /// sujet choisi.
  ///   GET /api/production-examples?epreuve=...&tacheNumero=...
  Future<List<ProductionExampleDto>> listExamples({
    required EpreuveType epreuve,
    required int tacheNumero,
  }) async {
    final res = await _client.dio.get<List<dynamic>>(
      '/api/production-examples',
      queryParameters: {'epreuve': epreuve.wire, 'tacheNumero': tacheNumero},
    );
    return (res.data ?? [])
        .map((e) => ProductionExampleDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Soumet un texte (epreuve EE). Le backend repond avec la submission deja
  /// EVALUATED (synchrone court-terme : 10-20 s d'attente cote serveur).
  Future<ProductionSubmissionDto> submitText({
    required String productionTaskId,
    required String attemptId,
    required String texte,
  }) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/production-submissions',
      data: {
        'productionTaskId': productionTaskId,
        'attemptId': attemptId,
        'texte': texte,
      },
      options: Options(
        contentType: Headers.jsonContentType,
        // Backend timeout = 60 s, on laisse un peu de marge.
        receiveTimeout: const Duration(seconds: 90),
      ),
    );
    return ProductionSubmissionDto.fromJson(res.data!);
  }

  /// Soumet un audio (epreuve EO). Le fichier est envoye en multipart sous le
  /// champ `audio`, accompagne de `productionTaskId` + `attemptId` en form fields.
  Future<ProductionSubmissionDto> submitAudio({
    required String productionTaskId,
    required String attemptId,
    required File audioFile,
    String? mimeType,
  }) async {
    final filename = audioFile.path.split('/').last;
    // Si mimeType est fourni on l'utilise, sinon dio infere depuis l'extension
    // (ex: .m4a -> audio/mp4) via `lookupMediaType` interne.
    final contentType = mimeType != null ? DioMediaType.parse(mimeType) : null;
    final formData = FormData.fromMap({
      'productionTaskId': productionTaskId,
      'attemptId': attemptId,
      'audio': await MultipartFile.fromFile(
        audioFile.path,
        filename: filename,
        contentType: contentType,
      ),
    });
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/production-submissions',
      data: formData,
      options: Options(
        contentType: Headers.multipartFormDataContentType,
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 90),
      ),
    );
    return ProductionSubmissionDto.fromJson(res.data!);
  }

  Future<ProductionSubmissionDto> getSubmission(String id) async {
    final res = await _client.dio.get<Map<String, dynamic>>('/api/production-submissions/$id');
    return ProductionSubmissionDto.fromJson(res.data!);
  }

  Future<ProductionSubmissionDto> retrySubmission(String id) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/production-submissions/$id/retry',
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );
    return ProductionSubmissionDto.fromJson(res.data!);
  }

  /// Bilan d'epreuve d'un attempt de production EO/EE. Le `niveauGlobal` n'est
  /// renseigne qu'en session d'examen blanc avec evaluations completes (calcul
  /// backend : moyenne ponderee + min local).
  ///   GET /api/attempts/{attemptId}/production-bilan
  Future<ProductionBilan> getProductionBilan(String attemptId) async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/attempts/$attemptId/production-bilan',
    );
    return ProductionBilan.fromJson(res.data!);
  }

  Future<List<ProductionSubmissionDto>> listMine({
    EpreuveType? epreuve,
    int limit = 20,
  }) async {
    final res = await _client.dio.get<List<dynamic>>(
      '/api/users/me/production-submissions',
      queryParameters: {
        if (epreuve != null) 'epreuve': epreuve.wire,
        'limit': limit,
      },
    );
    return (res.data ?? [])
        .map((e) => ProductionSubmissionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

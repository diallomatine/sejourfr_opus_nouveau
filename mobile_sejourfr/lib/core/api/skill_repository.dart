import 'dart:io';

import 'package:dio/dio.dart';

import '../models/skill_models.dart';
import 'api_client.dart';

/// Accès au module « Compétences TCF » :
///   GET  /api/skills?section=EE   (les 24 compétences d'une épreuve)
///   GET  /api/skills?taskCode=EE1
///   GET  /api/skills/{skillId}
///   GET  /api/skills/analysis-quota
///   GET  /api/skill-prompts/{promptId}
///   GET  /api/skill-prompts/{promptId}/references
///   POST /api/skill-attempts            (JSON texte EE | multipart audio EO)
///   GET  /api/skill-attempts/{id}
///   POST /api/skill-attempts/{id}/analyse
///   POST /api/skill-attempts/{id}/retry
class SkillRepository {
  SkillRepository(this._client);

  final ApiClient _client;

  /// Les compétences d'une **épreuve entière** (3 tâches × 8) en un seul
  /// appel, triées `taskCode` puis `displayOrder`. C'est ce filtre qui permet
  /// aux pastilles T1/T2/T3 d'être un tri local plutôt qu'un appel réseau.
  Future<List<SkillDto>> listSkillsBySection(String section) async {
    final res = await _client.dio.get<List<dynamic>>(
      '/api/skills',
      queryParameters: {'section': section},
    );
    return (res.data ?? [])
        .map((e) => SkillDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Les 8 compétences actives d'une tâche, avec la progression du user.
  /// Conservé comme **repli** de [listSkillsBySection] tant que le filtre
  /// `section` n'est pas déployé côté backend.
  Future<List<SkillDto>> listSkills(String taskCode) async {
    final res = await _client.dio.get<List<dynamic>>(
      '/api/skills',
      queryParameters: {'taskCode': taskCode},
    );
    return (res.data ?? [])
        .map((e) => SkillDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Une compétence + ses petits sujets avec leur statut.
  Future<SkillDetail> getSkillDetail(String skillId) async {
    final res =
        await _client.dio.get<Map<String, dynamic>>('/api/skills/$skillId');
    return SkillDetail.fromJson(res.data!);
  }

  /// Quota d'analyses IA du user (`remaining == -1` ⇒ illimité).
  Future<SkillAnalysisQuotaDto> analysisQuota() async {
    final res = await _client.dio
        .get<Map<String, dynamic>>('/api/skills/analysis-quota');
    return SkillAnalysisQuotaDto.fromJson(res.data!);
  }

  /// Le sujet complet, pour l'écran de production. Ne contient pas les
  /// références : elles ont leur propre appel, gardé serveur.
  Future<SkillPromptDto> getPrompt(String promptId) async {
    final res = await _client.dio
        .get<Map<String, dynamic>>('/api/skill-prompts/$promptId');
    return SkillPromptDto.fromJson(res.data!);
  }

  /// Les 3 références comparatives. **403 tant que le user n'a produit aucune
  /// tentative** sur ce sujet (garde serveur, cf. §13.2 de la spec).
  Future<List<SkillReferenceDto>> getReferences(String promptId) async {
    final res = await _client.dio.get<List<dynamic>>(
      '/api/skill-prompts/$promptId/references',
    );
    return (res.data ?? [])
        .map((e) => SkillReferenceDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Soumet une production écrite (section EE).
  Future<SkillAttemptDto> submitText({
    required String skillPromptId,
    required String texte,
    required bool requestAnalysis,
    SkillSelfEvaluation? selfEvaluation,
  }) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/skill-attempts',
      data: {
        'skillPromptId': skillPromptId,
        'texte': texte,
        'requestAnalysis': requestAnalysis,
        if (selfEvaluation != null) 'selfEvaluation': selfEvaluation.wire,
      },
      options: Options(
        contentType: Headers.jsonContentType,
        receiveTimeout: const Duration(seconds: 90),
      ),
    );
    return SkillAttemptDto.fromJson(res.data!);
  }

  /// Soumet une production orale (section EO). L'audio part en multipart sous
  /// le champ `audio`, le reste en champs de formulaire.
  Future<SkillAttemptDto> submitAudio({
    required String skillPromptId,
    required File audioFile,
    required int durationSec,
    required bool requestAnalysis,
    SkillSelfEvaluation? selfEvaluation,
    String? mimeType,
  }) async {
    final formData = FormData.fromMap({
      'skillPromptId': skillPromptId,
      'durationSec': durationSec,
      'requestAnalysis': requestAnalysis,
      if (selfEvaluation != null) 'selfEvaluation': selfEvaluation.wire,
      'audio': await MultipartFile.fromFile(
        audioFile.path,
        filename: audioFile.path.split('/').last,
        contentType: mimeType != null ? DioMediaType.parse(mimeType) : null,
      ),
    });
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/skill-attempts',
      data: formData,
      options: Options(
        contentType: Headers.multipartFormDataContentType,
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 90),
      ),
    );
    return SkillAttemptDto.fromJson(res.data!);
  }

  Future<SkillAttemptDto> getAttempt(String attemptId) async {
    final res = await _client.dio
        .get<Map<String, dynamic>>('/api/skill-attempts/$attemptId');
    return SkillAttemptDto.fromJson(res.data!);
  }

  /// Demande l'analyse IA d'une tentative déjà produite sans elle
  /// (`RECORDED`) : le candidat a produit gratuitement, puis a débloqué
  /// l'analyse. Consomme un quota, contrairement au retry.
  Future<SkillAttemptDto> requestAnalysis(String attemptId) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/skill-attempts/$attemptId/analyse',
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );
    return SkillAttemptDto.fromJson(res.data!);
  }

  /// Relance l'analyse d'une tentative `FAILED`. Ne re-consomme pas le quota
  /// gratuit (il a été prélevé à l'acceptation de la première demande).
  Future<SkillAttemptDto> retryAnalysis(String attemptId) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/skill-attempts/$attemptId/retry',
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );
    return SkillAttemptDto.fromJson(res.data!);
  }
}

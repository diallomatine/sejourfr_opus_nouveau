import '../models/enums.dart';
import '../models/question_models.dart';
import 'api_client.dart';

/// Endpoints autour du statut perso d'une question pour un user.
/// Backend :
///   GET    /api/me/questions/favorites
///   POST   /api/me/questions/{id}/favorite
///   DELETE /api/me/questions/{id}/favorite
///   GET    /api/me/questions/wrong
///   GET    /api/me/questions/{id}/review
///   GET    /api/me/stats?module=...
class UserContentRepository {
  UserContentRepository(this._client);

  final ApiClient _client;

  Future<List<QuestionDto>> favorites({AppModule? module}) async {
    final res = await _client.dio.get<List<dynamic>>(
      '/api/me/questions/favorites',
      queryParameters: module != null ? {'module': module.wire} : null,
    );
    return (res.data ?? [])
        .map((e) => QuestionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addFavorite(String questionId) async {
    await _client.dio.post('/api/me/questions/$questionId/favorite');
  }

  Future<void> removeFavorite(String questionId) async {
    await _client.dio.delete('/api/me/questions/$questionId/favorite');
  }

  Future<List<QuestionDto>> wrongAnswered({AppModule? module}) async {
    final res = await _client.dio.get<List<dynamic>>(
      '/api/me/questions/wrong',
      queryParameters: module != null ? {'module': module.wire} : null,
    );
    return (res.data ?? [])
        .map((e) => QuestionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Version détaillée d'une question pour la révision : inclut `correct` sur
  /// chaque choix et `explanation`. Le backend exige que l'utilisateur ait
  /// déjà tenté ou favori la question.
  Future<QuestionDto> reviewQuestion(String questionId) async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/me/questions/$questionId/review',
    );
    return QuestionDto.fromJson(res.data!);
  }

  Future<UserStats> stats({required AppModule module}) async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/me/stats',
      queryParameters: {'module': module.wire},
    );
    return UserStats.fromJson(res.data!);
  }
}

class UserStats {
  UserStats({
    required this.attemptsTotal,
    required this.questionsAnswered,
    required this.questionsCorrect,
    required this.successRate,
    required this.byTheme,
  });

  final int attemptsTotal;
  final int questionsAnswered;
  final int questionsCorrect;
  final double successRate; // 0..1
  final List<ThemeStats> byTheme;

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        attemptsTotal: (json['attemptsTotal'] as num? ?? 0).toInt(),
        questionsAnswered: (json['questionsAnswered'] as num? ?? 0).toInt(),
        questionsCorrect: (json['questionsCorrect'] as num? ?? 0).toInt(),
        successRate: (json['successRate'] as num? ?? 0).toDouble(),
        byTheme: (json['byTheme'] as List<dynamic>? ?? [])
            .map((e) => ThemeStats.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ThemeStats {
  ThemeStats({
    required this.themeId,
    required this.themeName,
    required this.answered,
    required this.correct,
    required this.total,
  });

  final String themeId;
  final String themeName;
  final int answered;
  final int correct;
  final int total;

  double get progress => total == 0 ? 0 : answered / total;
  double get successRate => answered == 0 ? 0 : correct / answered;

  factory ThemeStats.fromJson(Map<String, dynamic> json) => ThemeStats(
        themeId: json['themeId'] as String,
        themeName: json['themeName'] as String,
        answered: (json['answered'] as num? ?? 0).toInt(),
        correct: (json['correct'] as num? ?? 0).toInt(),
        total: (json['total'] as num? ?? 0).toInt(),
      );
}

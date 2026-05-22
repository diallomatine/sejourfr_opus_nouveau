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

  Future<List<QuestionDto>> wrongAnswered({
    AppModule? module,
    QuestionType? questionType,
    String? themeId,
  }) async {
    final res = await _client.dio.get<List<dynamic>>(
      '/api/me/questions/wrong',
      queryParameters: {
        if (module != null) 'module': module.wire,
        if (questionType != null) 'questionType': questionType.wire,
        if (themeId != null) 'themeId': themeId,
      },
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

  /// Résumé de progression aligné sur les examens passés (cf. backend
  /// `MeService.progressionSummary`). Une seule des deux structures
  /// (civique / tcf) est non null selon le module demandé.
  Future<ProgressionSummary> progression({required AppModule module}) async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/me/progression',
      queryParameters: {'module': module.wire},
    );
    return ProgressionSummary.fromJson(res.data!);
  }

  /// Définit / met à jour le parcours administratif visé (CSP/CR/NAT).
  /// Le backend dérive ensuite automatiquement la difficulté des questions
  /// tirées en entraînement et examen blanc.
  Future<void> updateTargetPath(TargetProcedure procedure) async {
    await _client.dio.put(
      '/api/me/target-path',
      data: {'targetProcedure': procedure.wire},
    );
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

  // Couverture : part du pool du thème déjà tentée (questions distinctes).
  double get progress => total == 0 ? 0 : answered / total;
  // Précision sur les questions tentées (correct / answered distincts).
  double get successRate => answered == 0 ? 0 : correct / answered;
  // Score de maîtrise : seul indicateur cohérent pour la progression par thème.
  // Sur 1 examen blanc avec 2 questions du thème (50 disponibles) : 2/50 = 4%.
  double get mastery => total == 0 ? 0 : correct / total;

  factory ThemeStats.fromJson(Map<String, dynamic> json) => ThemeStats(
        themeId: json['themeId'] as String,
        themeName: json['themeName'] as String,
        answered: (json['answered'] as num? ?? 0).toInt(),
        correct: (json['correct'] as num? ?? 0).toInt(),
        total: (json['total'] as num? ?? 0).toInt(),
      );
}

/// Résumé de progression côté front — miroir Dart de
/// `ProgressionSummaryResponse` backend. Le calcul des métriques (examens
/// passés, thèmes consolidés, niveau CECRL plafond, etc.) vit côté serveur ;
/// le front ne fait que parser et afficher.
class ProgressionSummary {
  ProgressionSummary({
    required this.module,
    required this.civique,
    required this.tcf,
  });

  final AppModule module;
  final CiviqueProgression? civique;
  final TcfProgression? tcf;

  factory ProgressionSummary.fromJson(Map<String, dynamic> json) => ProgressionSummary(
        module: AppModule.fromWire(json['module'] as String),
        civique: json['civique'] == null
            ? null
            : CiviqueProgression.fromJson(json['civique'] as Map<String, dynamic>),
        tcf: json['tcf'] == null
            ? null
            : TcfProgression.fromJson(json['tcf'] as Map<String, dynamic>),
      );
}

class CiviqueProgression {
  CiviqueProgression({
    required this.fullExamCount,
    required this.latestScore,
    required this.bestScore,
    required this.examTotal,
    required this.examThreshold,
    required this.themesConsolidated,
    required this.themesTotal,
  });

  /// Valeurs officielles de l'examen blanc complet civique — gardées en
  /// constantes côté mobile pour les usages UI (gauge ring, labels) sans
  /// imposer au caller de récupérer la valeur instance par instance. Le
  /// backend renvoie ces mêmes valeurs dans chaque DTO pour rester source
  /// de vérité unique.
  static const int defaultExamTotal = 40;
  static const int defaultExamThreshold = 32;

  final int fullExamCount;
  final int? latestScore;
  final int? bestScore;
  final int examTotal;
  final int examThreshold;
  final int themesConsolidated;
  final int themesTotal;

  factory CiviqueProgression.fromJson(Map<String, dynamic> json) => CiviqueProgression(
        fullExamCount: (json['fullExamCount'] as num? ?? 0).toInt(),
        latestScore: (json['latestScore'] as num?)?.toInt(),
        bestScore: (json['bestScore'] as num?)?.toInt(),
        examTotal: (json['examTotal'] as num? ?? 40).toInt(),
        examThreshold: (json['examThreshold'] as num? ?? 32).toInt(),
        themesConsolidated: (json['themesConsolidated'] as num? ?? 0).toInt(),
        themesTotal: (json['themesTotal'] as num? ?? 0).toInt(),
      );
}

class TcfProgression {
  TcfProgression({
    required this.qcmEpreuvesTried,
    required this.qcmEpreuvesTotal,
    required this.productionsEvaluated,
    required this.productionsTotal,
    required this.bestWeightedScore,
    required this.bestWeightedMax,
    required this.lastFullExam,
    required this.targetLevel,
  });

  final int qcmEpreuvesTried;
  final int qcmEpreuvesTotal;
  final int productionsEvaluated;
  final int productionsTotal;
  final int? bestWeightedScore;
  final int? bestWeightedMax;

  /// Dernier examen blanc complet TCF du user (TCF_COMPLET). Null si jamais
  /// lancé — le hero affiche alors une CTA pour en démarrer un.
  final LastFullTcfExam? lastFullExam;

  /// Niveau cible CECRL (dérivé de la procédure visée par le user). Null
  /// si l'onboarding parcours n'a pas été complété.
  final NiveauCecrl? targetLevel;

  factory TcfProgression.fromJson(Map<String, dynamic> json) => TcfProgression(
        qcmEpreuvesTried: (json['qcmEpreuvesTried'] as num? ?? 0).toInt(),
        qcmEpreuvesTotal: (json['qcmEpreuvesTotal'] as num? ?? 3).toInt(),
        productionsEvaluated: (json['productionsEvaluated'] as num? ?? 0).toInt(),
        productionsTotal: (json['productionsTotal'] as num? ?? 2).toInt(),
        bestWeightedScore: (json['bestWeightedScore'] as num?)?.toInt(),
        bestWeightedMax: (json['bestWeightedMax'] as num?)?.toInt(),
        lastFullExam: json['lastFullExam'] == null
            ? null
            : LastFullTcfExam.fromJson(json['lastFullExam'] as Map<String, dynamic>),
        targetLevel: NiveauCecrl.fromWireNullable(json['targetLevel'] as String?),
      );
}

/// Statut d'un examen blanc complet TCF. Miroir de
/// `FullTcfExamResponse.FullTcfExamStatus` côté backend (sérialisé en string).
enum LastFullTcfExamStatus {
  inProgress('IN_PROGRESS'),
  pendingEvaluations('PENDING_EVALUATIONS'),
  completed('COMPLETED');

  const LastFullTcfExamStatus(this.wire);
  final String wire;

  static LastFullTcfExamStatus fromWire(String value) =>
      LastFullTcfExamStatus.values.firstWhere(
        (e) => e.wire == value,
        orElse: () => LastFullTcfExamStatus.inProgress,
      );
}

/// Dernier examen blanc complet TCF d'un user — breakdown des 4 épreuves
/// IRN (CO + CE + EE + EO). Le `finalLevel` est le PLANCHER des 4 niveaux
/// (règle TCF IRN : pour valider une procédure il faut atteindre la cible
/// sur chacune des 4 épreuves).
class LastFullTcfExam {
  LastFullTcfExam({
    required this.attemptId,
    required this.finishedAt,
    required this.status,
    required this.finalLevel,
    required this.coLevel,
    required this.ceLevel,
    required this.eeLevel,
    required this.eoLevel,
  });

  final String attemptId;
  final DateTime? finishedAt;
  final LastFullTcfExamStatus status;
  final NiveauCecrl? finalLevel;
  final NiveauCecrl? coLevel;
  final NiveauCecrl? ceLevel;
  final NiveauCecrl? eeLevel;
  final NiveauCecrl? eoLevel;

  factory LastFullTcfExam.fromJson(Map<String, dynamic> json) => LastFullTcfExam(
        attemptId: json['attemptId'] as String,
        finishedAt: json['finishedAt'] == null
            ? null
            : DateTime.parse(json['finishedAt'] as String),
        status: LastFullTcfExamStatus.fromWire(json['status'] as String),
        finalLevel: NiveauCecrl.fromWireNullable(json['finalLevel'] as String?),
        coLevel: NiveauCecrl.fromWireNullable(json['coLevel'] as String?),
        ceLevel: NiveauCecrl.fromWireNullable(json['ceLevel'] as String?),
        eeLevel: NiveauCecrl.fromWireNullable(json['eeLevel'] as String?),
        eoLevel: NiveauCecrl.fromWireNullable(json['eoLevel'] as String?),
      );
}

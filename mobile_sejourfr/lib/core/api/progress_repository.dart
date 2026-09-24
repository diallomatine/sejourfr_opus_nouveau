import '../models/enums.dart';
import '../models/progress_models.dart';
import '../models/progression_models.dart';
import 'api_client.dart';

/// **La progression du candidat** — ce que l'Accueil lit (`/api/me/progress`)
/// et les quatre écrans de progression (`/api/me/progression/*`, 2026-09-24).
///
/// 🛑 **Rien n'est calculé côté app** : les paliers, les sens d'évolution, les
/// états, les bandes, les écarts, les ordinaux et les verrous arrivent servis.
class ProgressRepository {
  ProgressRepository(this._client);

  final ApiClient _client;

  /// 🛑 **Jamais `null`** : un candidat sans diagnostic reçoit des épreuves non
  /// mesurées. L'Accueil a besoin de savoir *pourquoi* il n'a rien à montrer.
  Future<Progress> progres() async {
    final res = await _client.dio.get<Map<String, dynamic>>('/api/me/progress');
    return Progress.fromJson(res.data!);
  }

  /// Progression **globale** TCF. [tous] = l'historique complet des examens
  /// complets (≤ 50) au lieu des 3 derniers (D8).
  Future<ProgressionTcf> progressionTcf({bool tous = false}) async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/me/progression/tcf',
      queryParameters: tous ? {'tous': true} : null,
    );
    return ProgressionTcf.fromJson(res.data!);
  }

  /// Progression d'**une épreuve** TCF (`TCF_CO|CE|EE|EO`).
  Future<ProgressionEpreuve> progressionEpreuve(EpreuveType epreuve) async {
    final res = await _client.dio
        .get<Map<String, dynamic>>('/api/me/progression/tcf/${epreuve.wire}');
    return ProgressionEpreuve.fromJson(res.data!);
  }

  /// Progression **globale** civique. [tous] : comme [progressionTcf].
  Future<ProgressionCivique> progressionCivique({bool tous = false}) async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/me/progression/civique',
      queryParameters: tous ? {'tous': true} : null,
    );
    return ProgressionCivique.fromJson(res.data!);
  }

  /// Progression d'**un thème** civique.
  Future<ProgressionTheme> progressionTheme(String themeId) async {
    final res = await _client.dio.get<Map<String, dynamic>>(
        '/api/me/progression/civique/themes/$themeId');
    return ProgressionTheme.fromJson(res.data!);
  }
}

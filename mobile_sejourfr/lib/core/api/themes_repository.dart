import '../models/enums.dart';
import '../models/question_models.dart';
import 'api_client.dart';

class ThemesRepository {
  ThemesRepository(this._client);

  final ApiClient _client;

  /// Récupère les thèmes accessibles à l'utilisateur courant pour un module.
  Future<List<ThemeDto>> list({AppModule? module}) async {
    final res = await _client.dio.get<List<dynamic>>(
      '/api/themes',
      queryParameters: module != null ? {'module': module.wire} : null,
    );
    return (res.data ?? [])
        .map((e) => ThemeDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

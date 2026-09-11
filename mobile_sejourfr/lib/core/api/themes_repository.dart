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

  /// La liste **publique** des thèmes d'un module, dans l'ordre d'affichage
  /// servi.
  ///
  /// 🛑 `GET /api/themes` est authentifié : un écran ouvert **sans compte** (le
  /// diagnostic civique, `V053`) n'en obtiendrait qu'un 401. Cette route-ci
  /// existe pour ça, et c'est elle qui évite de figer le livret dans une
  /// constante de front. Miroir de `publicThemeApi.list` côté web.
  Future<List<ThemeDto>> listPublic({required AppModule module}) async {
    final res = await _client.dio.get<List<dynamic>>(
      '/api/public/themes',
      queryParameters: {'module': module.wire},
    );
    final themes = (res.data ?? [])
        .map((e) => ThemeDto.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return themes;
  }
}

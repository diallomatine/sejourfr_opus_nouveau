import 'package:dio/dio.dart';

import 'api_client.dart';

/// `GET /api/public/app-config` — la configuration **publique** de l'app
/// (contrôle G-a). Aujourd'hui : la version minimale acceptée par plateforme.
class AppConfigRepository {
  AppConfigRepository(this._client);

  final ApiClient _client;

  /// Route publique : aucun jeton, et un échec ne déclenche jamais la
  /// déconnexion globale.
  static final Options _options = Options(
    extra: const {'skipAuth': true, 'skipRefresh': true},
    receiveTimeout: const Duration(seconds: 8),
  );

  /// La version minimale de [platform] (`ios` | `android`), telle que servie
  /// (`MAJOR.MINOR.PATCH`), ou `null` — personne n'est bloqué. Lève sur une
  /// erreur réseau : c'est à l'appelant de ne **jamais** bloquer dans ce cas.
  Future<String?> minSupportedVersion(String platform) async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/api/public/app-config',
      options: _options,
    );
    final min = res.data?['minSupportedVersion'];
    if (min is! Map<String, dynamic>) return null;
    final value = min[platform];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }
}

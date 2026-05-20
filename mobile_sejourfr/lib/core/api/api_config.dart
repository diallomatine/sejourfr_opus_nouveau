/// Configuration de l'API.
///
/// L'URL de base est paramétrée via `--dart-define=API_BASE_URL=http://...`
/// Si non fournie, on tombe sur la valeur dev pour iOS simulator / Android emulator.
///
/// Sous Android emulator, "localhost" pointe sur l'émulateur, pas la machine hôte.
/// Il faut utiliser `http://10.0.2.2:8080` pour atteindre le backend local.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    //defaultValue: 'http://192.168.1.13:8080',
    defaultValue: 'https://api.sejourfr.fr',
  );

  /// Diallo

  /// Timeout des requêtes.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Résout une URL de média stockée côté backend.
  ///
  /// Le backend persiste des URLs absolues du genre `http://localhost:8080/files/...`
  /// (cf. `sejourfr.storage.local.public-base-url`). Or sur un device physique ou
  /// un émulateur Android, `localhost` ne pointe pas vers la machine hôte — l'image
  /// ne charge donc jamais. On réécrit ces URLs vers [baseUrl]. Les URLs relatives
  /// (`/files/...`) sont également préfixées.
  static String resolveMediaUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('/')) return '$baseUrl$url';
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return url;
    final host = uri.host;
    if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
      return '$baseUrl${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
    }
    return url;
  }
}

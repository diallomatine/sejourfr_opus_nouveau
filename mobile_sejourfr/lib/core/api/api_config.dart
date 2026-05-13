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
    defaultValue: 'http://192.168.1.13:8080',
  );

  /// Timeout des requêtes.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}

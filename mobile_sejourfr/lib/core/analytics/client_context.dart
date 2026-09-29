import 'dart:io' show Platform;

import 'package:package_info_plus/package_info_plus.dart';

import 'analytics_identity.dart';

/// **Le contexte client, déclaré une seule fois** (Q4 du chantier « Suivi ») :
/// la plateforme réelle, l'identifiant anonyme de l'appareil et la version de
/// l'app. Posé par `ApiClient` sur **toutes** les requêtes — y compris
/// `skipAuth` (inscription, routes publiques) — et repris dans l'enveloppe du
/// lot d'événements.
///
/// Les trois valeurs sont **déclaratives** : elles n'ouvrent aucun droit côté
/// serveur (`ClientContextResolver`), elles disent d'où vient l'appel.
///
/// 🛑 Rien de personnel : ni modèle d'appareil, ni identifiant publicitaire,
/// ni compte. L'identifiant anonyme est un UUID tiré sur l'appareil (cf.
/// [AnalyticsIdentity]).
class ClientContext {
  ClientContext({required AnalyticsIdentity identity}) : _identity = identity;

  final AnalyticsIdentity _identity;

  static const headerClient = 'X-Sejourfr-Client';
  static const headerAnonymousId = 'X-Sejourfr-Anonymous-Id';
  static const headerAppVersion = 'X-Sejourfr-App-Version';

  /// `ios` | `android` — la plateforme **réelle**, jamais l'ancien `mobile`
  /// (que le serveur lit `MOBILE` et ne répartit pas). `null` hors de ces deux
  /// systèmes (tests sur poste) : on n'envoie alors rien plutôt qu'une valeur
  /// fausse.
  static String? get platform {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return null;
  }

  /// Motif accepté par le serveur (`X-Sejourfr-App-Version`). Une version qui
  /// n'y tient pas n'est pas envoyée.
  static final RegExp _versionPattern =
      RegExp(r'^[0-9A-Za-z][0-9A-Za-z.+_-]{0,31}$');

  static Future<String?>? _appVersion;

  /// `0.1.3+19` — la version **et** le numéro de build, lus une fois par
  /// lancement. `null` si la plateforme ne sait pas la dire.
  static Future<String?> appVersion() => _appVersion ??= _readAppVersion();

  static Future<String?> _readAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final build = info.buildNumber.trim();
      final version =
          build.isEmpty ? info.version.trim() : '${info.version.trim()}+$build';
      return _versionPattern.hasMatch(version) ? version : null;
    } catch (_) {
      return null;
    }
  }

  Future<String> anonymousId() => _identity.anonymousId();

  /// Les trois en-têtes à poser. Une valeur inconnue est **absente**, jamais
  /// inventée. Ne lève jamais.
  Future<Map<String, String>> headers() async {
    final client = platform;
    final version = await appVersion();
    String? anonymous;
    try {
      anonymous = await anonymousId();
    } catch (_) {
      anonymous = null;
    }
    return {
      if (client != null) headerClient: client,
      if (anonymous != null) headerAnonymousId: anonymous,
      if (version != null) headerAppVersion: version,
    };
  }
}

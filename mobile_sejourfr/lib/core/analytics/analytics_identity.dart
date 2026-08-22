import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// **L'identité anonyme d'un appareil**, miroir mobile de `lib/analytics.ts`
/// côté web.
///
/// Deux identifiants, deux durées de vie :
///
/// - `anonymousId` : un UUID v4 **first-party**, conservé **13 mois** (durée de
///   l'exemption CNIL de mesure d'audience — c'est une condition, pas un
///   détail). La date de pose est stockée à côté ; au-delà, l'identifiant est
///   **régénéré**, il n'est jamais prolongé.
/// - `sessionId` : un UUID v4 renouvelé après **30 minutes** d'inactivité.
///   L'horodatage de dernière activité est rafraîchi à chaque émission.
///
/// 🛑 **Rien de personnel n'est écrit ici** : ni e-mail, ni jeton, ni
/// identifiant de compte. Ce sont deux nombres aléatoires, jamais partagés,
/// jamais recoupés hors de SejourFR.
///
/// **Toute erreur de stockage est avalée** : une mesure d'audience ne casse
/// jamais un écran. Quand le stockage est indisponible, on garde une identité
/// **en mémoire de processus** — l'événement part quand même, il n'est
/// simplement plus rattachable au lancement suivant.
///
/// Le stockage choisi est `SharedPreferences`, comme les brouillons EE et le
/// diagnostic : c'est l'équivalent exact du `localStorage` du web (persistant,
/// effacé avec les données de l'app). Le trousseau sécurisé, lui, est réservé
/// aux **secrets** (jetons) et survit à la désinstallation — ce qui étirerait
/// silencieusement la rétention de 13 mois au-delà de ce qui est déclaré.
class AnalyticsIdentity {
  AnalyticsIdentity({Random? random}) : _random = random ?? Random.secure();

  static const _kAnonymousId = 'sejourfr.analytics.anonymousId';
  static const _kAnonymousIdSince = 'sejourfr.analytics.anonymousIdSince';
  static const _kSessionId = 'sejourfr.analytics.sessionId';
  static const _kSessionSeenAt = 'sejourfr.analytics.sessionSeenAt';
  static const _kFirstTouchSent = 'sejourfr.analytics.firstTouchSent';

  /// Rétention déclarée sur `/confidentialite`. Au-delà, on repart d'un
  /// identifiant neuf : c'est ce qui rend la promesse vérifiable.
  static const Duration retention = Duration(days: 396); // ≈ 13 mois

  /// Au-delà de cette inactivité, la visite suivante est une nouvelle session.
  static const Duration sessionIdleTimeout = Duration(minutes: 30);

  final Random _random;

  /// Repli en mémoire quand `SharedPreferences` est indisponible.
  String? _memoryAnonymousId;
  String? _memorySessionId;
  DateTime? _memorySessionSeenAt;

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  /// Résout le couple à émettre, en rafraîchissant l'activité de session.
  /// Ne lève jamais.
  Future<AnalyticsIds> resolve({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final prefs = await _prefs();
    if (prefs == null) return _memoryIds(at);
    try {
      return AnalyticsIds(
        anonymousId: await _anonymousId(prefs, at),
        sessionId: await _sessionId(prefs, at),
      );
    } catch (_) {
      return _memoryIds(at);
    }
  }

  /// Le bloc `firstTouch` ne part qu'**une fois par visiteur** : c'est la
  /// définition même d'une première touche, et le serveur ne l'écrase pas non
  /// plus. Renvoie `true` si l'appelant doit l'inclure — et le marque consommé.
  Future<bool> claimFirstTouch() async {
    final prefs = await _prefs();
    if (prefs == null) return false;
    try {
      if (prefs.getBool(_kFirstTouchSent) ?? false) return false;
      await prefs.setBool(_kFirstTouchSent, true);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> _anonymousId(SharedPreferences prefs, DateTime at) async {
    final existing = prefs.getString(_kAnonymousId);
    final since = DateTime.tryParse(prefs.getString(_kAnonymousIdSince) ?? '');
    final expired = since == null || at.difference(since) > retention;
    if (existing != null && existing.isNotEmpty && !expired) return existing;

    final fresh = _uuidV4();
    await prefs.setString(_kAnonymousId, fresh);
    await prefs.setString(_kAnonymousIdSince, at.toIso8601String());
    // Identifiant neuf = visiteur neuf : sa première touche reste à poser.
    await prefs.remove(_kFirstTouchSent);
    return fresh;
  }

  Future<String> _sessionId(SharedPreferences prefs, DateTime at) async {
    final existing = prefs.getString(_kSessionId);
    final seenAt = DateTime.tryParse(prefs.getString(_kSessionSeenAt) ?? '');
    final stale =
        seenAt == null || at.difference(seenAt) > sessionIdleTimeout;
    final id = (existing != null && existing.isNotEmpty && !stale)
        ? existing
        : _uuidV4();
    if (id != existing) await prefs.setString(_kSessionId, id);
    await prefs.setString(_kSessionSeenAt, at.toIso8601String());
    return id;
  }

  AnalyticsIds _memoryIds(DateTime at) {
    final seenAt = _memorySessionSeenAt;
    if (seenAt == null || at.difference(seenAt) > sessionIdleTimeout) {
      _memorySessionId = _uuidV4();
    }
    _memorySessionSeenAt = at;
    return AnalyticsIds(
      anonymousId: _memoryAnonymousId ??= _uuidV4(),
      sessionId: _memorySessionId ??= _uuidV4(),
    );
  }

  /// UUID v4 conforme (variante RFC 4122), tiré d'une source cryptographique.
  /// Écrit à la main plutôt qu'importé : le serveur n'attend qu'une chaîne
  /// d'UUID valide, ça ne vaut pas une dépendance de plus.
  String _uuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

class AnalyticsIds {
  const AnalyticsIds({required this.anonymousId, required this.sessionId});

  final String anonymousId;
  final String sessionId;
}

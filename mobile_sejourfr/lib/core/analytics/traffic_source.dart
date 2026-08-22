/// **La provenance d'un visiteur**, miroir mot pour mot de
/// `web_sejoufr/lib/audience-events.ts` (`TRAFFIC_SOURCES`,
/// `trafficSourceFromRaw`).
///
/// Elle voyage dans l'en-tête `X-Sejourfr-Source`, que le serveur normalise à
/// son tour (`util/TrafficSource`, autorité unique). Deux normalisations, une
/// seule liste : une chaîne inconnue ne crée jamais de dimension.
///
/// 🛑 **`direct` ≠ `inconnu`.** L'ancien `audience_repository.dart` postait
/// `source: 'direct'` **en dur** : toute inscription mobile ressortait de
/// l'accès direct, y compris celles nées d'une campagne. On préfère désormais
/// **ne rien envoyer** — le serveur rend alors « inconnu », qui est vrai — à
/// affirmer une provenance qu'on n'a pas observée.
///
/// ⚠️ **Aucun producteur n'existe encore côté mobile** : l'app n'a ni deep
/// link, ni lecture de l'install referrer (Play), ni paramètre d'URL — un
/// lancement natif ne porte aucune provenance. [current] vaut donc `null` en
/// permanence aujourd'hui, et l'en-tête n'est pas posé. Le jour où un deep
/// link de campagne arrive, il n'a qu'un seul point de câblage : [remember].
enum TrafficSource {
  tiktok('tiktok'),
  instagram('instagram'),
  whatsapp('whatsapp'),
  facebook('facebook'),
  youtube('youtube');

  const TrafficSource(this.wire);

  final String wire;
}

class AnalyticsTrafficSource {
  const AnalyticsTrafficSource._();

  static TrafficSource? _current;

  /// La provenance du lancement en cours, ou `null` si on n'en sait rien.
  /// Lue **à chaque requête** par `ApiClient` — comme le web recalcule
  /// `detectTrafficSource()` à chaque appel.
  static TrafficSource? get current => _current;

  /// Enregistre une provenance brute (paramètre `utm_source` / `src` d'un deep
  /// link, referrer d'installation…). Une valeur non reconnue **n'écrase
  /// jamais** une provenance déjà connue : on ne remplace pas un fait par un
  /// inconnu.
  static void remember(String? raw) {
    final source = fromRaw(raw);
    if (source != null) _current = source;
  }

  /// Réduit une provenance brute à la liste blanche partagée. `null` = accès
  /// direct, source non reconnue, ou rien à lire. Ne lève jamais.
  static TrafficSource? fromRaw(String? raw) {
    final n = raw?.trim().toLowerCase() ?? '';
    if (n.isEmpty) return null;
    if (n.contains('tiktok')) return TrafficSource.tiktok;
    if (n.contains('instagram')) return TrafficSource.instagram;
    if (n.contains('whatsapp') || n.contains('wa.me') || n == 'wa') {
      return TrafficSource.whatsapp;
    }
    if (n.contains('facebook') || n.contains('fb.') || n == 'fb') {
      return TrafficSource.facebook;
    }
    if (n.contains('youtube') || n.contains('youtu.be')) {
      return TrafficSource.youtube;
    }
    return null;
  }
}

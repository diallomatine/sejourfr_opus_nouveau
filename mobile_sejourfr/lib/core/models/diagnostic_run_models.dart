/// Miroirs de la **trace du tunnel diagnostic** (`diagnostic_run`, V074) —
/// `POST /api/public/diagnostic-runs` et `…/{id}/submit`.
///
/// 🛑 **Une trace, jamais un contenu** : ces DTO ne portent ni réponse, ni
/// texte, ni audio. Règle complète : `docs/regles/diagnostic.md`
/// § « La trace du tunnel ».
library;

/// Le diagnostic tracé. Miroir de `DiagnosticRunType` côté serveur.
///
/// ⚠️ **À ne pas confondre avec `AnalyticsDiagnosticType`** (`RAPID` /
/// `COMPLETE` / `UNKNOWN`), une **propriété** d'événement héritée : celui-ci
/// désigne la **run**, et c'est son type qui fait foi à l'ingestion.
enum DiagnosticRunType {
  quickTcf('QUICK_TCF'),
  fullTcf('FULL_TCF'),
  civique('CIVIQUE');

  const DiagnosticRunType(this.wire);

  final String wire;

  static DiagnosticRunType? fromWire(String? wire) {
    for (final type in values) {
      if (type.wire == wire) return type;
    }
    return null;
  }
}

/// Réponse de `POST /api/public/diagnostic-runs`.
///
/// 🛑 Un rejeu rend la **même** run avec un **nouveau** [claimToken] : l'ancien
/// ne vaut plus rien, on garde toujours la dernière réponse.
class DiagnosticRunCreated {
  const DiagnosticRunCreated({
    required this.diagnosticRunId,
    required this.claimToken,
    this.claimTokenExpiresAt,
  });

  final String diagnosticRunId;

  /// Le secret qui prouve la run à l'inscription ou à la connexion. Il ne part
  /// **jamais** dans un événement d'analytics.
  final String claimToken;

  final DateTime? claimTokenExpiresAt;

  static DiagnosticRunCreated? fromJson(Map<String, dynamic> json) {
    final id = json['diagnosticRunId'] as String?;
    final token = json['claimToken'] as String?;
    if (id == null || id.isEmpty || token == null || token.isEmpty) {
      return null;
    }
    return DiagnosticRunCreated(
      diagnosticRunId: id,
      claimToken: token,
      claimTokenExpiresAt:
          DateTime.tryParse(json['claimTokenExpiresAt'] as String? ?? ''),
    );
  }
}

/// Par où le jeton d'une run est revenu au serveur. Miroir de
/// `DiagnosticRunClaimVia` (`diagnostic_run.claimed_via`). Il qualifie le
/// rattachement, il ne l'autorise pas : seul le jeton prouve la run.
enum DiagnosticRunClaimVia {
  /// La run passée sur cet appareil, gardée avec son brouillon.
  sameDevice('SAME_DEVICE'),

  /// La run passée sur le web, reçue par le lien « Continuer sur
  /// l'application » (lot 3b).
  appLink('APP_LINK');

  const DiagnosticRunClaimVia(this.wire);

  final String wire;
}

/// Ce que l'authentification transmet pour rattacher une run (Q3, claim) :
/// l'identifiant **et** son jeton, ou rien — et par où ils sont arrivés.
class DiagnosticRunClaim {
  const DiagnosticRunClaim({
    required this.diagnosticRunId,
    required this.claimToken,
    this.via = DiagnosticRunClaimVia.sameDevice,
  });

  final String diagnosticRunId;
  final String claimToken;
  final DiagnosticRunClaimVia via;
}

/// **Le lien « Continuer sur l'application »** (lot 3b, scénario 4), relu.
/// Miroir de `web_sejoufr/lib/app-link.ts`, qui l'écrit :
/// `https://<hôte>/continuer-sur-app#run=<diagnosticRunId>&token=<claimToken>`.
///
/// 🛑 La run et son jeton sont lus **dans le fragment**, jamais en query
/// string (le web ne les y met pas : journaux d'accès). Un lien incomplet ou
/// mal formé ne rend rien — jamais une erreur.
class AppLinkClaim {
  AppLinkClaim._();

  static const path = '/continuer-sur-app';

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Un jeton est du base64url de 256 bits (43 caractères) : la borne ne sert
  /// qu'à refuser une adresse fabriquée démesurée.
  static final _token = RegExp(r'^[A-Za-z0-9_-]{16,128}$');

  static DiagnosticRunClaim? fromUri(Uri uri) {
    if (uri.path != path || uri.fragment.isEmpty) return null;
    final Map<String, String> params;
    try {
      params = Uri.splitQueryString(uri.fragment);
    } catch (_) {
      return null;
    }
    final runId = params['run'];
    final token = params['token'];
    if (runId == null || !_uuid.hasMatch(runId)) return null;
    if (token == null || !_token.hasMatch(token)) return null;
    return DiagnosticRunClaim(
      diagnosticRunId: runId.toLowerCase(),
      claimToken: token,
      via: DiagnosticRunClaimVia.appLink,
    );
  }
}

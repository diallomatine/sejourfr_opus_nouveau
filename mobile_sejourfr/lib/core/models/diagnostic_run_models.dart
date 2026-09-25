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

/// Ce que l'authentification transmet pour rattacher une run (Q3, claim) :
/// l'identifiant **et** son jeton, ou rien.
class DiagnosticRunClaim {
  const DiagnosticRunClaim({
    required this.diagnosticRunId,
    required this.claimToken,
  });

  final String diagnosticRunId;
  final String claimToken;
}

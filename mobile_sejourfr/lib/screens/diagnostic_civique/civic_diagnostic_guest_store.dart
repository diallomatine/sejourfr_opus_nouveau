import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/civic_diagnostic_models.dart';
import '../../core/models/enums.dart';

/// L'adresse d'un diagnostic civique ouvert **sans compte** (`V053`).
///
/// 🛑 **Arbitrage du propriétaire, 2026-09-10** : « que ce soit le diagnostic
/// examen civique ou TCF, l'utilisateur doit pouvoir passer le diagnostic avant
/// de créer son compte, il répond au QCM et seulement après on lui demande de
/// créer son compte pour voir le résultat. »
///
/// **Ce que ce store garde, et ce qu'il ne garde pas.** Il garde une *adresse* :
/// l'identifiant de la session ouverte côté serveur, celui de son attempt, et
/// la démarche déclarée au tirage. Les questions, les réponses et la correction
/// restent au serveur.
///
/// 🛑 **Différence assumée avec le TCF**, dont le brouillon invité conserve les
/// productions sur l'appareil ([DiagnosticDraftService]) : le TCF produit du
/// texte et de l'audio, que personne n'a besoin de corriger avant l'analyse. Le
/// civique est du QCM — le corriger côté client obligerait à **servir les bonnes
/// réponses à un visiteur**, et jouer 40 questions hors `attempts` obligerait à
/// écrire un **second runner**. Les deux sont interdits.
///
/// Miroir de `web_sejoufr/lib/civic-diagnostic-guest.ts`.
class CivicDiagnosticGuest {
  const CivicDiagnosticGuest({
    required this.sessionId,
    required this.attemptId,
    required this.procedure,
  });

  final String sessionId;
  final String attemptId;

  /// La démarche déclarée avant le tirage — elle préremplit le formulaire de
  /// création de compte.
  final TargetProcedure procedure;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'attemptId': attemptId,
        'procedure': procedure.wire,
      };

  static CivicDiagnosticGuest? fromJson(Map<String, dynamic> json) {
    final sessionId = json['sessionId'] as String?;
    final attemptId = json['attemptId'] as String?;
    if (sessionId == null || attemptId == null) return null;
    final wire = json['procedure'] as String?;
    return CivicDiagnosticGuest(
      sessionId: sessionId,
      attemptId: attemptId,
      // Une valeur absente ou inconnue retombe sur le périmètre le plus
      // étroit, comme le serveur : jamais une exception au chargement.
      procedure: wire == null
          ? TargetProcedure.csp
          : TargetProcedure.values.firstWhere(
              (e) => e.wire == wire,
              orElse: () => TargetProcedure.csp,
            ),
    );
  }
}

/// Lecture / écriture de l'adresse, **best-effort de bout en bout** : un
/// stockage refusé fait perdre la reprise, jamais la session — elle existe
/// côté serveur.
class CivicDiagnosticGuestStore {
  static const _key = 'sejourfr.civicDiagnostic.invite';

  Future<CivicDiagnosticGuest?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return CivicDiagnosticGuest.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(CivicDiagnosticDto dto, TargetProcedure procedure) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(CivicDiagnosticGuest(
          sessionId: dto.sessionId,
          attemptId: dto.attemptId,
          procedure: procedure,
        ).toJson()),
      );
    } catch (_) {
      // Sans conséquence sur le parcours en cours.
    }
  }

  Future<void> forget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}

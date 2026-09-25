import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/diagnostic_run_repository.dart';
import '../auth/auth_controller.dart';
import '../models/diagnostic_run_models.dart';
import '../utils/submission_key.dart';

/// Ce que l'appareil sait d'**un passage** dans un diagnostic : la clé qu'il a
/// tirée, la run que le serveur lui a rendue et son jeton de rattachement.
///
/// Un enregistrement **par type** de diagnostic : un visiteur peut commencer
/// le civique et le TCF rapide sur le même téléphone, et les deux passages
/// ont chacun leur run.
@immutable
class DiagnosticRunEntry {
  const DiagnosticRunEntry({
    required this.clientKey,
    required this.touchedAt,
    this.sessionId,
    this.diagnosticRunId,
    this.claimToken,
    this.claimTokenExpiresAt,
    this.ownerUserId,
    this.submitted = false,
    this.closed = false,
  });

  /// UUID tiré **une fois par passage**. C'est lui qui rend la création
  /// idempotente côté serveur, avec `X-Sejourfr-Anonymous-Id`.
  final String clientKey;

  /// La session serveur du passage, quand elle existe déjà à la première
  /// question (civique, TCF complet, TCF rapide connecté). `null` pour le TCF
  /// rapide invité : il n'a aucune session avant le compte (V053).
  final String? sessionId;

  final String? diagnosticRunId;

  /// 🛑 **Ne quitte jamais cet enregistrement que vers `submit` et l'auth.**
  final String? claimToken;
  final DateTime? claimTokenExpiresAt;

  /// Le compte qui porte la run **à la connaissance de l'appareil** : celui qui
  /// était connecté à sa création, ou celui dont l'authentification a transmis
  /// le jeton. Sert à ne jamais attacher la run d'un autre à un événement.
  final String? ownerUserId;

  /// « Soumis » déjà envoyé (TCF rapide) : on ne le rejoue pas.
  final bool submitted;

  /// Passage terminé : la run reste connue pour les événements du rapport et
  /// du Plan, mais le prochain diagnostic du même type tire une clé neuve.
  final bool closed;

  final DateTime touchedAt;

  bool claimUsable(DateTime now) =>
      diagnosticRunId != null &&
      claimToken != null &&
      ownerUserId == null &&
      (claimTokenExpiresAt == null || claimTokenExpiresAt!.isAfter(now));

  DiagnosticRunEntry copyWith({
    String? diagnosticRunId,
    String? claimToken,
    DateTime? claimTokenExpiresAt,
    String? ownerUserId,
    bool? submitted,
    bool? closed,
    DateTime? touchedAt,
  }) =>
      DiagnosticRunEntry(
        clientKey: clientKey,
        sessionId: sessionId,
        diagnosticRunId: diagnosticRunId ?? this.diagnosticRunId,
        claimToken: claimToken ?? this.claimToken,
        claimTokenExpiresAt: claimTokenExpiresAt ?? this.claimTokenExpiresAt,
        ownerUserId: ownerUserId ?? this.ownerUserId,
        submitted: submitted ?? this.submitted,
        closed: closed ?? this.closed,
        touchedAt: touchedAt ?? this.touchedAt,
      );

  Map<String, Object?> toJson() => {
        'clientKey': clientKey,
        'sessionId': sessionId,
        'diagnosticRunId': diagnosticRunId,
        'claimToken': claimToken,
        'claimTokenExpiresAt': claimTokenExpiresAt?.toIso8601String(),
        'ownerUserId': ownerUserId,
        'submitted': submitted,
        'closed': closed,
        'touchedAt': touchedAt.toIso8601String(),
      };

  static DiagnosticRunEntry? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final clientKey = json['clientKey'] as String?;
    if (clientKey == null || clientKey.isEmpty) return null;
    return DiagnosticRunEntry(
      clientKey: clientKey,
      sessionId: json['sessionId'] as String?,
      diagnosticRunId: json['diagnosticRunId'] as String?,
      claimToken: json['claimToken'] as String?,
      claimTokenExpiresAt:
          DateTime.tryParse(json['claimTokenExpiresAt'] as String? ?? ''),
      ownerUserId: json['ownerUserId'] as String?,
      submitted: json['submitted'] as bool? ?? false,
      closed: json['closed'] as bool? ?? false,
      touchedAt: DateTime.tryParse(json['touchedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// **La seule autorité du couple run + jeton sur l'appareil** (Q3, claim).
///
/// Miroir mobile de ce que le web garde avec son brouillon de diagnostic.
/// `SharedPreferences`, comme le brouillon lui-même : le jeton doit survivre à
/// la fermeture de l'app et au détour par Google / Apple sign-in, exactement
/// comme la production qu'il accompagne.
///
/// Trois règles, qui ne se négocient pas :
/// - **best-effort** : aucune méthode ne lève, aucune n'est attendue par un
///   écran — une trace perdue ne bloque jamais un diagnostic ;
/// - 🛑 **le `claimToken` ne sort d'ici que vers `submit` et l'auth**, jamais
///   vers un événement ([runIdFor] ne rend que l'identifiant) ;
/// - **aucune heuristique** : sans jeton, pas de rattachement ; une run portée
///   par un autre compte n'est jamais attachée à un événement.
class DiagnosticRunTracker {
  DiagnosticRunTracker({
    required DiagnosticRunRepository repository,
    required String? Function() currentUserId,
  })  : _repository = repository,
        _currentUserId = currentUserId;

  final DiagnosticRunRepository _repository;
  final String? Function() _currentUserId;

  static String _key(DiagnosticRunType type) =>
      'sejourfr.diagnosticRun.${type.wire}';

  /// Une création en vol par type : la première question peut se reconstruire
  /// plusieurs fois avant que la réponse arrive.
  final Map<DiagnosticRunType, Future<void>> _inFlight = {};

  // ---------------------------------------------------------------------------
  // Étape 1 — sujet vu
  // ---------------------------------------------------------------------------

  /// À l'affichage de la **première question**. Crée la run si l'appareil n'en
  /// a pas encore pour ce passage ; sinon ne fait rien (le serveur a déjà daté
  /// l'étape 1, la rejouer ne rendrait qu'un jeton neuf).
  Future<void> subjectViewed(DiagnosticRunType type, {String? sessionId}) {
    return _inFlight[type] ??= _subjectViewed(type, sessionId)
        .whenComplete(() => _inFlight.remove(type));
  }

  Future<void> _subjectViewed(DiagnosticRunType type, String? sessionId) async {
    try {
      final entry = await _passage(type, sessionId);
      if (entry.diagnosticRunId != null) return;
      await _create(type, entry);
    } catch (_) {
      // Une trace perdue ne bloque jamais le diagnostic.
    }
  }

  /// Le passage en cours pour [type] — le même tant qu'il n'est pas clos et
  /// qu'il porte sur la même session, sinon un neuf, avec une clé neuve.
  Future<DiagnosticRunEntry> _passage(
    DiagnosticRunType type,
    String? sessionId,
  ) async {
    final now = DateTime.now();
    final current = await _read(type);
    final sameSession = current != null &&
        (current.sessionId == null ||
            sessionId == null ||
            current.sessionId == sessionId);
    if (current != null && !current.closed && sameSession) return current;
    final fresh = DiagnosticRunEntry(
      clientKey: SubmissionKeys.newKey(),
      sessionId: sessionId,
      ownerUserId: _currentUserId(),
      touchedAt: now,
    );
    await _write(type, fresh);
    return fresh;
  }

  Future<DiagnosticRunEntry?> _create(
    DiagnosticRunType type,
    DiagnosticRunEntry entry,
  ) async {
    final created = await _repository.create(
      type: type,
      clientKey: entry.clientKey,
      sessionId: entry.sessionId,
    );
    if (created == null) return null;
    // 🛑 On garde TOUJOURS la dernière réponse : un rejeu a tué l'ancien jeton.
    final updated = entry.copyWith(
      diagnosticRunId: created.diagnosticRunId,
      claimToken: created.claimToken,
      claimTokenExpiresAt: created.claimTokenExpiresAt,
      ownerUserId: entry.ownerUserId ?? _currentUserId(),
      touchedAt: DateTime.now(),
    );
    await _write(type, updated);
    return updated;
  }

  // ---------------------------------------------------------------------------
  // Étape 2 — soumis (TCF rapide seulement)
  // ---------------------------------------------------------------------------

  /// « Analyser mes réponses » du **TCF rapide**. Le civique et le TCF complet
  /// sont posés « soumis » par le serveur : ne jamais appeler ceci pour eux.
  ///
  /// Sans run (la création avait échoué), on la crée d'abord : l'étape 1 sera
  /// datée un peu tard, mais le passage ne disparaît pas du tunnel.
  Future<void> submitted({String? sessionId}) async {
    const type = DiagnosticRunType.quickTcf;
    try {
      await _inFlight[type];
      var entry = await _passage(type, sessionId);
      if (entry.submitted) return;
      if (entry.diagnosticRunId == null) {
        entry = await _create(type, entry) ?? entry;
      }
      final runId = entry.diagnosticRunId;
      if (runId == null) return;
      await _repository.submit(
        diagnosticRunId: runId,
        claimToken: entry.claimToken,
      );
      await _write(type, entry.copyWith(submitted: true));
    } catch (_) {
      // Best-effort.
    }
  }

  // ---------------------------------------------------------------------------
  // Étape 3 — rattachement à l'authentification
  // ---------------------------------------------------------------------------

  /// La run à transmettre à `login` / `register` / `google` / `apple`, ou
  /// `null`. Le serveur n'en rattache qu'une : on prend le passage **le plus
  /// récemment touché** dont le jeton vaut encore et qu'aucun compte ne porte.
  Future<DiagnosticRunClaim?> claimForAuth() async {
    try {
      final now = DateTime.now();
      DiagnosticRunEntry? best;
      for (final type in DiagnosticRunType.values) {
        final entry = await _read(type);
        if (entry == null || !entry.claimUsable(now)) continue;
        if (best == null || entry.touchedAt.isAfter(best.touchedAt)) {
          best = entry;
        }
      }
      if (best == null) return null;
      return DiagnosticRunClaim(
        diagnosticRunId: best.diagnosticRunId!,
        claimToken: best.claimToken!,
      );
    } catch (_) {
      return null;
    }
  }

  /// L'authentification a réussi en transmettant [claim] : la run est
  /// désormais connue comme celle de [userId]. Le serveur peut l'avoir
  /// refusée (compte qui porte déjà sa run, jeton expiré) — il ne le dit pas,
  /// et un rattachement refusé laisse simplement la run hors des événements
  /// de ce compte côté serveur. Aucune vérité n'en dépend ici.
  Future<void> onAuthenticated(String userId, DiagnosticRunClaim? claim) async {
    if (claim == null) return;
    try {
      for (final type in DiagnosticRunType.values) {
        final entry = await _read(type);
        if (entry == null || entry.diagnosticRunId != claim.diagnosticRunId) {
          continue;
        }
        await _write(type, entry.copyWith(ownerUserId: userId));
      }
    } catch (_) {
      // Best-effort.
    }
  }

  // ---------------------------------------------------------------------------
  // Lectures pour le handoff et les événements
  // ---------------------------------------------------------------------------

  /// L'identifiant de la run du TCF rapide, pour `POST /api/diagnostics
  /// ?diagnosticRunId=`. Le serveur l'ignore si elle n'appartient pas déjà au
  /// compte : aucun jeton ne voyage en query string (D24).
  Future<String?> handoffRunId() async {
    try {
      final entry = await _read(DiagnosticRunType.quickTcf);
      return entry?.closed == true ? null : entry?.diagnosticRunId;
    } catch (_) {
      return null;
    }
  }

  /// La run de [type] à attacher à un événement — **seulement** si elle est
  /// celle du compte connecté (ou d'un visiteur, quand personne ne l'est).
  Future<String?> runIdFor(DiagnosticRunType type) async {
    try {
      // Une création en vol (première question tout juste affichée) : on
      // l'attend, sinon l'événement qui la suit partirait sans sa run.
      await _inFlight[type];
      final entry = await _read(type);
      final runId = entry?.diagnosticRunId;
      if (entry == null || runId == null) return null;
      return entry.ownerUserId == _currentUserId() ? runId : null;
    } catch (_) {
      return null;
    }
  }

  /// Le passage est fini (production transmise, ou effacée par le candidat) :
  /// le prochain diagnostic du même type tirera une clé neuve.
  Future<void> close(DiagnosticRunType type) async {
    try {
      final entry = await _read(type);
      if (entry == null || entry.closed) return;
      await _write(type, entry.copyWith(closed: true));
    } catch (_) {
      // Best-effort.
    }
  }

  // ---------------------------------------------------------------------------
  // Stockage
  // ---------------------------------------------------------------------------

  Future<DiagnosticRunEntry?> _read(DiagnosticRunType type) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(type));
    if (raw == null || raw.isEmpty) return null;
    try {
      return DiagnosticRunEntry.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(DiagnosticRunType type, DiagnosticRunEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(type), jsonEncode(entry.toJson()));
  }
}

final diagnosticRunRepositoryProvider = Provider<DiagnosticRunRepository>(
  (ref) => DiagnosticRunRepository(ref.watch(apiClientProvider)),
);

final diagnosticRunTrackerProvider = Provider<DiagnosticRunTracker>(
  (ref) => DiagnosticRunTracker(
    repository: ref.watch(diagnosticRunRepositoryProvider),
    currentUserId: () => ref.read(compteIdProvider),
  ),
);

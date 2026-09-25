import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/diagnostic_run_repository.dart';
import '../auth/auth_controller.dart';
import '../models/diagnostic_run_models.dart';
import '../utils/submission_key.dart';

/// Âge au-delà duquel un passage **d'invité** n'est plus repris par un
/// diagnostic **connecté** (contrôle F2). Miroir de la fenêtre du serveur
/// (réutilisation d'une run par `rejouer`, 24 h en config) : les deux côtés
/// ouvrent un passage neuf au même moment.
const Duration kGuestPassageReuseWindow = Duration(hours: 24);

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
    this.runCreatedAt,
    this.ownerUserId,
    this.createdAsGuest = false,
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

  /// Quand l'appareil a reçu la run **pour la première fois** (horloge
  /// locale ; le serveur la date `subject_viewed_at`). Un rejeu ne la déplace
  /// pas. `null` : pas encore de run, ou entrée écrite avant le contrôle F2 —
  /// on retombe alors sur [touchedAt].
  final DateTime? runCreatedAt;

  /// Le compte qui porte la run **à la connaissance de l'appareil** : celui qui
  /// était connecté à sa création, ou celui dont l'authentification a transmis
  /// le jeton. Sert à ne jamais attacher la run d'un autre à un événement.
  final String? ownerUserId;

  /// Passage commencé **sans compte** : seul ce cas se rattache par jeton à
  /// l'authentification. Une run créée connectée est déjà portée par son
  /// compte (D25).
  final bool createdAsGuest;

  /// « Soumis » déjà envoyé (TCF rapide) : on ne le rejoue pas.
  final bool submitted;

  /// Passage terminé : la run reste connue pour les événements du rapport et
  /// du Plan, mais le prochain diagnostic du même type tire une clé neuve.
  final bool closed;

  final DateTime touchedAt;

  /// Transmissible à l'auth : run d'invité, jeton encore valable. 🛑 Le jeton
  /// est **conservé** après l'auth (lien web → app du lot 3b) : une run déjà
  /// claimée peut être renvoyée, le serveur l'ignore sans erreur.
  bool claimUsable(DateTime now) =>
      createdAsGuest &&
      diagnosticRunId != null &&
      claimToken != null &&
      (claimTokenExpiresAt == null || claimTokenExpiresAt!.isAfter(now));

  /// 🛑 **Contrôle F2** — un passage d'invité non clos ne se prolonge pas
  /// indéfiniment dans un diagnostic connecté : [userId] connecté ouvre un
  /// passage neuf si l'entrée d'invité est **vieille** (plus de
  /// [kGuestPassageReuseWindow] depuis la création de sa run) ou si elle a
  /// **un autre porteur**. Sinon, un vieux `subject_viewed_at` rangerait le
  /// diagnostic connecté dans une vieille cohorte — ou, run non rattachable,
  /// ne le tracerait nulle part. Même borne côté serveur (`rejouer`).
  bool reusableBy(String? userId, DateTime now) {
    if (!createdAsGuest || userId == null) return true;
    if (ownerUserId != null && ownerUserId != userId) return false;
    final depuis = runCreatedAt ?? touchedAt;
    return now.difference(depuis) <= kGuestPassageReuseWindow;
  }

  DiagnosticRunEntry copyWith({
    String? diagnosticRunId,
    String? claimToken,
    DateTime? claimTokenExpiresAt,
    DateTime? runCreatedAt,
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
        runCreatedAt: runCreatedAt ?? this.runCreatedAt,
        ownerUserId: ownerUserId ?? this.ownerUserId,
        createdAsGuest: createdAsGuest,
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
        'runCreatedAt': runCreatedAt?.toIso8601String(),
        'ownerUserId': ownerUserId,
        'createdAsGuest': createdAsGuest,
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
      runCreatedAt: DateTime.tryParse(json['runCreatedAt'] as String? ?? ''),
      ownerUserId: json['ownerUserId'] as String?,
      createdAsGuest: json['createdAsGuest'] as bool? ?? false,
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

  /// Le passage en cours pour [type] — le même tant qu'il n'est pas clos,
  /// qu'il porte sur la même session et qu'il reste repris par l'appelant
  /// ([DiagnosticRunEntry.reusableBy], contrôle F2), sinon un neuf, avec une
  /// clé neuve.
  Future<DiagnosticRunEntry> _passage(
    DiagnosticRunType type,
    String? sessionId,
  ) async {
    final now = DateTime.now();
    final current = await _read(type);
    final owner = _currentUserId();
    final sameSession = current != null &&
        (current.sessionId == null ||
            sessionId == null ||
            current.sessionId == sessionId);
    if (current != null &&
        !current.closed &&
        sameSession &&
        current.reusableBy(owner, now)) {
      return current;
    }
    final fresh = DiagnosticRunEntry(
      clientKey: SubmissionKeys.newKey(),
      sessionId: sessionId,
      ownerUserId: owner,
      createdAsGuest: owner == null,
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
    // La date de création, elle, reste celle de la première réponse pour
    // cette run (F2) : un rejeu ne rajeunit pas le passage.
    final now = DateTime.now();
    final sameRun = entry.diagnosticRunId == created.diagnosticRunId;
    final updated = entry.copyWith(
      diagnosticRunId: created.diagnosticRunId,
      claimToken: created.claimToken,
      claimTokenExpiresAt: created.claimTokenExpiresAt,
      runCreatedAt: sameRun ? entry.runCreatedAt ?? now : now,
      ownerUserId: entry.ownerUserId ?? _currentUserId(),
      touchedAt: now,
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
  /// `null`. Le serveur n'en rattache qu'une : on prend la plus récente entre
  /// la run **d'invité** de l'appareil dont le jeton vaut encore (même règle
  /// que le web) et celle reçue par le **lien web → app** ([receiveAppLink]).
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
      final link = await _readAppLink();
      if (link != null &&
          (best == null || link.receivedAt.isAfter(best.touchedAt))) {
        return link.claim;
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
    if (claim.via == DiagnosticRunClaimVia.appLink) {
      // Transmise une fois : rattachée ou refusée, le serveur a tranché. La
      // run du web ne devient pas une run de l'appareil (son rapport n'est
      // pas ici) : aucun événement ne la portera.
      await _forgetAppLink();
      return;
    }
    try {
      for (final type in DiagnosticRunType.values) {
        final entry = await _read(type);
        if (entry == null || entry.diagnosticRunId != claim.diagnosticRunId) {
          continue;
        }
        // 🛑 Premier compte seulement : une run déjà claimée, renvoyée par un
        // autre compte, ne change pas de porteur (le serveur l'a refusée).
        if (entry.ownerUserId != null) continue;
        await _write(type, entry.copyWith(ownerUserId: userId));
      }
    } catch (_) {
      // Best-effort.
    }
  }

  // ---------------------------------------------------------------------------
  // Lien web → app (lot 3b)
  // ---------------------------------------------------------------------------

  static const _appLinkKey = 'sejourfr.diagnosticRun.appLink';

  /// Le lien « Continuer sur l'application » a ouvert l'app avec la run d'un
  /// diagnostic passé sur le web : on la garde pour la **prochaine**
  /// authentification, qui la transmet avec `claimVia = APP_LINK`.
  ///
  /// Rangée **à part** des passages de l'appareil : ce n'est pas un passage
  /// d'ici (pas de clé, pas de rapport), et elle ne doit ni reprendre ni
  /// masquer le prochain diagnostic fait dans l'app. Un nouveau lien remplace
  /// l'ancien. Rien n'est vérifié ici : le serveur juge le jeton.
  Future<void> receiveAppLink(DiagnosticRunClaim claim) async {
    if (claim.via != DiagnosticRunClaimVia.appLink) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _appLinkKey,
        jsonEncode({
          'diagnosticRunId': claim.diagnosticRunId,
          'claimToken': claim.claimToken,
          'receivedAt': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {
      // Best-effort : sans elle, l'inscription est simplement hors diagnostic.
    }
  }

  Future<({DiagnosticRunClaim claim, DateTime receivedAt})?>
      _readAppLink() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_appLinkKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      final runId = json['diagnosticRunId'] as String?;
      final token = json['claimToken'] as String?;
      final receivedAt = DateTime.tryParse(json['receivedAt'] as String? ?? '');
      if (runId == null || token == null || receivedAt == null) return null;
      return (
        claim: DiagnosticRunClaim(
          diagnosticRunId: runId,
          claimToken: token,
          via: DiagnosticRunClaimVia.appLink,
        ),
        receivedAt: receivedAt,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _forgetAppLink() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_appLinkKey);
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

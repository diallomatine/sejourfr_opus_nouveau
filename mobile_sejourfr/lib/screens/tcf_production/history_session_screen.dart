import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import 'ee_session_controller.dart';
import 'eo_session_controller.dart';
import 'production_result_labels.dart';
import 'widgets/bilan_hero.dart';
import 'widgets/feedback_block.dart';
import 'widgets/production_app_header.dart';
import 'widgets/tache_bilan_row.dart';

/// Charge toutes les tasks actives d'une epreuve (max 9 : 3 niveaux x 3 taches).
/// Utilise pour resoudre `productionTaskId` -> displayTitle dans l'historique.
final _allTasksProvider =
    FutureProvider.autoDispose.family<List<ProductionTaskDto>, EpreuveType>((ref, epreuve) {
  return ref.watch(productionRepositoryProvider).listTasks(epreuve: epreuve);
});

/// Charge l'historique complet pour pouvoir filtrer par attemptId. Reutilise
/// le meme provider que `ProductionHistoryScreen` pour beneficier du cache.
final _historyForBilanProvider =
    FutureProvider.autoDispose.family<List<ProductionSubmissionDto>, EpreuveType>((ref, epreuve) {
  return ref.watch(productionRepositoryProvider).listMine(epreuve: epreuve, limit: 200);
});

/// Bilan d'epreuve calcule cote backend (moyenne ponderee + niveau global en
/// examen blanc). Re-fetche en mode live au meme rythme que le polling des
/// submissions, jusqu'a ce que les evaluations soient completes.
final _bilanProvider =
    FutureProvider.autoDispose.family<ProductionBilan, String>((ref, attemptId) {
  return ref.watch(productionRepositoryProvider).getProductionBilan(attemptId);
});

/// Bilan d'une session de production EE/EO — sert à la fois pour les
/// sessions passées (depuis l'historique) et comme bilan vivant après la
/// 3ème tâche d'un examen 3-tâches.
///
/// Mode `live=1` (query param) : polling actif tant qu'une submission n'est
/// pas dans un statut final (`EVALUATED` ou `FAILED`). Le CTA du bas devient
/// "Terminer la session" et ramène au hub. Sinon (depuis historique) : CTA
/// "Retour" qui pop la stack.
class HistorySessionScreen extends ConsumerStatefulWidget {
  const HistorySessionScreen({
    super.key,
    required this.epreuve,
    required this.attemptId,
  });

  final EpreuveType epreuve;
  final String attemptId;

  @override
  ConsumerState<HistorySessionScreen> createState() => _HistorySessionScreenState();
}

class _HistorySessionScreenState extends ConsumerState<HistorySessionScreen> {
  Timer? _pollTimer;
  bool _pollExhausted = false;

  static const Duration _pollIntervalFast = Duration(seconds: 3);
  static const Duration _pollIntervalSlow = Duration(seconds: 8);
  static const Duration _pollSlowdownAt = Duration(seconds: 30);
  static const Duration _pollMaxDuration = Duration(minutes: 5);

  late final DateTime _pollStartedAt;
  late final bool _liveMode;

  String _resultsRoute(String submissionId, int taskIndex) {
    final base = widget.epreuve == EpreuveType.tcfEo ? '/tcf/expression-orale' : '/tcf/expression-ecrite';
    return '$base/resultats/$submissionId?taskIndex=$taskIndex&history=1';
  }

  String get _moduleTitle =>
      widget.epreuve == EpreuveType.tcfEo ? 'Résultats — Expression orale' : 'Résultats — Expression écrite';

  @override
  void initState() {
    super.initState();
    _pollStartedAt = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // `live=1` est passé par l'écran soumission (eo_finished / ee_briefing)
      // au push du bilan, juste après la dernière tâche. Le polling tourne
      // alors jusqu'à ce que les 3 submissions soient toutes EVALUATED ou
      // FAILED. Côté historique, la query est absente → pas de polling.
      final live = GoRouterState.of(context).uri.queryParameters['live'] == '1';
      _liveMode = live;
      if (live) _schedulePollTick(_pollIntervalFast);
    });
  }

  void _schedulePollTick(Duration delay) {
    _pollTimer?.cancel();
    _pollTimer = Timer(delay, _pollTick);
  }

  Future<void> _pollTick() async {
    if (!mounted) return;
    if (DateTime.now().difference(_pollStartedAt) > _pollMaxDuration) {
      if (mounted) setState(() => _pollExhausted = true);
      return;
    }
    ref.invalidate(_historyForBilanProvider(widget.epreuve));
    ref.invalidate(_bilanProvider(widget.attemptId));
    try {
      final all = await ref.read(_historyForBilanProvider(widget.epreuve).future);
      final bilan = await ref.read(_bilanProvider(widget.attemptId).future);
      if (!mounted) return;
      final session = all.where((s) => s.attemptId == widget.attemptId).toList();
      // On s'arrête quand toutes les submissions présentes sont évaluées ET
      // que le backend a posé `niveauGlobal` (signal que le pipeline IA est
      // vide) — y compris quand l'examen est `finished` avec < 3 tâches : les
      // manquantes sont comptées 0, le niveau est calculable et figé.
      final submissionsSettled =
          session.isNotEmpty && session.every((s) => s.statut.isFinal);
      final levelSettled = bilan.finished && bilan.niveauGlobal != null;
      if (submissionsSettled && (levelSettled || !bilan.exam)) {
        return; // plus rien à attendre.
      }
    } catch (_) {
      // Ignore : on retentera au prochain tick.
    }
    final elapsed = DateTime.now().difference(_pollStartedAt);
    final next = elapsed < _pollSlowdownAt ? _pollIntervalFast : _pollIntervalSlow;
    _schedulePollTick(next);
  }

  Future<void> _onManualRefresh() async {
    if (_pollExhausted) setState(() => _pollExhausted = false);
    ref.invalidate(_historyForBilanProvider(widget.epreuve));
    ref.invalidate(_bilanProvider(widget.attemptId));
    try {
      final all = await ref.read(_historyForBilanProvider(widget.epreuve).future);
      if (!mounted) return;
      final session = all.where((s) => s.attemptId == widget.attemptId).toList();
      if (session.isNotEmpty && !session.every((s) => s.statut.isFinal)) {
        _schedulePollTick(_pollIntervalFast);
      }
    } catch (_) {
      _schedulePollTick(_pollIntervalFast);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _onFinishLive() {
    // Reset le state du session controller (sinon le hub d'entraînement
    // continue à voir l'attempt comme actif) puis go vers le hub.
    if (widget.epreuve == EpreuveType.tcfEo) {
      ref.read(eoSessionProvider.notifier).reset();
    } else {
      ref.read(eeSessionProvider.notifier).reset();
    }
    context.go(AppRoutes.reviser);
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(_historyForBilanProvider(widget.epreuve));
    final allTasks = ref.watch(_allTasksProvider(widget.epreuve));
    final bilanAsync = ref.watch(_bilanProvider(widget.attemptId));
    final bilan = bilanAsync.valueOrNull;

    final fallbackRoute =
        widget.epreuve == EpreuveType.tcfEo ? '/tcf/eo' : '/tcf/ee';
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: ProductionAppHeader(
        title: _moduleTitle,
        fallbackRoute: fallbackRoute,
        rightAction: const ProductionAppHeaderInfo(),
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBox(
          message: ApiClient.toApiException(e).message,
          onRetry: () => ref.invalidate(_historyForBilanProvider(widget.epreuve)),
        ),
        data: (allSubs) {
          final session = allSubs.where((s) => s.attemptId == widget.attemptId).toList();
          if (session.isEmpty) {
            // Aucune submission pour cet attempt. Deux cas distincts :
            //  - examen blanc terminé sans aucune production rendue (abandon
            //    après CO/CE) → on rend le bilan « non évalué » : 3 tâches
            //    « Non rendue » + niveau plancher A1_NON_ATTEINT renvoyé par le
            //    backend. On continue le rendu normal (les slots seront vides).
            //  - attemptId réellement inconnu → erreur.
            if (bilanAsync.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final b = bilan;
            if (b == null || !b.exam || !b.finished) {
              return const _ErrorBox(
                message: 'Cette session est introuvable.',
                onRetry: null,
              );
            }
          }
          return allTasks.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorBox(
              message: ApiClient.toApiException(e).message,
              onRetry: () => ref.invalidate(_allTasksProvider(widget.epreuve)),
            ),
            data: (tasks) {
              final tasksById = {for (final t in tasks) t.id: t};
              int tacheNumOf(ProductionSubmissionDto s) =>
                  s.tacheNumero ??
                  tasksById[s.productionTaskId]?.tacheNumero ??
                  99;
              session.sort(
                  (a, b) => tacheNumOf(a).compareTo(tacheNumOf(b)));

              // Slots affichés : en examen terminé, on rend les 3 tâches
              // attendues (T1/T2/T3) — les manquantes apparaissent « Non
              // rendue ». Sinon, on liste simplement les submissions présentes.
              final expected =
                  (bilan?.exam ?? false) ? (bilan?.expectedCount ?? 3) : 0;
              final showAllSlots =
                  (bilan?.finished ?? false) && expected > 0;
              final slots = <_TaskSlot>[];
              if (showAllSlots) {
                final byNum = <int, ProductionSubmissionDto>{
                  for (final s in session) tacheNumOf(s): s,
                };
                for (var n = 1; n <= expected; n++) {
                  slots.add(_TaskSlot(tacheNumero: n, submission: byNum[n]));
                }
              } else {
                for (final s in session) {
                  slots.add(
                      _TaskSlot(tacheNumero: tacheNumOf(s), submission: s));
                }
              }

              final liveMode = _liveModeOrFalse();
              return _Body(
                epreuve: widget.epreuve,
                slots: slots,
                tasksById: tasksById,
                bilan: bilan,
                liveMode: liveMode,
                pollExhausted: _pollExhausted,
                onTapTache: (i) {
                  final s = slots[i].submission;
                  if (s == null || !s.statut.isFinal) return;
                  context.push(_resultsRoute(s.id, i));
                },
                onManualRefresh: _onManualRefresh,
                onFinishLive: _onFinishLive,
              );
            },
          );
        },
      ),
    );
  }

  bool _liveModeOrFalse() {
    // `_liveMode` est late et set après le premier postFrame ; pendant le
    // tout premier build (avant le callback), on retombe sur false (mode
    // historique). Pas de risque d'utiliser une valeur non initialisée.
    try {
      return _liveMode;
    } catch (_) {
      return false;
    }
  }
}

/// Slot affiché dans le détail par tâche. `submission` null = tâche jamais
/// rendue (examen terminé/abandonné) → affichée « Non rendue ».
class _TaskSlot {
  const _TaskSlot({required this.tacheNumero, this.submission});

  final int tacheNumero;
  final ProductionSubmissionDto? submission;
}

class _Body extends StatelessWidget {
  const _Body({
    required this.epreuve,
    required this.slots,
    required this.tasksById,
    required this.bilan,
    required this.liveMode,
    required this.pollExhausted,
    required this.onTapTache,
    required this.onManualRefresh,
    required this.onFinishLive,
  });

  final EpreuveType epreuve;
  final List<_TaskSlot> slots;
  final Map<String, ProductionTaskDto> tasksById;

  /// Bilan d'epreuve backend (null tant que non charge / en erreur). Source du
  /// niveau global (examen blanc uniquement) et de la moyenne ponderee.
  final ProductionBilan? bilan;
  final bool liveMode;
  final bool pollExhausted;
  final ValueChanged<int> onTapTache;
  final Future<void> Function() onManualRefresh;
  final VoidCallback onFinishLive;

  Iterable<ProductionSubmissionDto> get _submissions =>
      slots.map((s) => s.submission).whereType<ProductionSubmissionDto>();

  int get _pendingCount => _submissions.where((s) => !s.statut.isFinal).length;

  int get _evaluatedCount =>
      _submissions.where((s) => s.evaluation != null).length;

  /// Productions rendues dont l'évaluation IA a échoué : le candidat a une
  /// action à faire (relancer depuis l'écran de résultat), on ne peut pas les
  /// laisser passer pour de simples « non évaluées ».
  int get _failedCount =>
      _submissions.where((s) => s.statut == SubmissionStatut.failed).length;

  /// Moyenne locale de secours quand le backend n'a pas (encore) renvoyé de
  /// `moyenneSur20` dans le bilan.
  double? get _moyenneLocale {
    final notes =
        _submissions.map((s) => s.evaluation?.noteSurVingt).whereType<double>().toList();
    if (notes.isEmpty) return null;
    return notes.reduce((a, b) => a + b) / notes.length;
  }

  /// Niveau global du bilan d'épreuve (renseigné par le backend uniquement en
  /// examen blanc avec évaluations complètes). Null en entraînement libre.
  NiveauCecrl? get _niveauGlobal => bilan?.niveauGlobal;

  String _nextStepsMessage() {
    final niveau = _niveauGlobal;
    if (niveau == null) {
      return "Continue à t'entraîner pour qu'on puisse évaluer ton niveau "
          'avec précision.';
    }
    final modaliteAdj = epreuve == EpreuveType.tcfEo ? 'orale' : 'écrite';
    switch (niveau) {
      case NiveauCecrl.a1NonAtteint:
      case NiveauCecrl.a1:
        return "Reviens aux bases de l'expression $modaliteAdj — vise le A2 "
            'à ta prochaine session.';
      case NiveauCecrl.a2:
        return 'Niveau A2 sur cette épreuve — le palier demandé pour la carte '
            'de séjour pluriannuelle, à condition de l\'atteindre aussi dans '
            'les 3 autres épreuves. Continue pour viser le B1.';
      case NiveauCecrl.b1:
        return 'Niveau B1 sur cette épreuve — le palier demandé pour la carte '
            'de résident, à condition de l\'atteindre aussi dans les 3 autres '
            'épreuves. Vise le B2 pour la naturalisation.';
      case NiveauCecrl.b2:
        return 'Excellent — niveau B2 sur cette épreuve, le palier demandé '
            'pour la naturalisation. Il se juge dans les 4 épreuves sans '
            'moyenne : garde ce niveau partout.';
      case NiveauCecrl.c1:
      case NiveauCecrl.c2:
        return 'Niveau ${niveau.displayName} — bravo, ton français '
            '$modaliteAdj est avancé. Le TCF IRN, lui, s\'arrête à B2 : tu es '
            'au-dessus du palier le plus haut demandé.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pendingCount;
    final hasPending = pending > 0;
    final evaluated = _evaluatedCount;
    final total = _submissions.length;
    final allEvaluated = evaluated == total && total > 0;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            children: [
              BilanHero(
                moyenneSur20: bilan?.moyenneSur20 ?? _moyenneLocale,
                niveauGlobal: _niveauGlobal,
                correspondanceTcf: bilan?.correspondanceTcf,
                needsRetry: _failedCount > 0 && _niveauGlobal == null,
              ),
              if (liveMode && hasPending) ...[
                _EvaluatingBanner(
                  pending: pending,
                  exhausted: pollExhausted,
                  onRefresh: onManualRefresh,
                ),
                const SizedBox(height: 14),
              ],
              // Eyebrow + titre de section + sous-titre, pattern identique
              // aux autres écrans de résultats (results EE/EO, bilan exam).
              Text(
                'DÉTAIL PAR TÂCHE',
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.muted,
                  letterSpacing: 1.6,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _failedCount > 0
                    ? 'Une évaluation n\'a pas abouti : touche la tâche en rouge '
                        'pour la relancer.'
                    : allEvaluated
                        ? 'Touche une tâche pour revoir l\'évaluation détaillée.'
                        : 'Touche une tâche évaluée pour ouvrir son évaluation détaillée.',
                style: AppFonts.ui(
                  size: 12.5,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < slots.length; i++)
                _TacheRowTap(
                  enabled: slots[i].submission?.statut.isFinal ?? false,
                  onTap: () => onTapTache(i),
                  child: TacheBilanRow(
                    name: _taskName(i),
                    niveau: tacheNiveau(slots[i].submission?.evaluation),
                    evaluated: slots[i].submission?.statut ==
                        SubmissionStatut.evaluated,
                    pending: slots[i].submission != null &&
                        !slots[i].submission!.statut.isFinal,
                    notRendered: slots[i].submission == null,
                    failed: slots[i].submission?.statut ==
                        SubmissionStatut.failed,
                  ),
                ),
              const SizedBox(height: 16),
              FeedbackBlock(
                kind: FeedbackKind.suggest,
                title: 'Tes prochaines étapes',
                items: [_nextStepsMessage()],
              ),
            ],
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.line2, width: 1)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: SafeArea(
            top: false,
            child: AppButton(
              label: liveMode ? 'Terminer la session' : 'Retour à l\'historique',
              icon: liveMode ? LucideIcons.check : LucideIcons.arrowLeft,
              onPressed: liveMode
                  ? onFinishLive
                  : () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
            ),
          ),
        ),
      ],
    );
  }

  String _taskName(int i) {
    final slot = slots[i];
    final s = slot.submission;
    final t = s == null ? null : tasksById[s.productionTaskId];
    if (t == null) return 'Tâche ${slot.tacheNumero}';
    return 'Tâche ${t.tacheNumero} — ${t.displayTitle}';
  }
}

/// Wrapper InkWell autour d'une `TacheBilanRow`. Quand `enabled` est false
/// (eval IA encore en cours), la ligne reste affichée mais non-tappable.
class _TacheRowTap extends StatelessWidget {
  const _TacheRowTap({
    required this.onTap,
    required this.child,
    this.enabled = true,
  });

  final VoidCallback onTap;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}

/// Bandeau visible en mode live tant qu'une éval IA n'a pas remonté son
/// verdict. Devient rouge avec un CTA « Actualiser » quand le polling
/// (5 min) s'épuise sans succès.
class _EvaluatingBanner extends StatelessWidget {
  const _EvaluatingBanner({
    required this.pending,
    required this.exhausted,
    required this.onRefresh,
  });

  final int pending;
  final bool exhausted;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final bg = exhausted ? AppColors.redLight : AppColors.blueSoft;
    final fg = exhausted ? AppColors.red : AppColors.blue;
    final text = exhausted
        ? "L'évaluation prend plus de temps que prévu. Actualise dans un instant."
        : 'Évaluation IA en cours sur $pending tâche${pending > 1 ? "s" : ""} — encore quelques secondes…';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: fg.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          if (exhausted)
            Icon(LucideIcons.clock, color: fg, size: 20)
          else
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation(fg),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppFonts.ui(
                size: 12.5,
                color: AppColors.ink,
                height: 1.4,
              ),
            ),
          ),
          if (exhausted) ...[
            const SizedBox(width: 8),
            Material(
              color: fg,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onRefresh,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Text(
                    'Actualiser',
                    style: AppFonts.ui(
                      size: 12,
                      weight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.circleAlert, size: 32, color: AppColors.red),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.ui(size: 13, color: AppColors.muted),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            AppButton(
              label: 'Réessayer',
              onPressed: onRetry,
              icon: LucideIcons.refreshCw,
            ),
          ],
        ],
      ),
    );
  }
}

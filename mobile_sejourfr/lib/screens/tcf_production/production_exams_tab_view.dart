import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/utils/start_failure.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../module_detail/production_exam_briefing_sheet.dart';
import 'ee_session_controller.dart';
import 'eo_session_controller.dart';
import 'expression_hub_data.dart';
import 'production_catalog.dart';
import 'tcf_production_module.dart';
import 'widgets/exam_filter_chips.dart';
import 'widgets/exam_slot/exam_slot_card.dart';
import 'widgets/exams_error_view.dart';
import 'widgets/production_exam_done_result.dart';
import 'widgets/production_exam_trail.dart';

/// Identité des sessions d'examen d'une épreuve, sous forme comparable.
///
/// Sert de dépendance aux bilans : recharger le catalogue (le candidat vient de
/// produire un sujet) ne doit **pas** relancer un bilan par session — seule
/// l'apparition d'une session nouvelle le justifie. Riverpod compare la valeur
/// sélectionnée avec `==`, d'où la chaîne plutôt qu'une liste.
String _examIdsOf(AsyncValue<HubData> async) =>
    (async.valueOrNull?.exams.map((e) => e.attemptId).toList() ??
            const <String>[])
        .join(',');

/// Bilans des sessions d'examen blanc (≥ 3 tâches) d'une épreuve, fetchés en
/// parallèle. Sert à la fois au niveau estimé (le meilleur `niveauGlobal`) et
/// au mapping session → slot réel (`bilan.slotNumber`).
final examBilansProvider =
    FutureProvider.autoDispose.family<List<ProductionBilan>, EpreuveType>(
        (ref, epreuve) async {
  final ids = ref.watch(expressionHubProvider(epreuve).select(_examIdsOf));
  if (ids.isEmpty) return const [];
  final link = ref.keepAlive();
  try {
    final repo = ref.watch(productionRepositoryProvider);
    return await Future.wait(ids.split(',').map(repo.getProductionBilan));
  } catch (_) {
    link.close();
    rethrow;
  }
});

/// Niveau estimé d'une épreuve = le plus élevé des `niveauGlobal` des bilans
/// d'examen blanc. Renvoie null si aucun bilan exposé de niveau.
final _niveauEstimeProvider =
    Provider.autoDispose.family<NiveauCecrl?, EpreuveType>((ref, epreuve) {
  final bilans = ref.watch(examBilansProvider(epreuve)).valueOrNull;
  NiveauCecrl? best;
  for (final b in bilans ?? const <ProductionBilan>[]) {
    final n = b.niveauGlobal;
    if (n == null) continue;
    if (best == null || n.scaleIndex > best.scaleIndex) best = n;
  }
  return best;
});

/// Map `slotNumber (1-10) → ExamSession`. On lit le slot réel depuis le bilan
/// (`bilan.slotNumber`) au lieu d'un mapping chronologique. Les anciennes
/// sessions sans slot (toutes slot 1) tombent sur le slot 1 — accepté. En cas
/// de collision (plusieurs sessions sur le même slot), la plus récente gagne.
final _sessionsBySlotProvider =
    Provider.autoDispose.family<Map<int, ExamSession>, EpreuveType>(
        (ref, epreuve) {
  final data = ref.watch(expressionHubProvider(epreuve)).valueOrNull;
  if (data == null) return const {};
  final bilans =
      ref.watch(examBilansProvider(epreuve)).valueOrNull ?? const [];
  final slotByAttempt = <String, int>{
    for (final b in bilans)
      if (b.slotNumber != null) b.attemptId: b.slotNumber!,
  };
  final bySlot = <int, ExamSession>{};
  // `data.exams` est trié du plus récent au plus ancien → on insère d'abord
  // les récents, et un `putIfAbsent` laisse le récent gagner sur le slot.
  for (final exam in data.exams) {
    final slot = slotByAttempt[exam.attemptId] ?? 1;
    bySlot.putIfAbsent(slot, () => exam);
  }
  return bySlot;
});

/// Nombre de slots ouverts en mode gratuit ; au-delà → paywall TCF.
const int _freeSlots = 2;

/// Nombre de slots affichés par défaut (les autres masqués derrière « Voir »).
const int _visibleByDefault = 7;

/// État visuel d'un slot : palette d'icône / chip de difficulté.
enum _ExamDifficulty { facile, moyen, difficile }

_ExamDifficulty _difficultyFor(int slot) {
  if (slot <= 3) return _ExamDifficulty.facile;
  if (slot <= 6) return _ExamDifficulty.moyen;
  return _ExamDifficulty.difficile;
}

ExamSlotPill _difficultyPill(_ExamDifficulty d) {
  return switch (d) {
    _ExamDifficulty.facile => ExamSlotPill(
        label: 'A2 · Facile',
        bg: AppColors.green.withValues(alpha: 0.14),
        fg: AppColors.green,
      ),
    _ExamDifficulty.moyen => const ExamSlotPill(
        label: 'B1 · Moyen',
        bg: AppColors.line2,
        fg: AppColors.muted,
      ),
    _ExamDifficulty.difficile => ExamSlotPill(
        label: 'B2 · Difficile',
        bg: AppColors.red.withValues(alpha: 0.10),
        fg: AppColors.red,
      ),
  };
}

({Color bg, Color fg}) _badgeColors(_ExamDifficulty d) {
  return switch (d) {
    _ExamDifficulty.facile => (bg: AppColors.blueLight, fg: AppColors.blue),
    _ExamDifficulty.moyen => (bg: AppColors.line2, fg: AppColors.ink2),
    _ExamDifficulty.difficile => (bg: AppColors.redLight, fg: AppColors.red),
  };
}

/// Mode « Examens blancs » du parcours EE/EO : stats + barre de progression +
/// chips de filtre + liste des 10 slots numérotés.
///
/// Corps seul — l'en-tête et le voile d'attente sont portés par
/// [ProductionExamsScreen]. Le catalogue et les bilans restent en cache : y
/// revenir ne recharge rien.
class ProductionExamsTabView extends ConsumerStatefulWidget {
  const ProductionExamsTabView({
    super.key,
    required this.module,
    required this.onBusy,
    required this.top,
  });

  final TcfProductionModule module;

  /// Remonte l'attente à l'écran : le voile doit couvrir l'en-tête, sinon on
  /// peut naviguer pendant le démarrage d'un examen.
  final ValueChanged<bool> onBusy;

  /// Widgets rendus en tête de la grille. Vide sur l'écran des examens blancs,
  /// qui porte tout son contexte dans son en-tête.
  final List<Widget> top;

  @override
  ConsumerState<ProductionExamsTabView> createState() =>
      _ProductionExamsTabViewState();
}

class _ProductionExamsTabViewState
    extends ConsumerState<ProductionExamsTabView> {
  bool _starting = false;
  int _filter = 0;
  bool _showAll = false;

  void _setStarting(bool value) {
    setState(() => _starting = value);
    widget.onBusy(value);
  }

  bool _isPremium() {
    final auth = ref.read(authControllerProvider);
    return auth is AuthAuthenticated &&
        auth.user.canAccessModule(AppModule.tcf);
  }

  bool _isLocked(int slot) => !_isPremium() && slot > _freeSlots;

  void _onSlotTap({required int slot, required ExamSession? exam}) {
    if (exam != null) {
      _openSession(exam);
      return;
    }
    if (_isLocked(slot)) {
      showPaywallSheet(context);
      return;
    }
    _openBriefing(slot);
  }

  void _onSlotAction({required int slot, required ExamSession? exam}) {
    if (_isLocked(slot)) {
      showPaywallSheet(context);
      return;
    }
    _openBriefing(slot);
  }

  void _openBriefing(int slot) {
    if (!_isPremium()) {
      showPaywallSheet(context);
      return;
    }
    showProductionExamBriefingSheet(
      context,
      module: widget.module,
      starting: _starting,
      onStart: () => _startExam(slot),
    );
  }

  Future<void> _startExam(int slotNumber) async {
    if (_starting) return;
    _setStarting(true);
    ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
    try {
      if (widget.module.isEo) {
        await ref.read(eoSessionProvider.notifier).startExam(slotNumber: slotNumber);
        if (!mounted) return;
        context.push('/tcf/expression-orale/t/0');
      } else {
        await ref.read(eeSessionProvider.notifier).startExam(slotNumber: slotNumber);
        if (!mounted) return;
        context.push('/tcf/expression-ecrite/t/0');
      }
    } catch (e) {
      if (!mounted) return;
      showPaywallOrError(context, e);
    } finally {
      if (mounted) _setStarting(false);
    }
  }

  void _openSession(ExamSession exam) {
    final base =
        widget.module.isEo ? '/tcf/expression-orale' : '/tcf/expression-ecrite';
    context.push('$base/sessions/${exam.attemptId}');
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(expressionHubProvider(widget.module.epreuve)).when(
          // Le catalogue est en cache : un rechargement (retour d'un examen)
          // garde la grille à l'écran au lieu de la remplacer par un spinner.
          skipLoadingOnReload: true,
          loading: () => [
            Center(
                child: CircularProgressIndicator(color: widget.module.accent)),
          ],
          error: (e, _) => [
            ExamsErrorView(
              message: ApiClient.toApiException(e).message,
              onRetry: () =>
                  invalidateProductionCatalog(ref, widget.module.epreuve),
              accent: widget.module.accent,
            ),
          ],
          data: (_) => _content(),
        );

    return RefreshIndicator(
      color: widget.module.accent,
      onRefresh: () async {
        // Le tiré-pour-rafraîchir est le seul geste qui redemande tout : le
        // catalogue ET les bilans, dont la note peut avoir fini d'arriver.
        invalidateProductionCatalog(ref, widget.module.epreuve);
        ref.invalidate(examBilansProvider(widget.module.epreuve));
        await ref.read(productionCatalogProvider(widget.module.epreuve).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          ...widget.top,
          ...content,
        ],
      ),
    );
  }

  List<Widget> _content() {
    // Mapping session → slot réel (via `bilan.slotNumber`). Tant que les bilans
    // ne sont pas chargés, on retombe sur une map vide → tous les slots libres.
    final bySlot = ref.watch(_sessionsBySlotProvider(widget.module.epreuve));
    final nextSlot = _firstFreeSlot(bySlot);

    final filteredIndices = <int>[
      for (int i = 0; i < kProductionExamSlots; i++)
        if (_passesFilter(slotIndex: i, bySlot: bySlot)) i,
    ];

    final visibleIndices =
        _showAll ? filteredIndices : filteredIndices.take(_visibleByDefault).toList();
    final hiddenCount = filteredIndices.length - visibleIndices.length;

    final doneCount = bySlot.length;
    // Niveau estimé alimenté par le backend (bilans d'examen blanc), pas
    // dérivé localement par tâche.
    final niveauEstime = ref.watch(_niveauEstimeProvider(widget.module.epreuve));

    final lockedTodo = _isPremium() ? 0 : (kProductionExamSlots - _freeSlots);
    final todoCount = kProductionExamSlots - doneCount - lockedTodo;

    return [
      ProductionExamTrail(
        done: doneCount,
        total: kProductionExamSlots,
        accent: widget.module.accent,
        note: niveauEstime == null
            ? null
            : 'Niveau estimé · ${niveauEstime.displayName}',
      ),
      const SizedBox(height: 12),
      ExamFilterChips(
        active: _filter,
        accent: widget.module.accent,
        labels: [
          'Tous · $kProductionExamSlots',
          'À faire · $todoCount',
          'Terminés · $doneCount',
        ],
        onChanged: (i) => setState(() {
          _filter = i;
          _showAll = false;
        }),
      ),
      const SizedBox(height: 12),
      for (final i in visibleIndices) ...[
        _buildSlot(i, bySlot, nextSlot),
        const SizedBox(height: 8),
      ],
      if (filteredIndices.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
          child: Text(
            _filter == 1
                ? 'Tous les examens disponibles sont déjà faits.'
                : _filter == 2
                    ? 'Aucun examen terminé pour l\'instant.'
                    : 'Aucun examen.',
            style: AppFonts.ui(size: 13, color: AppColors.muted),
          ),
        ),
      if (hiddenCount > 0)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: TextButton.icon(
            onPressed: () => setState(() => _showAll = true),
            icon: Text(
              'Voir les examens ${visibleIndices.length + 1} à ${filteredIndices.length}',
              style: AppFonts.ui(
                  size: 13,
                  weight: FontWeight.w700,
                  color: widget.module.accent),
            ),
            label: Icon(LucideIcons.chevronDown,
                size: 18, color: widget.module.accent),
          ),
        ),
    ];
  }

  /// Premier slot 1-based sans session jouée (1 si tout est libre, sinon le
  /// plus petit numéro non présent dans la map).
  int _firstFreeSlot(Map<int, ExamSession> bySlot) {
    for (int n = 1; n <= kProductionExamSlots; n++) {
      if (!bySlot.containsKey(n)) return n;
    }
    return kProductionExamSlots + 1;
  }

  bool _passesFilter(
      {required int slotIndex, required Map<int, ExamSession> bySlot}) {
    final slotNumber = slotIndex + 1;
    final isDone = bySlot.containsKey(slotNumber);
    final isLocked = _isLocked(slotNumber);
    return switch (_filter) {
      1 => !isDone && !isLocked,
      2 => isDone,
      _ => true,
    };
  }

  Widget _buildSlot(int slotIndex, Map<int, ExamSession> bySlot, int nextSlot) {
    final number = slotIndex + 1;
    final exam = bySlot[number];
    final done = exam != null;
    final isLocked = _isLocked(number);
    final isNext = number == nextSlot && number <= kProductionExamSlots;
    final difficulty = _difficultyFor(number);
    final badge = _badgeColors(difficulty);

    final Widget secondaryStatus = done
        ? ProductionExamDoneResult(exam: exam)
        : Text(
            '3 tâches enchaînées',
            style: AppFonts.ui(size: 11, color: AppColors.muted2),
          );

    return ExamSlotCard(
      slot: number,
      done: done,
      isNext: isNext,
      isLocked: isLocked,
      badgeBaseBg: badge.bg,
      badgeBaseFg: badge.fg,
      title: 'Examen blanc n°$number',
      primaryPill: _difficultyPill(difficulty),
      secondaryStatus: secondaryStatus,
      onTap: () => _onSlotTap(slot: number, exam: exam),
      onAction: () => _onSlotAction(slot: number, exam: exam),
    );
  }
}


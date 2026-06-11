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
import '../../core/widgets/paywall_sheet.dart';
import '../module_detail/production_exam_briefing_sheet.dart';
import 'ee_session_controller.dart';
import 'eo_session_controller.dart';
import 'expression_hub_data.dart';
import 'tcf_production_module.dart';
import 'widgets/exam_filter_chips.dart';
import 'widgets/exam_progress_card.dart';
import 'widgets/exam_slot/exam_slot_card.dart';
import 'widgets/exams_error_view.dart';
import 'widgets/flag_badge.dart';
import 'widgets/module_screen_header.dart';
import 'widgets/production_exam_done_result.dart';
import 'widgets/production_exams_stats_row.dart';

/// Bilans des sessions d'examen blanc (≥ 3 tâches) d'une épreuve, fetchés en
/// parallèle. Sert à la fois au niveau estimé (le meilleur `niveauGlobal`) et
/// au mapping session → slot réel (`bilan.slotNumber`).
final _examBilansProvider =
    FutureProvider.autoDispose.family<List<ProductionBilan>, EpreuveType>((ref, epreuve) async {
  final repo = ref.watch(productionRepositoryProvider);
  final data = await ref.watch(expressionHubProvider(epreuve).future);
  if (data.exams.isEmpty) return const [];
  return Future.wait(
    data.exams.map((e) => repo.getProductionBilan(e.attemptId)),
  );
});

/// Niveau estimé d'une épreuve = le plus élevé des `niveauGlobal` des bilans
/// d'examen blanc. Renvoie null si aucun bilan exposé de niveau.
final _niveauEstimeProvider =
    FutureProvider.autoDispose.family<NiveauCecrl?, EpreuveType>((ref, epreuve) async {
  final bilans = await ref.watch(_examBilansProvider(epreuve).future);
  NiveauCecrl? best;
  for (final b in bilans) {
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
final _sessionsBySlotProvider = FutureProvider.autoDispose
    .family<Map<int, ExamSession>, EpreuveType>((ref, epreuve) async {
  final data = await ref.watch(expressionHubProvider(epreuve).future);
  final bilans = await ref.watch(_examBilansProvider(epreuve).future);
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

/// Nombre de slots d'examens blancs proposés pour une épreuve EE/EO.
const int _examSlotsCount = 10;

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

/// Page « Examens blancs » d'une épreuve EE/EO. Header + stats + barre de
/// progression + chips de filtre + liste des 10 slots numérotés.
class ProductionExamsScreen extends ConsumerStatefulWidget {
  const ProductionExamsScreen({super.key, required this.module});

  final TcfProductionModule module;

  @override
  ConsumerState<ProductionExamsScreen> createState() =>
      _ProductionExamsScreenState();
}

class _ProductionExamsScreenState extends ConsumerState<ProductionExamsScreen> {
  bool _starting = false;
  int _filter = 0;
  bool _showAll = false;

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
    setState(() => _starting = true);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiClient.toApiException(e).message),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _openSession(ExamSession exam) {
    final base =
        widget.module.isEo ? '/tcf/expression-orale' : '/tcf/expression-ecrite';
    context.push('$base/sessions/${exam.attemptId}');
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(widget.module.isEo ? '/tcf/eo' : '/tcf/ee');
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(expressionHubProvider(widget.module.epreuve));
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ModuleScreenHeader(
              title: 'Examens blancs',
              subtitle: '${widget.module.title} · TCF IRN',
              onBack: _back,
              trailing: const FlagBadge(),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.red)),
                error: (e, _) => ExamsErrorView(
                  message: ApiClient.toApiException(e).message,
                  onRetry: () => ref
                      .invalidate(expressionHubProvider(widget.module.epreuve)),
                  accent: AppColors.red,
                ),
                data: (_) => _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Mapping session → slot réel (via `bilan.slotNumber`). Tant que les bilans
    // ne sont pas chargés, on retombe sur une map vide → tous les slots libres.
    final bySlot =
        ref.watch(_sessionsBySlotProvider(widget.module.epreuve)).valueOrNull ??
            const <int, ExamSession>{};
    final nextSlot = _firstFreeSlot(bySlot);

    final filteredIndices = <int>[
      for (int i = 0; i < _examSlotsCount; i++)
        if (_passesFilter(slotIndex: i, bySlot: bySlot)) i,
    ];

    final visibleIndices =
        _showAll ? filteredIndices : filteredIndices.take(_visibleByDefault).toList();
    final hiddenCount = filteredIndices.length - visibleIndices.length;

    final doneCount = bySlot.length;
    final completed =
        bySlot.values.where((e) => e.isFullyEvaluated).toList();
    final avg = completed.isEmpty
        ? null
        : completed.map((e) => e.avgScore ?? 0).reduce((a, b) => a + b) /
            completed.length;
    // Niveau estimé alimenté par le backend (bilans d'examen blanc), pas
    // dérivé localement par tâche.
    final niveauEstime =
        ref.watch(_niveauEstimeProvider(widget.module.epreuve)).valueOrNull;

    final lockedTodo = _isPremium() ? 0 : (_examSlotsCount - _freeSlots);
    final todoCount = _examSlotsCount - doneCount - lockedTodo;

    return RefreshIndicator(
      color: AppColors.red,
      onRefresh: () async {
        ref.invalidate(expressionHubProvider(widget.module.epreuve));
        ref.invalidate(_examBilansProvider(widget.module.epreuve));
        await ref.read(expressionHubProvider(widget.module.epreuve).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        children: [
          ProductionExamsStatsRow(
            doneCount: doneCount,
            totalCount: _examSlotsCount,
            avgScore: avg,
            niveau: niveauEstime,
          ),
          const SizedBox(height: 12),
          ExamProgressCard(doneCount: doneCount, total: _examSlotsCount),
          const SizedBox(height: 12),
          ExamFilterChips(
            active: _filter,
            labels: [
              'Tous · $_examSlotsCount',
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
                      size: 13, weight: FontWeight.w700, color: AppColors.blue),
                ),
                label: const Icon(LucideIcons.chevronDown,
                    size: 18, color: AppColors.blue),
              ),
            ),
        ],
      ),
    );
  }

  /// Premier slot 1-based sans session jouée (1 si tout est libre, sinon le
  /// plus petit numéro non présent dans la map).
  int _firstFreeSlot(Map<int, ExamSession> bySlot) {
    for (int n = 1; n <= _examSlotsCount; n++) {
      if (!bySlot.containsKey(n)) return n;
    }
    return _examSlotsCount + 1;
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
    final isNext = number == nextSlot && number <= _examSlotsCount;
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


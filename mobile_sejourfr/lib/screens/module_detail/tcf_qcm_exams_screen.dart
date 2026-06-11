import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/attempt_summary.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../tcf_production/widgets/exam_filter_chips.dart';
import '../tcf_production/widgets/exam_progress_card.dart';
import '../tcf_production/widgets/exam_slot/exam_slot_card.dart';
import '../tcf_production/widgets/exams_error_view.dart';
import '../tcf_production/widgets/flag_badge.dart';
import '../tcf_production/widgets/module_screen_header.dart';
import 'qcm_hub_data.dart';
import 'tcf_module_exam_briefing_screen.dart';
import 'tcf_qcm_detail_screen.dart' show TcfQcmModule;
import 'widgets/exam_done_sheet.dart';
import 'widgets/qcm_exams/qcm_exams_stats_row.dart';

const int _examSlotsCount = 10;
const int _visibleByDefault = 7;

/// Page « Examens blancs » des modules TCF QCM (CO, CE, Structure). Header +
/// 3 stats (Terminés / Score moyen / Meilleur score) + barre de progression +
/// chips filtre + 10 slots numérotés. Slot 1 = examen de découverte gratuit,
/// slots 2-10 = premium.
class TcfQcmExamsScreen extends ConsumerStatefulWidget {
  const TcfQcmExamsScreen({super.key, required this.module});

  final TcfQcmModule module;

  @override
  ConsumerState<TcfQcmExamsScreen> createState() => _TcfQcmExamsScreenState();
}

class _TcfQcmExamsScreenState extends ConsumerState<TcfQcmExamsScreen> {
  int _filter = 0;
  bool _showAll = false;

  bool _isPremium() {
    final auth = ref.read(authControllerProvider);
    return auth is AuthAuthenticated &&
        auth.user.canAccessModule(AppModule.tcf);
  }

  bool _isLocked(int slot) => !_isPremium() && slot > 1;

  void _openBriefing({required int slotNumber}) {
    if (!_isPremium()) {
      final history = ref
              .read(qcmExamsHistoryProvider(widget.module.questionType))
              .valueOrNull ??
          const [];
      if (history.any((a) => a.isFinished)) {
        showPaywallSheet(context);
        return;
      }
    }
    ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
    showModuleExamBriefingSheet(context, widget.module, slotNumber: slotNumber);
  }

  /// Pousse le rapport Q-par-Q (`ExamReportScreen`) — même destination
  /// que « Voir le détail » des lots.
  void _openExamReport(AttemptSummary attempt) {
    context.push(AppRoutes.examReport.replaceFirst(':attemptId', attempt.id));
  }

  void _showExamSheet(AttemptSummary attempt, int slot) {
    final score = attempt.score;
    final total = attempt.totalQuestions;
    final subtitle =
        (score != null && total > 0) ? 'Dernier score : $score / $total' : null;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => ExamDoneSheet(
        title: 'Examen blanc $slot',
        subtitle: subtitle,
        accent: AppColors.blue,
        onViewDetail: () {
          Navigator.of(sheetCtx).pop();
          _openExamReport(attempt);
        },
        onResume: () {
          Navigator.of(sheetCtx).pop();
          _openBriefing(slotNumber: slot);
        },
      ),
    );
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/tcf/${widget.module.routeKey}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(qcmExamsHistoryProvider(widget.module.questionType));

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
                    child: CircularProgressIndicator(color: AppColors.blue)),
                error: (e, _) => ExamsErrorView(
                  message: ApiClient.toApiException(e).message,
                  onRetry: () => ref.invalidate(
                      qcmExamsHistoryProvider(widget.module.questionType)),
                  accent: AppColors.blue,
                ),
                data: (history) => _buildContent(history),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<AttemptSummary> history) {
    // Group by slot_number : on ne garde que le DERNIER essai par slot
    // (refait l'examen N → le nouvel attempt avec slot_number=N écrase
    // l'ancien dans la grille). Cf. migration V110 + bug « slot 2 prenait
    // la note d'un refait de l'examen 1 ». Le backend renvoie l'historique
    // en chrono DESC, donc le premier rencontré par slot est le bon.
    final bySlot = <int, AttemptSummary>{};
    for (final a in history) {
      if (!a.isFinished || a.slotNumber == null) continue;
      bySlot.putIfAbsent(a.slotNumber!, () => a);
    }
    final doneCount = bySlot.length;
    final nextSlot = _firstFreeSlot(bySlot);

    final filtered = <int>[
      for (int i = 0; i < _examSlotsCount; i++)
        if (_passesFilterBySlot(slotIndex: i, bySlot: bySlot)) i,
    ];

    final visible = _showAll ? filtered : filtered.take(_visibleByDefault).toList();
    final hiddenCount = filtered.length - visible.length;

    final finished = bySlot.values.toList();
    // Score calibré 100-499 (relevé façon TCF) au lieu du X/50 interne.
    final scores =
        finished.where((a) => a.calibratedScore != null).toList();
    const maxPossible = 499;
    final bestScore = scores.isEmpty
        ? null
        : scores.map((a) => a.calibratedScore!).reduce((a, b) => a > b ? a : b);
    final avgScore = scores.isEmpty
        ? null
        : (scores.map((a) => a.calibratedScore!).reduce((a, b) => a + b) /
                scores.length)
            .round();

    final todoCount =
        _examSlotsCount - bySlot.length - _lockedTodoCountBySlot(bySlot);
    final doneFilterCount = bySlot.length;

    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: () async {
        ref.invalidate(qcmExamsHistoryProvider(widget.module.questionType));
        await ref.read(qcmExamsHistoryProvider(widget.module.questionType).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        children: [
          QcmExamsStatsRow(
            doneCount: doneCount,
            totalCount: _examSlotsCount,
            bestScore: bestScore,
            avgScore: avgScore,
            maxPossible: maxPossible,
          ),
          const SizedBox(height: 12),
          ExamProgressCard(doneCount: doneCount, total: _examSlotsCount),
          const SizedBox(height: 12),
          ExamFilterChips(
            active: _filter,
            labels: [
              'Tous · $_examSlotsCount',
              'À faire · $todoCount',
              'Terminés · $doneFilterCount',
            ],
            onChanged: (i) => setState(() {
              _filter = i;
              _showAll = false;
            }),
          ),
          const SizedBox(height: 12),
          for (final i in visible) ...[
            _buildSlot(i, bySlot, nextSlot),
            const SizedBox(height: 8),
          ],
          if (filtered.isEmpty)
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
                  'Voir les examens ${visible.length + 1} à ${filtered.length}',
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

  bool _passesFilterBySlot(
      {required int slotIndex, required Map<int, AttemptSummary> bySlot}) {
    final slotNumber = slotIndex + 1;
    final isDone = bySlot.containsKey(slotNumber);
    final isLocked = _isLocked(slotNumber);
    return switch (_filter) {
      1 => !isDone && !isLocked,
      2 => isDone,
      _ => true,
    };
  }

  /// Premier slot vide (1..10). Sert au badge « À FAIRE ENSUITE ».
  int _firstFreeSlot(Map<int, AttemptSummary> bySlot) {
    for (int i = 1; i <= _examSlotsCount; i++) {
      if (!bySlot.containsKey(i)) return i;
    }
    return _examSlotsCount + 1;
  }

  int _lockedTodoCountBySlot(Map<int, AttemptSummary> bySlot) {
    if (_isPremium()) return 0;
    // Slots 2..10 verrouillés pour les non-premium ; un slot rempli n'est
    // jamais compté comme « à faire verrouillé ».
    var locked = 0;
    for (int i = 1; i <= _examSlotsCount; i++) {
      if (!bySlot.containsKey(i) && _isLocked(i)) locked++;
    }
    return locked;
  }

  Widget _buildSlot(
      int slotIndex, Map<int, AttemptSummary> bySlot, int nextSlot) {
    final number = slotIndex + 1;
    final attempt = bySlot[number];
    final done = attempt != null;
    final isLocked = _isLocked(number);
    final isNext = number == nextSlot && number <= _examSlotsCount;

    final calibrated = attempt?.calibratedScore;
    final level = attempt?.cecrlLevel;

    Widget? secondaryStatus;
    if (done && calibrated != null) {
      final c = level?.color ?? AppColors.green;
      secondaryStatus = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.circleCheck, size: 13, color: c),
          const SizedBox(width: 3),
          Text(
            level != null ? '$calibrated · ${level.displayName}' : '$calibrated/499',
            style: AppFonts.ui(
              size: 11,
              weight: FontWeight.w700,
              color: c,
            ),
          ),
        ],
      );
    } else if (!done && isNext && !isLocked) {
      secondaryStatus = Text(
        'À FAIRE ENSUITE',
        style: AppFonts.mono(
          size: 9,
          color: AppColors.blue,
          letterSpacing: 1.2,
          weight: FontWeight.w700,
        ),
      );
    }

    return ExamSlotCard(
      slot: number,
      done: done,
      isNext: isNext,
      isLocked: isLocked,
      badgeBaseBg: AppColors.blueLight,
      badgeBaseFg: AppColors.blue,
      title: 'Examen blanc n°$number',
      primaryPill: ExamSlotPill(
        label: widget.module.examSubtitle,
        bg: AppColors.blueLight,
        fg: AppColors.blueDark,
      ),
      secondaryStatus: secondaryStatus,
      onTap: done ? () => _showExamSheet(attempt, number) : _onEmptyTap(number),
      onAction: done ? () => _showExamSheet(attempt, number) : _onEmptyTap(number),
    );
  }

  VoidCallback _onEmptyTap(int slotNumber) {
    return () {
      if (_isLocked(slotNumber)) {
        showPaywallSheet(context);
      } else {
        _openBriefing(slotNumber: slotNumber);
      }
    };
  }
}


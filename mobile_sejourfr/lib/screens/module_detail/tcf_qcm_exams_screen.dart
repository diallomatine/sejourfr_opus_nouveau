import 'package:flutter/material.dart';
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
import 'widgets/qcm_exams/qcm_exam_action_sheet.dart';
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

  void _openBriefing() {
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
    showModuleExamBriefingSheet(context, widget.module);
  }

  void _openExamResult(AttemptSummary attempt) {
    context.push(AppRoutes.examResult.replaceFirst(':attemptId', attempt.id));
  }

  void _showExamSheet(AttemptSummary attempt) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => QcmExamActionSheet(
        attempt: attempt,
        onViewDetails: () {
          Navigator.of(sheetCtx).pop();
          _openExamResult(attempt);
        },
        onRetake: () {
          Navigator.of(sheetCtx).pop();
          _openBriefing();
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
    // Plus ancien examen en slot 1.
    final finished = history.where((a) => a.isFinished).toList().reversed.toList();
    final nextSlot = finished.length + 1;

    final filtered = <int>[
      for (int i = 0; i < _examSlotsCount; i++)
        if (_passesFilter(slotIndex: i, finished: finished)) i,
    ];

    final visible = _showAll ? filtered : filtered.take(_visibleByDefault).toList();
    final hiddenCount = filtered.length - visible.length;

    final doneCount = finished.length;
    final scores = finished
        .where((a) => a.weightedScore != null && a.maxWeightedScore != null)
        .toList();
    // Suppose `maxWeightedScore` constant entre les attempts du même module
    // (vrai à ce jour : 50 pour les examens module TCF). Si un jour ce n'est
    // plus le cas, repasser sur le pourcentage `score / maxScore`.
    final bestScore = scores.isEmpty
        ? null
        : scores
            .map((a) => a.weightedScore!)
            .reduce((a, b) => a > b ? a : b);
    final maxPossible = scores.isEmpty ? 50 : (scores.first.maxWeightedScore ?? 50);
    final avgScore = scores.isEmpty
        ? null
        : (scores.map((a) => a.weightedScore!).reduce((a, b) => a + b) /
                scores.length)
            .round();

    final todoCount =
        _examSlotsCount - finished.length - _lockedTodoCount(finished.length);
    final doneFilterCount = finished.length;

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
            _buildSlot(i, finished, nextSlot),
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
                style: AppFonts.jakarta(size: 13, color: AppColors.muted),
              ),
            ),
          if (hiddenCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: TextButton.icon(
                onPressed: () => setState(() => _showAll = true),
                icon: Text(
                  'Voir les examens ${visible.length + 1} à ${filtered.length}',
                  style: AppFonts.jakarta(
                      size: 13, weight: FontWeight.w700, color: AppColors.blue),
                ),
                label: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: AppColors.blue),
              ),
            ),
        ],
      ),
    );
  }

  bool _passesFilter(
      {required int slotIndex, required List<AttemptSummary> finished}) {
    final slotNumber = slotIndex + 1;
    final isDone = slotIndex < finished.length;
    final isLocked = _isLocked(slotNumber);
    return switch (_filter) {
      1 => !isDone && !isLocked,
      2 => isDone,
      _ => true,
    };
  }

  int _lockedTodoCount(int doneCount) {
    if (_isPremium()) return 0;
    // Les slots 2..10 sont premium (gratuit = slot 1 uniquement). Si le user
    // a déjà fini certains, ils restent comptés comme done et donc pas
    // « à faire » verrouillés.
    var locked = 0;
    for (int i = doneCount; i < _examSlotsCount; i++) {
      if (_isLocked(i + 1)) locked++;
    }
    return locked;
  }

  Widget _buildSlot(
      int slotIndex, List<AttemptSummary> finished, int nextSlot) {
    final number = slotIndex + 1;
    final attempt = slotIndex < finished.length ? finished[slotIndex] : null;
    final done = attempt != null;
    final isLocked = _isLocked(number);
    final isNext = number == nextSlot && number <= _examSlotsCount;

    final score = attempt?.weightedScore;
    final maxScore = attempt?.maxWeightedScore ?? 50;

    Widget? secondaryStatus;
    if (done && score != null) {
      secondaryStatus = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 13, color: AppColors.green),
          const SizedBox(width: 3),
          Text(
            '$score/$maxScore',
            style: AppFonts.jakarta(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.green,
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
      onTap: done ? () => _showExamSheet(attempt) : _onEmptyTap(number),
      onAction: done ? () => _showExamSheet(attempt) : _onEmptyTap(number),
    );
  }

  VoidCallback _onEmptyTap(int slotNumber) {
    return () {
      if (_isLocked(slotNumber)) {
        showPaywallSheet(context);
      } else {
        _openBriefing();
      }
    };
  }
}


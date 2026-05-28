import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/attempt_summary.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../module_detail/civique_exam_briefing_sheet.dart';
import '../module_detail/widgets/exam_done_sheet.dart';
import '../tcf_production/widgets/exam_filter_chips.dart';
import '../tcf_production/widgets/exam_progress_card.dart';
import '../tcf_production/widgets/exams_error_view.dart';
import '../tcf_production/widgets/flag_badge.dart';
import '../tcf_production/widgets/module_screen_header.dart';
import 'widgets/civique_full_exams/civique_full_exam_slot_builder.dart';
import 'widgets/civique_full_exams/civique_full_exams_stats_row.dart';

const int _examSlotsCount = 20;
const int _visibleByDefault = 7;
const int _examTotalQuestions = 40;

/// Historique des examens blancs civique GLOBAUX (40 Q tous thèmes). On
/// charge tous les `MOCK_EXAM module=CIVIQUE` puis on filtre côté client
/// pour ne garder QUE les globaux (`!isThemeScoped`, c.-à-d. `lotThemeId`
/// null). Le backend ne sait pas filtrer « globaux uniquement » en un
/// paramètre — l'inverse `themeId=` filtre par thème, ici on veut le
/// complément.
final _civiqueGlobalExamsProvider =
    FutureProvider.autoDispose<List<AttemptSummary>>((ref) async {
  final all = await ref.read(attemptsRepositoryProvider).listMine(
        type: AttemptType.mockExam,
        module: AppModule.civique,
        limit: 50,
      );
  return all.where((a) => !a.isThemeScoped).toList();
});

/// Page « Examens blancs » Civique GLOBAUX (`/civique/examens-blancs`).
/// Pendant de `TcfFullExamsScreen` côté Civique : 20 slots de 40 Q tous
/// thèmes, 45 min, seuil 32/40. Slot 1 = examen découverte gratuit,
/// slots 2-20 = premium. Accent bleu (convention Civique = bleu).
class CiviqueFullExamsScreen extends ConsumerStatefulWidget {
  const CiviqueFullExamsScreen({super.key});

  @override
  ConsumerState<CiviqueFullExamsScreen> createState() =>
      _CiviqueFullExamsScreenState();
}

class _CiviqueFullExamsScreenState
    extends ConsumerState<CiviqueFullExamsScreen> {
  int _filter = 0;
  bool _showAll = false;
  bool _starting = false;

  bool _isPremium() {
    final auth = ref.read(authControllerProvider);
    return auth is AuthAuthenticated &&
        auth.user.canAccessModule(AppModule.civique);
  }

  bool _isLocked(int slot) => !_isPremium() && slot > 1;

  Future<void> _startExam() async {
    if (_starting) return;
    if (!_isPremium()) {
      final history =
          ref.read(_civiqueGlobalExamsProvider).valueOrNull ?? const [];
      if (history.any((a) => a.isFinished)) {
        showPaywallSheet(context);
        return;
      }
    }
    setState(() => _starting = true);
    ref.read(selectedModuleProvider.notifier).state = AppModule.civique;
    try {
      final attempt = await ref.read(attemptsRepositoryProvider).start(
            StartAttemptRequest(
              type: AttemptType.mockExam,
              module: AppModule.civique,
            ),
          );
      if (!mounted) return;
      ref.invalidate(_civiqueGlobalExamsProvider);
      context.push(AppRoutes.runner.replaceFirst(':attemptId', attempt.id));
    } catch (e) {
      if (!mounted) return;
      final apiErr = ApiClient.toApiException(e);
      if (apiErr.isForbidden) {
        showPaywallSheet(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(apiErr.message), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _openBriefing() {
    if (_starting) return;
    if (!_isPremium()) {
      final history =
          ref.read(_civiqueGlobalExamsProvider).valueOrNull ?? const [];
      if (history.any((a) => a.isFinished)) {
        showPaywallSheet(context);
        return;
      }
    }
    showCiviqueExamBriefingSheet(context, onStart: _startExam);
  }

  /// Pousse le rapport Q-par-Q (`ExamReportScreen`) — même destination
  /// que « Voir le détail » des autres pages d'examens.
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
          _openBriefing();
        },
      ),
    );
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.civique);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_civiqueGlobalExamsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ModuleScreenHeader(
              title: 'Examens blancs',
              subtitle: 'Civique · 40 Q tous thèmes',
              onBack: _back,
              trailing: const FlagBadge(),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.blue)),
                error: (e, _) => ExamsErrorView(
                  message: ApiClient.toApiException(e).message,
                  onRetry: () => ref.invalidate(_civiqueGlobalExamsProvider),
                  accent: AppColors.blue,
                ),
                data: _buildContent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<AttemptSummary> history) {
    // Plus ancien examen en slot 1 — même règle que TCF QCM/Full et Civique
    // thème (l'historique backend descend par date desc, on retourne ASC).
    final finished =
        history.where((a) => a.isFinished).toList().reversed.toList();
    final nextSlot = finished.length + 1;

    final filtered = <int>[
      for (int i = 0; i < _examSlotsCount; i++)
        if (_passesFilter(slotIndex: i, finished: finished)) i,
    ];
    final visible =
        _showAll ? filtered : filtered.take(_visibleByDefault).toList();
    final hiddenCount = filtered.length - visible.length;

    final doneCount = finished.length;
    final scores = finished
        .where((a) => a.score != null && a.totalQuestions > 0)
        .toList();
    final bestScore = scores.isEmpty
        ? null
        : scores.map((a) => a.score!).reduce((a, b) => a > b ? a : b);
    final maxPossible =
        scores.isEmpty ? _examTotalQuestions : scores.first.totalQuestions;
    final avgScore = scores.isEmpty
        ? null
        : (scores.map((a) => a.score!).reduce((a, b) => a + b) / scores.length)
            .round();

    final todoCount =
        _examSlotsCount - finished.length - _lockedTodoCount(finished.length);

    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: () async {
        ref.invalidate(_civiqueGlobalExamsProvider);
        await ref.read(_civiqueGlobalExamsProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        children: [
          CiviqueFullExamsStatsRow(
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
              'Terminés · $doneCount',
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
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.blue,
                  ),
                ),
                label: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: AppColors.blue),
              ),
            ),
        ],
      ),
    );
  }

  bool _passesFilter({
    required int slotIndex,
    required List<AttemptSummary> finished,
  }) {
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
    var locked = 0;
    for (int i = doneCount; i < _examSlotsCount; i++) {
      if (_isLocked(i + 1)) locked++;
    }
    return locked;
  }

  Widget _buildSlot(
    int slotIndex,
    List<AttemptSummary> finished,
    int nextSlot,
  ) {
    final number = slotIndex + 1;
    final attempt = slotIndex < finished.length ? finished[slotIndex] : null;
    final isLocked = _isLocked(number);
    final isNext = number == nextSlot && number <= _examSlotsCount;
    final action = attempt != null
        ? () => _showExamSheet(attempt, number)
        : _onEmptyTap(number);
    return CiviqueFullExamSlotBuilder(
      number: number,
      attempt: attempt,
      isLocked: isLocked,
      isNext: isNext,
      examTotalQuestions: _examTotalQuestions,
      onTap: action,
      onAction: action,
    ).build();
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

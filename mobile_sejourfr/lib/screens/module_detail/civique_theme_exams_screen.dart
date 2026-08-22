import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics.dart';
import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/attempt_summary.dart';
import '../../core/models/enums.dart';
import '../../core/models/question_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/utils/start_failure.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../tcf_production/widgets/exam_filter_chips.dart';
import '../tcf_production/widgets/exam_progress_card.dart';
import '../tcf_production/widgets/exams_error_view.dart';
import '../tcf_production/widgets/flag_badge.dart';
import '../tcf_production/widgets/module_screen_header.dart';
import 'civique_exam_briefing_sheet.dart';
import 'civique_hub_data.dart';
import 'widgets/exam_done_sheet.dart';
import 'widgets/civique_exams/civique_exam_slot_builder.dart';
import 'widgets/civique_exams/civique_exams_stats_row.dart';

const int _examSlotsCount = 10;
const int _visibleByDefault = 7;
const int _examTotalQuestions = 20;

/// Page « Examens blancs » d'un thème Civique (`/civique/theme/:themeId/examens`).
/// Pendant de `TcfQcmExamsScreen` — header + drapeau + 3 stats + progress +
/// chips filtre + 10 slots numérotés. Slot 1 = examen de découverte gratuit,
/// slots 2-10 = premium.
class CiviqueThemeExamsScreen extends ConsumerStatefulWidget {
  const CiviqueThemeExamsScreen({super.key, required this.themeId});

  final String themeId;

  @override
  ConsumerState<CiviqueThemeExamsScreen> createState() =>
      _CiviqueThemeExamsScreenState();
}

class _CiviqueThemeExamsScreenState
    extends ConsumerState<CiviqueThemeExamsScreen> {
  int _filter = 0;
  bool _showAll = false;
  bool _starting = false;

  bool _isPremium() {
    final auth = ref.read(authControllerProvider);
    return auth is AuthAuthenticated &&
        auth.user.canAccessModule(AppModule.civique);
  }

  bool _isLocked(int slot) => !_isPremium() && slot > 1;

  Future<void> _startExam(ThemeDto theme, {required int slotNumber}) async {
    if (_starting) return;
    if (!_isPremium()) {
      final history =
          ref.read(civiqueThemeExamsHistoryProvider(theme.id)).valueOrNull ??
              const [];
      if (history.any((a) => a.isFinished)) {
        showPaywallSheet(
          context,
          ref: ref,
          ctaLocation: AnalyticsCtaLocation.mockExam,
        );
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
              themeId: theme.id,
              slotNumber: slotNumber,
            ),
          );
      if (!mounted) return;
      ref.invalidate(civiqueThemeExamsHistoryProvider(theme.id));
      context.push(AppRoutes.runner.replaceFirst(':attemptId', attempt.id));
    } catch (e) {
      if (!mounted) return;
      showPaywallOrError(context, e);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _openBriefing(ThemeDto theme, {required int slotNumber}) {
    if (_starting) return;
    if (!_isPremium()) {
      final history =
          ref.read(civiqueThemeExamsHistoryProvider(theme.id)).valueOrNull ??
              const [];
      if (history.any((a) => a.isFinished)) {
        showPaywallSheet(
          context,
          ref: ref,
          ctaLocation: AnalyticsCtaLocation.mockExam,
        );
        return;
      }
    }
    showCiviqueThemeExamBriefingSheet(
      context,
      themeName: theme.name,
      onStart: () => _startExam(theme, slotNumber: slotNumber),
    );
  }

  /// Pousse le rapport Q-par-Q (`ExamReportScreen`) — même destination
  /// que « Voir le détail » des lots.
  void _openExamReport(AttemptSummary attempt) {
    context.push(AppRoutes.examReport.replaceFirst(':attemptId', attempt.id));
  }

  void _showExamSheet(AttemptSummary attempt, ThemeDto theme, int slot) {
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
          _openBriefing(theme, slotNumber: slot);
        },
      ),
    );
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(
        AppRoutes.civiqueThemeDetail.replaceFirst(':themeId', widget.themeId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themesAsync = ref.watch(civiqueThemesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: themesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.blue),
          ),
          error: (e, _) => ExamsErrorView(
            message: ApiClient.toApiException(e).message,
            onRetry: () => ref.invalidate(civiqueThemesProvider),
            accent: AppColors.blue,
          ),
          data: (themes) {
            final theme =
                themes.where((t) => t.id == widget.themeId).firstOrNull;
            if (theme == null) {
              return ExamsErrorView(
                message: 'Thème introuvable.',
                onRetry: () => ref.invalidate(civiqueThemesProvider),
                accent: AppColors.blue,
              );
            }
            return _buildScaffold(theme);
          },
        ),
      ),
    );
  }

  Widget _buildScaffold(ThemeDto theme) {
    final async = ref.watch(civiqueThemeExamsHistoryProvider(theme.id));
    return Column(
      children: [
        ModuleScreenHeader(
          title: 'Examens blancs',
          subtitle: '${theme.name} · Civique',
          onBack: _back,
          trailing: const FlagBadge(),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.blue)),
            error: (e, _) => ExamsErrorView(
              message: ApiClient.toApiException(e).message,
              onRetry: () => ref
                  .invalidate(civiqueThemeExamsHistoryProvider(theme.id)),
              accent: AppColors.blue,
            ),
            data: (history) => _buildContent(theme, history),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeDto theme, List<AttemptSummary> history) {
    // Group by slot_number : dernier essai par slot (cf. V110 + commentaire
    // sur `civique_full_exams_screen.dart::_buildContent`).
    final bySlot = <int, AttemptSummary>{};
    for (final a in history) {
      if (!a.isFinished || a.slotNumber == null) continue;
      bySlot.putIfAbsent(a.slotNumber!, () => a);
    }
    final nextSlot = _firstFreeSlot(bySlot);

    final filtered = <int>[
      for (int i = 0; i < _examSlotsCount; i++)
        if (_passesFilterBySlot(slotIndex: i, bySlot: bySlot)) i,
    ];
    final visible =
        _showAll ? filtered : filtered.take(_visibleByDefault).toList();
    final hiddenCount = filtered.length - visible.length;

    final doneCount = bySlot.length;
    final scores = bySlot.values
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
        _examSlotsCount - bySlot.length - _lockedTodoCountBySlot(bySlot);

    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: () async {
        ref.invalidate(civiqueThemeExamsHistoryProvider(theme.id));
        await ref.read(civiqueThemeExamsHistoryProvider(theme.id).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        children: [
          CiviqueExamsStatsRow(
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
            _buildSlot(i, bySlot, nextSlot, theme),
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
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.blue,
                  ),
                ),
                label: const Icon(LucideIcons.chevronDown,
                    size: 18, color: AppColors.blue),
              ),
            ),
        ],
      ),
    );
  }

  bool _passesFilterBySlot({
    required int slotIndex,
    required Map<int, AttemptSummary> bySlot,
  }) {
    final slotNumber = slotIndex + 1;
    final isDone = bySlot.containsKey(slotNumber);
    final isLocked = _isLocked(slotNumber);
    return switch (_filter) {
      1 => !isDone && !isLocked,
      2 => isDone,
      _ => true,
    };
  }

  int _firstFreeSlot(Map<int, AttemptSummary> bySlot) {
    for (int i = 1; i <= _examSlotsCount; i++) {
      if (!bySlot.containsKey(i)) return i;
    }
    return _examSlotsCount + 1;
  }

  int _lockedTodoCountBySlot(Map<int, AttemptSummary> bySlot) {
    if (_isPremium()) return 0;
    var locked = 0;
    for (int i = 1; i <= _examSlotsCount; i++) {
      if (!bySlot.containsKey(i) && _isLocked(i)) locked++;
    }
    return locked;
  }

  Widget _buildSlot(
    int slotIndex,
    Map<int, AttemptSummary> bySlot,
    int nextSlot,
    ThemeDto theme,
  ) {
    final number = slotIndex + 1;
    final attempt = bySlot[number];
    final isLocked = _isLocked(number);
    final isNext = number == nextSlot && number <= _examSlotsCount;
    final action = attempt != null
        ? () => _showExamSheet(attempt, theme, number)
        : _onEmptyTap(number, theme);
    return CiviqueExamSlotBuilder(
      number: number,
      attempt: attempt,
      isLocked: isLocked,
      isNext: isNext,
      examTotalQuestions: _examTotalQuestions,
      onTap: action,
      onAction: action,
    ).build();
  }

  VoidCallback _onEmptyTap(int slotNumber, ThemeDto theme) {
    return () {
      if (_isLocked(slotNumber)) {
        showPaywallSheet(
          context,
          ref: ref,
          ctaLocation: AnalyticsCtaLocation.mockExam,
        );
      } else {
        _openBriefing(theme, slotNumber: slotNumber);
      }
    };
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
import '../../core/widgets/stat_value_card.dart';
import '../tcf_production/widgets/exam_info_chips.dart';
import '../tcf_production/widgets/exam_slot/full_exam_slot_card.dart';
import '../module_detail/civique_exam_briefing_sheet.dart';
import '../module_detail/widgets/exam_done_sheet.dart';
import '../tcf_production/widgets/exams_error_view.dart';
import '../tcf_production/widgets/flag_badge.dart';
import '../tcf_production/widgets/module_screen_header.dart';

const int _examSlotsCount = 20;
const int _visibleByDefault = 7;
const int _examTotalQuestions = 40;

/// Historique des examens blancs civique GLOBAUX (40 Q tous thèmes). On
/// charge tous les `MOCK_EXAM module=CIVIQUE` puis on filtre côté client
/// pour ne garder QUE les globaux (`!isThemeScoped`, c.-à-d. `lotThemeId`
/// null). Le backend ne sait pas filtrer « globaux uniquement » en un
/// paramètre — l'inverse `themeId=` filtre par thème, ici on veut le
/// complément.
final civiqueGlobalExamsProvider =
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
/// `CiviqueFullExamsView` (le corps) est réutilisé par l'onglet Examens du
/// shell, comme `TcfFullExamsView` côté TCF.
class CiviqueFullExamsScreen extends StatelessWidget {
  const CiviqueFullExamsScreen({super.key});

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.reviser);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ModuleScreenHeader(
              title: 'Examens blancs',
              subtitle: 'Civique · 40 Q tous thèmes',
              onBack: () => _back(context),
              trailing: const FlagBadge(),
            ),
            const Expanded(child: CiviqueFullExamsView()),
          ],
        ),
      ),
    );
  }
}

/// Corps réutilisable de la page (stats + filtre + 20 slots). Embarqué tel
/// quel par l'onglet Examens du shell.
class CiviqueFullExamsView extends ConsumerStatefulWidget {
  const CiviqueFullExamsView({super.key});

  @override
  ConsumerState<CiviqueFullExamsView> createState() =>
      _CiviqueFullExamsViewState();
}

class _CiviqueFullExamsViewState extends ConsumerState<CiviqueFullExamsView> {
  bool _showAll = false;
  bool _starting = false;

  bool _isPremium() {
    final auth = ref.read(authControllerProvider);
    return auth is AuthAuthenticated &&
        auth.user.canAccessModule(AppModule.civique);
  }

  bool _isLocked(int slot) => !_isPremium() && slot > 1;

  Future<void> _startExam({required int slotNumber}) async {
    if (_starting) return;
    if (!_isPremium()) {
      final history =
          ref.read(civiqueGlobalExamsProvider).valueOrNull ?? const [];
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
              slotNumber: slotNumber,
            ),
          );
      if (!mounted) return;
      ref.invalidate(civiqueGlobalExamsProvider);
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

  void _openBriefing({required int slotNumber}) {
    if (_starting) return;
    if (!_isPremium()) {
      final history =
          ref.read(civiqueGlobalExamsProvider).valueOrNull ?? const [];
      if (history.any((a) => a.isFinished)) {
        showPaywallSheet(context);
        return;
      }
    }
    showCiviqueExamBriefingSheet(
      context,
      onStart: () => _startExam(slotNumber: slotNumber),
    );
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
          _openBriefing(slotNumber: slot);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(civiqueGlobalExamsProvider);

    return async.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.blue)),
      error: (e, _) => ExamsErrorView(
        message: ApiClient.toApiException(e).message,
        onRetry: () => ref.invalidate(civiqueGlobalExamsProvider),
        accent: AppColors.blue,
      ),
      data: _buildContent,
    );
  }

  Widget _buildContent(List<AttemptSummary> history) {
    // Group by slot_number : on garde le DERNIER essai par slot (refait l'examen
    // N → nouvel attempt avec slot_number=N qui écrase l'ancien dans la grille).
    // Backend renvoie chrono DESC → le premier rencontré par slot est le bon.
    // Cf. V110 + bug « slot 2 prenait la note d'un refait de l'examen 1 ».
    final bySlot = <int, AttemptSummary>{};
    for (final a in history) {
      if (!a.isFinished || a.slotNumber == null) continue;
      bySlot.putIfAbsent(a.slotNumber!, () => a);
    }

    final scores = bySlot.values
        .where((a) => a.score != null && a.totalQuestions > 0)
        .toList();
    final bestScore = scores.isEmpty
        ? null
        : scores.map((a) => a.score!).reduce((a, b) => a > b ? a : b);
    final maxPossible =
        scores.isEmpty ? _examTotalQuestions : scores.first.totalQuestions;
    // Historique trié chrono DESC → le premier fini = dernier examen passé.
    final lastScore = history
        .where((a) => a.isFinished && a.score != null && a.totalQuestions > 0)
        .map((a) => a.score!)
        .firstOrNull;
    final progressPercent =
        (bySlot.length / _examSlotsCount * 100).round();

    final visibleCount = _showAll ? _examSlotsCount : _visibleByDefault;
    final hiddenCount = _examSlotsCount - visibleCount;

    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: () async {
        ref.invalidate(civiqueGlobalExamsProvider);
        await ref.read(civiqueGlobalExamsProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: StatValueCard(
                  value: bestScore == null ? '—' : '$bestScore/$maxPossible',
                  label: 'Meilleur score',
                  color: AppColors.blue,
                  valueSize: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatValueCard(
                  value: lastScore == null ? '—' : '$lastScore/$maxPossible',
                  label: 'Dernier examen',
                  valueSize: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatValueCard(
                  value: '$progressPercent %',
                  label: 'Progression',
                  color: AppColors.blue,
                  valueSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const ExamInfoChips(
            accent: AppColors.blue,
            soft: AppColors.blueLight,
            items: [
              (icon: LucideIcons.zap, label: 'Simulation réelle'),
              (icon: LucideIcons.clock, label: '45 minutes'),
              (icon: LucideIcons.target, label: 'Seuil de réussite : 32/40'),
              (icon: LucideIcons.fileText, label: '40 questions'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('Tes examens', style: AppFonts.display(size: 17)),
              const Spacer(),
              Text(
                '$_examSlotsCount disponibles',
                style: AppFonts.ui(size: 12, color: AppColors.inkFaint),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < visibleCount; i++) ...[
            _buildSlot(i + 1, bySlot),
            if (i != visibleCount - 1) const SizedBox(height: 10),
          ],
          if (hiddenCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextButton.icon(
                onPressed: () => setState(() => _showAll = true),
                icon: Text(
                  'Voir les examens ${visibleCount + 1} à $_examSlotsCount',
                  style: AppFonts.ui(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.blue,
                  ),
                ),
                label: const Icon(LucideIcons.chevronDown,
                    size: 16, color: AppColors.blue),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlot(int number, Map<int, AttemptSummary> bySlot) {
    final attempt = bySlot[number];
    final done = attempt != null;
    final lockedEmpty = _isLocked(number) && !done;

    final String subtitle;
    if (done) {
      subtitle = attempt.score != null && attempt.totalQuestions > 0
          ? 'Dernier score : ${attempt.score}/${attempt.totalQuestions}'
          : 'Terminé';
    } else if (lockedEmpty) {
      subtitle = 'Réservé à l\'abonnement';
    } else if (number == 1) {
      subtitle = 'Offert · 40 questions, 45 min';
    } else {
      subtitle = 'Pas encore fait';
    }

    return FullExamSlotCard(
      slot: number,
      filled: done,
      accent: AppColors.blue,
      title: 'Épreuve $number',
      subtitle: subtitle,
      subtitleColor: done ? AppColors.blue : AppColors.inkFaint,
      lockedEmpty: lockedEmpty,
      trailing: done
          ? FullExamSlotCard.faitPill(AppColors.blue, bg: AppColors.blueLight)
          : Icon(
              lockedEmpty ? LucideIcons.lock : LucideIcons.chevronRight,
              size: 18,
              color: AppColors.inkFaint,
            ),
      onTap:
          done ? () => _showExamSheet(attempt, number) : _onEmptyTap(number),
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

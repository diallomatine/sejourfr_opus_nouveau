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
import '../../core/widgets/app_button.dart';
import '../../core/widgets/paywall_sheet.dart';
import 'tcf_module_exam_briefing_screen.dart';
import 'tcf_qcm_detail_screen.dart' show TcfQcmModule;

const int _examSlotsCount = 10;
const int _visibleByDefault = 7;

/// Provider d'historique des examens module QCM — réutilisé par la page et
/// par le hub (TcfQcmDetailScreen) via import croisé.
final qcmExamsHistoryProvider =
    FutureProvider.autoDispose.family<List<AttemptSummary>, QuestionType>((ref, qt) {
  return ref.watch(attemptsRepositoryProvider).listMine(
        type: AttemptType.mockExam,
        module: AppModule.tcf,
        moduleExamQuestionType: qt,
        limit: 20,
      );
});

/// Page « Examens blancs » des modules TCF QCM (CO, CE, Structure).
/// Calquée sur `ProductionExamsScreen` (EE/EO) :
///   - Header avec drapeau France
///   - 3 stats : Terminés, Score moyen, Meilleur score
///   - Barre de progression
///   - Chips de filtre Tous / À faire / Terminés
///   - 10 slots numérotés avec pill « 25 questions · X min »
///
/// Slot 1 = examen de découverte gratuit, slots 2-10 = premium.
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
    return auth is AuthAuthenticated && auth.user.canAccessModule(AppModule.tcf);
  }

  bool _isLocked(int slot) => !_isPremium() && slot > 1;

  void _openBriefing() {
    if (!_isPremium()) {
      final history =
          ref.read(qcmExamsHistoryProvider(widget.module.questionType)).valueOrNull ?? const [];
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
      builder: (sheetCtx) => _ExamActionSheet(
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
            _Header(module: widget.module, onBack: _back),
            Expanded(
              child: async.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.blue)),
                error: (e, _) => _ErrorBox(
                  message: ApiClient.toApiException(e).message,
                  onRetry: () =>
                      ref.invalidate(qcmExamsHistoryProvider(widget.module.questionType)),
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
    // Plus ancien examen en slot 1
    final finished = history.where((a) => a.isFinished).toList().reversed.toList();
    final nextSlot = finished.length + 1;

    final allSlots = <_SlotInfo>[
      for (int i = 0; i < _examSlotsCount; i++)
        _SlotInfo(
          number: i + 1,
          attempt: i < finished.length ? finished[i] : null,
          isNext: i + 1 == nextSlot && i + 1 <= _examSlotsCount,
          isLocked: _isLocked(i + 1),
        ),
    ];

    final filtered = allSlots
        .where((s) => switch (_filter) {
              1 => s.attempt == null && !s.isLocked,
              2 => s.attempt != null,
              _ => true,
            })
        .toList();

    final visible = _showAll ? filtered : filtered.take(_visibleByDefault).toList();
    final hiddenCount = filtered.length - visible.length;

    final doneCount = finished.length;
    final scores = finished
        .where((a) => a.weightedScore != null && a.maxWeightedScore != null)
        .toList();
    final bestScore = scores.isEmpty
        ? null
        : scores.map((a) => a.weightedScore!).reduce((a, b) => a > b ? a : b);
    final maxPossible = scores.isEmpty ? 50 : (scores.first.maxWeightedScore ?? 50);
    final avgScore = scores.isEmpty
        ? null
        : (scores.map((a) => a.weightedScore!).reduce((a, b) => a + b) / scores.length)
            .round();

    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: () async {
        ref.invalidate(qcmExamsHistoryProvider(widget.module.questionType));
        await ref.read(qcmExamsHistoryProvider(widget.module.questionType).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        children: [
          _StatsRow(
              doneCount: doneCount,
              bestScore: bestScore,
              avgScore: avgScore,
              maxPossible: maxPossible),
          const SizedBox(height: 12),
          _ProgressCard(doneCount: doneCount, total: _examSlotsCount),
          const SizedBox(height: 12),
          _FilterChips(
            active: _filter,
            counts: [
              _examSlotsCount,
              allSlots.where((s) => s.attempt == null && !s.isLocked).length,
              allSlots.where((s) => s.attempt != null).length,
            ],
            onChanged: (i) => setState(() {
              _filter = i;
              _showAll = false;
            }),
          ),
          const SizedBox(height: 12),
          for (final slot in visible) ...[
            _ExamSlotCard(
              slot: slot,
              module: widget.module,
              onTapDone: _showExamSheet,
              onTapEmpty: () {
                if (_isLocked(slot.number)) {
                  showPaywallSheet(context);
                } else {
                  _openBriefing();
                }
              },
            ),
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
}

// ============================================================================
// Header avec drapeau France
// ============================================================================

class _Header extends StatelessWidget {
  const _Header({required this.module, required this.onBack});

  final TcfQcmModule module;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
      color: AppColors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Examens blancs',
                      style: AppFonts.jakarta(
                          size: 17, weight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(width: 8),
                    const _FlagBadge(),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  '${module.title} · TCF IRN',
                  style: AppFonts.jakarta(size: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagBadge extends StatelessWidget {
  const _FlagBadge();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: const SizedBox(
        height: 12,
        width: 18,
        child: Row(
          children: [
            Expanded(child: ColoredBox(color: Color(0xFF0055A4))),
            Expanded(child: ColoredBox(color: Colors.white)),
            Expanded(child: ColoredBox(color: Color(0xFFEF4135))),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Stats (3 cartes) — Terminés / Score moyen / Meilleur score
// ============================================================================

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.doneCount,
    required this.bestScore,
    required this.avgScore,
    required this.maxPossible,
  });

  final int doneCount;
  final int? bestScore;
  final int? avgScore;
  final int maxPossible;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.checklist_rounded,
            iconColor: AppColors.blue,
            value: '$doneCount',
            suffix: '/$_examSlotsCount',
            valueColor: AppColors.ink,
            label: 'Terminés',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.adjust_rounded,
            iconColor: AppColors.green,
            value: avgScore == null ? '—' : '$avgScore',
            suffix: avgScore == null ? '' : '/$maxPossible',
            valueColor: AppColors.green,
            label: 'Score moyen',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.amber,
            value: bestScore == null ? '—' : '$bestScore',
            suffix: bestScore == null ? '' : '/$maxPossible',
            valueColor: AppColors.ink,
            label: 'Meilleur score',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.suffix,
    required this.valueColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String suffix;
  final Color valueColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(children: [
                TextSpan(
                  text: value,
                  style: AppFonts.jakarta(
                      size: 18, weight: FontWeight.w700, color: valueColor),
                ),
                if (suffix.isNotEmpty)
                  TextSpan(
                    text: suffix,
                    style: AppFonts.jakarta(
                        size: 12, weight: FontWeight.w500, color: AppColors.muted2),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: AppFonts.jakarta(size: 10.5, color: AppColors.muted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ============================================================================
// Barre de progression
// ============================================================================

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.doneCount, required this.total});

  final int doneCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : doneCount / total;
    final percent = (ratio * 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Progression du parcours',
                style: AppFonts.jakarta(
                    size: 12, weight: FontWeight.w700, color: AppColors.blueDark),
              ),
              const Spacer(),
              Text(
                '$percent %',
                style: AppFonts.jakarta(
                    size: 11, weight: FontWeight.w700, color: AppColors.blue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.blue.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.blue),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Filter chips
// ============================================================================

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.active,
    required this.counts,
    required this.onChanged,
  });

  final int active;
  final List<int> counts;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = [
      'Tous · ${counts[0]}',
      'À faire · ${counts[1]}',
      'Terminés · ${counts[2]}',
    ];
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final on = active == i;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? AppColors.blue : AppColors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: on ? AppColors.blue : AppColors.line),
              ),
              child: Text(
                labels[i],
                style: AppFonts.jakarta(
                    size: 12,
                    weight: FontWeight.w700,
                    color: on ? AppColors.white : AppColors.muted),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// Slot card
// ============================================================================

class _SlotInfo {
  const _SlotInfo({
    required this.number,
    required this.attempt,
    required this.isNext,
    required this.isLocked,
  });

  final int number;
  final AttemptSummary? attempt;
  final bool isNext;
  final bool isLocked;
}

class _ExamSlotCard extends StatelessWidget {
  const _ExamSlotCard({
    required this.slot,
    required this.module,
    required this.onTapDone,
    required this.onTapEmpty,
  });

  final _SlotInfo slot;
  final TcfQcmModule module;
  final ValueChanged<AttemptSummary> onTapDone;
  final VoidCallback onTapEmpty;

  @override
  Widget build(BuildContext context) {
    final done = slot.attempt != null;
    final locked = slot.isLocked;
    final next = slot.isNext && !done && !locked;

    final score = slot.attempt?.weightedScore;
    final maxScore = slot.attempt?.maxWeightedScore ?? 50;

    return Opacity(
      opacity: locked ? 0.55 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: next ? AppColors.blue : AppColors.line,
            width: next ? 1.2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: done ? () => onTapDone(slot.attempt!) : onTapEmpty,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              child: Row(
                children: [
                  _NumberBadge(number: slot.number, locked: locked, next: next),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Examen blanc n°${slot.number}',
                          style: AppFonts.jakarta(
                              size: 14, weight: FontWeight.w700, color: AppColors.ink),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _Pill(
                              label: module.examSubtitle,
                              bg: AppColors.blueLight,
                              fg: AppColors.blueDark,
                            ),
                            if (done && score != null)
                              Row(
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
                                        color: AppColors.green),
                                  ),
                                ],
                              )
                            else if (!done && next)
                              Text(
                                'À FAIRE ENSUITE',
                                style: AppFonts.mono(
                                    size: 9,
                                    color: AppColors.blue,
                                    letterSpacing: 1.2,
                                    weight: FontWeight.w700),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SlotAction(
                    done: done,
                    next: next,
                    locked: locked,
                    onPressed: done ? () => onTapDone(slot.attempt!) : onTapEmpty,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({
    required this.number,
    required this.locked,
    required this.next,
  });

  final int number;
  final bool locked;
  final bool next;

  @override
  Widget build(BuildContext context) {
    final bg = locked
        ? AppColors.line2
        : next
            ? AppColors.blue
            : AppColors.blueLight;
    final fg = locked
        ? AppColors.muted2
        : next
            ? AppColors.white
            : AppColors.blue;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: locked
          ? Icon(Icons.lock_outline_rounded, size: 18, color: fg)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'N°',
                  style: AppFonts.jakarta(
                    size: 9,
                    color: fg.withValues(alpha: 0.75),
                    height: 1,
                  ),
                ),
                Text(
                  number.toString().padLeft(2, '0'),
                  style: AppFonts.jakarta(
                    size: 18,
                    weight: FontWeight.w800,
                    color: fg,
                    height: 1.1,
                  ),
                ),
              ],
            ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: AppFonts.jakarta(size: 10, weight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _SlotAction extends StatelessWidget {
  const _SlotAction({
    required this.done,
    required this.next,
    required this.locked,
    required this.onPressed,
  });

  final bool done;
  final bool next;
  final bool locked;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_outlined, size: 14, color: AppColors.muted2),
          const SizedBox(width: 4),
          Text(
            'Premium',
            style: AppFonts.jakarta(size: 11, weight: FontWeight.w700, color: AppColors.muted2),
          ),
        ],
      );
    }
    if (done) {
      return _ActionButton(
        label: 'Refaire',
        onPressed: onPressed,
        filled: false,
        color: AppColors.line,
        textColor: AppColors.muted,
      );
    }
    if (next) {
      return _ActionButton(
        label: 'Démarrer',
        onPressed: onPressed,
        filled: true,
        color: AppColors.blue,
        textColor: AppColors.white,
      );
    }
    return _ActionButton(
      label: 'Démarrer',
      onPressed: onPressed,
      filled: false,
      color: AppColors.blue,
      textColor: AppColors.blue,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.filled,
    required this.color,
    required this.textColor,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: filled ? null : Border.all(color: color, width: 1),
          ),
          child: Text(
            label,
            style: AppFonts.jakarta(size: 12, weight: FontWeight.w700, color: textColor),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Sheet action après tap sur un slot terminé
// ============================================================================

class _ExamActionSheet extends StatelessWidget {
  const _ExamActionSheet({
    required this.attempt,
    required this.onViewDetails,
    required this.onRetake,
  });

  final AttemptSummary attempt;
  final VoidCallback onViewDetails;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Examen passé',
                style: AppFonts.fraunces(size: 22, weight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Score : ${attempt.weightedScore ?? 0}/${attempt.maxWeightedScore ?? 50} · ${attempt.score ?? 0}/${attempt.totalQuestions} bonnes réponses',
                textAlign: TextAlign.center,
                style: AppFonts.jakarta(size: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Voir les détails',
                icon: Icons.visibility_outlined,
                onPressed: onViewDetails,
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Reprendre (questions différentes)',
                icon: Icons.refresh_rounded,
                variant: AppButtonVariant.ghost,
                onPressed: onRetake,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Erreur réseau
// ============================================================================

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 32, color: AppColors.red),
          const SizedBox(height: 8),
          Text(
            'Impossible de charger les examens',
            style: AppFonts.jakarta(size: 14, weight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.jakarta(size: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.blue),
            label: Text(
              'Réessayer',
              style: AppFonts.jakarta(size: 13, weight: FontWeight.w700, color: AppColors.blue),
            ),
          ),
        ],
      ),
    );
  }
}

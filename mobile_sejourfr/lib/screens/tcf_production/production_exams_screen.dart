import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../module_detail/production_exam_briefing_sheet.dart';
import 'ee_session_controller.dart';
import 'eo_session_controller.dart';
import 'expression_hub_data.dart';
import 'tcf_production_module.dart';

/// Nombre de slots d'examens blancs proposés pour une épreuve EE/EO.
const int _examSlotsCount = 10;

/// Nombre de slots ouverts en mode gratuit ; au-delà → paywall TCF.
const int _freeSlots = 2;

/// Nombre de slots affichés par défaut (les autres sont masqués derrière
/// « Voir les examens X à Y »).
const int _visibleByDefault = 7;

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

  /// 0 = Tous, 1 = À faire, 2 = Terminés.
  int _filter = 0;
  bool _showAll = false;

  bool _isPremium() {
    final auth = ref.read(authControllerProvider);
    return auth is AuthAuthenticated &&
        auth.user.canAccessModule(AppModule.tcf);
  }

  void _onSlotTap({required int slot, required ExamSession? exam}) {
    if (exam != null) {
      _openSession(exam);
      return;
    }
    if (_isLocked(slot)) {
      showPaywallSheet(context);
      return;
    }
    _openBriefing();
  }

  void _onSlotAction({required int slot, required ExamSession? exam}) {
    if (_isLocked(slot)) {
      showPaywallSheet(context);
      return;
    }
    _openBriefing();
    // Done ou empty : l'action « Refaire » / « Démarrer » lance toujours un
    // nouveau briefing (paywall déjà géré pour les slots verrouillés).
    if (exam != null) return;
  }

  bool _isLocked(int slot) => !_isPremium() && slot > _freeSlots;

  void _openBriefing() {
    if (!_isPremium()) {
      showPaywallSheet(context);
      return;
    }
    showProductionExamBriefingSheet(
      context,
      module: widget.module,
      starting: _starting,
      onStart: _startFullExam,
    );
  }

  Future<void> _startFullExam() async {
    if (_starting) return;
    final auth = ref.read(authControllerProvider);
    final niveau = auth is AuthAuthenticated
        ? (auth.user.targetProcedure?.tcfLevel ?? 'B1')
        : 'B1';
    setState(() => _starting = true);
    ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
    try {
      if (widget.module.isEo) {
        await ref.read(eoSessionProvider.notifier).start(niveau: niveau);
        if (!mounted) return;
        context.push('/tcf/expression-orale/t/0');
      } else {
        await ref.read(eeSessionProvider.notifier).start(niveau: niveau);
        if (!mounted) return;
        context.push('/tcf/expression-ecrite/t/0');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(ApiClient.toApiException(e).message),
            backgroundColor: AppColors.red),
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
            _Header(module: widget.module, onBack: _back),
            Expanded(
              child: async.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.red)),
                error: (e, _) => _ErrorBox(
                  message: ApiClient.toApiException(e).message,
                  onRetry: () => ref
                      .invalidate(expressionHubProvider(widget.module.epreuve)),
                ),
                data: (data) => _buildContent(data.exams),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<ExamSession> exams) {
    // Plus ancien en slot 1.
    final ordered = exams.reversed.toList();
    // Index du prochain slot à faire = nb d'examens passés + 1 (1-based).
    final nextSlot = ordered.length + 1;

    // Slots de 1..10 ; chacun a un exam s'il existe.
    final allSlots = <_SlotInfo>[
      for (int i = 0; i < _examSlotsCount; i++)
        _SlotInfo(
          number: i + 1,
          exam: i < ordered.length ? ordered[i] : null,
          difficulty: _difficultyFor(i + 1),
          isNext: i + 1 == nextSlot && i + 1 <= _examSlotsCount,
          isLocked: _isLocked(i + 1),
        ),
    ];

    final filtered = allSlots
        .where((s) => switch (_filter) {
              1 => s.exam == null && !s.isLocked,
              2 => s.exam != null,
              _ => true,
            })
        .toList();

    final visible =
        _showAll ? filtered : filtered.take(_visibleByDefault).toList();
    final hiddenCount = filtered.length - visible.length;

    final doneCount = exams.length;
    final completed = exams.where((e) => e.isFullyEvaluated).toList();
    final avg = completed.isEmpty
        ? null
        : completed.map((e) => e.avgScore ?? 0).reduce((a, b) => a + b) /
            completed.length;
    final niveauEstime = completed
        .map((e) => e.niveauPlancher)
        .whereType<NiveauCecrl>()
        .fold<NiveauCecrl?>(null, (best, n) {
      if (best == null) return n;
      return n.scaleIndex > best.scaleIndex ? n : best;
    });

    return RefreshIndicator(
      color: AppColors.red,
      onRefresh: () async {
        ref.invalidate(expressionHubProvider(widget.module.epreuve));
        await ref.read(expressionHubProvider(widget.module.epreuve).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        children: [
          _StatsRow(
            doneCount: doneCount,
            avgScore: avg,
            niveau: niveauEstime,
          ),
          const SizedBox(height: 12),
          _ProgressCard(
            doneCount: doneCount,
            total: _examSlotsCount,
          ),
          const SizedBox(height: 12),
          _FilterChips(
            active: _filter,
            counts: [
              _examSlotsCount,
              allSlots.where((s) => s.exam == null && !s.isLocked).length,
              allSlots.where((s) => s.exam != null).length,
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
              onTap: () => _onSlotTap(slot: slot.number, exam: slot.exam),
              onAction: () => _onSlotAction(slot: slot.number, exam: slot.exam),
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

  final TcfProductionModule module;
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
                    Text('Examens blancs',
                        style: AppFonts.jakarta(
                            size: 17,
                            weight: FontWeight.w700,
                            color: AppColors.ink)),
                    const SizedBox(width: 8),
                    const _FlagBadge(),
                  ],
                ),
                const SizedBox(height: 1),
                Text('${module.title} · TCF IRN',
                    style: AppFonts.jakarta(size: 12, color: AppColors.muted)),
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
// Stats row (3 cartes icône + valeur + label)
// ============================================================================

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.doneCount,
    required this.avgScore,
    required this.niveau,
  });

  final int doneCount;
  final double? avgScore;
  final NiveauCecrl? niveau;

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
            value: avgScore == null ? '—' : _formatIntScore(avgScore!),
            suffix: avgScore == null ? '' : '/20',
            valueColor: AppColors.green,
            label: 'Score moyen',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.red,
            value: niveau?.displayName ?? '—',
            suffix: '',
            valueColor: AppColors.ink,
            label: 'Niveau estimé',
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
                        size: 12,
                        weight: FontWeight.w500,
                        color: AppColors.muted2),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppFonts.jakarta(size: 10.5, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Barre de progression du parcours
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
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.blueDark),
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
// Filter chips Tous / À faire / Terminés
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
// Carte d'un slot d'examen blanc
// ============================================================================

/// État visuel d'un slot : palette d'icône / chip de difficulté / boutons.
enum _ExamDifficulty { facile, moyen, difficile }

_ExamDifficulty _difficultyFor(int slot) {
  if (slot <= 3) return _ExamDifficulty.facile;
  if (slot <= 6) return _ExamDifficulty.moyen;
  return _ExamDifficulty.difficile;
}

({String label, Color bg, Color fg}) _difficultyChip(_ExamDifficulty d) {
  return switch (d) {
    _ExamDifficulty.facile => (
        label: 'A2 · Facile',
        bg: AppColors.green.withValues(alpha: 0.14),
        fg: AppColors.green,
      ),
    _ExamDifficulty.moyen => (
        label: 'B1 · Moyen',
        bg: AppColors.line2,
        fg: AppColors.muted,
      ),
    _ExamDifficulty.difficile => (
        label: 'B2 · Difficile',
        bg: AppColors.red.withValues(alpha: 0.10),
        fg: AppColors.red,
      ),
  };
}

({Color bg, Color fg}) _iconColors(_ExamDifficulty d) {
  return switch (d) {
    _ExamDifficulty.facile => (bg: AppColors.blueLight, fg: AppColors.blue),
    _ExamDifficulty.moyen => (bg: AppColors.line2, fg: AppColors.ink2),
    _ExamDifficulty.difficile => (
        bg: AppColors.redLight,
        fg: AppColors.red,
      ),
  };
}

class _SlotInfo {
  const _SlotInfo({
    required this.number,
    required this.exam,
    required this.difficulty,
    required this.isNext,
    required this.isLocked,
  });

  final int number;
  final ExamSession? exam;
  final _ExamDifficulty difficulty;
  final bool isNext;
  final bool isLocked;
}

class _ExamSlotCard extends StatelessWidget {
  const _ExamSlotCard({
    required this.slot,
    required this.onTap,
    required this.onAction,
  });

  final _SlotInfo slot;
  final VoidCallback onTap;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final done = slot.exam != null;
    final locked = slot.isLocked;
    final next = slot.isNext && !done && !locked;
    final iconC = _iconColors(slot.difficulty);
    final chip = _difficultyChip(slot.difficulty);

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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                  child: Row(
                    children: [
                      _NumberBadge(
                        number: slot.number,
                        locked: locked,
                        next: next,
                        baseBg: iconC.bg,
                        baseFg: iconC.fg,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Examen blanc n°${slot.number}',
                                style: AppFonts.jakarta(
                                    size: 14,
                                    weight: FontWeight.w700,
                                    color: AppColors.ink)),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _Pill(
                                  label: chip.label,
                                  bg: chip.bg,
                                  fg: chip.fg,
                                ),
                                if (done)
                                  _DoneResult(exam: slot.exam!)
                                else
                                  Text('3 tâches enchaînées',
                                      style: AppFonts.jakarta(
                                          size: 11, color: AppColors.muted2)),
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
                        onPressed: onAction,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
    required this.baseBg,
    required this.baseFg,
  });

  final int number;
  final bool locked;
  final bool next;
  final Color baseBg;
  final Color baseFg;

  @override
  Widget build(BuildContext context) {
    final bg = locked
        ? AppColors.line2
        : next
            ? AppColors.blue
            : baseBg;
    final fg = locked
        ? AppColors.muted2
        : next
            ? AppColors.white
            : baseFg;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppFonts.jakarta(size: 10, weight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _DoneResult extends StatelessWidget {
  const _DoneResult({required this.exam});

  final ExamSession exam;

  @override
  Widget build(BuildContext context) {
    final niveau = exam.niveauPlancher;
    final score = exam.avgScore;
    final parts = <String>[
      if (niveau != null) niveau.displayName,
      if (score != null) '${_formatScore(score)}/20',
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded,
            size: 13, color: AppColors.green),
        const SizedBox(width: 3),
        Text(
          parts.isEmpty ? 'Terminé' : parts.join(' · '),
          style: AppFonts.jakarta(
              size: 11, weight: FontWeight.w700, color: AppColors.green),
        ),
      ],
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
          const Icon(Icons.workspace_premium_outlined,
              size: 14, color: AppColors.muted2),
          const SizedBox(width: 4),
          Text(
            'Premium',
            style: AppFonts.jakarta(
                size: 11, weight: FontWeight.w700, color: AppColors.muted2),
          ),
        ],
      );
    }
    if (done) {
      return _ActionButton(
        label: 'Refaire',
        onPressed: onPressed,
        filled: false,
        outlineColor: AppColors.line,
        textColor: AppColors.muted,
      );
    }
    if (next) {
      return _ActionButton(
        label: 'Démarrer',
        onPressed: onPressed,
        filled: true,
        outlineColor: AppColors.blue,
        textColor: AppColors.white,
      );
    }
    return _ActionButton(
      label: 'Démarrer',
      onPressed: onPressed,
      filled: false,
      outlineColor: AppColors.blue,
      textColor: AppColors.blue,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.filled,
    required this.outlineColor,
    required this.textColor,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final Color outlineColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.blue : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: filled ? null : Border.all(color: outlineColor, width: 1),
          ),
          child: Text(
            label,
            style: AppFonts.jakarta(
                size: 12, weight: FontWeight.w700, color: textColor),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Erreur
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
          const Icon(Icons.error_outline_rounded,
              size: 32, color: AppColors.red),
          const SizedBox(height: 8),
          Text('Impossible de charger les examens',
              style: AppFonts.jakarta(
                  size: 14, weight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: AppFonts.jakarta(size: 12, color: AppColors.muted)),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.red),
            label: Text('Réessayer',
                style: AppFonts.jakarta(
                    size: 13, weight: FontWeight.w700, color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Helpers
// ============================================================================

String _formatScore(double n) {
  if (n == n.truncateToDouble()) return n.toInt().toString();
  return n.toStringAsFixed(1).replaceAll('.', ',');
}

String _formatIntScore(double n) => n.round().toString();

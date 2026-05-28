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

/// Page « Examens blancs » d'une épreuve EE/EO.
///
/// Header + stats agrégés (faits, meilleure note, niveau, dernière session),
/// puis liste de 10 slots numérotés. Slot vide → briefing puis lancement
/// d'un nouvel examen. Slot fait → petit sheet « Voir le détail » / « Reprendre ».
class ProductionExamsScreen extends ConsumerStatefulWidget {
  const ProductionExamsScreen({super.key, required this.module});

  final TcfProductionModule module;

  @override
  ConsumerState<ProductionExamsScreen> createState() =>
      _ProductionExamsScreenState();
}

class _ProductionExamsScreenState extends ConsumerState<ProductionExamsScreen> {
  bool _starting = false;

  bool _isPremium() {
    final auth = ref.read(authControllerProvider);
    return auth is AuthAuthenticated &&
        auth.user.canAccessModule(AppModule.tcf);
  }

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

  void _openDoneSheet(ExamSession exam) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _ExamDoneSheet(
        exam: exam,
        slot: _slotOf(exam),
        onViewDetail: () {
          Navigator.of(sheetCtx).pop();
          _openSession(exam);
        },
        onResume: () {
          Navigator.of(sheetCtx).pop();
          _openBriefing();
        },
      ),
    );
  }

  /// Slot 1 = plus ancien (`exams` est trié DESC par `lastSubmittedAt`).
  int _slotOf(ExamSession exam) {
    final exams =
        ref.read(expressionHubProvider(widget.module.epreuve)).valueOrNull?.exams
            ?? const <ExamSession>[];
    final ordered = exams.reversed.toList();
    return ordered.indexWhere((e) => e.attemptId == exam.attemptId) + 1;
  }

  void _openSession(ExamSession exam) {
    final base = widget.module.isEo
        ? '/tcf/expression-orale'
        : '/tcf/expression-ecrite';
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
        child: Stack(
          children: [
            Column(
              children: [
                _Header(module: widget.module, onBack: _back),
                Expanded(
                  child: async.when(
                    loading: () => const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.red)),
                    error: (e, _) => _ErrorBox(
                      message: ApiClient.toApiException(e).message,
                      onRetry: () => ref
                          .invalidate(expressionHubProvider(widget.module.epreuve)),
                    ),
                    data: (data) {
                      final exams = data.exams;
                      // Ordre stable : plus ancien en slot 1.
                      final ordered = exams.reversed.toList();
                      return RefreshIndicator(
                        color: AppColors.red,
                        onRefresh: () async {
                          ref.invalidate(
                              expressionHubProvider(widget.module.epreuve));
                          await ref.read(expressionHubProvider(widget.module.epreuve).future);
                        },
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                          children: [
                            _StatsRow(exams: exams),
                            const SizedBox(height: 18),
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 10),
                              child: Row(
                                children: [
                                  Text('Tes examens',
                                      style: AppFonts.jakarta(
                                          size: 14,
                                          weight: FontWeight.w800,
                                          color: AppColors.ink)),
                                  const Spacer(),
                                  Text(
                                      '$_examSlotsCount disponibles',
                                      style: AppFonts.mono(
                                          size: 10,
                                          color: AppColors.muted,
                                          letterSpacing: 1.4,
                                          weight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            for (int i = 0; i < _examSlotsCount; i++) ...[
                              _ExamSlotCard(
                                slot: i + 1,
                                exam: i < ordered.length ? ordered[i] : null,
                                onTapEmpty: _openBriefing,
                                onTapDone: _openDoneSheet,
                              ),
                              if (i != _examSlotsCount - 1)
                                const SizedBox(height: 10),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_starting) const Positioned.fill(child: _BusyOverlay()),
          ],
        ),
      ),
    );
  }
}

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
                Text('Examens blancs',
                    style: AppFonts.jakarta(
                        size: 17,
                        weight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 1),
                Text(
                    '${module.title} · 3 tâches enchaînées comme le jour J',
                    style: AppFonts.jakarta(
                        size: 12, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.exams});

  final List<ExamSession> exams;

  @override
  Widget build(BuildContext context) {
    final done = exams.length;
    final completed = exams.where((e) => e.isFullyEvaluated).toList();
    final best = completed.isEmpty
        ? null
        : completed.map((e) => e.avgScore ?? 0).reduce((a, b) => a > b ? a : b);
    final highestLevel = completed
        .map((e) => e.niveauPlancher)
        .whereType<NiveauCecrl>()
        .fold<NiveauCecrl?>(null, (best, n) {
      if (best == null) return n;
      return n.scaleIndex > best.scaleIndex ? n : best;
    });
    final last = exams.isEmpty ? null : exams.first.lastSubmittedAt;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Examens faits',
            value: '$done / $_examSlotsCount',
            accent: AppColors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Meilleure note',
            value: best == null ? '—' : '${_formatScore(best)}/20',
            accent: AppColors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Meilleur niveau',
            value: highestLevel?.displayName ?? '—',
            accent: highestLevel != null
                ? _colorForLevel(highestLevel)
                : AppColors.muted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Dernière',
            value: last == null ? '—' : _shortDate(last),
            accent: AppColors.amber,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F1839),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: AppFonts.mono(
              size: 9,
              color: AppColors.muted,
              letterSpacing: 1.2,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppFonts.jakarta(
                size: 16,
                weight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamSlotCard extends StatelessWidget {
  const _ExamSlotCard({
    required this.slot,
    required this.exam,
    required this.onTapEmpty,
    required this.onTapDone,
  });

  final int slot;
  final ExamSession? exam;
  final VoidCallback onTapEmpty;
  final ValueChanged<ExamSession> onTapDone;

  @override
  Widget build(BuildContext context) {
    final done = exam != null;
    final niveau = exam?.niveauPlancher;
    final accent = done
        ? (niveau != null ? _colorForLevel(niveau) : AppColors.blue)
        : AppColors.muted2;

    return Container(
      decoration: BoxDecoration(
        color: done ? accent.withValues(alpha: 0.06) : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done ? accent.withValues(alpha: 0.28) : AppColors.line,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F1839),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: done ? () => onTapDone(exam!) : onTapEmpty,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: done ? accent : AppColors.line2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$slot',
                      style: AppFonts.jakarta(
                          size: 14,
                          weight: FontWeight.w800,
                          color: done ? AppColors.white : AppColors.muted)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Examen blanc $slot',
                          style: AppFonts.jakarta(
                              size: 14.5,
                              weight: FontWeight.w800,
                              color: AppColors.ink)),
                      const SizedBox(height: 2),
                      Text(
                        done
                            ? '${_formatLongDate(exam!.lastSubmittedAt)} · ${_doneStatus(exam!)}'
                            : 'Disponible · 3 tâches enchaînées',
                        style: AppFonts.jakarta(
                            size: 12, color: AppColors.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (done && niveau != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(niveau.displayName,
                        style: AppFonts.jakarta(
                            size: 11,
                            weight: FontWeight.w800,
                            color: accent)),
                  )
                else if (done)
                  const Icon(Icons.hourglass_top_rounded,
                      size: 18, color: AppColors.muted2)
                else
                  const Icon(Icons.play_arrow_rounded,
                      size: 22, color: AppColors.muted2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _doneStatus(ExamSession s) =>
      s.isFullyEvaluated ? 'Terminé' : 'Évaluation IA en cours';
}

class _ExamDoneSheet extends StatelessWidget {
  const _ExamDoneSheet({
    required this.exam,
    required this.slot,
    required this.onViewDetail,
    required this.onResume,
  });

  final ExamSession exam;
  final int slot;
  final VoidCallback onViewDetail;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final niveau = exam.niveauPlancher;
    final accent = niveau != null ? _colorForLevel(niveau) : AppColors.blue;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.line2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Examen blanc $slot',
                style: AppFonts.jakarta(
                    size: 18, weight: FontWeight.w800, color: AppColors.ink),
              ),
              const SizedBox(height: 4),
              Text(
                _formatLongDate(exam.lastSubmittedAt) +
                    (niveau != null ? ' · ${niveau.displayName}' : ''),
                style: AppFonts.jakarta(size: 12.5, color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              _SheetButton(
                label: 'Voir le détail',
                icon: Icons.description_outlined,
                background: accent.withValues(alpha: 0.10),
                foreground: accent,
                onPressed: onViewDetail,
              ),
              const SizedBox(height: 10),
              _SheetButton(
                label: 'Reprendre',
                icon: Icons.refresh_rounded,
                background: AppColors.red,
                foreground: AppColors.white,
                onPressed: onResume,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Text(label,
                  style: AppFonts.jakarta(
                      size: 14,
                      weight: FontWeight.w800,
                      color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusyOverlay extends StatelessWidget {
  const _BusyOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.25),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: AppColors.white),
    );
  }
}

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
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppColors.ink)),
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
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

Color _colorForLevel(NiveauCecrl level) {
  switch (level) {
    case NiveauCecrl.a1NonAtteint:
    case NiveauCecrl.a1:
    case NiveauCecrl.a2:
      return AppColors.red;
    case NiveauCecrl.b1:
      return AppColors.amber;
    case NiveauCecrl.b2:
    case NiveauCecrl.c1:
    case NiveauCecrl.c2:
      return AppColors.green;
  }
}

String _formatScore(double n) {
  if (n == n.truncateToDouble()) return n.toInt().toString();
  return n.toStringAsFixed(1).replaceAll('.', ',');
}

String _formatLongDate(DateTime d) {
  const months = [
    'janv.', 'févr.', 'mars', 'avril', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String _shortDate(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

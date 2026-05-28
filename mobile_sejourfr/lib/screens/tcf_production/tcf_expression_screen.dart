import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/paywall_sheet.dart';
import 'ee_session_controller.dart';
import 'eo_session_controller.dart';
import 'expression_hub_data.dart';
import 'tcf_production_module.dart';
import 'widgets/preparation_points.dart';
import 'widgets/task_palette.dart';

// ============================================================================
// HUB d'épreuve (/tcf/eo, /tcf/ee)
// ============================================================================

/// Écran d'accueil d'une épreuve d'Expression (EO/EE) : carte « examen blanc »,
/// entrée par tâche (3 lignes → `TcfTaskTrainingScreen`) et historique.
class TcfExpressionScreen extends ConsumerStatefulWidget {
  const TcfExpressionScreen({super.key, required this.module});

  final TcfProductionModule module;

  @override
  ConsumerState<TcfExpressionScreen> createState() =>
      _TcfExpressionScreenState();
}

// HubData / ExamSession / expressionHubProvider sont extraits dans
// expression_hub_data.dart (réutilisés par ProductionExamsScreen).

class _TcfExpressionScreenState extends ConsumerState<TcfExpressionScreen> {
  void _openExamBriefing() {
    // L'ancien briefing-direct est remplacé par une page dédiée listant
    // les 10 slots d'examens blancs avec stats — cf. ProductionExamsScreen.
    final route = widget.module.isEo
        ? '/tcf/expression-orale/examens'
        : '/tcf/expression-ecrite/examens';
    context.push(route);
  }

  void _openTask(int tache) {
    context.push('/tcf/${widget.module.routeKey}/tache/$tache');
  }

  void _openHistory() {
    final base =
        widget.module.isEo ? '/tcf/expression-orale' : '/tcf/expression-ecrite';
    context.push('$base/historique');
  }

  void _openExamSession(ExamSession s) {
    final base =
        widget.module.isEo ? '/tcf/expression-orale' : '/tcf/expression-ecrite';
    context.push('$base/sessions/${s.attemptId}');
  }

  void _openReport(ProductionSubmissionDto sub) {
    final base = widget.module.isEo
        ? '/tcf/expression-orale/resultats'
        : '/tcf/expression-ecrite/resultats';
    final tache = sub.tacheNumero ?? 1;
    context.push('$base/${sub.id}?taskIndex=${tache - 1}&history=1');
  }

  @override
  Widget build(BuildContext context) {
    final mod = widget.module;
    final async = ref.watch(expressionHubProvider(mod.epreuve));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                _AppHeader(
                  title: mod.title,
                  subtitle: 'TCF IRN · ${mod.isEo ? "Oral" : "Écrit"}',
                  onBack: () => _back(context),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _ExamenHero(module: mod, onStart: _openExamBriefing),
                ),
                const _SectionLabel('S\'entraîner par tâche'),
                for (int n = 1; n <= 3; n++)
                  _TaskRow(
                    module: mod,
                    tache: n,
                    count: async.valueOrNull?.countByTache[n],
                    onTap: () => _openTask(n),
                  ),
                const SizedBox(height: 8),
                async.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (data) => _History(
                    data: data,
                    onSeeAll: _openHistory,
                    onExam: _openExamSession,
                    onSingle: _openReport,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }
}

/// Carte « Lancer un examen blanc » — fond teinté, CTA rouge.
class _ExamenHero extends StatelessWidget {
  const _ExamenHero({required this.module, required this.onStart});

  final TcfProductionModule module;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(module.isEo ? Icons.mic_rounded : Icons.edit_note_rounded,
                  size: 15, color: AppColors.redDark),
              const SizedBox(width: 6),
              Text(
                'EXAMEN COMPLET · ${module.durationLabel} MIN',
                style: AppFonts.mono(
                    size: 10,
                    color: AppColors.redDark,
                    letterSpacing: 1.2,
                    weight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Lancer un examen blanc',
            style: AppFonts.jakarta(
                size: 17, weight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            module.isEo
                ? 'Les 3 tâches enchaînées comme le jour J, avec enregistrement.'
                : 'Les 3 tâches enchaînées comme le jour J, à rédiger.',
            style:
                AppFonts.jakarta(size: 13, color: AppColors.ink2, height: 1.5),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow_rounded,
                      size: 18, color: AppColors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Commencer',
                    style: AppFonts.jakarta(
                        size: 13.5,
                        weight: FontWeight.w800,
                        color: AppColors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne d'une tâche dans le hub : pastille colorée + titre + sous-titre +
/// nombre de sujets + chevron. Tap → écran d'entraînement de la tâche.
class _TaskRow extends StatelessWidget {
  const _TaskRow(
      {required this.module,
      required this.tache,
      required this.count,
      required this.onTap});

  final TcfProductionModule module;
  final int tache;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = _taskMeta(module, tache);
    final (bg, fg) = _taskColors(tache);
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: _cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Text('$tache',
                      style: AppFonts.jakarta(
                          size: 13, weight: FontWeight.w800, color: fg)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(meta.title,
                          style: AppFonts.jakarta(
                              size: 14,
                              weight: FontWeight.w700,
                              color: AppColors.ink)),
                      const SizedBox(height: 1),
                      Text(meta.subtitle,
                          style: AppFonts.jakarta(
                              size: 12, color: AppColors.muted)),
                    ],
                  ),
                ),
                if (count != null) ...[
                  Text('$count exercices',
                      style:
                          AppFonts.jakarta(size: 11, color: AppColors.muted2)),
                  const SizedBox(width: 6),
                ],
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.muted2, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bloc « Historique » : stats + dernier examen blanc + dernier entraînement.
/// Fusion examens + sujets, triée par date décroissante, limitée à [limit].
/// Renvoie une liste d'`Object` (mix `ExamSession` / `ProductionSubmissionDto`)
/// que `_History` dispatche par type à l'affichage.
List<Object> _recentMerged(HubData data, int limit) {
  final entries = <Object>[
    ...data.exams,
    ...data.singles,
  ];
  entries.sort((a, b) {
    final wa = a is ExamSession
        ? a.lastSubmittedAt
        : (a as ProductionSubmissionDto).submittedAt;
    final wb = b is ExamSession
        ? b.lastSubmittedAt
        : (b as ProductionSubmissionDto).submittedAt;
    return wb.compareTo(wa);
  });
  return entries.take(limit).toList();
}

class _History extends StatelessWidget {
  const _History({
    required this.data,
    required this.onSeeAll,
    required this.onExam,
    required this.onSingle,
  });

  final HubData data;
  final VoidCallback onSeeAll;
  final ValueChanged<ExamSession> onExam;
  final ValueChanged<ProductionSubmissionDto> onSingle;

  @override
  Widget build(BuildContext context) {
    final hasHistory = data.exams.isNotEmpty || data.singles.isNotEmpty;
    if (!hasHistory) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        child: _MutedHint(
            text:
                'Aucun passage pour l\'instant. Lance un examen blanc ou entraîne-toi par tâche.'),
      );
    }
    final niveau =
        data.exams.isNotEmpty ? data.exams.first.niveauPlancher : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
          child: Row(
            children: [
              Text('Historique',
                  style: AppFonts.jakarta(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.muted)),
              const Spacer(),
              GestureDetector(
                onTap: onSeeAll,
                child: Text('Tout voir',
                    style: AppFonts.jakarta(
                        size: 12,
                        weight: FontWeight.w700,
                        color: AppColors.red)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Row(
            children: [
              Expanded(
                  child: _HubStat(
                      label: 'Examens passés', value: '${data.exams.length}')),
              const SizedBox(width: 8),
              Expanded(
                child: _HubStat(
                  label: 'Niveau estimé',
                  value: niveau?.displayName ?? '—',
                  valueColor:
                      niveau != null ? _colorForLevel(niveau) : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        // 3 dernières activités (examens + sujets) confondues, triées par date
        // décroissante. Le reste est accessible via « Tout voir ».
        for (final entry in _recentMerged(data, 3))
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: switch (entry) {
              ExamSession e =>
                _LastExamCard(session: e, onTap: () => onExam(e)),
              ProductionSubmissionDto s =>
                _RecentSingleRow(submission: s, onTap: () => onSingle(s)),
              _ => const SizedBox.shrink(),
            },
          ),
      ],
    );
  }
}

class _HubStat extends StatelessWidget {
  const _HubStat({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppFonts.jakarta(size: 11, color: AppColors.muted)),
          const SizedBox(height: 2),
          Text(value,
              style: AppFonts.jakarta(
                  size: 18,
                  weight: FontWeight.w800,
                  color: valueColor ?? AppColors.ink)),
        ],
      ),
    );
  }
}

class _LastExamCard extends StatelessWidget {
  const _LastExamCard({required this.session, required this.onTap});

  final ExamSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final niveau = session.niveauPlancher;
    final color = niveau != null ? _colorForLevel(niveau) : AppColors.muted;
    final notes = <int, double>{};
    for (final s in session.submissions) {
      final n = s.evaluation?.noteSurVingt;
      if (s.tacheNumero != null && n != null) notes[s.tacheNumero!] = n;
    }

    return Container(
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line)),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          color: AppColors.blueLight, shape: BoxShape.circle),
                      child: const Icon(Icons.assignment_turned_in_rounded,
                          size: 18, color: AppColors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Examen blanc complet',
                              style: AppFonts.jakarta(
                                  size: 13.5,
                                  weight: FontWeight.w700,
                                  color: AppColors.ink)),
                          const SizedBox(height: 1),
                          Text(_formatDate(session.lastSubmittedAt),
                              style: AppFonts.jakarta(
                                  size: 11, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(niveau?.displayName ?? '…',
                          style: AppFonts.jakarta(
                              size: 11, weight: FontWeight.w800, color: color)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (int t = 1; t <= 3; t++) ...[
                      if (t != 1) const SizedBox(width: 6),
                      Expanded(child: _MiniScore(tache: t, note: notes[t])),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  const _MiniScore({required this.tache, required this.note});

  final int tache;
  final double? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: AppColors.bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        note != null ? 'T$tache · ${_formatNote(note!)}/20' : 'T$tache · —',
        style: AppFonts.jakarta(
            size: 11, color: AppColors.muted, weight: FontWeight.w600),
      ),
    );
  }
}

class _RecentSingleRow extends StatelessWidget {
  const _RecentSingleRow({required this.submission, required this.onTap});

  final ProductionSubmissionDto submission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tache = submission.tacheNumero ?? 1;
    final niveau = submission.evaluation?.niveauCecrl;
    final color = niveau != null ? _colorForLevel(niveau) : AppColors.muted;
    final (badgeBg, badgeFg) = _taskColors(tache);
    return Container(
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line)),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
                  child: Text('$tache',
                      style: AppFonts.jakarta(
                          size: 13, weight: FontWeight.w800, color: badgeFg)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tâche $tache · entraînement libre',
                          style: AppFonts.jakarta(
                              size: 13,
                              weight: FontWeight.w700,
                              color: AppColors.ink)),
                      const SizedBox(height: 1),
                      Text(_formatDate(submission.submittedAt),
                          style: AppFonts.jakarta(
                              size: 11, color: AppColors.muted)),
                    ],
                  ),
                ),
                if (niveau != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(niveau.displayName,
                        style: AppFonts.jakarta(
                            size: 11, weight: FontWeight.w800, color: color)),
                  ),
                  const SizedBox(width: 6),
                ],
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.muted2, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ÉCRAN PAR TÂCHE (/tcf/eo/tache/:n) — sujets + exemples
// ============================================================================

class _EntrainementKey {
  const _EntrainementKey({required this.epreuve, required this.tacheNumero});

  final EpreuveType epreuve;
  final int tacheNumero;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _EntrainementKey &&
          other.epreuve == epreuve &&
          other.tacheNumero == tacheNumero;

  @override
  int get hashCode => Object.hash(epreuve, tacheNumero);
}

class _TaskData {
  const _TaskData(
      {required this.subjects,
      required this.examples,
      required this.lastByTaskId});

  final List<ProductionTaskDto> subjects;
  final List<ProductionExampleDto> examples;
  final Map<String, ProductionSubmissionDto> lastByTaskId;
}

final _taskProvider = FutureProvider.autoDispose
    .family<_TaskData, _EntrainementKey>((ref, key) async {
  final repo = ref.watch(productionRepositoryProvider);
  final all = await repo.listTasks(epreuve: key.epreuve);
  final subjects = all.where((t) => t.tacheNumero == key.tacheNumero).toList();
  final examples = await repo.listExamples(
      epreuve: key.epreuve, tacheNumero: key.tacheNumero);
  final subs = await repo.listMine(epreuve: key.epreuve, limit: 200);
  final lastByTaskId = <String, ProductionSubmissionDto>{};
  for (final s in subs) {
    final tid = s.productionTaskId;
    if (tid == null) continue;
    final cur = lastByTaskId[tid];
    if (cur == null || s.submittedAt.isAfter(cur.submittedAt)) {
      lastByTaskId[tid] = s;
    }
  }
  return _TaskData(
      subjects: subjects, examples: examples, lastByTaskId: lastByTaskId);
});

/// Écran d'entraînement d'une tâche : toggle Sujets / Exemples + liste.
class TcfTaskTrainingScreen extends ConsumerStatefulWidget {
  const TcfTaskTrainingScreen(
      {super.key, required this.module, required this.tache});

  final TcfProductionModule module;
  final int tache;

  @override
  ConsumerState<TcfTaskTrainingScreen> createState() =>
      _TcfTaskTrainingScreenState();
}

class _TcfTaskTrainingScreenState extends ConsumerState<TcfTaskTrainingScreen> {
  bool _starting = false;
  int _tab = 0; // 0 = Exercices (sujets), 1 = Exemples
  int _filter = 0; // 0 = Tous, 1 = À faire, 2 = Faits
  bool _showAll = false;

  void _openExample(ProductionExampleDto example) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ExampleDetailSheet(module: widget.module, example: example),
    );
  }

  Future<void> _practice(ProductionTaskDto task) async {
    if (_starting) return;
    setState(() => _starting = true);
    ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
    try {
      if (widget.module.isEo) {
        await ref.read(eoSessionProvider.notifier).startSingle(task: task);
      } else {
        await ref.read(eeSessionProvider.notifier).startSingle(task: task);
      }
      if (!mounted) return;
      context.push(widget.module.isEo
          ? '/tcf/expression-orale/t/0'
          : '/tcf/expression-ecrite/t/0');
    } catch (e) {
      if (!mounted) return;
      final err = ApiClient.toApiException(e);
      if (err.isForbidden) {
        showPaywallSheet(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.message), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _startRandom(List<ProductionTaskDto> subjects,
      Map<String, ProductionSubmissionDto> done) {
    final todo = subjects.where((t) => !done.containsKey(t.id)).toList();
    final pool = todo.isNotEmpty ? todo : subjects;
    pool.shuffle();
    _practice(pool.first);
  }

  void _openPlan() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlanSheet(module: widget.module, tache: widget.tache),
    );
  }

  void _openReport(ProductionSubmissionDto sub) {
    final base = widget.module.isEo
        ? '/tcf/expression-orale/resultats'
        : '/tcf/expression-ecrite/resultats';
    final tache = sub.tacheNumero ?? widget.tache;
    context.push('$base/${sub.id}?taskIndex=${tache - 1}&history=1');
  }

  void _openDoneSheet(ProductionTaskDto task, ProductionSubmissionDto last) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final note = last.evaluation?.noteSurVingt;
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetHandle(),
                Text(
                  task.displayTitle,
                  style: AppFonts.jakarta(
                      size: 16, weight: FontWeight.w800, color: AppColors.ink),
                ),
                if (note != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 13, color: AppColors.green),
                      const SizedBox(width: 5),
                      Text(
                        'Dernière note : ${_formatNote(note)}/20',
                        style: AppFonts.jakarta(
                            size: 12.5,
                            color: AppColors.green,
                            weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                AppButton(
                  label: 'Voir le détail',
                  icon: Icons.description_outlined,
                  variant: AppButtonVariant.ghost,
                  height: 46,
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openReport(last);
                  },
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Reprendre',
                  icon: Icons.refresh_rounded,
                  variant: AppButtonVariant.danger,
                  height: 46,
                  onPressed: () {
                    Navigator.pop(ctx);
                    _practice(task);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mod = widget.module;
    final meta = _taskMeta(mod, widget.tache);
    final async = ref.watch(_taskProvider(
        _EntrainementKey(epreuve: mod.epreuve, tacheNumero: widget.tache)));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _AppHeader(
                  title: meta.title,
                  subtitle: 'Tâche ${widget.tache} · ${meta.subtitle}',
                  onBack: () => _back(context),
                ),
                Expanded(
                  child: async.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(color: AppColors.red)),
                    error: (e, _) =>
                        _ErrorBox(message: ApiClient.toApiException(e).message),
                    data: (data) {
                      final subjects = data.subjects;
                      if (subjects.isEmpty) {
                        return _Placeholder(
                          icon: Icons.hourglass_empty_rounded,
                          title: 'Bientôt disponible',
                          description:
                              'Les sujets de cette tâche ne sont pas encore prêts. Reviens vite !',
                        );
                      }
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        children: [
                          _TaskTabs(
                            active: _tab,
                            onChanged: (i) => setState(() => _tab = i),
                          ),
                          const SizedBox(height: 14),
                          if (_tab == 0)
                            ..._buildExercices(mod, data)
                          else
                            ..._buildExemples(mod, data.examples),
                        ],
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

  List<Widget> _buildExercices(TcfProductionModule mod, _TaskData data) {
    final subjects = data.subjects;
    final done = data.lastByTaskId;
    final doneCount = subjects.where((t) => done.containsKey(t.id)).length;
    final List<ProductionTaskDto> filtered = switch (_filter) {
      1 => subjects.where((t) => !done.containsKey(t.id)).toList(),
      2 => subjects.where((t) => done.containsKey(t.id)).toList(),
      _ => subjects,
    };
    final visible = _showAll ? filtered : filtered.take(6).toList();
    final remaining = filtered.length - visible.length;
    return [
      _IntroCard(text: _introFor(mod, widget.tache)),
      const SizedBox(height: 12),
      _FilterChips(
        active: _filter,
        total: subjects.length,
        todo: subjects.length - doneCount,
        done: doneCount,
        onChanged: (i) => setState(() {
          _filter = i;
          _showAll = false;
        }),
      ),
      const SizedBox(height: 12),
      _RandomCard(onStart: () => _startRandom(subjects, done)),
      const SizedBox(height: 12),
      for (int i = 0; i < visible.length; i++)
        _ExerciseRow(
          index: i + 1,
          task: visible[i],
          last: done[visible[i].id],
          onTap: () {
            final last = done[visible[i].id];
            if (last != null) {
              _openDoneSheet(visible[i], last);
            } else {
              _practice(visible[i]);
            }
          },
        ),
      if (filtered.isEmpty) _MutedHint(text: 'Aucun sujet dans ce filtre.'),
      if (remaining > 0)
        _ShowMoreButton(
          label: 'Voir les $remaining autres',
          onTap: () => setState(() => _showAll = true),
        ),
    ];
  }

  List<Widget> _buildExemples(
      TcfProductionModule mod, List<ProductionExampleDto> examples) {
    return [
      if (examples.isEmpty)
        _MutedHint(
          text: mod.isEo
              ? 'Les exemples audio arriveront bientôt pour cette tâche.'
              : 'Les exemples rédigés arriveront bientôt pour cette tâche.',
        )
      else ...[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Modèles corrigés, avec stratégie et formules-clés.',
            style:
                AppFonts.jakarta(size: 12, color: AppColors.muted, height: 1.4),
          ),
        ),
        for (final ex in examples)
          _FeaturedExampleCard(example: ex, onOpen: () => _openExample(ex)),
      ],
      const SizedBox(height: 4),
      _StrategyCard(onTap: _openPlan),
    ];
  }

  String _introFor(TcfProductionModule mod, int tache) {
    if (mod.isEo) {
      return switch (tache) {
        1 =>
          'Présentez-vous clairement : identité, parcours, loisirs et projets. Parlez 2 à 3 minutes.',
        2 =>
          'Obtenez une information en posant des questions à l\'examinateur. Pensez à varier les formules.',
        _ =>
          'Donnez votre opinion et défendez-la avec deux arguments illustrés d\'exemples.',
      };
    }
    return switch (tache) {
      1 => 'Répondez au message reçu : soyez clair et complet en 60-120 mots.',
      2 =>
        'Racontez une expérience au passé : contexte, déroulement, puis bilan.',
      _ =>
        'Donnez un avis argumenté : thèse, deux arguments illustrés, et une objection.',
    };
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/tcf/${widget.module.routeKey}');
    }
  }
}

// ============================================================================
// Widgets partagés
// ============================================================================

class _AppHeader extends StatelessWidget {
  const _AppHeader(
      {required this.title, required this.subtitle, required this.onBack});

  final String title;
  final String subtitle;
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
                Text(title,
                    style: AppFonts.jakarta(
                        size: 17,
                        weight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: AppFonts.jakarta(size: 12, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
      child: Text(text,
          style: AppFonts.jakarta(
              size: 13, weight: FontWeight.w700, color: AppColors.muted)),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999)),
            child: const Icon(Icons.check_rounded,
                size: 13, color: AppColors.green),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: AppFonts.jakarta(
                      size: 13, color: AppColors.ink2, height: 1.4))),
        ],
      ),
    );
  }
}

class _ExampleDetailSheet extends StatefulWidget {
  const _ExampleDetailSheet({required this.module, required this.example});

  final TcfProductionModule module;
  final ProductionExampleDto example;

  @override
  State<_ExampleDetailSheet> createState() => _ExampleDetailSheetState();
}

class _ExampleDetailSheetState extends State<_ExampleDetailSheet> {
  final AudioPlayer _player = AudioPlayer();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final url = widget.example.audioUrl;
    if (url != null && url.isNotEmpty) {
      _player.setUrl(url).then((_) {
        if (mounted) setState(() => _ready = true);
      }).catchError((_) {});
      _player.playerStateStream.listen((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.example;
    final playing = _player.playing;
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(
          children: [
            const _SheetHandle(),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                children: [
                  Text(ex.titre,
                      style: AppFonts.jakarta(
                          size: 19,
                          weight: FontWeight.w800,
                          color: AppColors.ink)),
                  if (ex.resume != null) ...[
                    const SizedBox(height: 6),
                    Text(ex.resume!,
                        style: AppFonts.jakarta(
                            size: 13, color: AppColors.muted, height: 1.4)),
                  ],
                  if (ex.hasAudio) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _ready ? _toggle : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                            color: _ready ? AppColors.red : AppColors.muted2,
                            borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            Icon(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: AppColors.white,
                                size: 24),
                            const SizedBox(width: 10),
                            Text(playing ? 'Pause' : 'Écouter le modèle',
                                style: AppFonts.jakarta(
                                    size: 14,
                                    weight: FontWeight.w800,
                                    color: AppColors.white)),
                            const Spacer(),
                            if (!_ready)
                              const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    widget.module.isEo ? 'Transcription' : 'Texte du modèle',
                    style: AppFonts.mono(
                        size: 10,
                        color: AppColors.muted,
                        letterSpacing: 1.4,
                        weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(16),
                      border: const Border(
                          left: BorderSide(color: AppColors.red, width: 4)),
                    ),
                    child: Text(ex.contenu,
                        style: AppFonts.jakarta(
                            size: 14, color: AppColors.ink2, height: 1.6)),
                  ),
                  if (ex.explications != null &&
                      ex.explications!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppColors.redLight,
                          borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded,
                              size: 18, color: AppColors.red),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(ex.explications!,
                                  style: AppFonts.jakarta(
                                      size: 13,
                                      color: AppColors.ink2,
                                      height: 1.5))),
                        ],
                      ),
                    ),
                  ],
                  if (ex.planPoints.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text('Plan rapide',
                        style: AppFonts.jakarta(
                            size: 15,
                            weight: FontWeight.w800,
                            color: AppColors.ink)),
                    const SizedBox(height: 10),
                    for (final p in ex.planPoints) _PlanRow(text: p),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Center(
        child: Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.line, borderRadius: BorderRadius.circular(2))),
      ),
    );
  }
}

class _BusyOverlay extends StatelessWidget {
  const _BusyOverlay();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0x55000000),
      child: Center(child: CircularProgressIndicator(color: AppColors.white)),
    );
  }
}

class _MutedHint extends StatelessWidget {
  const _MutedHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line)),
      child: Text(text,
          style: AppFonts.jakarta(
              size: 12.5, color: AppColors.muted, height: 1.4)),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(
      {required this.icon, required this.title, required this.description});

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: AppColors.redLight,
                  borderRadius: BorderRadius.circular(20)),
              child: Icon(icon, color: AppColors.red, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: AppFonts.jakarta(
                    size: 16, weight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 8),
            Text(description,
                textAlign: TextAlign.center,
                style: AppFonts.jakarta(
                    size: 13, color: AppColors.muted, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.redLight, borderRadius: BorderRadius.circular(12)),
        child: Text(message,
            style: AppFonts.jakarta(size: 12.5, color: AppColors.redDark)),
      ),
    );
  }
}

({String title, String subtitle}) _taskMeta(
    TcfProductionModule module, int tache) {
  if (module.isEo) {
    return switch (tache) {
      1 => (title: 'Entretien dirigé', subtitle: 'Se présenter · 3 min'),
      2 => (title: 'Jeu de rôle', subtitle: 'Poser des questions · 3 min 30'),
      _ => (title: 'Donner son opinion', subtitle: 'Point de vue · 3 min 30'),
    };
  }
  return switch (tache) {
    1 => (title: 'Message', subtitle: 'Répondre à un message · 30-60 mots'),
    2 => (title: 'Récit', subtitle: 'Raconter une expérience · 40-90 mots'),
    _ => (title: 'Opinion', subtitle: 'Avis argumenté · 40-90 mots'),
  };
}

(Color, Color) _taskColors(int tache) => taskPalette(tache);

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

String _formatNote(double n) => n.toStringAsFixed(1).replaceAll('.', ',');

String _formatDate(DateTime d) {
  const months = [
    'janv.',
    'févr.',
    'mars',
    'avril',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

// ============================================================================
// Onglets + contenu de l'écran par tâche
// ============================================================================

/// Ombre douce partagée : léger relief pour fluidifier les cartes blanches.
const _cardShadow = [
  BoxShadow(color: Color(0x0A0F1839), blurRadius: 12, offset: Offset(0, 4)),
];

/// Onglets « Exercices / Exemples » (segment blanc actif, façon iOS).
class _TaskTabs extends StatelessWidget {
  const _TaskTabs({required this.active, required this.onChanged});

  final int active;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: AppColors.line2, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(child: _tab(0, Icons.list_rounded, 'Exercices')),
          Expanded(child: _tab(1, Icons.menu_book_rounded, 'Exemples')),
        ],
      ),
    );
  }

  Widget _tab(int i, IconData icon, String label) {
    final on = active == i;
    return GestureDetector(
      onTap: () => onChanged(i),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: on
              ? [
                  BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1))
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: on ? AppColors.red : AppColors.muted),
            const SizedBox(width: 6),
            Text(label,
                style: AppFonts.jakarta(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: on ? AppColors.ink : AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

/// Encart « Comment ça marche » (fond teinté rouge léger).
class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.redLight, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.redDark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comment ça marche',
                    style: AppFonts.jakarta(
                        size: 12,
                        weight: FontWeight.w800,
                        color: AppColors.redDark)),
                const SizedBox(height: 3),
                Text(text,
                    style: AppFonts.jakarta(
                        size: 12, color: AppColors.ink2, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chips de filtre Tous / À faire / Faits.
class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.active,
    required this.total,
    required this.todo,
    required this.done,
    required this.onChanged,
  });

  final int active;
  final int total;
  final int todo;
  final int done;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = ['Tous · $total', 'À faire · $todo', 'Faits · $done'];
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final on = active == i;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? AppColors.red : AppColors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: on ? AppColors.red : AppColors.line),
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

/// Carte « Sujet aléatoire » (bord pointillé).
class _RandomCard extends StatelessWidget {
  const _RandomCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: _cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: AppColors.redLight, shape: BoxShape.circle),
            child: const Icon(Icons.casino_rounded,
                size: 20, color: AppColors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Sujet aléatoire',
                    style: AppFonts.jakarta(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 1),
                Text('Comme à l\'examen, sans le voir',
                    style: AppFonts.jakarta(size: 12, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(10)),
              child: Text('Démarrer',
                  style: AppFonts.jakarta(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne d'exercice (sujet) : numéro + niveau + statut + énoncé.
class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow(
      {required this.index,
      required this.task,
      required this.last,
      required this.onTap});

  final int index;
  final ProductionTaskDto task;
  final ProductionSubmissionDto? last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = last != null;
    final note = last?.evaluation?.noteSurVingt;
    final (nbg, nfg) = _niveauColors(task.niveauCible);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: _cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(index.toString().padLeft(2, '0'),
                        style: AppFonts.mono(
                            size: 11,
                            color: AppColors.muted2,
                            weight: FontWeight.w700)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: nbg, borderRadius: BorderRadius.circular(999)),
                      child: Text(task.niveauCible,
                          style: AppFonts.jakarta(
                              size: 10, weight: FontWeight.w800, color: nfg)),
                    ),
                    const SizedBox(width: 8),
                    if (done)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 13, color: AppColors.green),
                          const SizedBox(width: 3),
                          Text(
                              note != null ? '${_formatNote(note)}/20' : 'Fait',
                              style: AppFonts.jakarta(
                                  size: 10.5,
                                  weight: FontWeight.w700,
                                  color: AppColors.green)),
                        ],
                      )
                    else
                      Text('Nouveau',
                          style: AppFonts.jakarta(
                              size: 10.5, color: AppColors.muted2)),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.muted2),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  task.consigne,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.jakarta(
                      size: 13, color: AppColors.ink, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShowMoreButton extends StatelessWidget {
  const _ShowMoreButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Text(label,
            style: AppFonts.jakarta(
                size: 13, weight: FontWeight.w700, color: AppColors.red)),
        label: const Icon(Icons.keyboard_arrow_down_rounded,
            size: 18, color: AppColors.red),
      ),
    );
  }
}

/// Carte « exemple corrigé » mise en avant (onglet Exemples).
class _FeaturedExampleCard extends StatelessWidget {
  const _FeaturedExampleCard({required this.example, required this.onOpen});

  final ProductionExampleDto example;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final (nbg, nfg) = _niveauColors(example.niveauIndicatif);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 14, color: AppColors.red),
              const SizedBox(width: 6),
              Text('EXEMPLE CORRIGÉ',
                  style: AppFonts.mono(
                      size: 9.5,
                      color: AppColors.red,
                      letterSpacing: 0.8,
                      weight: FontWeight.w700)),
              const Spacer(),
              if (example.niveauIndicatif != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: nbg, borderRadius: BorderRadius.circular(999)),
                  child: Text(example.niveauIndicatif!,
                      style: AppFonts.jakarta(
                          size: 10, weight: FontWeight.w800, color: nfg)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(example.titre,
              style: AppFonts.jakarta(
                  size: 13.5,
                  weight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.4)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
                color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
            child: Text(
              example.resume ?? example.contenu,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.jakarta(
                  size: 12, color: AppColors.muted, height: 1.45),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _OutlineBtn(
                      icon: Icons.description_outlined,
                      label: 'Voir le corrigé',
                      onTap: onOpen)),
              if (example.hasAudio) ...[
                const SizedBox(width: 6),
                Expanded(
                    child: _OutlineBtn(
                        icon: Icons.headphones_rounded,
                        label: 'Écouter',
                        onTap: onOpen)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.ink),
            const SizedBox(width: 5),
            Text(label,
                style: AppFonts.jakarta(
                    size: 12, weight: FontWeight.w700, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}

/// Carte « Méthode & formules-clés » → ouvre le plan d'aide.
class _StrategyCard extends StatelessWidget {
  const _StrategyCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
          color: AppColors.redLight, borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.15),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.lightbulb_outline_rounded,
                      size: 18, color: AppColors.redDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Méthode & formules-clés',
                          style: AppFonts.jakarta(
                              size: 12.5,
                              weight: FontWeight.w800,
                              color: AppColors.redDark)),
                      const SizedBox(height: 1),
                      Text('Le plan en 3 points',
                          style: AppFonts.jakarta(
                              size: 11, color: AppColors.redDark)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.redDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sheet de méthode : le plan d'aide en points (source `PreparationPoints`).
class _PlanSheet extends StatelessWidget {
  const _PlanSheet({required this.module, required this.tache});

  final TcfProductionModule module;
  final int tache;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(
          children: [
            const _SheetHandle(),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text('Méthode & formules-clés',
                      style: AppFonts.jakarta(
                          size: 18,
                          weight: FontWeight.w800,
                          color: AppColors.ink)),
                  const SizedBox(height: 14),
                  PreparationPoints(isEo: module.isEo, tache: tache),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Couleurs du badge niveau (A2 vert, B1 ambre, B2 rouge).
(Color, Color) _niveauColors(String? niveau) {
  switch (niveau) {
    case 'A2':
      return (AppColors.green.withValues(alpha: 0.14), AppColors.green);
    case 'B1':
      return (AppColors.amber.withValues(alpha: 0.18), AppColors.amber);
    case 'B2':
      return (AppColors.red.withValues(alpha: 0.12), AppColors.red);
    default:
      return (AppColors.line2, AppColors.muted);
  }
}

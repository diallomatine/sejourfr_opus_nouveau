import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format_date.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/fixed_action_bar.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/segmented_tabs.dart';
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
        child: Column(
          children: [
            ScreenHeader(
              title: mod.title,
              sub: mod.isEo
                  ? '3 tâches · la 1re est la présentation'
                  : "Les 3 tâches de l'épreuve",
              onBack: () => _back(context),
            ),
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      for (int n = 1; n <= 3; n++) ...[
                        _TaskCard(
                          module: mod,
                          tache: n,
                          count: async.valueOrNull?.countByTache[n],
                          onTap: () => _openTask(n),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 4),
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
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: FixedActionBar(
                      child: AppButton(
                        label: 'Examens blancs',
                        icon: LucideIcons.target,
                        variant: mod.isEo
                            ? AppButtonVariant.accent
                            : AppButtonVariant.primary,
                        onPressed: _openExamBriefing,
                      ),
                    ),
                  ),
                ],
              ),
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
      context.go('/reviser');
    }
  }
}

/// Carte d'une tâche (cf. `MTasks` maquette) : chip numéro 50 px coloré
/// (T1 EO = rouge « présentation imposée », sinon accent du module),
/// titre + badge, description, nombre de sujets.
class _TaskCard extends StatelessWidget {
  const _TaskCard(
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
    final fixed = module.isEo && tache == 1;
    final accent = fixed
        ? AppColors.red
        : module.isEo
            ? AppColors.red
            : AppColors.blue;
    final soft = fixed
        ? AppColors.redLight
        : module.isEo
            ? AppColors.redLight
            : AppColors.blueLight;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Text('$tache',
                      style: AppFonts.display(size: 22, color: accent)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              meta.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.ui(
                                  size: 15, weight: FontWeight.w700),
                            ),
                          ),
                          if (fixed) ...[
                            const SizedBox(width: 7),
                            const AppTag(
                              label: 'Présentation',
                              tone: TagTone.red,
                              icon: LucideIcons.mapPin,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        meta.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.ui(
                            size: 12.5, color: AppColors.inkSoft, height: 1.4),
                      ),
                      if (count != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$count sujets',
                          style: AppFonts.ui(
                              size: 12,
                              weight: FontWeight.w600,
                              color: AppColors.inkFaint),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.chevronRight,
                    size: 18, color: AppColors.inkFaint),
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
                  style: AppFonts.ui(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.muted)),
              const Spacer(),
              GestureDetector(
                onTap: onSeeAll,
                child: Text('Tout voir',
                    style: AppFonts.ui(
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
          Text(label, style: AppFonts.ui(size: 11, color: AppColors.muted)),
          const SizedBox(height: 2),
          Text(value,
              style: AppFonts.ui(
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
                      child: const Icon(LucideIcons.clipboardCheck,
                          size: 18, color: AppColors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Examen blanc complet',
                              style: AppFonts.ui(
                                  size: 13.5,
                                  weight: FontWeight.w700,
                                  color: AppColors.ink)),
                          const SizedBox(height: 1),
                          Text(formatLongDate(session.lastSubmittedAt),
                              style: AppFonts.ui(
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
                          style: AppFonts.ui(
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
        style: AppFonts.ui(
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
                  decoration:
                      BoxDecoration(color: badgeBg, shape: BoxShape.circle),
                  child: Text('$tache',
                      style: AppFonts.ui(
                          size: 13, weight: FontWeight.w800, color: badgeFg)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tâche $tache · entraînement libre',
                          style: AppFonts.ui(
                              size: 13,
                              weight: FontWeight.w700,
                              color: AppColors.ink)),
                      const SizedBox(height: 1),
                      Text(formatLongDate(submission.submittedAt),
                          style: AppFonts.ui(size: 11, color: AppColors.muted)),
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
                        style: AppFonts.ui(
                            size: 11, weight: FontWeight.w800, color: color)),
                  ),
                  const SizedBox(width: 6),
                ],
                const Icon(LucideIcons.chevronRight,
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
                  style: AppFonts.ui(
                      size: 16, weight: FontWeight.w800, color: AppColors.ink),
                ),
                if (note != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(LucideIcons.circleCheck,
                          size: 13, color: AppColors.green),
                      const SizedBox(width: 5),
                      Text(
                        'Dernière note : ${_formatNote(note)}/20',
                        style: AppFonts.ui(
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
                  icon: LucideIcons.fileText,
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
                  icon: LucideIcons.refreshCw,
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
                ScreenHeader(
                  title: meta.title,
                  sub: 'Tâche ${widget.tache} · ${meta.subtitle}',
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
                          icon: LucideIcons.hourglass,
                          title: 'Bientôt disponible',
                          description:
                              'Les sujets de cette tâche ne sont pas encore prêts. Reviens vite !',
                        );
                      }
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        children: [
                          SegmentedTabs<int>(
                            tabs: const [
                              SegmentTab(value: 0, label: 'Sujets'),
                              SegmentTab(value: 1, label: 'Exemples'),
                            ],
                            value: _tab,
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
      _IntroCard(text: _introFor(mod, widget.tache), module: mod),
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
          module: mod,
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
            style: AppFonts.ui(size: 12, color: AppColors.muted, height: 1.4),
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
            child:
                const Icon(LucideIcons.check, size: 13, color: AppColors.green),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: AppFonts.ui(
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
                      style: AppFonts.ui(
                          size: 19,
                          weight: FontWeight.w800,
                          color: AppColors.ink)),
                  if (ex.resume != null) ...[
                    const SizedBox(height: 6),
                    Text(ex.resume!,
                        style: AppFonts.ui(
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
                            Icon(playing ? LucideIcons.pause : LucideIcons.play,
                                color: AppColors.white, size: 24),
                            const SizedBox(width: 10),
                            Text(playing ? 'Pause' : 'Écouter le modèle',
                                style: AppFonts.ui(
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
                  // EO : on n'affiche pas la transcription du dialogue, le
                  // candidat doit s'entraîner à l'écoute seule. EE : le texte
                  // EST le modèle, on le montre.
                  if (!widget.module.isEo) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Texte du modèle',
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
                          style: AppFonts.ui(
                              size: 14, color: AppColors.ink2, height: 1.6)),
                    ),
                  ],
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
                          const Icon(LucideIcons.lightbulb,
                              size: 18, color: AppColors.red),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(ex.explications!,
                                  style: AppFonts.ui(
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
                        style: AppFonts.ui(
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
          style: AppFonts.ui(size: 12.5, color: AppColors.muted, height: 1.4)),
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
                style: AppFonts.ui(
                    size: 16, weight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 8),
            Text(description,
                textAlign: TextAlign.center,
                style:
                    AppFonts.ui(size: 13, color: AppColors.muted, height: 1.5)),
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
            style: AppFonts.ui(size: 12.5, color: AppColors.redDark)),
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

Color _colorForLevel(NiveauCecrl level) => level.color;

String _formatNote(double n) => n.toStringAsFixed(1).replaceAll('.', ',');

// ============================================================================
// Onglets + contenu de l'écran par tâche
// ============================================================================

/// Onglets « Exercices / Exemples » (segment blanc actif, façon iOS).
/// Bannière de consigne de la tâche (cf. `MPractice` maquette) : fond
/// teinté + liseré accent à gauche — rouge EO, bleu EE.
class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.text, required this.module});

  final String text;
  final TcfProductionModule module;

  @override
  Widget build(BuildContext context) {
    final accent = module.isEo ? AppColors.red : AppColors.blue;
    final soft = module.isEo ? AppColors.redLight : AppColors.blueLight;
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Text(
        text,
        style: AppFonts.ui(size: 14, weight: FontWeight.w500, height: 1.45),
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
                style: AppFonts.ui(
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
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: AppColors.redLight, shape: BoxShape.circle),
            child:
                const Icon(LucideIcons.dices, size: 20, color: AppColors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Sujet aléatoire',
                    style: AppFonts.ui(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 1),
                Text('Comme à l\'examen, sans le voir',
                    style: AppFonts.ui(size: 12, color: AppColors.muted)),
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
                  style: AppFonts.ui(
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

/// Carte d'un sujet (cf. `MTask` maquette) : icône mic/pen en pastille,
/// énoncé, pill niveau + note si déjà fait, icône play / refaire. Tap →
/// l'entraînement démarre directement sur ce sujet.
class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow(
      {required this.module,
      required this.task,
      required this.last,
      required this.onTap});

  final TcfProductionModule module;
  final ProductionTaskDto task;
  final ProductionSubmissionDto? last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = last != null;
    final note = last?.evaluation?.noteSurVingt;
    final accent = module.isEo ? AppColors.red : AppColors.blue;
    final (nbg, nfg) = _niveauColors(task.niveauCible);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(
                    module.isEo ? LucideIcons.mic : LucideIcons.penLine,
                    size: 19,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.consigne,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.ui(
                            size: 14.5, weight: FontWeight.w500, height: 1.45),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                                color: nbg,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.pill)),
                            child: Text(task.niveauCible,
                                style: AppFonts.ui(
                                    size: 11,
                                    weight: FontWeight.w700,
                                    color: nfg)),
                          ),
                          const SizedBox(width: 8),
                          if (done)
                            AppTag(
                              label: note != null
                                  ? '${_formatNote(note)}/20'
                                  : 'Fait',
                              tone: TagTone.success,
                              icon: LucideIcons.check,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  done ? LucideIcons.refreshCw : LucideIcons.play,
                  size: 19,
                  color: accent,
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
            style: AppFonts.ui(
                size: 13, weight: FontWeight.w700, color: AppColors.red)),
        label:
            const Icon(LucideIcons.chevronDown, size: 18, color: AppColors.red),
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
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, size: 14, color: AppColors.red),
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
                      style: AppFonts.ui(
                          size: 10, weight: FontWeight.w800, color: nfg)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(example.titre,
              style: AppFonts.ui(
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
              style:
                  AppFonts.ui(size: 12, color: AppColors.muted, height: 1.45),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _OutlineBtn(
                      icon: LucideIcons.fileText,
                      label: 'Voir le corrigé',
                      onTap: onOpen)),
              if (example.hasAudio) ...[
                const SizedBox(width: 6),
                Expanded(
                    child: _OutlineBtn(
                        icon: LucideIcons.headphones,
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
                style: AppFonts.ui(
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
                  child: const Icon(LucideIcons.lightbulb,
                      size: 18, color: AppColors.redDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Méthode & formules-clés',
                          style: AppFonts.ui(
                              size: 12.5,
                              weight: FontWeight.w800,
                              color: AppColors.redDark)),
                      const SizedBox(height: 1),
                      Text('Le plan en 3 points',
                          style:
                              AppFonts.ui(size: 11, color: AppColors.redDark)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight,
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
                      style: AppFonts.ui(
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import '../../core/router/route_observer.dart';
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
import 'widgets/exam_filter_chips.dart';
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
    final examAvgs =
        data.exams.map((e) => e.avgScore).whereType<double>().toList();
    final moyenneExamens = examAvgs.isEmpty
        ? null
        : examAvgs.reduce((a, b) => a + b) / examAvgs.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
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
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                  child: _HubStat(
                      label: 'Examens passés', value: '${data.exams.length}')),
              const SizedBox(width: 8),
              Expanded(
                child: _HubStat(
                  label: 'Score moyen',
                  value: moyenneExamens == null
                      ? '—'
                      : '${_formatNote(moyenneExamens)}/20',
                ),
              ),
            ],
          ),
        ),
        // 3 dernières activités (examens + sujets) confondues, triées par date
        // décroissante. Le reste est accessible via « Tout voir ».
        for (final entry in _recentMerged(data, 3))
          Padding(
            padding: const EdgeInsets.all(8),
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
  const _HubStat({required this.label, required this.value});

  final String label;
  final String value;

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
                  size: 18, weight: FontWeight.w800, color: AppColors.ink)),
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
    final notes = <int, double>{};
    for (final s in session.submissions) {
      final n = s.evaluation?.noteSurVingt;
      if (s.tacheNumero != null && n != null) notes[s.tacheNumero!] = n;
    }
    final avg = session.avgScore;

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
                          color: AppColors.blueLight,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(avg != null ? '${_formatNote(avg)}/20' : '…',
                          style: AppFonts.ui(
                              size: 11,
                              weight: FontWeight.w800,
                              color: AppColors.blue)),
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
    final note = submission.evaluation?.noteSurVingt;
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
                if (note != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('${_formatNote(note)}/20',
                        style: AppFonts.ui(
                            size: 11, weight: FontWeight.w800, color: badgeFg)),
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

class _TcfTaskTrainingScreenState extends ConsumerState<TcfTaskTrainingScreen>
    with RouteAware {
  bool _starting = false;
  int _tab = 0; // 0 = Exercices (sujets), 1 = Exemples
  int _filter = 0; // 0 = Tout, 1 = À faire, 2 = Fait
  bool _showAll = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// Retour sur la liste des sujets après un flux poussé au-dessus (entraînement
  /// d'un sujet → rapport). Le provider `autoDispose` est resté en cache : on
  /// l'invalide pour que le sujet qu'on vient de traiter s'affiche « fait » avec
  /// sa note, sans avoir à quitter/revenir sur l'écran.
  @override
  void didPopNext() {
    ref.invalidate(_taskProvider(_EntrainementKey(
        epreuve: widget.module.epreuve, tacheNumero: widget.tache)));
  }

  /// EE/EO sont des épreuves TCF → accès gouverné par l'abonnement Intégral
  /// (`hasTcf`). Non-abonné : seuls le 1er sujet + le 1er exemple sont ouverts,
  /// le reste est cadenassé (parité avec les séries CO/CE/Structure).
  bool _isPremium() {
    final auth = ref.read(authControllerProvider);
    return auth is AuthAuthenticated &&
        auth.user.canAccessModule(AppModule.tcf);
  }

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
      // On ouvre TOUJOURS le briefing (lecture du sujet). Le choix du mode EO
      // T1/T2 (examinateur temps réel vs enregistrement seul) est proposé LÀ-BAS,
      // au moment de « Commencer l'enregistrement » — jamais avant d'avoir lu le
      // sujet. Cf. eo_briefing_screen._onStartPressed.
      if (widget.module.isEo) {
        await ref.read(eoSessionProvider.notifier).startSingle(task: task);
      } else {
        await ref.read(eeSessionProvider.notifier).startSingle(task: task);
      }
      if (!mounted) return;
      // On retire le scrim AVANT le push : sinon l'écran sortant le garde
      // pendant l'animation de slide → flash d'un écran sombre avant le
      // briefing. La session single-task est déjà prête (await ci-dessus),
      // donc le briefing s'affiche directement, sans loader intermédiaire.
      setState(() => _starting = false);
      // Le rafraîchissement de la liste au retour est géré par `didPopNext`
      // (RouteAware) : la liste reste montée sous le flux (briefing →
      // enregistrement/rédaction → résultats), son provider `autoDispose`
      // n'est donc jamais recyclé. On ne peut pas se fier au `Future` du push
      // ici car le flux fait des `pushReplacement` (le push d'origine se
      // résout dès la soumission, avant que l'évaluation/la note existe).
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
                  label: 'Refaire',
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
                    // Au retour d'un entraînement (didPopNext → invalidate), on
                    // garde la liste affichée pendant le refetch au lieu de
                    // flasher un spinner plein écran ; elle se met à jour avec la
                    // nouvelle note dès que les données arrivent.
                    skipLoadingOnReload: true,
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
    final premium = _isPremium();

    // Index d'origine conservé : c'est lui qui pilote le verrou freemium
    // (1er sujet offert, suivants premium), indépendamment du filtre courant.
    final indexed = [for (int i = 0; i < subjects.length; i++) (i, subjects[i])];
    final doneCount = indexed.where((e) => done[e.$2.id] != null).length;
    final todoCount = indexed.length - doneCount;
    final filtered = indexed.where((e) {
      final isDone = done[e.$2.id] != null;
      if (_filter == 1) return !isDone;
      if (_filter == 2) return isDone;
      return true;
    }).toList();

    final visible = _showAll ? filtered : filtered.take(6).toList();
    final remaining = filtered.length - visible.length;

    return [
      ExamFilterChips(
        active: _filter,
        labels: [
          'Tout · ${indexed.length}',
          'À faire · $todoCount',
          'Fait · $doneCount',
        ],
        onChanged: (i) => setState(() {
          _filter = i;
          _showAll = false;
        }),
      ),
      const SizedBox(height: 12),
      if (filtered.isEmpty)
        _MutedHint(
          text: _filter == 2
              ? 'Aucun sujet terminé pour l\'instant.'
              : 'Tous les sujets sont terminés. Bravo !',
        )
      else
        for (final (origIndex, task) in visible)
          _ExerciseRow(
            module: mod,
            task: task,
            last: done[task.id],
            locked: !premium && origIndex > 0,
            onTap: () {
              if (!premium && origIndex > 0) {
                showPaywallSheet(context);
                return;
              }
              final last = done[task.id];
              if (last != null) {
                _openDoneSheet(task, last);
              } else {
                _practice(task);
              }
            },
          ),
      if (remaining > 0)
        _ShowMoreButton(
          label: 'Voir les $remaining autres',
          onTap: () => setState(() => _showAll = true),
        ),
    ];
  }

  List<Widget> _buildExemples(
      TcfProductionModule mod, List<ProductionExampleDto> examples) {
    final premium = _isPremium();
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
        for (int i = 0; i < examples.length; i++)
          _FeaturedExampleCard(
            example: examples[i],
            locked: !premium && i > 0,
            onOpen: (!premium && i > 0)
                ? () => showPaywallSheet(context)
                : () => _openExample(examples[i]),
          ),
      ],
      const SizedBox(height: 4),
      _StrategyCard(onTap: _openPlan),
    ];
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
      _player.playerStateStream.listen((state) {
        if (!mounted) return;
        // Fin de lecture : repasse le bouton sur « Écouter » au lieu de rester
        // bloqué sur « Pause » (just_audio garde `playing` à true en completed).
        if (state.processingState == ProcessingState.completed) {
          _player.pause();
          _player.seek(Duration.zero);
        }
        setState(() {});
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

String _formatNote(double n) => n.toStringAsFixed(1).replaceAll('.', ',');

// ============================================================================
// Onglets + contenu de l'écran par tâche
// ============================================================================

/// Onglets « Exercices / Exemples » (segment blanc actif, façon iOS).
/// Bannière de consigne de la tâche (cf. `MPractice` maquette) : fond
/// teinté + liseré accent à gauche — rouge EO, bleu EE.
/// Carte d'un sujet (cf. `MTask` maquette) : icône mic/pen en pastille,
/// énoncé, pill niveau + note si déjà fait, icône play / refaire. Tap →
/// l'entraînement démarre directement sur ce sujet.
class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow(
      {required this.module,
      required this.task,
      required this.last,
      required this.locked,
      required this.onTap});

  final TcfProductionModule module;
  final ProductionTaskDto task;
  final ProductionSubmissionDto? last;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = last != null;
    final note = last?.evaluation?.noteSurVingt;
    final accent = module.isEo ? AppColors.red : AppColors.blue;

    // La carte reste neutre (blanche) ; seul le badge d'état porte une couleur.
    // Fait : icône ✓ rouge si note <= 12, verte sinon (verte par défaut tant
    // que la note n'est pas encore évaluée). À faire : pastille accent module.
    final scoreColor =
        (note != null && note <= 12) ? AppColors.red : AppColors.green;
    final pastilleBg = locked
        ? AppColors.surface2
        : done
            ? scoreColor.withValues(alpha: 0.12)
            : accent.withValues(alpha: 0.10);
    final pastilleFg = locked
        ? AppColors.inkFaint
        : done
            ? scoreColor
            : accent;
    final pastilleIcon = locked
        ? LucideIcons.lock
        : done
            ? LucideIcons.check
            : (module.isEo ? LucideIcons.mic : LucideIcons.penLine);

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
                    color: pastilleBg,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(pastilleIcon, size: 19, color: pastilleFg),
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
                            size: 14.5,
                            weight: FontWeight.w500,
                            height: 1.45,
                            color: AppColors.ink),
                      ),
                      const SizedBox(height: 8),
                      if (done)
                        AppTag(
                          label: note != null
                              ? '${_formatNote(note)}/20'
                              : 'Terminé',
                          tone: (note != null && note <= 12)
                              ? TagTone.red
                              : TagTone.success,
                          icon: LucideIcons.check,
                        )
                      else if (locked)
                        const AppTag(
                          label: 'Abonnement',
                          tone: TagTone.neutral,
                          icon: LucideIcons.lock,
                        )
                      else
                        AppTag(
                          label: 'À faire',
                          tone: module.isEo ? TagTone.red : TagTone.blue,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (locked)
                  const Icon(LucideIcons.lock,
                      size: 19, color: AppColors.inkFaint)
                else if (done)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.refreshCw,
                          size: 15, color: AppColors.muted),
                      const SizedBox(width: 5),
                      Text('Refaire',
                          style: AppFonts.ui(
                              size: 12.5,
                              weight: FontWeight.w600,
                              color: AppColors.muted)),
                    ],
                  )
                else
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.play,
                        size: 16, color: AppColors.white),
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

/// Carte « exemple corrigé » mise en avant (onglet Exemples). Quand l'exemple
/// porte un audio (EO), la carte intègre un lecteur inline : bouton Écouter,
/// barre de progression et durée totale. Sinon (EE, texte), elle ouvre le
/// corrigé rédigé.
class _FeaturedExampleCard extends StatefulWidget {
  const _FeaturedExampleCard(
      {required this.example, required this.locked, required this.onOpen});

  final ProductionExampleDto example;
  final bool locked;
  final VoidCallback onOpen;

  @override
  State<_FeaturedExampleCard> createState() => _FeaturedExampleCardState();
}

class _FeaturedExampleCardState extends State<_FeaturedExampleCard> {
  AudioPlayer? _player;
  bool _ready = false;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Exemple cadenassé (non-abonné, au-delà du 1er) : on ne charge même pas
    // l'audio — la carte affiche un état verrouillé qui ouvre le paywall.
    if (widget.locked) return;
    final url = widget.example.audioUrl;
    if (widget.example.hasAudio && url != null && url.isNotEmpty) {
      final player = AudioPlayer();
      _player = player;
      player.setUrl(url).then((d) {
        if (!mounted) return;
        setState(() {
          _ready = true;
          if (d != null) _dur = d;
        });
      }).catchError((_) {});
      player.durationStream.listen((d) {
        if (mounted && d != null) setState(() => _dur = d);
      });
      player.positionStream.listen((p) {
        if (mounted) setState(() => _pos = p);
      });
      player.playerStateStream.listen((state) {
        if (!mounted) return;
        // Fin de lecture : just_audio garde `playing == true` sur l'état
        // `completed` → on remet le lecteur au repos (bouton ▶ + barre à 0).
        if (state.processingState == ProcessingState.completed) {
          player.pause();
          player.seek(Duration.zero);
        }
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final player = _player;
    if (player == null) return;
    if (player.playing) {
      await player.pause();
    } else {
      if (player.processingState == ProcessingState.completed) {
        await player.seek(Duration.zero);
      }
      await player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final example = widget.example;
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
                  style: AppFonts.ui(
                      size: 9.5,
                      color: AppColors.red,
                      letterSpacing: 0.8,
                      weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(example.titre,
              style: AppFonts.ui(
                  size: 13.5,
                  weight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.4)),
          const SizedBox(height: 10),
          if (widget.locked)
            _LockedExampleBar(isEo: example.hasAudio, onTap: widget.onOpen)
          else if (example.hasAudio)
            _buildPlayer()
          else
            _OutlineBtn(
                icon: LucideIcons.fileText,
                label: 'Voir le corrigé',
                onTap: widget.onOpen),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    final playing = _player?.playing ?? false;
    final progress = _dur.inMilliseconds > 0
        ? (_pos.inMilliseconds / _dur.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          GestureDetector(
            onTap: _ready ? _toggle : null,
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _ready ? AppColors.red : AppColors.muted2,
                  shape: BoxShape.circle),
              child: _ready
                  ? Icon(playing ? LucideIcons.pause : LucideIcons.play,
                      color: AppColors.white, size: 20)
                  : const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: AppColors.line,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.red),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmtClock(_pos),
                        style: AppFonts.ui(
                            size: 11,
                            color: AppColors.muted,
                            weight: FontWeight.w600)),
                    Text(_fmtClock(_dur),
                        style: AppFonts.ui(
                            size: 11,
                            color: AppColors.muted,
                            weight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtClock(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
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

/// Barre « exemple réservé » affichée à la place du lecteur / du bouton corrigé
/// quand l'exemple est cadenassé (non-abonné, au-delà du 1er). Tap → paywall.
class _LockedExampleBar extends StatelessWidget {
  const _LockedExampleBar({required this.isEo, required this.onTap});

  final bool isEo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
            color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: AppColors.surface2, shape: BoxShape.circle),
              child: const Icon(LucideIcons.lock,
                  size: 17, color: AppColors.inkFaint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isEo
                    ? 'Écoute réservée à l\'abonnement Intégral'
                    : 'Corrigé réservé à l\'abonnement Intégral',
                style: AppFonts.ui(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: AppColors.muted,
                    height: 1.3),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.chevronRight,
                size: 18, color: AppColors.inkFaint),
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

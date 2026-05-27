import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../module_detail/production_exam_briefing_sheet.dart';
import 'ee_session_controller.dart';
import 'eo_session_controller.dart';
import 'tcf_production_module.dart';

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

class _HubData {
  const _HubData(
      {required this.countByTache, required this.exams, required this.singles});

  /// Nombre de sujets par numéro de tâche.
  final Map<int, int> countByTache;

  /// Sessions d'examen blanc (≥3 submissions), les plus récentes d'abord.
  final List<_ExamSession> exams;

  /// Dernières productions en entraînement libre (single-task), récentes d'abord.
  final List<ProductionSubmissionDto> singles;
}

final _hubProvider = FutureProvider.autoDispose
    .family<_HubData, EpreuveType>((ref, epreuve) async {
  final repo = ref.watch(productionRepositoryProvider);
  final tasks = await repo.listTasks(epreuve: epreuve);
  final countByTache = <int, int>{};
  for (final t in tasks) {
    countByTache[t.tacheNumero] = (countByTache[t.tacheNumero] ?? 0) + 1;
  }

  final subs = await repo.listMine(epreuve: epreuve, limit: 200);
  final byAttempt = <String, List<ProductionSubmissionDto>>{};
  for (final s in subs) {
    final id = s.attemptId;
    if (id == null) continue;
    byAttempt.putIfAbsent(id, () => []).add(s);
  }
  final exams = <_ExamSession>[];
  final singles = <ProductionSubmissionDto>[];
  for (final entry in byAttempt.entries) {
    if (entry.value.length >= 3) {
      exams.add(_ExamSession(attemptId: entry.key, submissions: entry.value));
    } else {
      singles.addAll(entry.value);
    }
  }
  exams.sort((a, b) => b.lastSubmittedAt.compareTo(a.lastSubmittedAt));
  singles.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  return _HubData(countByTache: countByTache, exams: exams, singles: singles);
});

class _TcfExpressionScreenState extends ConsumerState<TcfExpressionScreen> {
  bool _starting = false;

  bool _isPremium() {
    final auth = ref.read(authControllerProvider);
    return auth is AuthAuthenticated &&
        auth.user.canAccessModule(AppModule.tcf);
  }

  void _openExamBriefing() {
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

  void _openTask(int tache) {
    context.push('/tcf/${widget.module.routeKey}/tache/$tache');
  }

  void _openHistory() {
    final base =
        widget.module.isEo ? '/tcf/expression-orale' : '/tcf/expression-ecrite';
    context.push('$base/historique');
  }

  void _openExamSession(_ExamSession s) {
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
    final async = ref.watch(_hubProvider(mod.epreuve));

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
            if (_starting) const Positioned.fill(child: _BusyOverlay()),
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
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
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
class _History extends StatelessWidget {
  const _History({
    required this.data,
    required this.onSeeAll,
    required this.onExam,
    required this.onSingle,
  });

  final _HubData data;
  final VoidCallback onSeeAll;
  final ValueChanged<_ExamSession> onExam;
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
        if (data.exams.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: _LastExamCard(
                session: data.exams.first,
                onTap: () => onExam(data.exams.first)),
          ),
        if (data.singles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: _RecentSingleRow(
                submission: data.singles.first,
                onTap: () => onSingle(data.singles.first)),
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

  final _ExamSession session;
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
  int _subTab = 0; // 0 = Sujets, 1 = Exemples

  void _openSubject(ProductionTaskDto subject, ProductionSubmissionDto? last) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _SubjectSheet(
        module: widget.module,
        task: subject,
        last: last,
        onPractice: () {
          Navigator.of(sheetCtx).pop();
          _practice(subject);
        },
        onReport: last == null
            ? null
            : () {
                Navigator.of(sheetCtx).pop();
                _openReport(last);
              },
      ),
    );
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

  void _openReport(ProductionSubmissionDto sub) {
    final base = widget.module.isEo
        ? '/tcf/expression-orale/resultats'
        : '/tcf/expression-ecrite/resultats';
    final tache = sub.tacheNumero ?? widget.tache;
    context.push('$base/${sub.id}?taskIndex=${tache - 1}&history=1');
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
                      final examples = data.examples;
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        children: [
                          _SubToggle(
                            active: _subTab,
                            sujetsLabel: 'Sujets · ${subjects.length}',
                            exemplesLabel: 'Exemples · ${examples.length}',
                            onChanged: (i) => setState(() => _subTab = i),
                          ),
                          const SizedBox(height: 14),
                          if (_subTab == 0)
                            for (int i = 0; i < subjects.length; i++)
                              _SubjectRow(
                                index: i + 1,
                                task: subjects[i],
                                last: data.lastByTaskId[subjects[i].id],
                                onTap: () => _openSubject(subjects[i],
                                    data.lastByTaskId[subjects[i].id]),
                              )
                          else if (examples.isEmpty)
                            _MutedHint(
                              text: mod.isEo
                                  ? 'Les exemples audio arriveront bientôt pour cette tâche.'
                                  : 'Les exemples rédigés arriveront bientôt pour cette tâche.',
                            )
                          else
                            for (int i = 0; i < examples.length; i++)
                              _ExampleRow(
                                index: i + 1,
                                example: examples[i],
                                onTap: () => _openExample(examples[i]),
                              ),
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

class _SubToggle extends StatelessWidget {
  const _SubToggle({
    required this.active,
    required this.sujetsLabel,
    required this.exemplesLabel,
    required this.onChanged,
  });

  final int active;
  final String sujetsLabel;
  final String exemplesLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: AppColors.line2, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
              child: _SegButton(
                  label: sujetsLabel,
                  active: active == 0,
                  onTap: () => onChanged(0))),
          Expanded(
              child: _SegButton(
                  label: exemplesLabel,
                  active: active == 1,
                  onTap: () => onChanged(1))),
        ],
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  const _SegButton(
      {required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.red : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.jakarta(
              size: 13,
              weight: FontWeight.w800,
              color: active ? AppColors.white : AppColors.muted),
        ),
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow(
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
    final niveau = last?.evaluation?.niveauCecrl;
    final color = niveau != null ? _colorForLevel(niveau) : AppColors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: done ? color.withValues(alpha: 0.35) : AppColors.line),
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
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: done ? color : AppColors.redLight,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('$index',
                      style: AppFonts.jakarta(
                          size: 14,
                          weight: FontWeight.w800,
                          color: done ? AppColors.white : AppColors.red)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        task.consigne,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.jakarta(
                            size: 13.5,
                            weight: FontWeight.w600,
                            color: AppColors.ink,
                            height: 1.3),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        done
                            ? (niveau != null
                                ? '✓ Fait · ${niveau.displayName}'
                                : '✓ Fait · évaluation…')
                            : 'À faire',
                        style: AppFonts.jakarta(
                            size: 11.5,
                            weight: FontWeight.w700,
                            color: done ? color : AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.muted2, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  const _ExampleRow(
      {required this.index, required this.example, required this.onTap});

  final int index;
  final ProductionExampleDto example;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line)),
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
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: AppColors.redLight,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('$index',
                      style: AppFonts.jakarta(
                          size: 14,
                          weight: FontWeight.w800,
                          color: AppColors.red)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(example.titre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.jakarta(
                              size: 14,
                              weight: FontWeight.w800,
                              color: AppColors.ink)),
                      const SizedBox(height: 3),
                      Text(example.resume ?? example.contenu,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.jakarta(
                              size: 12.5,
                              color: AppColors.muted,
                              height: 1.35)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (example.hasAudio)
                  const Icon(Icons.volume_up_rounded,
                      size: 18, color: AppColors.red),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.muted2, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fiche d'un sujet : consigne + plan d'aide, puis action selon l'état.
class _SubjectSheet extends StatelessWidget {
  const _SubjectSheet({
    required this.module,
    required this.task,
    required this.last,
    required this.onPractice,
    this.onReport,
  });

  final TcfProductionModule module;
  final ProductionTaskDto task;
  final ProductionSubmissionDto? last;
  final VoidCallback onPractice;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final done = last != null;
    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                children: [
                  _ConsigneCard(module: module, task: task),
                  const SizedBox(height: 16),
                  if (done) ...[
                    _LastResultBanner(last: last!),
                    const SizedBox(height: 14),
                    AppButton(
                        label: 'Refaire ce sujet',
                        icon: Icons.refresh_rounded,
                        variant: AppButtonVariant.danger,
                        onPressed: onPractice),
                    if (onReport != null) ...[
                      const SizedBox(height: 8),
                      AppButton(
                          label: 'Voir le rapport détaillé',
                          icon: Icons.description_outlined,
                          variant: AppButtonVariant.ghost,
                          onPressed: onReport!),
                    ],
                  ] else
                    AppButton(
                      label: module.isEo
                          ? "M'enregistrer sur ce sujet"
                          : 'Rédiger ma réponse',
                      icon:
                          module.isEo ? Icons.mic_rounded : Icons.edit_rounded,
                      variant: AppButtonVariant.danger,
                      onPressed: onPractice,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsigneCard extends StatelessWidget {
  const _ConsigneCard({required this.module, required this.task});

  final TcfProductionModule module;
  final ProductionTaskDto task;

  @override
  Widget build(BuildContext context) {
    final badge = module.isEo
        ? (task.dureeMaxSec != null
            ? '${(task.dureeMaxSec! / 60).ceil()} min'
            : null)
        : (task.motsMin != null && task.motsMax != null
            ? '${task.motsMin}-${task.motsMax} mots'
            : null);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: Text('Consigne & préparation',
                      style: AppFonts.jakarta(
                          size: 18,
                          weight: FontWeight.w800,
                          color: AppColors.ink))),
              if (badge != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(14)),
                  child: Text(badge,
                      style: AppFonts.jakarta(
                          size: 12,
                          weight: FontWeight.w800,
                          color: AppColors.white)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(task.consigne,
              style: AppFonts.jakarta(
                  size: 14, color: AppColors.ink2, height: 1.55)),
          const SizedBox(height: 16),
          Text('POUR RÉUSSIR, PENSEZ À',
              style: AppFonts.mono(
                  size: 9.5,
                  color: AppColors.muted,
                  letterSpacing: 1.6,
                  weight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final (i, point)
              in _planFor(module, task.tacheNumero).indexed) ...[
            _HelpPoint(index: i + 1, titre: point.$1, aide: point.$2),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _HelpPoint extends StatelessWidget {
  const _HelpPoint(
      {required this.index, required this.titre, required this.aide});

  final int index;
  final String titre;
  final String aide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: AppColors.redLight,
                borderRadius: BorderRadius.circular(10)),
            child: Text('$index',
                style: AppFonts.jakarta(
                    size: 13, weight: FontWeight.w800, color: AppColors.red)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre,
                    style: AppFonts.jakarta(
                        size: 13.5,
                        weight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 3),
                Text(aide,
                    style: AppFonts.jakarta(
                        size: 12, color: AppColors.muted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
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

class _LastResultBanner extends StatelessWidget {
  const _LastResultBanner({required this.last});

  final ProductionSubmissionDto last;

  @override
  Widget build(BuildContext context) {
    final niveau = last.evaluation?.niveauCecrl;
    final note = last.evaluation?.noteSurVingt;
    final color = niveau != null ? _colorForLevel(niveau) : AppColors.muted;
    final subtitle = niveau != null
        ? '${niveau.displayName}${note != null ? " · ${_formatNote(note)}/20" : ""} · ${_formatDate(last.submittedAt)}'
        : 'Évaluation en cours… · ${_formatDate(last.submittedAt)}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dernier passage',
                    style: AppFonts.jakarta(
                        size: 13,
                        weight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
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

// ============================================================================
// Données examen blanc + helpers
// ============================================================================

class _ExamSession {
  _ExamSession({required this.attemptId, required this.submissions});

  final String attemptId;
  final List<ProductionSubmissionDto> submissions;

  DateTime get lastSubmittedAt => submissions
      .map((s) => s.submittedAt)
      .reduce((a, b) => a.isAfter(b) ? a : b);

  NiveauCecrl? get niveauPlancher {
    NiveauCecrl? floor;
    for (final s in submissions) {
      final n = s.evaluation?.niveauCecrl;
      if (n == null) continue;
      if (floor == null || n.scaleIndex < floor.scaleIndex) floor = n;
    }
    return floor;
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
    1 => (title: 'Message', subtitle: 'Répondre à un message · 60-120 mots'),
    2 => (title: 'Récit', subtitle: 'Raconter une expérience · 120-150 mots'),
    _ => (title: 'Opinion', subtitle: 'Avis argumenté · 150-180 mots'),
  };
}

(Color, Color) _taskColors(int tache) {
  switch (tache) {
    case 1:
      return (AppColors.green.withValues(alpha: 0.14), AppColors.green);
    case 2:
      return (AppColors.amber.withValues(alpha: 0.18), AppColors.amber);
    default:
      return (AppColors.red.withValues(alpha: 0.12), AppColors.red);
  }
}

List<(String, String)> _planFor(TcfProductionModule module, int tache) {
  if (module.isEo) {
    return switch (tache) {
      1 => const [
          ('Présentez-vous', 'Prénom, origine, ville et situation actuelle.'),
          (
            'Parlez de votre quotidien',
            'Travail ou études, famille, activités.'
          ),
          (
            'Terminez par votre projet',
            'Pourquoi vous passez le TCF, vos objectifs.'
          ),
        ],
      2 => const [
          (
            'Posez des questions claires',
            'Au moins 4 questions sur des aspects différents.'
          ),
          (
            'Réagissez à l\'interlocuteur',
            '« D\'accord », « Très bien », « C\'est possible quand ? »'
          ),
          ('Terminez l\'échange', 'Proposez une suite, puis remerciez.'),
        ],
      _ => const [
          ('Annoncez votre position', '« À mon avis… », « Je pense que… »'),
          (
            'Donnez deux arguments',
            '« D\'abord… ensuite… » avec un exemple pour chacun.'
          ),
          ('Concluez en nuançant', '« Cependant… », « Pour finir… »'),
        ],
    };
  }
  return switch (tache) {
    1 => const [
        (
          'Répondez au message reçu',
          'Acceptez ou refusez, réagissez au déclencheur.'
        ),
        (
          'Donnez les informations utiles',
          'Jour, heure, lieu, détails demandés.'
        ),
        (
          'Posez une question et concluez',
          'Avec une formule de fin adaptée à un ami.'
        ),
      ],
    2 => const [
        ('Plantez le décor', 'Quand, où, avec qui.'),
        (
          'Racontez le déroulement',
          'Au passé composé / imparfait, avec une anecdote.'
        ),
        ('Terminez par un bilan', 'Ce que vous en avez retenu.'),
      ],
    _ => const [
        ('Annoncez votre thèse', '« Selon moi… », « Je pense que… »'),
        ('Donnez deux arguments illustrés', 'Un exemple concret pour chacun.'),
        ('Traitez une objection', '« Certes… toutefois… » puis concluez.'),
      ],
  };
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

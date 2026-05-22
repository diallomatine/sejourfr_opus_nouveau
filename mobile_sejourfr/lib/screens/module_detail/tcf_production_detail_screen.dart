import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../tcf_production/ee_session_controller.dart';
import '../tcf_production/eo_session_controller.dart';
import 'production_exam_briefing_sheet.dart';
import 'widgets/module_detail_widgets.dart';

/// Historique des submissions IA du user, par épreuve. Family indexée par
/// EpreuveType (TCF_EO ou TCF_EE).
final _submissionsHistoryProvider = FutureProvider.autoDispose
    .family<List<ProductionSubmissionDto>, EpreuveType>((ref, epreuve) {
  return ref.watch(productionRepositoryProvider).listMine(
        epreuve: epreuve,
        limit: 30,
      );
});

/// Historique des **examens** (sessions 3-tâches enchaînées) du user, par
/// épreuve. Dérivé de `listMine` : on groupe les submissions par `attemptId`
/// et on retient uniquement les attempts qui en ont **3 ou plus** — un attempt
/// single-task (entraînement libre) n'a qu'une submission et n'est pas un
/// examen. Trié ASC par date de première submission pour que le slot 1
/// corresponde au plus ancien examen passé (même logique que TCF QCM).
final _productionExamsHistoryProvider = FutureProvider.autoDispose
    .family<List<_ProductionExamSession>, EpreuveType>((ref, epreuve) async {
  final all = await ref.watch(productionRepositoryProvider).listMine(
        epreuve: epreuve,
        limit: 200,
      );
  final byAttempt = <String, List<ProductionSubmissionDto>>{};
  for (final s in all) {
    final id = s.attemptId;
    if (id == null) continue;
    byAttempt.putIfAbsent(id, () => []).add(s);
  }
  final exams = <_ProductionExamSession>[];
  for (final entry in byAttempt.entries) {
    if (entry.value.length < 3) continue; // single-task → pas un examen
    exams.add(_ProductionExamSession(
      attemptId: entry.key,
      submissions: entry.value,
    ));
  }
  exams.sort((a, b) => a.firstSubmittedAt.compareTo(b.firstSubmittedAt));
  return exams;
});

/// Snapshot d'une session 3-tâches finie : utilisé par l'onglet Examens pour
/// afficher la card du slot (date + niveau global + nombre d'évaluations
/// remontées).
class _ProductionExamSession {
  _ProductionExamSession({
    required this.attemptId,
    required this.submissions,
  });

  final String attemptId;
  final List<ProductionSubmissionDto> submissions;

  DateTime get firstSubmittedAt =>
      submissions.map((s) => s.submittedAt).reduce((a, b) => a.isBefore(b) ? a : b);

  DateTime get lastSubmittedAt =>
      submissions.map((s) => s.submittedAt).reduce((a, b) => a.isAfter(b) ? a : b);

  int get evaluatedCount =>
      submissions.where((s) => s.evaluation != null).length;

  /// Niveau CECRL plancher des évaluations disponibles (règle TCF IRN).
  /// Null tant qu'aucune submission n'a été évaluée.
  NiveauCecrl? get niveauPlancher {
    NiveauCecrl? floor;
    for (final s in submissions) {
      final n = s.evaluation?.niveauCecrl;
      if (n == null) continue;
      if (floor == null || n.scaleIndex < floor.scaleIndex) floor = n;
    }
    return floor;
  }

  double? get noteMoyenne {
    final notes = submissions
        .map((s) => s.evaluation?.noteSurVingt)
        .whereType<double>()
        .toList();
    if (notes.isEmpty) return null;
    return notes.reduce((a, b) => a + b) / notes.length;
  }
}

/// Module TCF productif (Expression écrite ou orale). Reste séparé de
/// `TcfQcmModule` parce que le flow downstream est différent : ces 2 modules
/// pushent un `ProductionHubScreen` (sélection T1/T2/T3) et non un runner QCM.
///
/// Couleurs : palette stricte bleu / blanc / rouge SejourFR (pas de vert ni
/// violet). EE et EO se distinguent par leur icône et le libellé du 3ᵉ onglet
/// (Corrections vs Analyses) + le CTA du bas (Commencer à écrire / parler).
enum TcfProductionModule {
  ee(
    routeKey: 'ee',
    epreuve: EpreuveType.tcfEe,
    eyebrow: 'Production écrite',
    title: 'Expression écrite',
    headline: 'Correction IA détaillée',
    description:
        'Rédige tes réponses puis reçois un niveau CECRL, des corrections et des conseils personnalisés.',
    icon: Icons.edit_note_rounded,
    durationLabel: '30',
    hubRoutePath: AppRoutes.tcfExpressionEcrite,
    historyTabLabel: 'Corrections',
    ctaLabel: 'Commencer à écrire',
  ),
  eo(
    routeKey: 'eo',
    epreuve: EpreuveType.tcfEo,
    eyebrow: 'Production orale',
    title: 'Expression orale',
    headline: 'Parle comme au vrai examen',
    description:
        'Enregistre tes réponses et reçois une analyse IA avec transcription et niveau CECRL.',
    icon: Icons.mic_rounded,
    durationLabel: '10',
    hubRoutePath: AppRoutes.tcfExpressionOrale,
    historyTabLabel: 'Analyses',
    ctaLabel: 'Commencer à parler',
  );

  const TcfProductionModule({
    required this.routeKey,
    required this.epreuve,
    required this.eyebrow,
    required this.title,
    required this.headline,
    required this.description,
    required this.icon,
    required this.durationLabel,
    required this.hubRoutePath,
    required this.historyTabLabel,
    required this.ctaLabel,
  });

  final String routeKey;
  final EpreuveType epreuve;
  final String eyebrow;
  final String title;
  final String headline;
  final String description;
  final IconData icon;
  final String durationLabel;
  final String hubRoutePath;
  final String historyTabLabel;
  final String ctaLabel;
}

/// Définition d'une tâche affichée dans l'onglet Tâches. Pour l'instant
/// statique — quand on aura l'écran lots par tâche, on chargera dynamiquement
/// les sujets depuis `/api/production-tasks?epreuve=...&tacheNumero=...`.
class _ProductionTaskCard {
  const _ProductionTaskCard({
    required this.index,
    required this.title,
    required this.description,
    this.premiumOnly = false,
  });

  final int index;
  final String title;
  final String description;
  final bool premiumOnly;
}

const _eeTaskCards = <_ProductionTaskCard>[
  _ProductionTaskCard(
    index: 1,
    title: 'Tâche 1 · Message simple',
    description: 'Email, invitation, annulation · 60-120 mots',
  ),
  _ProductionTaskCard(
    index: 2,
    title: 'Tâche 2 · Récit',
    description: 'Expérience personnelle · 120-150 mots',
  ),
  _ProductionTaskCard(
    index: 3,
    title: 'Tâche 3 · Opinion',
    description: 'Donner son avis · argumentation simple',
    premiumOnly: true,
  ),
];

const _eoTaskCards = <_ProductionTaskCard>[
  _ProductionTaskCard(
    index: 1,
    title: 'Tâche 1 · Présentation',
    description: 'Parler de soi, travail, loisirs',
  ),
  _ProductionTaskCard(
    index: 2,
    title: 'Tâche 2 · Jeu de rôle',
    description: 'Poser des questions et interagir',
  ),
  _ProductionTaskCard(
    index: 3,
    title: 'Tâche 3 · Opinion',
    description: 'Donner son avis et argumenter',
    premiumOnly: true,
  ),
];

enum _ProductionTab { tasks, exams, history }

/// Écran détail TCF EE/EO. Pattern miroir du détail QCM (topbar + title +
/// hero + stats + carte dernier niveau + onglets) en palette bleu / blanc /
/// rouge. Pas de score de maîtrise — un niveau CECRL placeholder est affiché
/// dans la carte "Dernier niveau" (branché au backend dans un prochain lot).
class TcfProductionDetailScreen extends ConsumerStatefulWidget {
  const TcfProductionDetailScreen({super.key, required this.module});

  final TcfProductionModule module;

  @override
  ConsumerState<TcfProductionDetailScreen> createState() =>
      _TcfProductionDetailScreenState();
}

class _TcfProductionDetailScreenState
    extends ConsumerState<TcfProductionDetailScreen> {
  _ProductionTab _tab = _ProductionTab.tasks;

  bool _isPremium() {
    final auth = ref.read(authControllerProvider);
    return auth is AuthAuthenticated && auth.user.canAccessModule(AppModule.tcf);
  }

  void _openTask(_ProductionTaskCard task) {
    if (task.premiumOnly && !_isPremium()) {
      showPaywallSheet(context);
      return;
    }
    if (!_isPremium()) {
      showPaywallSheet(context);
      return;
    }
    ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
    // Push l'écran lots par tâche. Pour EO T1 (consigne fixe), l'écran lots
    // détecte ça et bypass automatiquement vers le briefing.
    final base = widget.module.epreuve == EpreuveType.tcfEo
        ? AppRoutes.tcfEoTaskSubjects
        : AppRoutes.tcfEeTaskSubjects;
    context.push(base.replaceFirst(':tacheNumero', '${task.index}'));
  }

  /// Bouton primary du bas — démarrage rapide sur la Tâche 1.
  void _startFirstTask() {
    final cards = widget.module.epreuve == EpreuveType.tcfEo
        ? _eoTaskCards
        : _eeTaskCards;
    _openTask(cards.first);
  }

  bool _startingExam = false;

  /// Démarre un examen complet 3-tâches enchaînées (mode legacy session).
  /// Reload tasks + crée l'attempt parent via le session controller, puis
  /// push le briefing T1 mode session.
  Future<void> _startFullExam() async {
    if (_startingExam) return;
    if (!_isPremium()) {
      showPaywallSheet(context);
      return;
    }
    final auth = ref.read(authControllerProvider);
    final niveau = auth is AuthAuthenticated
        ? (auth.user.targetProcedure?.tcfLevel ?? 'B1')
        : 'B1';

    setState(() => _startingExam = true);
    ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
    try {
      if (widget.module.epreuve == EpreuveType.tcfEo) {
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
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _startingExam = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mod = widget.module;
    final auth = ref.watch(authControllerProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final target = user?.targetProcedure?.tcfLevel;
    final niveauCible = target ?? 'B2';
    final isPremium = _isPremium();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            ModuleDetailTopBar(
              onBack: () => context.pop(),
              icon: mod.icon,
              iconColor: AppColors.red,
              iconBg: AppColors.redLight,
            ),
            const SizedBox(height: 22),
            ModuleDetailTitle(eyebrow: mod.eyebrow, title: mod.title),
            const SizedBox(height: 22),
            ModuleDetailHero(
              icon: mod.icon,
              headline: mod.headline,
              description: mod.description,
              // Gradient rouge — cohérent avec le détail TCF CO/CE.
              gradient: const [AppColors.red, AppColors.redDark],
            ),
            const SizedBox(height: 16),
            ModuleDetailStats(
              items: [
                (value: '3', label: 'Tâches'),
                (value: mod.durationLabel, label: 'Minutes'),
                (value: niveauCible, label: 'Objectif'),
              ],
            ),
            const SizedBox(height: 14),
            const _LastLevelCard(),
            const SizedBox(height: 18),
            ModuleDetailTabs(
              labels: ['Tâches', 'Examens', mod.historyTabLabel],
              activeIndex: _tab.index,
              onChanged: (i) =>
                  setState(() => _tab = _ProductionTab.values[i]),
              accent: AppColors.blue,
            ),
            const SizedBox(height: 14),
            _TabContent(
              tab: _tab,
              module: mod,
              isPremium: isPremium,
              onTaskTap: _openTask,
              onStartFullExam: _startFullExam,
              startingExam: _startingExam,
            ),
            if (_tab == _ProductionTab.tasks) ...[
              const SizedBox(height: 18),
              AppButton(
                label: mod.ctaLabel,
                icon: Icons.play_arrow_rounded,
                onPressed: _startFirstTask,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.tab,
    required this.module,
    required this.isPremium,
    required this.onTaskTap,
    required this.onStartFullExam,
    required this.startingExam,
  });

  final _ProductionTab tab;
  final TcfProductionModule module;
  final bool isPremium;
  final ValueChanged<_ProductionTaskCard> onTaskTap;
  final VoidCallback onStartFullExam;
  final bool startingExam;

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case _ProductionTab.tasks:
        final cards =
            module.epreuve == EpreuveType.tcfEo ? _eoTaskCards : _eeTaskCards;
        return Column(
          children: [
            for (final task in cards)
              ModuleDetailSeriesCard(
                index: task.index,
                title: task.title,
                description: task.description,
                // T1 vert, T2 ambre, T3 rouge — pattern miroir des niveaux
                // A2/B1/B2 des séries QCM (progression vert → rouge).
                accent: _colorForTaskIndex(task.index),
                locked: task.premiumOnly && !isPremium,
                onTap: () => onTaskTap(task),
              ),
          ],
        );
      case _ProductionTab.exams:
        return _ExamsTab(
          module: module,
          starting: startingExam,
          onStart: onStartFullExam,
        );
      case _ProductionTab.history:
        return _AnalysisTab(module: module);
    }
  }
}

const int _productionExamSlotsCount = 10;

/// Onglet Examens : 10 slots numérotés (Examen 1 → 10) sur le même pattern
/// que TCF QCM. Les sessions 3-tâches finies du user remplissent les slots
/// de 1 vers le haut (slot 1 = plus ancien examen, comme CO/CE). Tap slot
/// vide → briefing + start. Tap slot fait → bottom sheet avec "Voir les
/// détails" (push HistorySessionScreen) ou "Reprendre".
class _ExamsTab extends ConsumerWidget {
  const _ExamsTab({
    required this.module,
    required this.starting,
    required this.onStart,
  });

  final TcfProductionModule module;
  final bool starting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEo = module.epreuve == EpreuveType.tcfEo;
    final asyncExams = ref.watch(_productionExamsHistoryProvider(module.epreuve));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EXAMEN COMPLET ${module.title.toUpperCase()}',
                style: AppFonts.mono(
                  size: 9.5,
                  color: AppColors.muted,
                  letterSpacing: 1.8,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isEo
                    ? '3 tâches orales enchaînées comme au vrai TCF : présentation, jeu de rôle, opinion. Évaluation IA en fin de session.'
                    : '3 tâches écrites enchaînées comme au vrai TCF : message simple, récit, opinion. Évaluation IA en fin de session.',
                style: AppFonts.jakarta(
                  size: 13,
                  color: AppColors.ink2,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  const _Chip(text: '3 tâches'),
                  _Chip(text: '${module.durationLabel} min'),
                  _Chip(text: isEo ? 'Audio + texte' : 'Écrit'),
                  const _Chip(text: 'Niveau CECRL'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Tes examens',
              style: AppFonts.jakarta(
                size: 14,
                weight: FontWeight.w800,
                color: AppColors.ink,
              ).copyWith(letterSpacing: -0.2),
            ),
            const Spacer(),
            Text(
              '$_productionExamSlotsCount disponibles',
              style: AppFonts.mono(
                size: 10,
                color: AppColors.muted,
                letterSpacing: 1.4,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        asyncExams.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.red),
              ),
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              ApiClient.toApiException(e).message,
              style: AppFonts.jakarta(size: 12.5, color: AppColors.muted),
            ),
          ),
          data: (exams) => Column(
            children: [
              for (int i = 0; i < _productionExamSlotsCount; i++)
                _ProductionExamSlotCard(
                  slot: i + 1,
                  session: i < exams.length ? exams[i] : null,
                  onTapEmpty: starting
                      ? null
                      : () => showProductionExamBriefingSheet(
                            context,
                            module: module,
                            starting: starting,
                            onStart: onStart,
                          ),
                  onTapDone: (session) => _showSessionSheet(
                    context,
                    session,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSessionSheet(BuildContext context, _ProductionExamSession session) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _ProductionExamActionSheet(
        session: session,
        onViewDetails: () {
          Navigator.of(sheetCtx).pop();
          final base = module.epreuve == EpreuveType.tcfEo
              ? '/tcf/expression-orale'
              : '/tcf/expression-ecrite';
          context.push('$base/sessions/${session.attemptId}');
        },
        onRetake: () {
          Navigator.of(sheetCtx).pop();
          // Même flow que tap slot vide : briefing → start nouvelle session.
          showProductionExamBriefingSheet(
            context,
            module: module,
            starting: starting,
            onStart: onStart,
          );
        },
      ),
    );
  }
}

/// Bottom sheet déclenchée au tap sur un slot d'examen déjà fait. Deux CTAs :
/// "Voir les détails" (push le bilan détaillé) ou "Reprendre" (nouvelle
/// session 3-tâches).
class _ProductionExamActionSheet extends StatelessWidget {
  const _ProductionExamActionSheet({
    required this.session,
    required this.onViewDetails,
    required this.onRetake,
  });

  final _ProductionExamSession session;
  final VoidCallback onViewDetails;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final niveau = session.niveauPlancher;
    final note = session.noteMoyenne;
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
                _summary(niveau, note),
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
                label: 'Reprendre (nouvelle session)',
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

  String _summary(NiveauCecrl? niveau, double? note) {
    final parts = <String>[];
    if (niveau != null) parts.add('Niveau ${niveau.displayName}');
    if (note != null) {
      final formatted = note == note.truncateToDouble()
          ? note.toInt().toString()
          : note.toStringAsFixed(1).replaceAll('.', ',');
      parts.add('moyenne $formatted/20');
    }
    if (session.evaluatedCount < session.submissions.length) {
      parts.add(
        '${session.evaluatedCount}/${session.submissions.length} évaluations remontées',
      );
    }
    if (parts.isEmpty) return 'Évaluation IA en cours.';
    return parts.join(' · ');
  }
}

/// Card slot d'examen complet 3-tâches. Quand `session != null`, c'est un
/// examen déjà passé : numéro coloré, date + niveau global + badge CECRL
/// teinté selon le score, tap → bottom sheet "Voir détails / Reprendre".
/// Sinon (slot vide), affichage neutre + chevron play → briefing + start.
class _ProductionExamSlotCard extends StatelessWidget {
  const _ProductionExamSlotCard({
    required this.slot,
    required this.session,
    required this.onTapEmpty,
    required this.onTapDone,
  });

  final int slot;
  final _ProductionExamSession? session;
  final VoidCallback? onTapEmpty;
  final ValueChanged<_ProductionExamSession> onTapDone;

  @override
  Widget build(BuildContext context) {
    final done = session != null;
    final color = _slotColor(session);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: done ? color.withValues(alpha: 0.05) : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? color.withValues(alpha: 0.3) : AppColors.line,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: done ? () => onTapDone(session!) : onTapEmpty,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: done ? color : AppColors.line2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$slot',
                      style: AppFonts.jakarta(
                        size: 14,
                        weight: FontWeight.w800,
                        color: done ? AppColors.white : AppColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Examen $slot',
                          style: AppFonts.jakarta(
                            size: 14.5,
                            weight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          done
                              ? _formatDoneSubtitle(session!)
                              : 'Disponible · 3 tâches enchaînées',
                          style: AppFonts.jakarta(
                            size: 12,
                            color: AppColors.muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (done)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _badgeText(session!),
                        style: AppFonts.jakarta(
                          size: 12,
                          weight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    )
                  else
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.muted2,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _slotColor(_ProductionExamSession? s) {
    final niveau = s?.niveauPlancher;
    if (niveau == null) return AppColors.muted;
    switch (niveau) {
      case NiveauCecrl.a1NonAtteint:
      case NiveauCecrl.a1:
        return AppColors.red;
      case NiveauCecrl.a2:
        return AppColors.amber;
      case NiveauCecrl.b1:
        return AppColors.blue;
      case NiveauCecrl.b2:
      case NiveauCecrl.c1:
      case NiveauCecrl.c2:
        return AppColors.green;
    }
  }

  String _badgeText(_ProductionExamSession s) {
    final niveau = s.niveauPlancher;
    if (niveau != null) return niveau.displayName;
    // Pas encore d'évaluation IA finalisée : badge muet d'attente.
    return '…';
  }

  String _formatDoneSubtitle(_ProductionExamSession s) {
    const months = [
      'janv.', 'févr.', 'mars', 'avril', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    final d = s.lastSubmittedAt;
    final date = '${d.day} ${months[d.month - 1]} ${d.year}';
    final note = s.noteMoyenne;
    if (note == null) {
      return '$date · évaluation en cours';
    }
    final formatted = note == note.truncateToDouble()
        ? note.toInt().toString()
        : note.toStringAsFixed(1).replaceAll('.', ',');
    return '$date · $formatted/20 moyenne';
  }
}

/// Onglet Analyses (EO) / Corrections (EE) : liste des submissions IA du
/// user, du plus récent au plus ancien. Tap → push l'écran résultats
/// existant en mode history.
class _AnalysisTab extends ConsumerWidget {
  const _AnalysisTab({required this.module});

  final TcfProductionModule module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSubs = ref.watch(_submissionsHistoryProvider(module.epreuve));

    return asyncSubs.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.blue),
          ),
        ),
      ),
      error: (e, _) => _ErrorBox(message: ApiClient.toApiException(e).message),
      data: (subs) {
        final finished = subs.where((s) => s.statut.isFinal).toList();
        if (finished.isEmpty) {
          return ModuleDetailTabPlaceholder(
            icon: Icons.history_rounded,
            title: 'Pas encore de ${module.historyTabLabel.toLowerCase()}',
            description:
                'Tes ${module.historyTabLabel.toLowerCase()} apparaîtront ici une fois la première tâche évaluée par l\'IA.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${finished.length} ${module.historyTabLabel.toUpperCase()}',
                    style: AppFonts.mono(
                      size: 9.5,
                      color: AppColors.blue,
                      letterSpacing: 1.6,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Plus récent en haut',
                  style: AppFonts.jakarta(size: 12, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final s in finished)
              _SubmissionRow(module: module, submission: s),
          ],
        );
      },
    );
  }
}

class _SubmissionRow extends StatelessWidget {
  const _SubmissionRow({required this.module, required this.submission});

  final TcfProductionModule module;
  final ProductionSubmissionDto submission;

  @override
  Widget build(BuildContext context) {
    final isEval = submission.statut == SubmissionStatut.evaluated;
    final isFailed = submission.statut == SubmissionStatut.failed;
    final niveau = submission.evaluation?.niveauCecrl;
    final note = submission.evaluation?.noteSurVingt;
    final tache = submission.tacheNumero ?? 1;

    final color = isFailed
        ? AppColors.red
        : niveau == null
            ? AppColors.muted
            : _colorForLevel(niveau);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final base = module.epreuve == EpreuveType.tcfEo
                  ? '/tcf/expression-orale/resultats'
                  : '/tcf/expression-ecrite/resultats';
              context.push(
                '$base/${submission.id}?taskIndex=${tache - 1}&history=1',
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'T$tache',
                      style: AppFonts.jakarta(
                        size: 12,
                        weight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatDate(submission.submittedAt),
                          style: AppFonts.jakarta(
                            size: 13.5,
                            weight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isFailed
                              ? 'Évaluation échouée'
                              : isEval && niveau != null
                                  ? '${niveau.displayName}${note != null ? " · ${_formatNote(note)}/20" : ""}'
                                  : 'Évaluation en cours…',
                          style: AppFonts.jakarta(
                            size: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isEval && niveau != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        niveau.displayName,
                        style: AppFonts.jakarta(
                          size: 12,
                          weight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    )
                  else
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.muted2,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'janv.', 'févr.', 'mars', 'avril', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

/// Formate une note décimale à la française (virgule au lieu du point).
/// Toujours une décimale : 14 → "14,0", 14.5 → "14,5".
String _formatNote(double n) => n.toStringAsFixed(1).replaceAll('.', ',');

/// Couleur d'accent d'une tâche selon son numéro (T1 = vert, T2 = ambre,
/// T3 = rouge). Suit le pattern visuel des niveaux A2/B1/B2 dans les
/// séries QCM — progression "facile → challenge".
Color _colorForTaskIndex(int index) {
  switch (index) {
    case 1:
      return AppColors.green;
    case 2:
      return AppColors.amber;
    case 3:
      return AppColors.red;
    default:
      return AppColors.blue;
  }
}

/// Couleur du badge / accent en fonction du niveau CECRL atteint.
///   A1 / A2 → rouge (à renforcer significativement)
///   B1      → ambre (en progression, vise le palier)
///   B2+     → vert (bon niveau, objectif TCF visé)
/// Cohérent avec le pattern QCM (rouge < 40 %, ambre 40-69 %, vert ≥ 70 %).
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

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.line2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppFonts.mono(
          size: 9.5,
          color: AppColors.ink2,
          letterSpacing: 1.2,
          weight: FontWeight.w600,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: AppFonts.jakarta(size: 12, color: AppColors.redDark),
      ),
    );
  }
}

/// Carte "Dernier niveau" — pattern visuel de la `white-card` du design.
/// Placeholder pour ce lot : niveau et conseil seront branchés sur les
/// dernières submissions IA dans un prochain lot.
class _LastLevelCard extends StatelessWidget {
  const _LastLevelCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DERNIER NIVEAU',
                    style: AppFonts.mono(
                      size: 9.5,
                      color: AppColors.muted,
                      letterSpacing: 1.8,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '—',
                    style: AppFonts.jakarta(
                      size: 22,
                      weight: FontWeight.w800,
                      color: AppColors.ink,
                    ).copyWith(letterSpacing: -0.4),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'À démarrer',
                  style: AppFonts.jakarta(
                    size: 11.5,
                    weight: FontWeight.w800,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(height: 8, color: AppColors.line2),
          ),
          const SizedBox(height: 10),
          Text(
            'Lance ta première tâche pour voir ton niveau CECRL apparaître ici.',
            style: AppFonts.jakarta(size: 12.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

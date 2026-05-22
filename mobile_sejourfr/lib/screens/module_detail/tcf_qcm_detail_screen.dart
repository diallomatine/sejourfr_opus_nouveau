import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/api/user_content_repository.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/attempt_summary.dart';
import '../../core/models/enums.dart';
import '../../core/models/question_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../../core/widgets/question_detail_sheet.dart';
import 'tcf_module_exam_briefing_screen.dart';
import 'widgets/module_detail_widgets.dart';

/// Identifie le module TCF QCM exposé via `/tcf/co`, `/tcf/ce` ou
/// `/tcf/structure`. EE/EO ont leur propre détail.
///
/// `structure` porte un `notice` non nul → bannière d'info rendue en haut du
/// détail pour signaler que ce module ne fait pas partie du TCF IRN officiel.
enum TcfQcmModule {
  co(
    routeKey: 'co',
    questionType: QuestionType.co,
    eyebrow: 'Module TCF',
    title: 'Compréhension orale',
    headline: '25 questions audio',
    description: 'Écoute des dialogues courts, annonces ou messages, puis choisis la bonne réponse.',
    icon: Icons.headphones_rounded,
    durationLabel: '≈ 20 min',
  ),
  ce(
    routeKey: 'ce',
    questionType: QuestionType.ce,
    eyebrow: 'Module TCF',
    title: 'Compréhension écrite',
    headline: '25 questions sur textes courts',
    description: 'Affiches, articles, courriels, structure de la langue — lis et identifie la bonne réponse.',
    icon: Icons.menu_book_rounded,
    durationLabel: '≈ 35 min',
  ),
  structure(
    routeKey: 'structure',
    questionType: QuestionType.structure,
    eyebrow: 'Entraînement complémentaire',
    title: 'Structure de la langue',
    headline: 'Grammaire et lexique en QCM',
    description:
        'Conjugaison, accords, prépositions, connecteurs : choisis la forme correcte parmi les propositions.',
    icon: Icons.spellcheck_rounded,
    durationLabel: '≈ 20 min',
    notice:
        'Module non évalué dans le TCF IRN officiel. Cet entraînement reste très utile pour consolider ta grammaire et progresser sur les autres épreuves.',
  );

  const TcfQcmModule({
    required this.routeKey,
    required this.questionType,
    required this.eyebrow,
    required this.title,
    required this.headline,
    required this.description,
    required this.icon,
    required this.durationLabel,
    this.notice,
  });

  final String routeKey;
  final QuestionType questionType;
  final String eyebrow;
  final String title;
  final String headline;
  final String description;
  final IconData icon;
  final String durationLabel;

  /// Message d'avertissement affiché en haut du détail (juste sous le titre)
  /// quand ce module n'est pas une épreuve officielle TCF IRN. `null` pour
  /// CO/CE.
  final String? notice;
}

final _tcfStatsProvider = FutureProvider.autoDispose<UserStats>((ref) {
  return ref.watch(userContentRepositoryProvider).stats(module: AppModule.tcf);
});

/// Historique des examens module (CO ou CE) du user. Family indexée par
/// QuestionType pour distinguer les deux épreuves.
final _moduleExamsHistoryProvider =
    FutureProvider.autoDispose.family<List<AttemptSummary>, QuestionType>((ref, questionType) {
  return ref.watch(attemptsRepositoryProvider).listMine(
        type: AttemptType.mockExam,
        module: AppModule.tcf,
        moduleExamQuestionType: questionType,
        limit: 20,
      );
});

/// Questions ratées de l'utilisateur sur une épreuve (CO ou CE). Family
/// indexée par QuestionType.
final _wrongQuestionsProvider =
    FutureProvider.autoDispose.family<List<QuestionDto>, QuestionType>((ref, questionType) {
  return ref.watch(userContentRepositoryProvider).wrongAnswered(
        module: AppModule.tcf,
        questionType: questionType,
      );
});

enum _DetailTab { series, exams, errors }

/// Carte de niveau exposée dans l'onglet Séries. Tap → push l'écran lots.
class _SeriesLevel {
  const _SeriesLevel({
    required this.difficulty,
    required this.label,
    required this.subtitle,
    required this.lotSize,
    required this.accent,
    required this.accentBg,
  });

  final Difficulty difficulty;
  final String label;
  final String subtitle;
  final int lotSize;
  final Color accent;
  final Color accentBg;
}

const _seriesLevels = <_SeriesLevel>[
  _SeriesLevel(
    difficulty: Difficulty.a2,
    label: 'Niveau débutant',
    subtitle: 'Bases — 15 questions par lot',
    lotSize: 15,
    accent: AppColors.green,
    accentBg: Color(0xFFE6F4EC),
  ),
  _SeriesLevel(
    difficulty: Difficulty.b1,
    label: 'Niveau intermédiaire',
    subtitle: 'Intermédiaire — 20 questions par lot',
    lotSize: 20,
    accent: AppColors.amber,
    accentBg: Color(0xFFFEF3DD),
  ),
  _SeriesLevel(
    difficulty: Difficulty.b2,
    label: 'Niveau avancée',
    subtitle: 'Challenge — 25 questions par lot',
    lotSize: 25,
    accent: AppColors.red,
    accentBg: AppColors.redLight,
  ),
];

class TcfQcmDetailScreen extends ConsumerStatefulWidget {
  const TcfQcmDetailScreen({super.key, required this.module});

  final TcfQcmModule module;

  @override
  ConsumerState<TcfQcmDetailScreen> createState() => _TcfQcmDetailScreenState();
}

class _TcfQcmDetailScreenState extends ConsumerState<TcfQcmDetailScreen> {
  bool _starting = false;
  _DetailTab _tab = _DetailTab.series;

  bool _isPremium() {
    final auth = ref.read(authControllerProvider);
    return auth is AuthAuthenticated && auth.user.canAccessModule(AppModule.tcf);
  }

  /// Démarre un entraînement standard 25 Q sur le module (sans filtre niveau)
  /// — accroché au bouton du bas. Le tap niveau, lui, push vers l'écran lots
  /// (cf. `_LevelCard.onTap`).
  Future<void> _startStandard() async {
    if (_starting) return;
    final isPremium = _isPremium();

    setState(() => _starting = true);
    ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;

    try {
      final attempt = await ref.read(attemptsRepositoryProvider).start(
            StartAttemptRequest(
              type: AttemptType.training,
              module: AppModule.tcf,
              questionType: isPremium ? widget.module.questionType : null,
              size: isPremium ? kInitialBatchSize : null,
            ),
          );
      if (!mounted) return;
      context.push(AppRoutes.runner.replaceFirst(':attemptId', attempt.id));
    } catch (e) {
      if (!mounted) return;
      final apiErr = ApiClient.toApiException(e);
      if (apiErr.isForbidden) {
        showPaywallSheet(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErr.message), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _openLevel(_SeriesLevel level) {
    ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
    final route = AppRoutes.tcfLevelLots
        .replaceFirst(':moduleKey', widget.module.routeKey)
        .replaceFirst(':level', level.difficulty.wire.toLowerCase());
    context.push(route);
  }

  /// Ouvre le briefing en bottomsheet modal avant le démarrage d'un examen
  /// module. Le sheet rappelle les consignes (durée, audio unique, pas de
  /// retour arrière) puis appelle le POST /api/attempts au tap "Commencer
  /// maintenant". Réservé premium : 403 → paywall depuis le sheet.
  void _openExamBriefing() {
    if (_starting) return;
    if (!_isPremium()) {
      showPaywallSheet(context);
      return;
    }
    ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
    showModuleExamBriefingSheet(context, widget.module);
  }

  @override
  Widget build(BuildContext context) {
    final mod = widget.module;
    final statsAsync = ref.watch(_tcfStatsProvider);

    final tcfStats = statsAsync.maybeWhen(
      data: (s) {
        final correct = s.byTheme.fold<int>(0, (sum, t) => sum + t.correct);
        final total = s.byTheme.fold<int>(0, (sum, t) => sum + t.total);
        return (
          percent: total == 0 ? 0 : ((correct / total) * 100).round(),
          attempts: s.attemptsTotal,
        );
      },
      orElse: () => (percent: 0, attempts: 0),
    );

    final auth = ref.watch(authControllerProvider);
    final target = auth is AuthAuthenticated ? auth.user.targetProcedure?.tcfLevel : null;
    final niveauLabel = target == null ? 'A2-B2' : 'Cible $target';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
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
                if (mod.notice != null) ...[
                  const SizedBox(height: 16),
                  _ModuleNoticeBanner(message: mod.notice!),
                ],
                const SizedBox(height: 22),
                ModuleDetailHero(
                  icon: mod.icon,
                  headline: mod.headline,
                  description: mod.description,
                  gradient: const [AppColors.red, AppColors.redDark],
                ),
                const SizedBox(height: 16),
                ModuleDetailStats(
                  items: [
                    (value: '$kInitialBatchSize', label: 'Questions'),
                    (value: mod.durationLabel, label: 'Durée'),
                    (value: niveauLabel, label: 'Niveau'),
                  ],
                ),
                const SizedBox(height: 14),
                ModuleDetailScoreCard(
                  percent: tcfStats.percent,
                  attemptsCount: tcfStats.attempts,
                  accent: AppColors.red,
                ),
                const SizedBox(height: 18),
                ModuleDetailTabs(
                  labels: const ['Séries', 'Examens', 'Erreurs'],
                  activeIndex: _tab.index,
                  onChanged: (i) => setState(() => _tab = _DetailTab.values[i]),
                  accent: AppColors.red,
                ),
                const SizedBox(height: 14),
                _TabContent(
                  tab: _tab,
                  module: mod,
                  onLevelTap: _openLevel,
                  onStartExam: _openExamBriefing,
                  examStarting: _starting,
                ),
                if (_tab == _DetailTab.series) ...[
                  const SizedBox(height: 18),
                  AppButton(
                    label: 'Commencer l\'entraînement',
                    icon: Icons.play_arrow_rounded,
                    isLoading: _starting,
                    onPressed: _starting ? null : _startStandard,
                  ),
                ],
              ],
            ),
            if (_starting)
              const Positioned.fill(
                child: ModuleDetailStartingOverlay(accent: AppColors.red),
              ),
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
    required this.onLevelTap,
    required this.onStartExam,
    required this.examStarting,
  });

  final _DetailTab tab;
  final TcfQcmModule module;
  final ValueChanged<_SeriesLevel> onLevelTap;
  final VoidCallback onStartExam;
  final bool examStarting;

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case _DetailTab.series:
        return Column(
          children: [
            for (final level in _seriesLevels) _LevelCard(level: level, onTap: () => onLevelTap(level)),
          ],
        );
      case _DetailTab.exams:
        return _ExamsTab(
          module: module,
          onStartExam: onStartExam,
          starting: examStarting,
        );
      case _DetailTab.errors:
        return _ErrorsTab(module: module);
    }
  }
}

const int _examSlotsCount = 10;

/// Onglet Examens : 10 slots numérotés. Les premiers slots sont remplis avec
/// les attempts finis du user (ordre chronologique), les slots restants sont
/// disponibles. Tap slot vide → lance un nouvel examen. Tap slot fait →
/// bottomsheet "Voir détails" / "Reprendre".
class _ExamsTab extends ConsumerWidget {
  const _ExamsTab({
    required this.module,
    required this.onStartExam,
    required this.starting,
  });

  final TcfQcmModule module;
  final VoidCallback onStartExam;
  final bool starting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(_moduleExamsHistoryProvider(module.questionType));
    final examDuration = module.questionType == QuestionType.co ? '20 min' : '35 min';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intro card : pitch de l'examen module.
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
                'EXAMEN BLANC ${module.title.toUpperCase()}',
                style: AppFonts.mono(
                  size: 9.5,
                  color: AppColors.muted,
                  letterSpacing: 1.8,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '25 questions A2 → B1 → B2, en $examDuration. Score pondéré par niveau (max 50 pts).',
                style: AppFonts.jakarta(
                  size: 13,
                  color: AppColors.ink2,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: const [
                  _Chip(text: '25 questions'),
                  _Chip(text: 'A2 → B1 → B2'),
                  _Chip(text: 'Score pondéré /50'),
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
              '$_examSlotsCount disponibles',
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
        asyncHistory.when(
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
          error: (e, _) => _ErrorBox(message: ApiClient.toApiException(e).message),
          data: (history) {
            // L'historique vient triée DESC par startedAt — on inverse pour
            // que le slot 1 corresponde au plus ancien attempt (logique
            // "Examen 1 = premier passé").
            final finished = history.where((a) => a.isFinished).toList().reversed.toList();
            return Column(
              children: [
                for (int i = 0; i < _examSlotsCount; i++)
                  _ExamSlotCard(
                    slot: i + 1,
                    attempt: i < finished.length ? finished[i] : null,
                    onTapEmpty: starting ? null : onStartExam,
                    onTapDone: (attempt) => _showExamSheet(context, attempt, onStartExam),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showExamSheet(
    BuildContext context,
    AttemptSummary attempt,
    VoidCallback onRetake,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _ExamActionSheet(
        attempt: attempt,
        onViewDetails: () {
          Navigator.of(sheetCtx).pop();
          // Push depuis le context parent (l'écran) — le sheetCtx est en
          // train d'être disposé après le pop.
          context.push(
            AppRoutes.examResult.replaceFirst(':attemptId', attempt.id),
          );
        },
        onRetake: () {
          Navigator.of(sheetCtx).pop();
          onRetake();
        },
      ),
    );
  }
}

/// Une carte slot d'examen (1 à 10). Visuellement : numéro de slot à
/// gauche, titre + sous-titre, badge score (si fait) ou pastille
/// "Disponible" (si vide).
class _ExamSlotCard extends StatelessWidget {
  const _ExamSlotCard({
    required this.slot,
    required this.attempt,
    required this.onTapEmpty,
    required this.onTapDone,
  });

  final int slot;
  final AttemptSummary? attempt;
  final VoidCallback? onTapEmpty;
  final ValueChanged<AttemptSummary> onTapDone;

  @override
  Widget build(BuildContext context) {
    final done = attempt != null;
    final color = _scoreColor(attempt);

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
            onTap: done ? () => onTapDone(attempt!) : onTapEmpty,
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
                          done ? _formatDoneSubtitle(attempt!) : 'Disponible · 25 questions',
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
                        '${attempt!.weightedScore ?? 0}/${attempt!.maxWeightedScore ?? 50}',
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

  Color _scoreColor(AttemptSummary? a) {
    if (a == null || a.weightedScore == null || a.maxWeightedScore == null || a.maxWeightedScore! == 0) {
      return AppColors.muted;
    }
    final pct = a.weightedScore! / a.maxWeightedScore! * 100;
    if (pct >= 70) return AppColors.green;
    if (pct >= 40) return AppColors.amber;
    return AppColors.red;
  }

  String _formatDoneSubtitle(AttemptSummary a) {
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
    final d = a.finishedAt!;
    return '${d.day} ${months[d.month - 1]} ${d.year} · ${a.score ?? 0}/${a.totalQuestions}';
  }
}

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

class _ErrorsTab extends ConsumerWidget {
  const _ErrorsTab({required this.module});

  final TcfQcmModule module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncWrong = ref.watch(_wrongQuestionsProvider(module.questionType));

    return asyncWrong.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.red),
          ),
        ),
      ),
      error: (e, _) => _ErrorBox(message: ApiClient.toApiException(e).message),
      data: (wrongs) {
        if (wrongs.isEmpty) {
          return ModuleDetailTabPlaceholder(
            icon: Icons.verified_outlined,
            title: 'Aucune erreur récente',
            description:
                'Bravo — pas de question ratée sur ${module.title} pour l\'instant. Continue les lots pour rester au top.',
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
                    color: AppColors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${wrongs.length} ERREUR${wrongs.length > 1 ? "S" : ""}',
                    style: AppFonts.mono(
                      size: 9.5,
                      color: AppColors.red,
                      letterSpacing: 1.6,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  module.title,
                  style: AppFonts.jakarta(size: 12, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final q in wrongs) _WrongQuestionCard(question: q),
          ],
        );
      },
    );
  }
}

/// Card review-style : filet rouge à gauche, chip niveau + type, statement
/// en preview, thème en bas. Tap → bottomsheet avec le détail complet.
class _WrongQuestionCard extends ConsumerWidget {
  const _WrongQuestionCard({required this.question});

  final QuestionDto question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openDetail(context, ref),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.redLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: AppColors.red,
                                ),
                              ),
                              const SizedBox(width: 10),
                              QuestionMiniTag(
                                label: question.difficulty.wire,
                                fg: AppColors.red,
                                bg: AppColors.redLight,
                              ),
                              const SizedBox(width: 6),
                              QuestionMiniTag(
                                label: question.questionType.displayLabel,
                                fg: AppColors.blue,
                                bg: AppColors.blueLight,
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.muted2,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            question.statement,
                            style: AppFonts.jakarta(
                              size: 14,
                              weight: FontWeight.w600,
                              height: 1.4,
                              color: AppColors.ink,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.bookmarks_outlined,
                                size: 12,
                                color: AppColors.muted2,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  question.themeName,
                                  style: AppFonts.mono(
                                    size: 10,
                                    color: AppColors.muted,
                                    letterSpacing: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, WidgetRef ref) async {
    // Le card ne porte que la version "preview" de la question (sans
    // correct flags ni explication). On fetche la version review avant
    // d'ouvrir le sheet partagé.
    final messenger = ScaffoldMessenger.of(context);
    try {
      final detailed = await ref.read(userContentRepositoryProvider).reviewQuestion(question.id);
      if (!context.mounted) return;
      showQuestionDetailSheet(context, question: detailed);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(ApiClient.toApiException(e).message),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }
}

/// Card cliquable d'un niveau (A2/B1/B2) dans l'onglet Séries. Tap → push
/// `TcfLevelLotsScreen`. Le chip niveau coloré à gauche reprend la couleur
/// d'accent du niveau.
class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level, required this.onTap});

  final _SeriesLevel level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: level.accent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      level.difficulty.wire,
                      style: AppFonts.jakarta(
                        size: 16,
                        weight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          level.label,
                          style: AppFonts.jakarta(
                            size: 16,
                            weight: FontWeight.w800,
                            color: AppColors.ink,
                          ).copyWith(letterSpacing: -0.2),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          level.subtitle,
                          style: AppFonts.jakarta(
                            size: 12.5,
                            color: AppColors.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: level.accentBg,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: level.accent,
                      size: 20,
                    ),
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

/// Petit chip mono utilisé dans l'intro de l'onglet Examens.
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

/// Bannière d'avertissement rendue sous le titre du détail quand le module
/// n'est pas une épreuve officielle TCF IRN (cf. `TcfQcmModule.structure`).
class _ModuleNoticeBanner extends StatelessWidget {
  const _ModuleNoticeBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blueLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.blue,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'À SAVOIR',
                  style: AppFonts.mono(
                    size: 9.5,
                    color: AppColors.blue,
                    letterSpacing: 1.8,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppFonts.jakarta(
                    size: 12.5,
                    color: AppColors.ink2,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Box d'erreur réseau / API affichée dans les onglets Examens et Erreurs.
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

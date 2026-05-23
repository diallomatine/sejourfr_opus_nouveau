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
import '../../core/models/production_models.dart';
import '../../core/models/question_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/paywall_sheet.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _statsProvider = FutureProvider.autoDispose.family<UserStats, AppModule>((ref, module) {
  return ref.watch(userContentRepositoryProvider).stats(module: module);
});

/// Résumé de progression aligné sur les examens passés — calculé côté
/// backend (`MeService.progressionSummary`). Le front ne fait que parser
/// et afficher : pas d'agrégation locale (Sessions / Questions / Mastery
/// globaux ne disaient rien sur la préparation à l'examen, cf. discussion
/// 2026-05-22). Family par module pour rester aligné sur le tab actif.
final _progressionProvider = FutureProvider.autoDispose.family<ProgressionSummary, AppModule>((ref, module) {
  return ref.watch(userContentRepositoryProvider).progression(module: module);
});

/// Derniers attempts du user pour ce module — sert au graphe de tendance
/// (score sur 7 derniers passages d'examens blancs).
final _recentAttemptsProvider =
    FutureProvider.autoDispose.family<List<AttemptSummary>, AppModule>((ref, module) {
  return ref.watch(attemptsRepositoryProvider).listMine(module: module, limit: 100);
});

/// Liste complete des themes du module — utilisee pour afficher toutes les
/// competences/thematiques meme celles ou l'utilisateur n'a encore aucune
/// reponse (`0 / total`). Les themes seedes (5 civique, 3 TCF) ne bougent
/// pas souvent : on garde le cache autoDispose pour rafraichir au refresh.
final _allThemesProvider = FutureProvider.autoDispose.family<List<ThemeDto>, AppModule>((ref, module) {
  return ref.watch(themesRepositoryProvider).list(module: module);
});

/// Submissions EE + EO du user, agregees par epreuve. Sert a afficher
/// Expression ecrite / Expression orale comme competences additionnelles
/// dans la liste TCF "Par competence" (pas de notion de theme cote backend
/// pour ces epreuves : on a juste des productions notees par l'IA).
final _productionStatsProvider =
    FutureProvider.autoDispose<Map<EpreuveType, _ProductionCompetenceStats>>((ref) async {
  final repo = ref.watch(productionRepositoryProvider);
  final results = await Future.wait([
    repo.listMine(epreuve: EpreuveType.tcfEe, limit: 100),
    repo.listMine(epreuve: EpreuveType.tcfEo, limit: 100),
  ]);
  return {
    EpreuveType.tcfEe: _ProductionCompetenceStats.fromSubmissions(results[0]),
    EpreuveType.tcfEo: _ProductionCompetenceStats.fromSubmissions(results[1]),
  };
});

/// Stats agregees pour une epreuve productive : nombre de submissions notees
/// et meilleur niveau CECRL atteint. Quand `evaluatedCount == 0`, la ligne
/// affiche "A demarrer".
class _ProductionCompetenceStats {
  const _ProductionCompetenceStats({
    required this.evaluatedCount,
    required this.bestLevel,
    required this.lastLevel,
  });

  final int evaluatedCount;
  final NiveauCecrl? bestLevel;
  final NiveauCecrl? lastLevel;

  bool get hasEvaluated => evaluatedCount > 0;

  factory _ProductionCompetenceStats.fromSubmissions(
    List<ProductionSubmissionDto> subs,
  ) {
    final evaluated = subs.where((s) => s.evaluation?.niveauCecrl != null).toList();
    if (evaluated.isEmpty) {
      return const _ProductionCompetenceStats(
        evaluatedCount: 0,
        bestLevel: null,
        lastLevel: null,
      );
    }
    final byScale = [...evaluated]..sort(
        (a, b) => b.evaluation!.niveauCecrl!.scaleIndex.compareTo(a.evaluation!.niveauCecrl!.scaleIndex),
      );
    final byDate = [...evaluated]..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return _ProductionCompetenceStats(
      evaluatedCount: evaluated.length,
      bestLevel: byScale.first.evaluation!.niveauCecrl,
      lastLevel: byDate.first.evaluation!.niveauCecrl,
    );
  }
}

void _showProgressPaywall(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.42),
    builder: (_) => const _ProgressPaywallSheet(),
  );
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = ref.watch(selectedModuleProvider);
    final auth = ref.watch(authControllerProvider);
    final isPremiumForModule = auth is AuthAuthenticated && auth.user.canAccessModule(module);

    final stats = ref.watch(_statsProvider(module));
    final attemptsAsync = ref.watch(_recentAttemptsProvider(module));
    final allThemesAsync = ref.watch(_allThemesProvider(module));
    final productionStatsAsync = module == AppModule.tcf ? ref.watch(_productionStatsProvider) : null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_statsProvider(module));
            ref.invalidate(_progressionProvider(module));
            ref.invalidate(_recentAttemptsProvider(module));
            ref.invalidate(_allThemesProvider(module));
            if (module == AppModule.tcf) {
              ref.invalidate(_productionStatsProvider);
            }
          },
          color: AppColors.blue,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const _TopBar(),
              const SizedBox(height: 14),
              const _ModuleTabs(),
              const SizedBox(height: 18),
              if (!isPremiumForModule) ...[
                _ProgressUpsellBanner(
                  onTap: () => _showProgressPaywall(context),
                ),
                const SizedBox(height: 18),
              ],
              stats.when(
                loading: () => const _LoadingState(),
                error: (e, _) => _ErrorState(
                  message: ApiClient.toApiException(e).message,
                  onRetry: () => ref.invalidate(_statsProvider(module)),
                ),
                data: (s) => _Body(
                  stats: s,
                  attempts: attemptsAsync.valueOrNull ?? const [],
                  allThemes: allThemesAsync.valueOrNull ?? const [],
                  productionStats: productionStatsAsync?.valueOrNull ?? const {},
                  module: module,
                  isPremium: isPremiumForModule,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar + tabs
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Progression',
          style: AppFonts.jakarta(
            size: 22,
            weight: FontWeight.w800,
            color: AppColors.ink,
          ).copyWith(letterSpacing: -0.4),
        ),
      ],
    );
  }
}

/// Switch Civique / TCF stylé en segmented control sur fond blanc (calqué
/// sur la maquette). Chaque label porte la cible du user (CSP / CR / NAT
/// pour civique, A2 / B1 / B2 pour TCF) en chip mono à droite du nom.
class _ModuleTabs extends ConsumerWidget {
  const _ModuleTabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(selectedModuleProvider);
    final auth = ref.watch(authControllerProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;

    final civiqueTag = switch (user?.targetProcedure) {
      TargetProcedure.csp => 'CSP',
      TargetProcedure.cr => 'CR',
      TargetProcedure.nat => 'NAT',
      null => 'CIV',
    };
    final tcfTag = user?.targetProcedure?.tcfLevel ?? 'TCF';

    void select(AppModule m) {
      if (m == current) return;
      ref.read(selectedModuleProvider.notifier).state = m;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModuleTabBtn(
              label: 'Civique',
              tag: civiqueTag,
              active: current == AppModule.civique,
              activeColor: AppColors.blue,
              onTap: () => select(AppModule.civique),
            ),
          ),
          Expanded(
            child: _ModuleTabBtn(
              label: 'TCF',
              tag: tcfTag,
              active: current == AppModule.tcf,
              activeColor: AppColors.red,
              onTap: () => select(AppModule.tcf),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleTabBtn extends StatelessWidget {
  const _ModuleTabBtn({
    required this.label,
    required this.tag,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final String tag;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppFonts.jakarta(
                  size: 13,
                  weight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? AppColors.white : AppColors.muted,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                tag,
                style: AppFonts.mono(
                  size: 10,
                  color: active ? AppColors.white.withValues(alpha: 0.7) : AppColors.muted2,
                  letterSpacing: 0.8,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body (state with data)
// ---------------------------------------------------------------------------

class _Body extends ConsumerWidget {
  const _Body({
    required this.stats,
    required this.attempts,
    required this.allThemes,
    required this.productionStats,
    required this.module,
    required this.isPremium,
  });

  final UserStats stats;
  final List<AttemptSummary> attempts;
  final List<ThemeDto> allThemes;

  /// Stats EE/EO du user. Vide si module != TCF, ou si fetch en cours / KO.
  final Map<EpreuveType, _ProductionCompetenceStats> productionStats;
  final AppModule module;
  final bool isPremium;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Snapshot de progression calculé côté backend (cf.
    // `MeService.progressionSummary`). Tant que la requête est en cours, on
    // affiche le rendu sans hero (les autres sections fonctionnent avec
    // `stats` et `attempts`). Une fois là, on dérive le snapshot module-spé.
    final progressionAsync = ref.watch(_progressionProvider(module));
    final progression = progressionAsync.valueOrNull;
    // Fusion themes seedes + stats par theme : on garde l'ordre canonique
    // du backend (displayOrder) et on injecte les stats quand elles existent.
    // Les themes sans reponse apparaissent en 0 / questionCount.
    final themes = _mergeThemes(allThemes, stats.byTheme);

    // Pour TCF, on liste aussi EE et EO comme competences (productions
    // notees par l'IA, distinctes des thèmes QCM). Ordre fixe : EE puis EO.
    final productions = module == AppModule.tcf
        ? <({EpreuveType epreuve, _ProductionCompetenceStats stats})>[
            (
              epreuve: EpreuveType.tcfEe,
              stats: productionStats[EpreuveType.tcfEe] ??
                  const _ProductionCompetenceStats(
                    evaluatedCount: 0,
                    bestLevel: null,
                    lastLevel: null,
                  ),
            ),
            (
              epreuve: EpreuveType.tcfEo,
              stats: productionStats[EpreuveType.tcfEo] ??
                  const _ProductionCompetenceStats(
                    evaluatedCount: 0,
                    bestLevel: null,
                    lastLevel: null,
                  ),
            ),
          ]
        : const <({EpreuveType epreuve, _ProductionCompetenceStats stats})>[];

    // Cas exceptionnel : aucun theme seede (backend pas pret) ET aucun
    // attempt → on garde l'empty state historique pour guider vers le hub.
    if (themes.isEmpty && productions.isEmpty && stats.questionsAnswered == 0) {
      return const _EmptyState();
    }

    final accent = module == AppModule.civique ? AppColors.blue : AppColors.red;
    final civiqueProgress = progression?.civique;
    final tcfProgress = progression?.tcf;

    // Pour la tendance, on isole les MOCK_EXAM uniquement — le score d'un
    // lot d'entraînement n'a pas le même poids que celui d'un examen blanc,
    // les mélanger ferait mentir le graphe.
    final examAttempts = attempts.where((a) => a.type == AttemptType.mockExam).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReadinessHero(
          module: module,
          accent: accent,
          civiqueProgress: civiqueProgress,
          tcfProgress: tcfProgress,
        ),
        const SizedBox(height: 14),
        _StatsRow(
          module: module,
          civiqueProgress: civiqueProgress,
          tcfProgress: tcfProgress,
        ),
        const SizedBox(height: 22),
        _TrendCard(attempts: examAttempts, accent: accent),
        const SizedBox(height: 22),
        _SectionTitle(
          module == AppModule.tcf ? 'Par compétence' : 'Par thématique',
          hint:
              '${themes.where((t) => t.answered > 0).length + productions.where((p) => p.stats.hasEvaluated).length}'
              ' / ${themes.length + productions.length}',
        ),
        const SizedBox(height: 12),
        _ThemesCard(
          themes: themes,
          productions: productions,
          module: module,
          locked: !isPremium,
        ),
      ],
    );
  }

  /// Pour chaque theme seede, retourne le `ThemeStats` correspondant si
  /// l'utilisateur y a deja repondu, sinon un placeholder a 0 / total.
  /// Si la liste des themes seedes est vide (cas degrade), on retombe sur
  /// `stats.byTheme` tel quel pour rester resilient.
  List<ThemeStats> _mergeThemes(
    List<ThemeDto> seeded,
    List<ThemeStats> answered,
  ) {
    if (seeded.isEmpty) return answered;
    final byId = {for (final s in answered) s.themeId: s};
    final ordered = [...seeded]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return ordered
        .map((t) =>
            byId[t.id] ??
            ThemeStats(
              themeId: t.id,
              themeName: t.name,
              answered: 0,
              correct: 0,
              total: t.questionCount,
            ))
        .toList();
  }
}

// ---------------------------------------------------------------------------
// Readiness hero (gauge sur 100 + status dynamique)
// ---------------------------------------------------------------------------

class _ReadinessHero extends StatelessWidget {
  const _ReadinessHero({
    required this.module,
    required this.accent,
    required this.civiqueProgress,
    required this.tcfProgress,
  });

  final AppModule module;
  final Color accent;
  final CiviqueProgression? civiqueProgress;
  final TcfProgression? tcfProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: module == AppModule.civique
              ? const [AppColors.blue, AppColors.blueDark]
              : const [AppColors.red, AppColors.redDark],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: module == AppModule.civique
          ? (civiqueProgress == null ? const _HeroLoading() : _CiviqueHero(progress: civiqueProgress!))
          : (tcfProgress == null ? const _HeroLoading() : _TcfHero(progress: tcfProgress!)),
    );
  }
}

/// Placeholder rendu en attendant que `/api/me/progression` réponde. Garde
/// la même hauteur que le hero réel pour éviter un sursaut de layout au
/// moment où la donnée arrive.
class _HeroLoading extends StatelessWidget {
  const _HeroLoading();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 124,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation(AppColors.white.withValues(alpha: 0.8)),
          ),
        ),
      ),
    );
  }
}

/// Hero Civique : gauge basé sur le score du dernier examen blanc complet
/// /40 (vs seuil officiel 32). Si jamais tenté → état "À démarrer" avec un
/// gauge vide et un sous-titre qui guide vers le 1er examen.
class _CiviqueHero extends StatelessWidget {
  const _CiviqueHero({required this.progress});

  final CiviqueProgression progress;

  @override
  Widget build(BuildContext context) {
    final score = progress.latestScore;
    final ratio = score == null ? 0.0 : score / CiviqueProgression.defaultExamTotal;
    final (status, detail) = _statusFor(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'DERNIER EXAMEN BLANC',
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.white.withValues(alpha: 0.7),
                  letterSpacing: 1.6,
                  weight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'Seuil ${CiviqueProgression.defaultExamThreshold} / ${CiviqueProgression.defaultExamTotal}',
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.white,
                  letterSpacing: 0.8,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _GaugeCircle(
              percent: ratio,
              centerLabel: score == null ? '—' : '$score',
              subLabel: '/ ${CiviqueProgression.defaultExamTotal}',
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: AppFonts.jakarta(
                      size: 17,
                      weight: FontWeight.w700,
                      color: AppColors.white,
                    ).copyWith(letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    detail,
                    style: AppFonts.jakarta(
                      size: 12.5,
                      color: AppColors.white.withValues(alpha: 0.78),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  (String, String) _statusFor(int? score) {
    if (score == null) {
      return (
        'Pas encore tenté',
        'Passe ton 1er examen blanc pour voir où tu en es vs le seuil officiel.',
      );
    }
    final delta = score - CiviqueProgression.defaultExamThreshold;
    if (delta >= 0) {
      return (
        'Réussi',
        'Tu es au-dessus du seuil officiel. Refais 1-2 examens pour confirmer.',
      );
    }
    if (delta >= -3) {
      return (
        'À ${-delta} point${-delta > 1 ? "s" : ""} du seuil',
        'Tu y es presque — cible les thèmes faibles avant ton prochain blanc.',
      );
    }
    return (
      'En progression',
      'Travaille thème par thème, puis retente un examen blanc d\'ici 1 semaine.',
    );
  }
}

/// Hero TCF : affiche le résultat du dernier examen blanc complet
/// (TCF_COMPLET) ou une CTA pour en démarrer un.
///
/// 4 états :
/// - aucun examen passé → CTA "Passe un examen blanc"
/// - {@code IN_PROGRESS} → examen en cours, bouton "Reprendre"
/// - {@code PENDING_EVALUATIONS} → "Évaluations IA en cours"
/// - {@code COMPLETED} → badge CECRL plancher + breakdown des 4 épreuves
class _TcfHero extends StatelessWidget {
  const _TcfHero({required this.progress});

  final TcfProgression progress;

  @override
  Widget build(BuildContext context) {
    final exam = progress.lastFullExam;

    // État 1 : aucun examen blanc passé → CTA pour en démarrer un.
    if (exam == null) {
      return _TcfHeroNoExam(target: progress.targetLevel);
    }

    // États 2 & 3 : examen en cours ou évaluations IA en attente.
    if (exam.status != LastFullTcfExamStatus.completed) {
      return _TcfHeroPending(exam: exam, target: progress.targetLevel);
    }

    // État 4 : examen finalisé, on affiche le breakdown.
    return _TcfHeroCompleted(exam: exam, target: progress.targetLevel);
  }
}

/// État "aucun examen blanc complet" — CTA pour en démarrer un.
class _TcfHeroNoExam extends StatelessWidget {
  const _TcfHeroNoExam({required this.target});

  final NiveauCecrl? target;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'NIVEAU TCF IRN',
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.white.withValues(alpha: 0.7),
                  letterSpacing: 1.6,
                  weight: FontWeight.w500,
                ),
              ),
            ),
            if (target != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Cible ${target!.displayName}',
                  style: AppFonts.mono(
                    size: 10,
                    color: AppColors.white,
                    letterSpacing: 0.8,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Passe un examen blanc complet',
          style: AppFonts.jakarta(
            size: 19,
            weight: FontWeight.w800,
            color: AppColors.white,
            height: 1.2,
          ).copyWith(letterSpacing: -0.3),
        ),
        const SizedBox(height: 8),
        Text(
          'Les 4 épreuves IRN (CO, CE, EE, EO) en conditions réelles — '
          'le seul vrai indicateur de ton niveau actuel.',
          style: AppFonts.jakarta(
            size: 12.5,
            color: AppColors.white.withValues(alpha: 0.85),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        AppButton(
          label: 'Lancer un examen blanc',
          icon: Icons.play_arrow_rounded,
          variant: AppButtonVariant.primary,
          onPressed: () => context.push(AppRoutes.tcfFullExams),
        ),
      ],
    );
  }
}

/// État "examen en cours" ou "évaluations IA en attente" — badge "…",
/// status, et bouton de reprise vers le hub de progression.
class _TcfHeroPending extends StatelessWidget {
  const _TcfHeroPending({required this.exam, required this.target});

  final LastFullTcfExam exam;
  final NiveauCecrl? target;

  @override
  Widget build(BuildContext context) {
    final isInProgress = exam.status == LastFullTcfExamStatus.inProgress;
    final title = isInProgress ? 'Examen en cours' : 'Évaluations IA en cours';
    final detail = isInProgress
        ? 'Tu n\'as pas encore terminé toutes les épreuves. Reprends pour voir ton niveau.'
        : 'Les évaluations IA (EE / EO) tournent encore. Reviens dans quelques instants.';
    final cta = isInProgress ? 'Reprendre' : 'Voir l\'avancement';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'NIVEAU TCF IRN',
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.white.withValues(alpha: 0.7),
                  letterSpacing: 1.6,
                  weight: FontWeight.w500,
                ),
              ),
            ),
            if (target != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Cible ${target!.displayName}',
                  style: AppFonts.mono(
                    size: 10,
                    color: AppColors.white,
                    letterSpacing: 0.8,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _CecrlBadge(level: null),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.jakarta(
                      size: 17,
                      weight: FontWeight.w700,
                      color: AppColors.white,
                    ).copyWith(letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    detail,
                    style: AppFonts.jakarta(
                      size: 12.5,
                      color: AppColors.white.withValues(alpha: 0.78),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => context.push(
                      AppRoutes.tcfFullExamProgress.replaceFirst(':parentId', exam.attemptId),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        cta,
                        style: AppFonts.jakarta(
                          size: 12,
                          weight: FontWeight.w800,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// État "examen complet finalisé" — badge plancher + 4 mini-badges
/// (CO/CE/EE/EO) + signalement de l'épreuve qui limite si nécessaire.
class _TcfHeroCompleted extends StatelessWidget {
  const _TcfHeroCompleted({required this.exam, required this.target});

  final LastFullTcfExam exam;
  final NiveauCecrl? target;

  @override
  Widget build(BuildContext context) {
    final final_ = exam.finalLevel;
    final (status, detail) = _statusFor(final_, target);

    // Identifie l'épreuve qui limite le plancher (= celle au niveau le plus
    // bas). Utilisé pour le message "Limité par EE".
    final epreuves = <(String, NiveauCecrl?)>[
      ('CO', exam.coLevel),
      ('CE', exam.ceLevel),
      ('EE', exam.eeLevel),
      ('EO', exam.eoLevel),
    ];
    String? limitedBy;
    if (final_ != null) {
      final weak = epreuves
          .where((e) => e.$2 != null && e.$2!.scaleIndex == final_.scaleIndex)
          .map((e) => e.$1)
          .toList();
      if (weak.length < 4) {
        limitedBy = weak.join(' / ');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'NIVEAU TCF IRN',
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.white.withValues(alpha: 0.7),
                  letterSpacing: 1.6,
                  weight: FontWeight.w500,
                ),
              ),
            ),
            if (target != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Cible ${target!.displayName}',
                  style: AppFonts.mono(
                    size: 10,
                    color: AppColors.white,
                    letterSpacing: 0.8,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _CecrlBadge(level: final_),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: AppFonts.jakarta(
                      size: 17,
                      weight: FontWeight.w700,
                      color: AppColors.white,
                    ).copyWith(letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    limitedBy == null ? detail : '$detail Épreuve à renforcer : $limitedBy.',
                    style: AppFonts.jakarta(
                      size: 12.5,
                      color: AppColors.white.withValues(alpha: 0.78),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Breakdown des 4 épreuves IRN. Visuellement : 4 chips alignées.
        Row(
          children: [
            for (final e in epreuves) ...[
              Expanded(child: _EpreuveChip(label: e.$1, level: e.$2, target: target)),
              if (e != epreuves.last) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }

  (String, String) _statusFor(NiveauCecrl? level, NiveauCecrl? target) {
    if (level == null) {
      return (
        'Examen en attente',
        'Le calcul du niveau plancher est en cours.',
      );
    }
    if (target == null) {
      return (
        'Niveau plancher : ${level.displayName}',
        'Règle TCF IRN : ton niveau = le plus bas des 4 épreuves. Définis ton parcours dans le profil pour voir la cible.',
      );
    }
    final delta = level.scaleIndex - target.scaleIndex;
    if (delta >= 0) {
      return (
        'Objectif atteint',
        'Tes 4 épreuves sont à ${level.displayName} ou plus, cible ${target.displayName}.',
      );
    }
    if (delta == -1) {
      return (
        'Tu y es presque',
        'Un palier à gagner pour atteindre ${target.displayName} partout.',
      );
    }
    return (
      'En progression',
      'Vise ${target.displayName} sur chaque épreuve.',
    );
  }
}

/// Mini-chip rendant une épreuve dans le breakdown du hero TCF : libellé
/// court (CO/CE/EE/EO) + niveau atteint (ou "—" si non passée). Coloration
/// verte si le niveau atteint ≥ cible, rouge sinon.
class _EpreuveChip extends StatelessWidget {
  const _EpreuveChip({
    required this.label,
    required this.level,
    required this.target,
  });

  final String label;
  final NiveauCecrl? level;
  final NiveauCecrl? target;

  @override
  Widget build(BuildContext context) {
    final reached = level != null && target != null && level!.scaleIndex >= target!.scaleIndex;
    final bg = level == null
        ? AppColors.white.withValues(alpha: 0.08)
        : reached
            ? AppColors.white.withValues(alpha: 0.22)
            : AppColors.white.withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppFonts.mono(
              size: 9.5,
              color: AppColors.white.withValues(alpha: 0.75),
              letterSpacing: 1.2,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            level == null ? '—' : level!.displayName,
            style: AppFonts.jakarta(
              size: 13,
              weight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grand badge "B1" / "A2" / ... pour le hero TCF.
class _CecrlBadge extends StatelessWidget {
  const _CecrlBadge({required this.level});

  final NiveauCecrl? level;

  @override
  Widget build(BuildContext context) {
    final label = level == null ? '—' : (level == NiveauCecrl.a1NonAtteint ? 'A1-' : level!.displayName);
    return Container(
      width: 92,
      height: 92,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withValues(alpha: 0.14),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.3), width: 2),
      ),
      child: Text(
        label,
        style: AppFonts.jakarta(
          size: 28,
          weight: FontWeight.w800,
          color: AppColors.white,
          height: 1,
        ).copyWith(letterSpacing: -0.5),
      ),
    );
  }
}

class _GaugeCircle extends StatelessWidget {
  const _GaugeCircle({
    required this.percent,
    required this.centerLabel,
    required this.subLabel,
  });

  /// 0..1
  final double percent;
  final String centerLabel;
  final String subLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(92, 92),
            painter: _GaugePainter(progress: percent.clamp(0.0, 1.0)),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel,
                style: AppFonts.jakarta(
                  size: 28,
                  weight: FontWeight.w800,
                  color: AppColors.white,
                  height: 1,
                ).copyWith(letterSpacing: -0.5),
              ),
              const SizedBox(height: 2),
              Text(
                subLabel,
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.white.withValues(alpha: 0.7),
                  letterSpacing: 0.6,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final bg = Paint()
      ..color = AppColors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, bg);

    final fg = Paint()
      ..color = const Color(0xFFFF8A3D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    const startAngle = -1.5708; // -90°
    final sweepAngle = 6.2832 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ---------------------------------------------------------------------------
// Stats row (3 mini cards)
// ---------------------------------------------------------------------------

/// 3 stats cards alignées sur la préparation à l'examen (pas l'activité brute).
/// Module-dépendant : civique parle examens blancs / thèmes consolidés,
/// TCF parle épreuves passées / productions évaluées / meilleur score QCM.
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.module,
    required this.civiqueProgress,
    required this.tcfProgress,
  });

  final AppModule module;
  final CiviqueProgression? civiqueProgress;
  final TcfProgression? tcfProgress;

  @override
  Widget build(BuildContext context) {
    if (module == AppModule.civique) {
      // Pendant que `_progressionProvider` charge, on rend des cards
      // "neutres" (—) plutôt que de crasher — même hauteur de layout,
      // pas de sursaut au moment où la donnée arrive.
      if (civiqueProgress == null) {
        return _StatsRowSkeleton(
          accents: const [AppColors.blue, AppColors.green, AppColors.amber],
          labels: const ['Examens passés', 'Thèmes consolidés', 'Meilleur score'],
        );
      }
      final p = civiqueProgress!;
      return Row(
        children: [
          Expanded(
            child: _StatMini(
              value: '${p.fullExamCount}',
              label: 'Examens passés',
              color: AppColors.blue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatMini(
              value: '${p.themesConsolidated}/${p.themesTotal}',
              label: 'Thèmes consolidés',
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatMini(
              value: p.bestScore == null ? '—' : '${p.bestScore}/${CiviqueProgression.defaultExamTotal}',
              label: 'Meilleur score',
              color: AppColors.amber,
            ),
          ),
        ],
      );
    }
    // TCF
    if (tcfProgress == null) {
      return _StatsRowSkeleton(
        accents: const [AppColors.red, AppColors.green, AppColors.amber],
        labels: const ['Épreuves QCM', 'EE / EO évaluées', 'Meilleur QCM'],
      );
    }
    final p = tcfProgress!;
    return Row(
      children: [
        Expanded(
          child: _StatMini(
            value: '${p.qcmEpreuvesTried}/${p.qcmEpreuvesTotal}',
            label: 'Épreuves QCM',
            color: AppColors.red,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatMini(
            value: '${p.productionsEvaluated}/${p.productionsTotal}',
            label: 'EE / EO évaluées',
            color: AppColors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatMini(
            value: p.bestWeightedScore == null ? '—' : '${p.bestWeightedScore}/${p.bestWeightedMax}',
            label: 'Meilleur QCM',
            color: AppColors.amber,
          ),
        ),
      ],
    );
  }
}

/// Placeholder des 3 stats cards en attendant que `/api/me/progression`
/// réponde. Garde la même hauteur et les mêmes labels que le rendu réel
/// pour éviter un saut de layout au moment où la donnée arrive.
class _StatsRowSkeleton extends StatelessWidget {
  const _StatsRowSkeleton({required this.accents, required this.labels});

  final List<Color> accents;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < labels.length; i++) ...[
          Expanded(
            child: _StatMini(value: '—', label: labels[i], color: accents[i]),
          ),
          if (i != labels.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppFonts.jakarta(
              size: 20,
              weight: FontWeight.w800,
              color: color,
              height: 1,
            ).copyWith(letterSpacing: -0.4),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: AppFonts.mono(
              size: 9,
              color: AppColors.muted,
              letterSpacing: 1.2,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trend chart (line chart sur 7 derniers attempts finis)
// ---------------------------------------------------------------------------

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.attempts, required this.accent});

  final List<AttemptSummary> attempts;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final finished = attempts
        .where((a) => a.isFinished && a.score != null && a.totalQuestions > 0)
        .toList()
        // listMine renvoie DESC — on inverse pour avoir le plus ancien à gauche.
        .reversed
        .toList();
    if (finished.length < 2) {
      // Pas assez de données pour tracer une tendance — on affiche un état
      // vide minimal pour ne pas mentir avec un graphe plat.
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tendance · examens blancs',
              style: AppFonts.jakarta(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Passe au moins 2 examens blancs pour voir ta tendance.',
              style: AppFonts.jakarta(size: 11.5, color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    // Garde les 7 derniers (chronologique).
    final sample = finished.length > 7 ? finished.sublist(finished.length - 7) : finished;
    final percents = sample.map((a) => (a.score! / a.totalQuestions).clamp(0.0, 1.0)).toList();
    final last = percents.last;
    final first = percents.first;
    final deltaPts = ((last - first) * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tendance · examens blancs',
                      style: AppFonts.jakarta(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${sample.length} derniers passages',
                      style: AppFonts.jakarta(
                        size: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: deltaPts >= 0
                      ? AppColors.green.withValues(alpha: 0.12)
                      : AppColors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${deltaPts >= 0 ? "↑ +" : "↓ "}$deltaPts pts',
                  style: AppFonts.mono(
                    size: 11,
                    color: deltaPts >= 0 ? AppColors.green : AppColors.red,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: CustomPaint(
              painter: _TrendPainter(percents: percents, accent: accent),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.percents, required this.accent});

  final List<double> percents;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (percents.length < 2) return;
    final padding = 6.0;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;

    // Ligne seuil à 80% (32/40) — ligne pointillée.
    final thresholdY = padding + h * (1 - 0.8);
    final dashPaint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    double x = padding;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, thresholdY),
        Offset(x + 4, thresholdY),
        dashPaint,
      );
      x += 8;
    }

    // Polyligne.
    final path = Path();
    final fillPath = Path();
    for (int i = 0; i < percents.length; i++) {
      final px = padding + (w * (i / (percents.length - 1)));
      final py = padding + (h * (1 - percents[i].clamp(0.0, 1.0)));
      if (i == 0) {
        path.moveTo(px, py);
        fillPath.moveTo(px, size.height);
        fillPath.lineTo(px, py);
      } else {
        path.lineTo(px, py);
        fillPath.lineTo(px, py);
      }
    }
    fillPath.lineTo(size.width - padding, size.height);
    fillPath.close();

    // Area gradient.
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accent.withValues(alpha: 0.18),
          accent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Ligne.
    final linePaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // Points.
    for (int i = 0; i < percents.length; i++) {
      final px = padding + (w * (i / (percents.length - 1)));
      final py = padding + (h * (1 - percents[i].clamp(0.0, 1.0)));
      final isLast = i == percents.length - 1;
      // Point blanc + bordure accent.
      canvas.drawCircle(
        Offset(px, py),
        isLast ? 5 : 3.5,
        Paint()..color = AppColors.white,
      );
      canvas.drawCircle(
        Offset(px, py),
        isLast ? 5 : 3.5,
        Paint()
          ..color = isLast ? AppColors.red : accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = isLast ? 2.5 : 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.percents != percents || oldDelegate.accent != accent;
  }
}

// ---------------------------------------------------------------------------
// Themes breakdown
// ---------------------------------------------------------------------------

class _ThemesCard extends ConsumerWidget {
  const _ThemesCard({
    required this.themes,
    required this.productions,
    required this.module,
    required this.locked,
  });

  final List<ThemeStats> themes;
  final List<({EpreuveType epreuve, _ProductionCompetenceStats stats})> productions;
  final AppModule module;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Themes QCM en haut (tries du plus faible au plus fort, non-demarres
    // a la fin). Productions EE/EO toujours en bas en ordre fixe — ce sont
    // des "competences" a part, on ne les melange pas au tri.
    final sortedThemes = _sortedByWeakest(themes);
    final hasProductions = productions.isNotEmpty;
    final totalRows = sortedThemes.length + productions.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (int i = 0; i < sortedThemes.length; i++)
            _ThemeRow(
              index: i + 1,
              theme: sortedThemes[i],
              isLast: i == totalRows - 1,
              locked: locked,
              onTap: locked
                  ? () => _showProgressPaywall(context)
                  : () => _trainTheme(context, ref, sortedThemes[i]),
            ),
          if (hasProductions)
            for (int i = 0; i < productions.length; i++)
              _ProductionRow(
                index: sortedThemes.length + i + 1,
                production: productions[i],
                isLast: sortedThemes.length + i == totalRows - 1,
                locked: locked,
                onTap: locked
                    ? () => _showProgressPaywall(context)
                    : () => _openProductionHub(context, productions[i].epreuve),
              ),
        ],
      ),
    );
  }

  void _openProductionHub(BuildContext context, EpreuveType epreuve) {
    // Le `ProductionHubScreen` a été supprimé : la sélection T1/T2/T3 vit
    // désormais sur l'onglet Tâches du détail module (`/tcf/eo` ou `/tcf/ee`).
    final route = epreuve == EpreuveType.tcfEe ? AppRoutes.tcfEeDetail : AppRoutes.tcfEoDetail;
    context.push(route);
  }

  Future<void> _trainTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeStats theme,
  ) async {
    final repo = ref.read(attemptsRepositoryProvider);
    try {
      final attempt = await repo.start(
        StartAttemptRequest(
          type: AttemptType.training,
          module: module,
          themeId: theme.themeId,
          size: 30,
        ),
      );
      if (!context.mounted) return;
      context.push(AppRoutes.runner.replaceFirst(':attemptId', attempt.id));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
          content: Text(
            ApiClient.toApiException(e).message,
            style: AppFonts.jakarta(color: AppColors.white, size: 13),
          ),
        ),
      );
    }
  }

  List<ThemeStats> _sortedByWeakest(List<ThemeStats> input) {
    final answered = input.where((t) => t.answered > 0).toList()
      ..sort((a, b) => a.mastery.compareTo(b.mastery));
    final notStarted = input.where((t) => t.answered == 0).toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return [...answered, ...notStarted];
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({
    required this.index,
    required this.theme,
    required this.isLast,
    required this.locked,
    required this.onTap,
  });

  final int index;
  final ThemeStats theme;
  final bool isLast;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasAnswered = theme.answered > 0;
    // Couverture du pool = X questions distinctes vues sur le total actif.
    final coverage = theme.progress.clamp(0.0, 1.0);
    // Précision = % de bonnes réponses sur ce que le user a tenté.
    final successRate = theme.successRate.clamp(0.0, 1.0);

    final (barColor, tagColor, tagBg, tagLabel) = _statusFor(
      hasAnswered: hasAnswered,
      coverage: coverage,
      successRate: successRate,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: AppFonts.mono(
                      size: 10,
                      color: AppColors.blue,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    theme.themeName,
                    style: AppFonts.jakarta(
                      size: 13.5,
                      weight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.25,
                    ).copyWith(letterSpacing: -0.1),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (locked)
                  const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.muted2)
                else
                  // Compteur "vues / total" du pool (couverture chiffrée).
                  // Le suffixe "vues" est explicite — sans ça le user pense
                  // que "8 / 32" = "8 bonnes réponses sur 32" (confondu avec
                  // un score), alors que c'est "8 questions distinctes
                  // touchées sur les 32 actives du thème".
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${theme.answered}',
                          style: AppFonts.mono(
                            size: 12,
                            weight: FontWeight.w700,
                            color: hasAnswered ? AppColors.ink : AppColors.muted2,
                          ),
                        ),
                        TextSpan(
                          text: ' / ${theme.total} vues',
                          style: AppFonts.mono(
                            size: 12,
                            color: AppColors.muted2,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Barre = COUVERTURE (% du pool de questions déjà vu). On a
            // séparé la qualité (badge ci-dessous) pour qu'un user qui a
            // 100 % de justesse sur 10 questions ne se voie pas afficher
            // une barre quasi vide qui le démotive.
            Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.line2,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                if (!locked && hasAnswered)
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: coverage.clamp(0.02, 1.0),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Tag status — couleur synchronisée sur la précision.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tagBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '● $tagLabel',
                    style: AppFonts.mono(
                      size: 9.5,
                      color: tagColor,
                      letterSpacing: 1.2,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Badge précision : % de bonnes réponses parmi les vues.
                if (!locked && hasAnswered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.line2,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '✓ ${(successRate * 100).round()}% justes',
                      style: AppFonts.mono(
                        size: 9.5,
                        color: AppColors.ink2,
                        letterSpacing: 1.2,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (!isLast) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.line2),
            ],
          ],
        ),
      ),
    );
  }

  /// Couleurs + label de status combinant couverture (% du pool vu) et
  /// précision (% de bonnes réponses sur ce que le user a tenté).
  ///
  /// "Maîtrisé" exige les DEUX : couverture ≥ 70 % ET précision ≥ 85 %.
  /// Sans ça, voir 1 question + la réussir = "Maîtrisé" → trompeur (le
  /// user croit avoir fini alors qu'il a vu 3 % du programme).
  ///
  /// "Bon démarrage" est introduit pour le cas spécifique "précision OK
  /// mais peu de couverture" — encourage à élargir sans dévaloriser.
  (Color, Color, Color, String) _statusFor({
    required bool hasAnswered,
    required double coverage,
    required double successRate,
  }) {
    if (!hasAnswered) {
      return (
        AppColors.muted2,
        AppColors.muted,
        AppColors.line2,
        'À démarrer',
      );
    }
    // Précision faible → priorité : la qualité doit s'améliorer avant de
    // se soucier de la couverture.
    if (successRate < 0.45) {
      return (
        AppColors.red,
        AppColors.red,
        AppColors.redLight,
        'À retravailler',
      );
    }
    if (successRate < 0.65) {
      return (
        AppColors.amber,
        const Color(0xFFB5811A),
        const Color(0xFFFDF3DD),
        'À consolider',
      );
    }
    // Précision ≥ 65 %. On regarde maintenant la couverture pour décider
    // entre "bon démarrage" (précis mais peu vu), "en progrès" (bien
    // engagé) et "maîtrisé" (couvre largement le pool avec précision haute).
    if (coverage < 0.30) {
      return (
        AppColors.blue,
        AppColors.blue,
        AppColors.blueLight,
        'Bon démarrage',
      );
    }
    if (coverage >= 0.70 && successRate >= 0.85) {
      return (
        AppColors.green,
        AppColors.green,
        const Color(0xFFE6F4ED),
        'Maîtrisé',
      );
    }
    return (
      AppColors.blue,
      AppColors.blue,
      AppColors.blueLight,
      'En progrès',
    );
  }
}

/// Ligne "competence" pour les epreuves productives EE/EO. Distincte de
/// `_ThemeRow` car ces epreuves n'ont pas de notion correct/total : on
/// affiche le nb de productions notees et le niveau CECRL atteint sur
/// une echelle A1→C2.
class _ProductionRow extends StatelessWidget {
  const _ProductionRow({
    required this.index,
    required this.production,
    required this.isLast,
    required this.locked,
    required this.onTap,
  });

  final int index;
  final ({EpreuveType epreuve, _ProductionCompetenceStats stats}) production;
  final bool isLast;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final epreuve = production.epreuve;
    final stats = production.stats;
    final label = epreuve == EpreuveType.tcfEe ? 'Expression écrite' : 'Expression orale';
    final hasEvaluated = stats.hasEvaluated;
    final level = stats.bestLevel;
    // Position du curseur sur l'echelle A1→C2 (6 paliers, index 0..5).
    final scalePct = level == null ? 0.0 : (level.scaleIndex + 1) / 6;
    final (barColor, tagColor, tagBg, tagLabel) = _statusFor(level);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.redLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: AppFonts.mono(
                      size: 10,
                      color: AppColors.red,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: AppFonts.jakarta(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: AppColors.ink,
                          height: 1.25,
                        ).copyWith(letterSpacing: -0.1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Évaluation IA',
                        style: AppFonts.mono(
                          size: 9,
                          color: AppColors.muted2,
                          letterSpacing: 1.2,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (locked)
                  const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.muted2)
                else
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${stats.evaluatedCount}',
                          style: AppFonts.mono(
                            size: 12,
                            weight: FontWeight.w700,
                            color: hasEvaluated ? AppColors.ink : AppColors.muted2,
                          ),
                        ),
                        TextSpan(
                          text: ' prod.',
                          style: AppFonts.mono(
                            size: 12,
                            color: AppColors.muted2,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Barre = position du meilleur niveau sur l'echelle A1→C2.
            // Marqueur seuil = B1 (palier de la majorite des parcours).
            Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.line2,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                if (!locked && hasEvaluated)
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: scalePct.clamp(0.05, 1.0),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: -2,
                  bottom: -2,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    // Seuil B1 = palier 3 sur 6 → 0.5.
                    widthFactor: 0.5,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tagBg,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '● $tagLabel',
                style: AppFonts.mono(
                  size: 9.5,
                  color: tagColor,
                  letterSpacing: 1.2,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            if (!isLast) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.line2),
            ],
          ],
        ),
      ),
    );
  }

  /// Couleurs + label de status selon le niveau CECRL atteint. Aucune
  /// evaluation → "À démarrer".
  (Color, Color, Color, String) _statusFor(NiveauCecrl? level) {
    if (level == null) {
      return (
        AppColors.muted2,
        AppColors.muted,
        AppColors.line2,
        'À démarrer',
      );
    }
    if (level.scaleIndex >= NiveauCecrl.b2.scaleIndex) {
      return (
        AppColors.green,
        AppColors.green,
        const Color(0xFFE6F4ED),
        level.displayName,
      );
    }
    if (level.scaleIndex >= NiveauCecrl.b1.scaleIndex) {
      return (
        AppColors.blue,
        AppColors.blue,
        AppColors.blueLight,
        level.displayName,
      );
    }
    if (level.scaleIndex >= NiveauCecrl.a2.scaleIndex) {
      return (
        AppColors.amber,
        const Color(0xFFB5811A),
        const Color(0xFFFDF3DD),
        level.displayName,
      );
    }
    return (
      AppColors.red,
      AppColors.red,
      AppColors.redLight,
      level.displayName,
    );
  }
}

// ---------------------------------------------------------------------------
// Bits divers : section title, empty/loading/error states, paywall sheet
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: AppFonts.jakarta(
            size: 16,
            weight: FontWeight.w700,
            color: AppColors.ink,
          ).copyWith(letterSpacing: -0.2),
        ),
        const Spacer(),
        if (hint != null)
          Text(
            hint!,
            style: AppFonts.mono(
              size: 10,
              color: AppColors.blue,
              letterSpacing: 1.4,
              weight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = ref.watch(selectedModuleProvider);
    final hubRoute = module == AppModule.civique ? AppRoutes.civique : AppRoutes.tcf;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: AppColors.blue,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Aucune statistique pour l\'instant',
            style: AppFonts.fraunces(
              size: 20,
              weight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Commence un entraînement et reviens ici pour voir ta progression par thématique.',
            textAlign: TextAlign.center,
            style: AppFonts.jakarta(
              size: 13,
              color: AppColors.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'Lancer un entraînement',
            icon: Icons.play_arrow_rounded,
            onPressed: () => context.go(hubRoute),
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.line2,
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              Expanded(
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              if (i != 2) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 22),
        for (var i = 0; i < 4; i++)
          Container(
            height: 76,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
          ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.red, size: 28),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppFonts.jakarta(size: 13, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _ProgressUpsellBanner extends StatelessWidget {
  const _ProgressUpsellBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.amber.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.amber,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vos stats par thème en Premium',
                      style: AppFonts.jakarta(
                        size: 13.5,
                        weight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Débloquez le détail et la révision ciblée par thématique.',
                      style: AppFonts.jakarta(
                        size: 11.5,
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.amber,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressPaywallSheet extends StatelessWidget {
  const _ProgressPaywallSheet();

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
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
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
              const SizedBox(height: 22),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.blue, AppColors.blueDark],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: AppColors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Suivez votre progression',
                textAlign: TextAlign.center,
                style: AppFonts.fraunces(size: 24, weight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'L\'accès complet révèle votre score par thématique et débloque la révision ciblée. À activer sur le web.',
                textAlign: TextAlign.center,
                style: AppFonts.jakarta(
                  size: 13,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              AppButton(
                label: 'Voir les abonnements',
                icon: Icons.open_in_new_rounded,
                variant: AppButtonVariant.primary,
                onPressed: () {
                  Navigator.of(context).pop();
                  showPaywallSheet(context);
                },
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Plus tard',
                  style: AppFonts.jakarta(size: 13, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

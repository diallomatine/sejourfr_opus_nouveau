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
import '../../core/widgets/tcf_paywall.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _statsProvider = FutureProvider.autoDispose.family<UserStats, AppModule>((ref, module) {
  return ref.watch(userContentRepositoryProvider).stats(module: module);
});

/// Derniers attempts du user pour ce module — sert au graphe de tendance
/// (score sur 7 derniers jours) et à la heatmap d'activité (28 jours).
final _recentAttemptsProvider =
    FutureProvider.autoDispose.family<List<AttemptSummary>, AppModule>((ref, module) {
  return ref.watch(attemptsRepositoryProvider).listMine(module: module, limit: 100);
});

/// Liste complete des themes du module — utilisee pour afficher toutes les
/// competences/thematiques meme celles ou l'utilisateur n'a encore aucune
/// reponse (`0 / total`). Les themes seedes (5 civique, 3 TCF) ne bougent
/// pas souvent : on garde le cache autoDispose pour rafraichir au refresh.
final _allThemesProvider =
    FutureProvider.autoDispose.family<List<ThemeDto>, AppModule>((ref, module) {
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
        (a, b) =>
            b.evaluation!.niveauCecrl!.scaleIndex.compareTo(a.evaluation!.niveauCecrl!.scaleIndex),
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
    final productionStatsAsync = module == AppModule.tcf
        ? ref.watch(_productionStatsProvider)
        : null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_statsProvider(module));
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

class _Body extends StatelessWidget {
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
  Widget build(BuildContext context) {
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

    // Score global = somme correct / somme total des thèmes du module
    // (couverture × justesse — cohérent avec les barres par thème).
    final globalCorrect = themes.fold<int>(0, (sum, t) => sum + t.correct);
    final globalTotal = themes.fold<int>(0, (sum, t) => sum + t.total);
    final mastery = globalTotal == 0 ? 0.0 : globalCorrect / globalTotal;
    final successRate = stats.questionsAnswered == 0 ? 0.0 : stats.questionsCorrect / stats.questionsAnswered;
    final accent = module == AppModule.civique ? AppColors.blue : AppColors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReadinessHero(
          mastery: mastery,
          module: module,
          accent: accent,
          themes: themes,
        ),
        const SizedBox(height: 14),
        _StatsRow(
          questions: stats.questionsAnswered,
          successRate: successRate,
          attempts: stats.attemptsTotal,
        ),
        const SizedBox(height: 22),
        _TrendCard(attempts: attempts, accent: accent),
        const SizedBox(height: 22),
        _SectionTitle(
          module == AppModule.tcf ? 'Par compétence' : 'Par thématique',
          hint: '${themes.where((t) => t.answered > 0).length + productions.where((p) => p.stats.hasEvaluated).length}'
              ' / ${themes.length + productions.length}',
        ),
        const SizedBox(height: 12),
        _ThemesCard(
          themes: themes,
          productions: productions,
          module: module,
          locked: !isPremium,
        ),
        const SizedBox(height: 22),
        _ActivityHeatmap(attempts: attempts, accent: accent),
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
    required this.mastery,
    required this.module,
    required this.accent,
    required this.themes,
  });

  final double mastery;
  final AppModule module;
  final Color accent;
  final List<ThemeStats> themes;

  @override
  Widget build(BuildContext context) {
    final score100 = (mastery * 100).round();
    // Seuil de réussite indicatif :
    //  - Civique : 32/40 sur l'examen blanc officiel.
    //  - TCF : niveau B1 = ≥ 60% sur les épreuves QCM (règle interne app).
    final thresholdLabel = module == AppModule.civique ? 'Seuil : 32 / 40' : 'Niveau visé : B1+';

    final notStarted = themes.where((t) => t.answered == 0).length;
    final weak = themes.where((t) => t.answered > 0 && t.mastery < 0.6).length;
    final toConsolidate = notStarted + weak;

    final (status, detail) = _statusFor(mastery, toConsolidate);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'NIVEAU DE PRÉPARATION',
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
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    thresholdLabel,
                    style: AppFonts.mono(
                      size: 10,
                      color: AppColors.white,
                      letterSpacing: 0.8,
                      weight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _GaugeCircle(percent: mastery, value: score100),
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
      ),
    );
  }

  (String, String) _statusFor(double mastery, int toConsolidate) {
    if (mastery >= 0.85) {
      return (
        'Prêt pour l\'examen',
        'Tu maîtrises bien le programme. Continue 10 min / jour pour rester au top.',
      );
    }
    if (mastery >= 0.7) {
      final extra = toConsolidate == 0
          ? 'Encore quelques sessions pour sécuriser ton niveau.'
          : 'Encore $toConsolidate thème${toConsolidate > 1 ? "s" : ""} '
              'à consolider pour passer l\'examen sereinement.';
      return ('Tu y es presque', extra);
    }
    if (mastery >= 0.4) {
      return (
        'En progression',
        'Reviens sur les thèmes faibles et enchaîne les lots pour gagner en régularité.',
      );
    }
    return (
      'À démarrer',
      'Commence par 1 thème par jour et passe un examen blanc en fin de semaine.',
    );
  }
}

class _GaugeCircle extends StatelessWidget {
  const _GaugeCircle({required this.percent, required this.value});

  /// 0..1
  final double percent;
  final int value;

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
                '$value',
                style: AppFonts.jakarta(
                  size: 28,
                  weight: FontWeight.w800,
                  color: AppColors.white,
                  height: 1,
                ).copyWith(letterSpacing: -0.5),
              ),
              const SizedBox(height: 2),
              Text(
                '/ 100',
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.questions,
    required this.successRate,
    required this.attempts,
  });

  final int questions;
  final double successRate;
  final int attempts;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatMini(
            value: '$questions',
            label: 'Questions',
            color: AppColors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatMini(
            value: '${(successRate * 100).round()}%',
            label: 'Réussite',
            color: AppColors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatMini(
            value: '$attempts',
            label: 'Sessions',
            color: AppColors.amber,
          ),
        ),
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
              'Score moyen · derniers attempts',
              style: AppFonts.jakarta(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Au moins 2 sessions finies pour voir la tendance.',
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
                      'Score · derniers attempts',
                      style: AppFonts.jakarta(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${sample.length} sessions',
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
    final route = epreuve == EpreuveType.tcfEe
        ? AppRoutes.tcfEeDetail
        : AppRoutes.tcfEoDetail;
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
    final pct = theme.mastery.clamp(0.0, 1.0);

    final (barColor, tagColor, tagBg, tagLabel) = _statusFor(
      hasAnswered: hasAnswered,
      mastery: pct,
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
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: hasAnswered ? '${theme.correct}' : '0',
                          style: AppFonts.mono(
                            size: 12,
                            weight: FontWeight.w700,
                            color: hasAnswered ? AppColors.ink : AppColors.muted2,
                          ),
                        ),
                        TextSpan(
                          text: ' / ${theme.total}',
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
            // Barre + marqueur de seuil à 80%.
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
                    widthFactor: pct.clamp(0.02, 1.0),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                // Marqueur seuil à 80%.
                Positioned(
                  left: 0,
                  right: 0,
                  top: -2,
                  bottom: -2,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.8,
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

  /// Couleurs + label de status selon le ratio de maîtrise. Pas démarré
  /// → "À démarrer" en muted.
  (Color, Color, Color, String) _statusFor({
    required bool hasAnswered,
    required double mastery,
  }) {
    if (!hasAnswered) {
      return (
        AppColors.muted2,
        AppColors.muted,
        AppColors.line2,
        'À démarrer',
      );
    }
    if (mastery >= 0.8) {
      return (
        AppColors.green,
        AppColors.green,
        const Color(0xFFE6F4ED),
        'Maîtrisé',
      );
    }
    if (mastery >= 0.6) {
      return (
        AppColors.blue,
        AppColors.blue,
        AppColors.blueLight,
        'En progrès',
      );
    }
    if (mastery >= 0.4) {
      return (
        AppColors.amber,
        const Color(0xFFB5811A),
        const Color(0xFFFDF3DD),
        'À consolider',
      );
    }
    return (
      AppColors.red,
      AppColors.red,
      AppColors.redLight,
      'À retravailler',
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
// Heatmap (28 derniers jours d'activité, basé sur attempts.startedAt)
// ---------------------------------------------------------------------------

class _ActivityHeatmap extends StatelessWidget {
  const _ActivityHeatmap({required this.attempts, required this.accent});

  final List<AttemptSummary> attempts;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    // Compte des sessions par jour sur les 28 derniers jours (cellule 0 = il
    // y a 27 jours, cellule 27 = aujourd'hui).
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final counts = List<int>.filled(28, 0);
    for (final a in attempts) {
      final d = DateTime(a.startedAt.year, a.startedAt.month, a.startedAt.day);
      final daysAgo = today.difference(d).inDays;
      if (daysAgo >= 0 && daysAgo < 28) {
        counts[27 - daysAgo]++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Activité · 4 dernières semaines',
                style: AppFonts.jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppColors.ink,
                ).copyWith(letterSpacing: -0.1),
              ),
              const Spacer(),
              Text(
                '28 J',
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.muted,
                  letterSpacing: 1.0,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 14,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: 28,
            itemBuilder: (_, i) {
              final level = _level(counts[i]);
              return Container(
                decoration: BoxDecoration(
                  color: _cellColor(level),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Moins',
                style: AppFonts.mono(
                  size: 9,
                  color: AppColors.muted,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 6),
              for (final l in [0, 1, 2, 3, 4]) ...[
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 3),
                  decoration: BoxDecoration(
                    color: _cellColor(l),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Text(
                'Plus',
                style: AppFonts.mono(
                  size: 9,
                  color: AppColors.muted,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _level(int count) {
    if (count == 0) return 0;
    if (count == 1) return 1;
    if (count == 2) return 2;
    if (count <= 4) return 3;
    return 4;
  }

  Color _cellColor(int level) {
    switch (level) {
      case 0:
        return AppColors.line2;
      case 1:
        return const Color(0xFFD6DDF1);
      case 2:
        return const Color(0xFF8DA0D6);
      case 3:
        return const Color(0xFF4F6BBC);
      case 4:
        return AppColors.blue;
      default:
        return AppColors.line2;
    }
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
                label: 'Gérer mon accès sur le web',
                icon: Icons.open_in_new_rounded,
                variant: AppButtonVariant.primary,
                onPressed: () async {
                  Navigator.of(context).pop();
                  await openSubscriptionWeb(context);
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

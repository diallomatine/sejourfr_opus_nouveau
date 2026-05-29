import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/eyebrow.dart';
import '../civique/civique_full_exams_screen.dart'
    show civiqueGlobalExamsProvider;
import '../module_detail/civique_hub_data.dart'
    show civiqueThemeExamsHistoryProvider;
import '../module_detail/qcm_hub_data.dart' show qcmExamsHistoryProvider;
import '../module_detail/tcf_full_exams_screen.dart'
    show fullExamsHistoryProvider;

/// Provider qui charge l'attempt finalisé (avec ses questions + corrections).
final examAttemptProvider =
    FutureProvider.autoDispose.family<Attempt, String>((ref, id) {
  return ref.watch(attemptsRepositoryProvider).getById(id);
});

class ExamResultScreen extends ConsumerStatefulWidget {
  const ExamResultScreen({super.key, required this.attemptId});

  final String attemptId;

  @override
  ConsumerState<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends ConsumerState<ExamResultScreen> {
  // Capturé tant que le context est vivant : `ref` n'est plus utilisable dans
  // `dispose()` (Riverpod assert l'élément déjà démonté). On passe par le
  // container pour invalider au démontage.
  late final ProviderContainer _container;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context, listen: false);
  }

  @override
  void dispose() {
    // Au pop / démontage : invalide les caches d'historique d'examens. Comme
    // le runner fait un `pushReplacement` vers cet écran, l'écran liste qui
    // a lancé l'examen reste mounted en dessous — sans invalidation, on
    // retombe dessus avec ses anciennes données et la note du nouvel examen
    // n'apparaît pas (il faut tirer pour rafraîchir).
    //
    // On invalide les 4 listes possibles (civique global, civique par thème,
    // TCF QCM par épreuve, TCF complet). Pour les family providers, sans
    // argument, invalide TOUTES les instances — exactement ce qu'on veut
    // puisqu'on ne connaît pas la clé d'origine ici.
    _container.invalidate(civiqueGlobalExamsProvider);
    _container.invalidate(civiqueThemeExamsHistoryProvider);
    _container.invalidate(qcmExamsHistoryProvider);
    _container.invalidate(fullExamsHistoryProvider);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(examAttemptProvider(widget.attemptId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      // Retour contextuel : on pop si possible (revient à l'écran qui a
      // lancé l'examen — liste examens, hub, historique). Le runner fait un
      // `pushReplacement` vers cet écran pour préserver la stack. Fallback
      // home si la stack a été reset (deep link direct).
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Text(
          'Résultat',
          style: AppFonts.jakarta(size: 16, weight: FontWeight.w700),
        ),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: ApiClient.toApiException(e).message,
          onRetry: () => ref.invalidate(examAttemptProvider(widget.attemptId)),
        ),
        data: (attempt) => _ResultView(attempt: attempt),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.attempt});

  final Attempt attempt;

  @override
  Widget build(BuildContext context) {
    final score = attempt.score ?? 0;
    final total = attempt.totalQuestions;
    final threshold = attempt.passThreshold;
    final passed = threshold != null && score >= threshold;
    final percent = total == 0 ? 0 : ((score / total) * 100).round();
    final errors = total - score;

    final duration = attempt.finishedAt != null
        ? attempt.finishedAt!.difference(attempt.startedAt)
        : null;

    final breakdown = _computeBreakdown(attempt);

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                _Hero(
                  attempt: attempt,
                  passed: passed,
                  score: score,
                  total: total,
                  threshold: threshold,
                ),
                const SizedBox(height: 18),
                _StatsRow(
                  percent: percent,
                  durationMinutes: duration == null ? null : duration.inMinutes,
                  errors: errors,
                ),
                const SizedBox(height: 24),
                const Eyebrow('§ Détail par thématique'),
                const SizedBox(height: 12),
                if (breakdown.isEmpty)
                  _emptyBreakdownCard()
                else
                  ...breakdown.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BreakdownItem(item: b),
                      )),
              ],
            ),
          ),
          _BottomActions(
            attempt: attempt,
            errors: errors,
          ),
        ],
      ),
    );
  }

  Widget _emptyBreakdownCard() => AppCard(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Pas de détail disponible',
            style: AppFonts.jakarta(color: AppColors.muted, size: 13),
          ),
        ),
      );

  static List<_ThemeBreakdown> _computeBreakdown(Attempt attempt) {
    final map = <String, _ThemeBreakdown>{};
    for (final aq in attempt.questions) {
      final themeName = aq.question.themeName;
      final themeId = aq.question.themeId;
      final key = themeId;
      final existing = map[key];
      final isCorrect = aq.correct == true;
      if (existing == null) {
        map[key] = _ThemeBreakdown(
          themeName: themeName,
          correct: isCorrect ? 1 : 0,
          total: 1,
        );
      } else {
        map[key] = _ThemeBreakdown(
          themeName: existing.themeName,
          correct: existing.correct + (isCorrect ? 1 : 0),
          total: existing.total + 1,
        );
      }
    }
    return map.values.toList();
  }
}

class _ThemeBreakdown {
  const _ThemeBreakdown({
    required this.themeName,
    required this.correct,
    required this.total,
  });

  final String themeName;
  final int correct;
  final int total;

  double get ratio => total == 0 ? 0 : correct / total;

  bool get isMedium => ratio >= 0.6 && ratio < 0.8;

  bool get isLow => ratio < 0.6;
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero({
    required this.attempt,
    required this.passed,
    required this.score,
    required this.total,
    required this.threshold,
  });

  final Attempt attempt;
  final bool passed;
  final int score;
  final int total;
  final int? threshold;

  @override
  Widget build(BuildContext context) {
    // En TCF, on remplace la mécanique réussi/raté par une restitution du
    // niveau CECRL atteint (calculé côté backend à partir des taux par strate).
    if (attempt.isTcf) {
      return _TcfHero(attempt: attempt, score: score, total: total);
    }
    return _CiviqueHero(
      attempt: attempt,
      passed: passed,
      score: score,
      total: total,
      threshold: threshold,
    );
  }
}

class _CiviqueHero extends StatelessWidget {
  const _CiviqueHero({
    required this.attempt,
    required this.passed,
    required this.score,
    required this.total,
    required this.threshold,
  });

  final Attempt attempt;
  final bool passed;
  final int score;
  final int total;
  final int? threshold;

  @override
  Widget build(BuildContext context) {
    final isExam = attempt.isMockExam;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      color: AppColors.white,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: passed
                  ? AppColors.green.withValues(alpha: 0.12)
                  : AppColors.redLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              passed ? Icons.emoji_events : Icons.refresh,
              size: 32,
              color: passed ? AppColors.green : AppColors.red,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _eyebrow(attempt),
            textAlign: TextAlign.center,
            style: AppFonts.mono(
              size: 10,
              color: AppColors.muted,
              letterSpacing: 1.8,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$score',
                  style: AppFonts.fraunces(
                    size: 64,
                    weight: FontWeight.w700,
                    height: 1.0,
                    letterSpacing: -2,
                  ),
                ),
                TextSpan(
                  text: ' / $total',
                  style: AppFonts.fraunces(
                    size: 22,
                    weight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            passed
                ? (isExam ? 'Réussite confirmée' : 'Session terminée')
                : 'Pas encore',
            style: AppFonts.jakarta(
              size: 15,
              weight: FontWeight.w700,
              color: passed ? AppColors.green : AppColors.red,
            ),
          ),
          if (threshold != null) ...[
            const SizedBox(height: 4),
            Text(
              passed
                  ? 'Seuil officiel : $threshold/$total · vous êtes au-dessus de la barre'
                  : 'Seuil officiel : $threshold/$total · il manque ${(threshold ?? 0) - score} bonnes réponses',
              textAlign: TextAlign.center,
              style: AppFonts.jakarta(
                size: 12,
                color: AppColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _eyebrow(Attempt a) {
    final mod = a.module == AppModule.civique ? 'Civique' : 'TCF';
    final label = a.isMockExam ? 'Examen blanc' : 'Entraînement';
    return '$label · $mod';
  }
}

class _TcfHero extends StatelessWidget {
  const _TcfHero({
    required this.attempt,
    required this.score,
    required this.total,
  });

  final Attempt attempt;
  final int score;
  final int total;

  @override
  Widget build(BuildContext context) {
    final level = attempt.levelAchieved;
    final percent = total == 0 ? 0 : ((score / total) * 100).round();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      color: AppColors.white,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.translate_rounded,
              size: 30,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'TCF IRN · Diagnostic',
            textAlign: TextAlign.center,
            style: AppFonts.mono(
              size: 10,
              color: AppColors.muted,
              letterSpacing: 1.8,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Text(
            'Votre niveau estimé',
            style: AppFonts.jakarta(size: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          Text(
            level?.wire ?? '< A2',
            style: AppFonts.fraunces(
              size: 64,
              weight: FontWeight.w700,
              height: 1.0,
              letterSpacing: -2,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            level == null
                ? 'Vous n\'atteignez pas encore le seuil A2. Continuez à vous entraîner.'
                : _messageFor(level),
            textAlign: TextAlign.center,
            style: AppFonts.jakarta(
              size: 13,
              color: AppColors.ink2,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$score/$total bonnes réponses · $percent %',
            style: AppFonts.jakarta(
              size: 12,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  String _messageFor(TargetLevel level) {
    switch (level) {
      case TargetLevel.a2:
        return 'A2 ouvre l\'accès à la carte de séjour (CSP). Visez B1 pour la carte de résident.';
      case TargetLevel.b1:
        return 'B1 est requis pour la carte de résident. Visez B2 pour la naturalisation.';
      case TargetLevel.b2:
        return 'B2 est le niveau requis pour la naturalisation. Bravo, vous y êtes.';
    }
  }
}

// ---------------------------------------------------------------------------
// Stats
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.percent,
    required this.durationMinutes,
    required this.errors,
  });

  final int percent;
  final int? durationMinutes;
  final int errors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: '$percent',
            suffix: '%',
            label: 'Taux',
            color: AppColors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: durationMinutes != null ? '$durationMinutes' : '—',
            suffix: durationMinutes != null ? 'min' : '',
            label: 'Durée',
            color: AppColors.ink,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: '$errors',
            suffix: '',
            label: 'Erreurs',
            color: errors > 0 ? AppColors.red : AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.suffix,
    required this.label,
    required this.color,
  });

  final String value;
  final String suffix;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppFonts.fraunces(
                    size: 26,
                    weight: FontWeight.w700,
                    color: color,
                    height: 1.0,
                  ),
                ),
                if (suffix.isNotEmpty)
                  TextSpan(
                    text: suffix,
                    style: AppFonts.jakarta(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppFonts.mono(
              size: 9,
              color: AppColors.muted,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Breakdown par thème
// ---------------------------------------------------------------------------

class _BreakdownItem extends StatelessWidget {
  const _BreakdownItem({required this.item});

  final _ThemeBreakdown item;

  @override
  Widget build(BuildContext context) {
    Color fillColor;
    if (item.isLow) {
      fillColor = AppColors.red;
    } else if (item.isMedium) {
      fillColor = AppColors.amber;
    } else {
      fillColor = AppColors.green;
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.themeName,
                  style: AppFonts.jakarta(
                    size: 13,
                    weight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${item.correct}/${item.total}',
                style: AppFonts.mono(
                  size: 11,
                  color: AppColors.muted,
                  letterSpacing: 0.5,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: item.ratio,
              minHeight: 5,
              backgroundColor: AppColors.line2,
              valueColor: AlwaysStoppedAnimation(fillColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Boutons du bas — Rapport détaillé + Retour accueil
// ---------------------------------------------------------------------------

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.attempt, required this.errors});

  final Attempt attempt;
  final int errors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        children: [
          // Rapport détaillé : ouvre l'écran qui montre TOUTES les questions
          // de cet examen avec corrections, filtrables (tout / erreurs / justes).
          AppButton(
            label: errors > 0
                ? 'Voir le rapport détaillé ($errors erreur${errors > 1 ? 's' : ''})'
                : 'Voir le rapport détaillé',
            icon: Icons.description_outlined,
            onPressed: () => context.push(
              AppRoutes.examReport.replaceFirst(':attemptId', attempt.id),
            ),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Retour',
            variant: AppButtonVariant.secondary,
            // Pop si possible (revient à la liste d'examens / l'écran qui a
            // lancé le runner — préservé grâce au pushReplacement côté runner,
            // cf. `RunnerScreen._navigateToResult`). Fallback accueil si la
            // stack a été reset (deep link direct sur cet écran).
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Erreur
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: AppColors.red, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.jakarta(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Réessayer',
              variant: AppButtonVariant.secondary,
              fullWidth: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

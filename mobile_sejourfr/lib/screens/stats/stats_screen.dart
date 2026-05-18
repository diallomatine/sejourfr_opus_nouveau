import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/api/user_content_repository.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/eyebrow.dart';
import '../../core/widgets/tcf_paywall.dart';
import '../home/widgets/module_switch.dart';

void _showProgressPaywall(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.42),
    builder: (_) => const _ProgressPaywallSheet(),
  );
}

final _statsProvider = FutureProvider.autoDispose<UserStats>((ref) {
  final module = ref.watch(selectedModuleProvider);
  return ref.watch(userContentRepositoryProvider).stats(module: module);
});

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(_statsProvider);
    final module = ref.watch(selectedModuleProvider);
    final auth = ref.watch(authControllerProvider);
    // Premium pour CE module : règle identique aux écrans training/exam.
    // Sans accès payant, l'utilisateur voit quand même ses stats (issues de la
    // démo) et un upsell pour passer à la formule du module en question.
    final isPremiumForModule = auth is AuthAuthenticated &&
        auth.user.canAccessModule(module);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(_statsProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const Eyebrow('Progression'),
              const SizedBox(height: 10),
              Text(
                'Vos forces et axes de travail',
                style: AppFonts.fraunces(
                  size: 28,
                  weight: FontWeight.w600,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Suivez votre réussite par thématique pour cibler ce qu\'il reste à retravailler.',
                style: AppFonts.jakarta(
                  size: 13.5,
                  color: AppColors.muted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              const ModuleSwitch(),
              if (!isPremiumForModule) ...[
                const SizedBox(height: 18),
                _ProgressUpsellBanner(
                  onTap: () => _showProgressPaywall(context),
                ),
              ],
              const SizedBox(height: 22),
              stats.when(
                loading: () => const _LoadingState(),
                error: (e, _) => _ErrorState(
                  message: ApiClient.toApiException(e).message,
                  onRetry: () => ref.invalidate(_statsProvider),
                ),
                data: (s) => _StatsContent(
                  stats: s,
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

class _StatsContent extends StatelessWidget {
  const _StatsContent({
    required this.stats,
    required this.module,
    required this.isPremium,
  });

  final UserStats stats;
  final AppModule module;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    if (stats.questionsAnswered == 0) {
      return const _EmptyState();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GlobalCard(stats: stats),
        const SizedBox(height: 22),
        _SectionLabel(
          module == AppModule.tcf ? 'Par compétence' : 'Par thématique',
          hint: isPremium ? '${stats.byTheme.length}' : 'verrouillé',
        ),
        const SizedBox(height: 12),
        for (final theme in _sortedByWeakest(stats.byTheme))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ThemeBar(
              theme: theme,
              module: module,
              locked: !isPremium,
            ),
          ),
      ],
    );
  }

  /// Trie pour mettre en haut les thèmes les moins maîtrisés (et déjà tentés),
  /// puis les non commencés. C'est ce que l'utilisateur doit retravailler — un
  /// thème jamais touché ou plein d'erreurs remonte avant un thème déjà bien
  /// avancé.
  List<ThemeStats> _sortedByWeakest(List<ThemeStats> input) {
    final answered = input.where((t) => t.answered > 0).toList()
      ..sort((a, b) => a.mastery.compareTo(b.mastery));
    final notStarted = input.where((t) => t.answered == 0).toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return [...answered, ...notStarted];
  }
}

class _GlobalCard extends StatelessWidget {
  const _GlobalCard({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final pct = (stats.successRate * 100).round();
    final accent = _pctColor(stats.successRate);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue, AppColors.blueDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SCORE GLOBAL',
            style: AppFonts.mono(
              size: 9,
              color: AppColors.white.withValues(alpha: 0.65),
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$pct',
                style: AppFonts.fraunces(
                  size: 56,
                  weight: FontWeight.w700,
                  color: AppColors.white,
                  height: 0.95,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 9, left: 4),
                child: Text(
                  '%',
                  style: AppFonts.fraunces(
                    size: 22,
                    weight: FontWeight.w600,
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _pctLabel(stats.successRate),
                  style: AppFonts.mono(
                    size: 9,
                    color: AppColors.white,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(99),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: stats.successRate.clamp(0.02, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Questions',
                  value: '${stats.questionsAnswered}',
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: AppColors.white.withValues(alpha: 0.18),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Bonnes',
                  value: '${stats.questionsCorrect}',
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: AppColors.white.withValues(alpha: 0.18),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Sessions',
                  value: '${stats.attemptsTotal}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppFonts.fraunces(
            size: 22,
            weight: FontWeight.w700,
            color: AppColors.white,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: AppFonts.mono(
            size: 9,
            color: AppColors.white.withValues(alpha: 0.65),
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ThemeBar extends ConsumerWidget {
  const _ThemeBar({
    required this.theme,
    required this.module,
    required this.locked,
  });

  final ThemeStats theme;
  final AppModule module;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAnswered = theme.answered > 0;
    // Score de maîtrise : reflète à la fois la couverture (avoir vu les
    // questions) et la justesse (les avoir réussies). Un seul examen blanc
    // avec 2 questions du thème ne donne plus 100%, mais 2/total.
    final pct = (theme.mastery * 100).round();
    final accent = hasAnswered ? _pctColor(theme.mastery) : AppColors.muted2;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: locked ? () => _showProgressPaywall(context) : () => _trainThisTheme(context, ref),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      theme.themeName,
                      style: AppFonts.jakarta(
                        size: 14,
                        weight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (locked)
                    const _LockedValue(width: 44, height: 18)
                  else if (hasAnswered)
                    Text(
                      '$pct%',
                      style: AppFonts.fraunces(
                        size: 18,
                        weight: FontWeight.w700,
                        color: accent,
                        height: 1.0,
                      ),
                    )
                  else
                    Text(
                      '—',
                      style: AppFonts.mono(
                        size: 12,
                        color: AppColors.muted2,
                        letterSpacing: 1.2,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.line2,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: locked
                    ? null
                    : FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: hasAnswered ? theme.mastery.clamp(0.02, 1.0) : 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      locked
                          ? '${theme.total} disponibles'
                          : hasAnswered
                              ? '${theme.correct} / ${theme.total} maîtrisées · ${theme.answered} tentées'
                              : 'Pas encore abordé · ${theme.total} disponibles',
                      style: AppFonts.jakarta(
                        size: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (locked)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Retravailler',
                          style: AppFonts.jakarta(
                            size: 11.5,
                            weight: FontWeight.w700,
                            color: AppColors.muted2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.lock_rounded,
                          size: 12,
                          color: AppColors.muted2,
                        ),
                      ],
                    )
                  else
                    Text(
                      hasAnswered ? 'Retravailler →' : 'Commencer →',
                      style: AppFonts.jakarta(
                        size: 11.5,
                        weight: FontWeight.w700,
                        color: AppColors.blue,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _trainThisTheme(BuildContext context, WidgetRef ref) async {
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
}

class _LockedValue extends StatelessWidget {
  const _LockedValue({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.line2,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title, {this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: AppFonts.jakarta(size: 14, weight: FontWeight.w800),
        ),
        if (hint != null) ...[
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Text(
              hint!,
              style: AppFonts.jakarta(size: 11.5, color: AppColors.muted2),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
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
            'Commencez un entraînement et revenez ici pour voir votre progression par thématique.',
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
            onPressed: () => context.go(AppRoutes.trainingSetup),
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
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 22),
        for (var i = 0; i < 5; i++)
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

// ---------------------------------------------------------------------------
// Bandeau d'upsell + paywall sheet (mode démo)
// ---------------------------------------------------------------------------

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
                'L’accès complet révèle votre score par thématique et débloque la révision ciblée. À activer sur le web.',
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

Color _pctColor(double rate) {
  if (rate >= 0.75) return AppColors.green;
  if (rate >= 0.5) return AppColors.amber;
  return AppColors.red;
}

String _pctLabel(double rate) {
  if (rate >= 0.75) return 'BON';
  if (rate >= 0.5) return 'À CONSOLIDER';
  return 'À RETRAVAILLER';
}

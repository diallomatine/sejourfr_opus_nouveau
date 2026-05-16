import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/api/user_content_repository.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/auth_models.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/sejourfr_logo.dart';

final _civiqueStatsProvider = FutureProvider.autoDispose<UserStats>((ref) {
  return ref.watch(userContentRepositoryProvider).stats(module: AppModule.civique);
});

final _tcfStatsProvider = FutureProvider.autoDispose<UserStats>((ref) {
  return ref.watch(userContentRepositoryProvider).stats(module: AppModule.tcf);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final civiqueStats = ref.watch(_civiqueStatsProvider);
    final tcfStats = ref.watch(_tcfStatsProvider);

    void selectAndGo(AppModule module, String route) {
      ref.read(selectedModuleProvider.notifier).state = module;
      context.go(route);
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.blue,
          onRefresh: () async {
            ref.invalidate(_civiqueStatsProvider);
            ref.invalidate(_tcfStatsProvider);
            await Future.wait([
              ref.read(_civiqueStatsProvider.future),
              ref.read(_tcfStatsProvider.future),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            children: [
              _Greeting(user: user),
              const SizedBox(height: 18),
              _TargetStrip(target: user?.targetProcedure),
              const SizedBox(height: 18),
              _CiviqueHero(
                stats: civiqueStats,
                onStart: () => selectAndGo(AppModule.civique, AppRoutes.trainingSetup),
                onExam: () => selectAndGo(AppModule.civique, AppRoutes.examSetup),
                onRetry: () => ref.invalidate(_civiqueStatsProvider),
              ),
              const SizedBox(height: 12),
              _TcfCard(
                stats: tcfStats,
                // Démo TCF accessible à tous (20 Q + 1 examen blanc gratuits) ;
                // l'upsell Intégral est affiché dans les écrans setup eux-mêmes.
                isDemo: user != null && !user.canAccessModule(AppModule.tcf),
                onTraining: () => selectAndGo(AppModule.tcf, AppRoutes.trainingSetup),
                onExam: () => selectAndGo(AppModule.tcf, AppRoutes.examSetup),
              ),
              const SizedBox(height: 26),
              Text(
                '§ RACCOURCIS',
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.muted,
                  letterSpacing: 2.0,
                ).copyWith(height: 1.0),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ShortcutTile(
                      icon: Icons.insights_rounded,
                      title: 'Progression',
                      subtitle: 'Forces et axes\nà retravailler',
                      accent: AppColors.blue,
                      accentBg: AppColors.blueLight,
                      onTap: () => context.go(AppRoutes.progress),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ShortcutTile(
                      icon: Icons.bookmark_rounded,
                      title: 'Mes questions',
                      subtitle: 'Favoris et\nerreurs récentes',
                      accent: AppColors.red,
                      accentBg: AppColors.redLight,
                      onTap: () => context.push(AppRoutes.review),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _DailyTip(),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Greeting
// ---------------------------------------------------------------------------

class _Greeting extends StatelessWidget {
  const _Greeting({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final firstName = user?.firstName?.trim() ?? '';
    return Row(
      children: [
        const Cocarde(size: 40),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BONJOUR${firstName.isNotEmpty ? ' · ${firstName.toUpperCase()}' : ''}',
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.muted,
                  letterSpacing: 1.8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                'Préparons votre examen',
                style: AppFonts.fraunces(
                  size: 24,
                  weight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bandeau objectif (clickable pour éditer / définir)
// ---------------------------------------------------------------------------

class _TargetStrip extends StatelessWidget {
  const _TargetStrip({required this.target});

  final TargetProcedure? target;

  @override
  Widget build(BuildContext context) {
    final hasTarget = target != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          '${AppRoutes.targetPath}?from=${Uri.encodeComponent(AppRoutes.home)}',
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.blueSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.blue.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasTarget ? Icons.flag_rounded : Icons.flag_outlined,
                  size: 16,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasTarget ? 'MON OBJECTIF' : 'DÉFINIR MON OBJECTIF',
                      style: AppFonts.mono(
                        size: 9,
                        color: AppColors.muted,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasTarget
                          ? '${target!.shortLabel} · TCF ${target!.tcfLevel}'
                          : 'Adaptez les questions à votre démarche',
                      style: AppFonts.jakarta(
                        size: 13,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                hasTarget ? Icons.edit_outlined : Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero Civique (dominant)
// ---------------------------------------------------------------------------

class _CiviqueHero extends StatelessWidget {
  const _CiviqueHero({
    required this.stats,
    required this.onStart,
    required this.onExam,
    required this.onRetry,
  });

  final AsyncValue<UserStats> stats;
  final VoidCallback onStart;
  final VoidCallback onExam;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue, AppColors.blueDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              top: -36,
              right: -36,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.08),
                    width: 18,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 38,
              right: 22,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.red,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _HeroBadge(
                        label: 'EXAMEN OFFICIEL',
                        bg: AppColors.white.withValues(alpha: 0.14),
                        fg: AppColors.white,
                      ),
                      const SizedBox(width: 6),
                      const _HeroBadge(
                        label: 'RECOMMANDÉ',
                        bg: AppColors.red,
                        fg: AppColors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Examen civique',
                    style: AppFonts.fraunces(
                      size: 30,
                      weight: FontWeight.w600,
                      color: AppColors.white,
                      fontStyle: FontStyle.italic,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Valeurs, institutions et histoire de la République française.',
                    style: AppFonts.jakarta(
                      size: 13,
                      color: AppColors.white.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  stats.when(
                    loading: () => const _HeroLoader(),
                    error: (e, _) => _HeroError(
                      message: ApiClient.toApiException(e).message,
                      onRetry: onRetry,
                    ),
                    data: (s) => _HeroStats(stats: s),
                  ),
                  const SizedBox(height: 18),
                  _HeroPrimaryCta(onTap: onStart),
                  const SizedBox(height: 10),
                  _HeroSecondaryCta(onTap: onExam),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppFonts.mono(
          size: 9,
          color: fg,
          letterSpacing: 1.6,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeroStats extends StatelessWidget {
  const _HeroStats({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final percent = (stats.successRate * 100).round();
    return Row(
      children: [
        _StatTile(value: '$percent%', label: 'Réussite'),
        const SizedBox(width: 8),
        _StatTile(value: '${stats.attemptsTotal}', label: 'Sessions'),
        const SizedBox(width: 8),
        _StatTile(value: '${stats.questionsAnswered}', label: 'Questions'),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppFonts.fraunces(
                size: 22,
                weight: FontWeight.w600,
                color: AppColors.white,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: AppFonts.mono(
                size: 9,
                color: AppColors.white.withValues(alpha: 0.7),
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPrimaryCta extends StatelessWidget {
  const _HeroPrimaryCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              const Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.blue,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Commencer l\'entraînement',
                  style: AppFonts.jakarta(
                    size: 14.5,
                    weight: FontWeight.w800,
                    color: AppColors.blue,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.blue,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSecondaryCta extends StatelessWidget {
  const _HeroSecondaryCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.28),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Examen blanc · 40Q · 45 min',
                  style: AppFonts.jakarta(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.white.withValues(alpha: 0.75),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroLoader extends StatelessWidget {
  const _HeroLoader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _HeroError extends StatelessWidget {
  const _HeroError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: AppColors.white.withValues(alpha: 0.75),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppFonts.jakarta(
                size: 11.5,
                color: AppColors.white.withValues(alpha: 0.85),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'RÉESSAYER',
              style: AppFonts.mono(
                size: 9,
                color: AppColors.white,
                letterSpacing: 1.6,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte TCF (secondaire mais distincte)
// ---------------------------------------------------------------------------

class _TcfCard extends StatelessWidget {
  const _TcfCard({
    required this.stats,
    required this.onTraining,
    required this.onExam,
    this.isDemo = false,
  });

  final AsyncValue<UserStats> stats;
  final VoidCallback onTraining;
  final VoidCallback onExam;

  /// L'utilisateur n'a pas l'Intégral : il reste en mode démo (20 Q d'entraînement
  /// + 1 examen blanc gratuits). On affiche un petit badge pour le signaler ;
  /// les actions restent cliquables et redirigent vers leurs écrans setup qui
  /// portent l'upsell détaillé.
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTraining,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  size: 22,
                  color: AppColors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'TCF',
                          style: AppFonts.jakarta(
                            size: 15,
                            weight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.redLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'A2 · B1 · B2',
                            style: AppFonts.mono(
                              size: 9,
                              color: AppColors.red,
                              letterSpacing: 1.2,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isDemo) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'DÉMO',
                              style: AppFonts.mono(
                                size: 9,
                                color: AppColors.amber,
                                letterSpacing: 1.2,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Compréhension orale, écrite, structure',
                      style: AppFonts.jakarta(
                        size: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              stats.maybeWhen(
                data: (s) => s.attemptsTotal == 0
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${(s.successRate * 100).round()}%',
                            style: AppFonts.fraunces(
                              size: 18,
                              weight: FontWeight.w600,
                              color: AppColors.red,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${s.attemptsTotal} sessions',
                            style: AppFonts.mono(
                              size: 9,
                              color: AppColors.muted,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TcfSubAction(
                  icon: Icons.play_arrow_rounded,
                  label: 'Entraînement',
                  onTap: onTraining,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TcfSubAction(
                  icon: Icons.timer_outlined,
                  label: 'Examen blanc',
                  onTap: onExam,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TcfSubAction extends StatelessWidget {
  const _TcfSubAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.redLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.red.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: AppColors.red),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppFonts.jakarta(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.red,
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
// Raccourci (carte verticale en duo)
// ---------------------------------------------------------------------------

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.accentBg,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color accentBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accentBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppFonts.jakarta(size: 14, weight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppFonts.jakarta(
              size: 11.5,
              color: AppColors.muted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Astuce / Le saviez-vous
// ---------------------------------------------------------------------------

class _DailyTip extends StatelessWidget {
  const _DailyTip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_stories_outlined,
                size: 14,
                color: AppColors.blue,
              ),
              const SizedBox(width: 6),
              Text(
                'LE SAVIEZ-VOUS ?',
                style: AppFonts.mono(
                  size: 9,
                  color: AppColors.blue,
                  letterSpacing: 1.8,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '« Liberté, Égalité, Fraternité »',
            style: AppFonts.fraunces(
              size: 16,
              weight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Devise inscrite à l\'article 2 de la Constitution du 4 octobre 1958.',
            style: AppFonts.jakarta(
              size: 12,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

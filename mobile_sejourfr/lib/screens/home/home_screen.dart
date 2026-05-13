import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/api/user_content_repository.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/eyebrow.dart';
import '../../core/widgets/sejourfr_logo.dart';
import 'widgets/module_switch.dart';

// Provider qui charge les stats du module actif
final _statsProvider = FutureProvider.autoDispose<UserStats>((ref) {
  final module = ref.watch(selectedModuleProvider);
  return ref.watch(userContentRepositoryProvider).stats(module: module);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final module = ref.watch(selectedModuleProvider);
    final stats = ref.watch(_statsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(_statsProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              _Header(displayName: user?.firstName ?? user?.email ?? ''),
              const SizedBox(height: 22),
              const ModuleSwitch(),
              const SizedBox(height: 24),
              const Eyebrow('§ 01 — Votre progression'),
              const SizedBox(height: 10),
              stats.when(
                loading: () => const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _ErrorBox(
                  message: ApiClient.toApiException(e).message,
                  onRetry: () => ref.refresh(_statsProvider),
                ),
                data: (s) => _StatsCard(stats: s, module: module),
              ),
              const SizedBox(height: 28),
              const Eyebrow('§ 02 — Démarrer'),
              const SizedBox(height: 10),
              _ActionCard(
                title: 'Entraînement libre',
                subtitle: 'Choisissez un thème et un niveau',
                icon: Icons.school_outlined,
                accent: AppColors.blue,
                onTap: () => context.go(AppRoutes.trainingSetup),
              ),
              const SizedBox(height: 10),
              _ActionCard(
                title: 'Examen blanc',
                subtitle: module == AppModule.civique
                    ? '40 questions · 45 min · seuil 32/40'
                    : 'En conditions réelles',
                icon: Icons.timer_outlined,
                accent: AppColors.red,
                onTap: () => context.go(AppRoutes.examSetup),
              ),
              const SizedBox(height: 10),
              _ActionCard(
                title: 'Révision',
                subtitle: 'Erreurs récentes et favoris',
                icon: Icons.bookmark_outline,
                accent: AppColors.amber,
                onTap: () => context.go(AppRoutes.review),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.displayName});
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Cocarde(size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour${displayName.isNotEmpty ? ', $displayName' : ''}',
                style: AppFonts.jakarta(
                  size: 13,
                  color: AppColors.muted,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Continuons',
                style: AppFonts.fraunces(
                  size: 26,
                  weight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats, required this.module});

  final UserStats stats;
  final AppModule module;

  @override
  Widget build(BuildContext context) {
    final percent = (stats.successRate * 100).round();

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppTag(
                label: module == AppModule.civique ? 'Civique' : 'TCF',
                tone: module == AppModule.civique
                    ? TagTone.blue
                    : TagTone.amber,
              ),
              const Spacer(),
              Text(
                '${stats.attemptsTotal} sessions',
                style: AppFonts.mono(size: 10, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$percent',
                style: AppFonts.fraunces(
                  size: 56,
                  weight: FontWeight.w700,
                  height: 1.0,
                  letterSpacing: -2,
                ),
              ),
              Text(
                ' %',
                style: AppFonts.fraunces(
                  size: 24,
                  weight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
              const Spacer(),
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: AppColors.blue,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Taux de réussite global',
            style: AppFonts.jakarta(
              size: 12,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stats.successRate.clamp(0, 1),
              minHeight: 6,
              backgroundColor: AppColors.line2,
              valueColor: const AlwaysStoppedAnimation(AppColors.blue),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${stats.questionsCorrect} bonnes réponses sur ${stats.questionsAnswered}',
            style: AppFonts.jakarta(
              size: 12,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.jakarta(
                    size: 15,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppFonts.jakarta(
                    size: 12.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.muted2),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.red, size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppFonts.jakarta(size: 13, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Réessayer',
              style: AppFonts.jakarta(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

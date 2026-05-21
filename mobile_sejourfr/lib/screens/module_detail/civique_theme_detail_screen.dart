import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/api/user_content_repository.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/question_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/paywall_sheet.dart';
import 'widgets/module_detail_widgets.dart';

/// Pool des thèmes civique — partagé avec le hub mais on évite de l'importer
/// (pour ne pas créer un cycle si on déplace les écrans plus tard).
final _civiqueThemesProvider =
    FutureProvider.autoDispose<List<ThemeDto>>((ref) {
  return ref.watch(themesRepositoryProvider).list(module: AppModule.civique);
});

final _civiqueStatsProvider = FutureProvider.autoDispose<UserStats>((ref) {
  return ref.watch(userContentRepositoryProvider).stats(module: AppModule.civique);
});

/// Écran détail d'un thème civique. Accessible via `/civique/theme/:themeId`.
class CiviqueThemeDetailScreen extends ConsumerStatefulWidget {
  const CiviqueThemeDetailScreen({super.key, required this.themeId});

  final String themeId;

  @override
  ConsumerState<CiviqueThemeDetailScreen> createState() =>
      _CiviqueThemeDetailScreenState();
}

class _CiviqueThemeDetailScreenState
    extends ConsumerState<CiviqueThemeDetailScreen> {
  bool _starting = false;

  Future<void> _start(ThemeDto theme) async {
    if (_starting) return;
    final auth = ref.read(authControllerProvider);
    final isPremium = auth is AuthAuthenticated &&
        auth.user.canAccessModule(AppModule.civique);

    setState(() => _starting = true);
    ref.read(selectedModuleProvider.notifier).state = AppModule.civique;

    try {
      final attempt = await ref.read(attemptsRepositoryProvider).start(
            StartAttemptRequest(
              type: AttemptType.training,
              module: AppModule.civique,
              themeId: isPremium ? theme.id : null,
              size: isPremium ? kInitialBatchSize : kDemoBatchSize,
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

  @override
  Widget build(BuildContext context) {
    final themesAsync = ref.watch(_civiqueThemesProvider);
    final statsAsync = ref.watch(_civiqueStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: themesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.blue),
          ),
          error: (e, _) => _ErrorBlock(
            message: ApiClient.toApiException(e).message,
            onBack: () => context.pop(),
          ),
          data: (themes) {
            final theme = themes.where((t) => t.id == widget.themeId).firstOrNull;
            if (theme == null) {
              return _ErrorBlock(
                message: 'Thème introuvable.',
                onBack: () => context.pop(),
              );
            }

            final themeStats = statsAsync.maybeWhen(
              data: (s) =>
                  s.byTheme.where((t) => t.themeId == theme.id).firstOrNull,
              orElse: () => null,
            );
            final percent = themeStats == null
                ? 0
                : (themeStats.mastery * 100).round();
            final attempts = themeStats?.answered ?? 0;

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  children: [
                    ModuleDetailTopBar(
                      onBack: () => context.pop(),
                      icon: _iconForTheme(theme.code),
                      iconColor: AppColors.blue,
                      iconBg: AppColors.blueLight,
                    ),
                    const SizedBox(height: 22),
                    ModuleDetailTitle(
                      eyebrow: 'Module civique',
                      title: theme.name,
                    ),
                    const SizedBox(height: 22),
                    ModuleDetailHero(
                      icon: _iconForTheme(theme.code),
                      headline: '${theme.questionCount} questions au programme',
                      description: theme.description ??
                          'Questions officielles couvrant ce thème.',
                      gradient: const [AppColors.blue, AppColors.blueDark],
                    ),
                    const SizedBox(height: 16),
                    ModuleDetailStats(
                      items: [
                        (value: '${theme.questionCount}', label: 'Questions'),
                        (value: '≈ 20 min', label: 'Durée'),
                        (
                          value: _parcoursLabel(ref),
                          label: 'Parcours',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ModuleDetailScoreCard(
                      percent: percent,
                      attemptsCount: attempts,
                      accent: AppColors.blue,
                    ),
                    const SizedBox(height: 22),
                    AppButton(
                      label: 'Commencer l\'entraînement',
                      icon: Icons.play_arrow_rounded,
                      isLoading: _starting,
                      onPressed: _starting ? null : () => _start(theme),
                    ),
                  ],
                ),
                if (_starting)
                  const Positioned.fill(
                    child: ModuleDetailStartingOverlay(accent: AppColors.blue),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _parcoursLabel(WidgetRef ref) {
    final auth = ref.read(authControllerProvider);
    if (auth is! AuthAuthenticated) return 'CSP · CR · NAT';
    final target = auth.user.targetProcedure;
    return switch (target) {
      TargetProcedure.csp => 'CSP',
      TargetProcedure.cr => 'CR',
      TargetProcedure.nat => 'NAT',
      null => 'CSP · CR · NAT',
    };
  }

  IconData _iconForTheme(String code) {
    final lower = code.toLowerCase();
    if (lower.contains('principe') || lower.contains('symbole')) {
      return Icons.flag_rounded;
    }
    if (lower.contains('institution')) return Icons.account_balance_rounded;
    if (lower.contains('droit') || lower.contains('devoir')) {
      return Icons.gavel_rounded;
    }
    if (lower.contains('histoire') || lower.contains('geo')) {
      return Icons.public_rounded;
    }
    if (lower.contains('societe') || lower.contains('société')) {
      return Icons.people_alt_rounded;
    }
    return Icons.menu_book_rounded;
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.ink,
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: AppFonts.jakarta(size: 14, color: AppColors.red),
          ),
        ],
      ),
    );
  }
}

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
import '../../core/widgets/paywall_sheet.dart';
import '../hub/widgets/hub_widgets.dart';

final _civiqueThemesProvider =
    FutureProvider.autoDispose<List<ThemeDto>>((ref) {
  return ref.watch(themesRepositoryProvider).list(module: AppModule.civique);
});

final _civiqueStatsProvider = FutureProvider.autoDispose<UserStats>((ref) {
  return ref.watch(userContentRepositoryProvider).stats(module: AppModule.civique);
});

class CiviqueScreen extends ConsumerStatefulWidget {
  const CiviqueScreen({super.key});

  @override
  ConsumerState<CiviqueScreen> createState() => _CiviqueScreenState();
}

class _CiviqueScreenState extends ConsumerState<CiviqueScreen> {
  bool _starting = false;

  Future<void> _startTraining({ThemeDto? theme}) async {
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
              // En démo, le backend ignore le thème : on n'envoie rien pour
              // éviter toute confusion côté API.
              themeId: isPremium ? theme?.id : null,
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
    final auth = ref.watch(authControllerProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final themes = ref.watch(_civiqueThemesProvider);
    final stats = ref.watch(_civiqueStatsProvider);

    final target = user?.targetProcedure;
    final badgeText = switch (target) {
      TargetProcedure.csp => 'CSP',
      TargetProcedure.cr => 'CR',
      TargetProcedure.nat => 'NAT',
      null => 'CIV',
    };
    final objectiveValue = target?.shortLabel ?? 'Définis ton parcours';

    final percent = stats.maybeWhen(
      data: (s) {
        if (s.byTheme.isEmpty) return 0;
        final correct = s.byTheme.fold<int>(0, (sum, t) => sum + t.correct);
        final total = s.byTheme.fold<int>(0, (sum, t) => sum + t.total);
        return total == 0 ? 0 : ((correct / total) * 100).round();
      },
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              color: AppColors.blue,
              onRefresh: () async {
                ref.invalidate(_civiqueThemesProvider);
                ref.invalidate(_civiqueStatsProvider);
                await Future.wait([
                  ref.read(_civiqueThemesProvider.future),
                  ref.read(_civiqueStatsProvider.future),
                ]);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                children: [
                  HubTopBar(
                    badgeText: badgeText,
                    badgeColor: AppColors.blue,
                  ),
                  const SizedBox(height: 18),
                  const HubHero(
                    eyebrow: 'Examen civique',
                    titleTop: 'Prépare ton',
                    titleBottom: 'entretien citoyen',
                    description:
                        'Principes, institutions, droits et devoirs, histoire et société — toutes les questions officielles.',
                    colors: [AppColors.blue, AppColors.blueDark],
                  ),
                  const SizedBox(height: 14),
                  HubProgressCard(
                    objectiveLabel: 'Objectif actuel',
                    objectiveValue: objectiveValue,
                    percent: percent,
                    accent: AppColors.blue,
                    hint: percent == 0
                        ? 'Commence par un thème pour voir ta progression.'
                        : 'Continue 15 min aujourd\'hui pour garder ton avance.',
                  ),
                  const SizedBox(height: 22),
                  const HubSectionTitle('Modules d\'entraînement'),
                  const SizedBox(height: 12),
                  themes.when(
                    loading: () => const _ThemesLoading(),
                    error: (e, _) => _ThemesError(message: e.toString()),
                    data: (list) {
                      final sorted = [...list]
                        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
                      return Column(
                        children: [
                          for (final t in sorted)
                            HubModuleCard(
                              icon: _iconForTheme(t.code),
                              iconColor: _accentForOrder(t.displayOrder),
                              iconBg: _accentBgForOrder(t.displayOrder),
                              title: t.name,
                              description: t.description ??
                                  'Questions officielles du programme',
                              meta: '${t.questionCount} questions',
                              onTap: () => _startTraining(theme: t),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  HubExamCard(
                    title: 'Examen blanc civique',
                    subtitle:
                        'QCM en conditions réelles · ${target?.shortLabel ?? 'CSP · CR · NAT'}',
                    ctaLabel: 'Bientôt',
                    // onTap volontairement omis — branchement à venir.
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            if (_starting)
              const Positioned.fill(
                child: _StartingOverlay(),
              ),
          ],
        ),
      ),
    );
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

  Color _accentForOrder(int order) {
    switch (order % 5) {
      case 0:
      case 1:
        return AppColors.blue;
      case 2:
        return AppColors.red;
      case 3:
        return AppColors.amber;
      case 4:
        return AppColors.green;
      default:
        return AppColors.blue;
    }
  }

  Color _accentBgForOrder(int order) {
    switch (order % 5) {
      case 0:
      case 1:
        return AppColors.blueLight;
      case 2:
        return AppColors.redLight;
      case 3:
        return AppColors.amber.withValues(alpha: 0.12);
      case 4:
        return AppColors.green.withValues(alpha: 0.12);
      default:
        return AppColors.blueLight;
    }
  }
}

class _ThemesLoading extends StatelessWidget {
  const _ThemesLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.blue,
          ),
        ),
      ),
    );
  }
}

class _ThemesError extends StatelessWidget {
  const _ThemesError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.2)),
      ),
      child: Text(
        'Impossible de charger les thèmes : $message',
        style: AppFonts.jakarta(size: 12.5, color: AppColors.redDark),
      ),
    );
  }
}

class _StartingOverlay extends StatelessWidget {
  const _StartingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.ink.withValues(alpha: 0.32),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Préparation de la session…',
                style: AppFonts.jakarta(size: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

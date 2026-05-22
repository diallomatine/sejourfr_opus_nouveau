import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/repositories.dart';
import '../../core/api/user_content_repository.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/models/question_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../hub/widgets/hub_widgets.dart';

final _civiqueThemesProvider =
    FutureProvider.autoDispose<List<ThemeDto>>((ref) {
  return ref.watch(themesRepositoryProvider).list(module: AppModule.civique);
});

final _civiqueStatsProvider = FutureProvider.autoDispose<UserStats>((ref) {
  return ref.watch(userContentRepositoryProvider).stats(module: AppModule.civique);
});

class CiviqueScreen extends ConsumerWidget {
  const CiviqueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    // Couverture du programme = % des questions actives déjà tentées au
    // moins une fois. Aligné avec la barre par thème de l'écran Progression
    // qui distingue couverture (vues/total) et précision (justes/vues).
    // Une mastery agrégée correct/total mélangeait les deux et démotivait
    // les débuts (cf. discussion 2026-05-22).
    final percent = stats.maybeWhen(
      data: (s) {
        if (s.byTheme.isEmpty) return 0;
        final answered = s.byTheme.fold<int>(0, (sum, t) => sum + t.answered);
        final total = s.byTheme.fold<int>(0, (sum, t) => sum + t.total);
        return total == 0 ? 0 : ((answered / total) * 100).round();
      },
      orElse: () => 0,
    );

    // Compteurs absolus + précision globale. Le hint affiche les chiffres
    // bruts ("71/263 questions vues") plutôt qu'un second % — le pool
    // d'environ 250-300 questions de l'app fait que la barre couverture
    // monte vite en %, et un user prudent peut trouver "27 %" exagéré.
    // Les chiffres absolus collent mieux au ressenti.
    final coverageSummary = stats.maybeWhen(
      data: (s) {
        final answered = s.byTheme.fold<int>(0, (sum, t) => sum + t.answered);
        final correct = s.byTheme.fold<int>(0, (sum, t) => sum + t.correct);
        final total = s.byTheme.fold<int>(0, (sum, t) => sum + t.total);
        if (total == 0) return null;
        if (answered == 0) {
          return (answered: 0, total: total, precision: null as int?);
        }
        return (
          answered: answered,
          total: total,
          precision: (correct / answered * 100).round() as int?,
        );
      },
      orElse: () => null,
    );

    void openThemeDetail(ThemeDto theme) {
      ref.read(selectedModuleProvider.notifier).state = AppModule.civique;
      context.push(
        AppRoutes.civiqueThemeDetail.replaceFirst(':themeId', theme.id),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
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
                hint: coverageSummary == null || coverageSummary.answered == 0
                    ? 'Commence par un thème pour voir ta progression.'
                    : coverageSummary.precision == null
                        ? '${coverageSummary.answered}/${coverageSummary.total} questions vues.'
                        : '${coverageSummary.answered}/${coverageSummary.total} questions vues · '
                            '${coverageSummary.precision} % de bonnes réponses.',
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
                          onTap: () => openThemeDetail(t),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              HubExamCard(
                title: 'Examen blanc civique',
                subtitle:
                    '40 questions, 45 min · ${target?.shortLabel ?? 'CSP · CR · NAT'}',
                ctaLabel: 'Lancer',
                onTap: () {
                  ref.read(selectedModuleProvider.notifier).state =
                      AppModule.civique;
                  context.push(AppRoutes.civiqueExamsBlancs);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
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

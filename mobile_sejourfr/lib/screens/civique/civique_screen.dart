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
import '../hub/widgets/hub_home_widgets.dart';
import 'widgets/civique_mastery_card.dart';

final _civiqueThemesProvider =
    FutureProvider.autoDispose<List<ThemeDto>>((ref) {
  return ref.watch(themesRepositoryProvider).list(module: AppModule.civique);
});

final _civiqueStatsProvider = FutureProvider.autoDispose<UserStats>((ref) {
  return ref
      .watch(userContentRepositoryProvider)
      .stats(module: AppModule.civique);
});

/// Hub Civique : home en single scroll. Header titre dynamique + hero
/// examen blanc 40 Q + N thèmes (cartes verticales) + maîtrise globale.
/// Plus d'onglets — l'examen blanc complet civique reste accessible via
/// l'écran routé dédié au tap du hero (briefing + 40 Q tous thèmes).
class CiviqueScreen extends ConsumerWidget {
  const CiviqueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final target = user?.targetProcedure;
    final themesAsync = ref.watch(_civiqueThemesProvider);
    final statsAsync = ref.watch(_civiqueStatsProvider);

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
              HubHomeHeader(
                title: 'Préparer l\'examen civique',
                subtitle: _headerSubtitle(target, themesAsync),
              ),
              const SizedBox(height: 14),
              ExamBlancHero(
                eyebrow: 'Examen blanc · 40 questions',
                title: 'Simuler l\'entretien',
                description:
                    '40 questions tous thèmes, en 45 minutes. Seuil : 32/40.',
                ctaLabel: 'Voir les examens blancs',
                accent: AppColors.blueDark,
                accentLight: AppColors.blueLight,
                accentStart: AppColors.blue,
                onTap: () {
                  ref.read(selectedModuleProvider.notifier).state =
                      AppModule.civique;
                  context.push(AppRoutes.civiqueExamsBlanc);
                },
              ),
              const SizedBox(height: 18),
              themesAsync.when(
                loading: () => const _ThemesLoading(),
                error: (e, _) => _ThemesError(message: e.toString()),
                data: (list) {
                  final sorted = [...list]
                    ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
                  final statsByTheme = statsAsync.maybeWhen(
                    data: (s) => {for (final ts in s.byTheme) ts.themeId: ts},
                    orElse: () => const <String, ThemeStats>{},
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionLabel(
                        "S'entraîner par thème",
                        trailing: SectionCounter('${sorted.length} thèmes'),
                      ),
                      const SizedBox(height: 10),
                      for (final t in sorted)
                        _themeCard(
                          context,
                          ref,
                          t,
                          statsByTheme[t.id],
                          target,
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              SectionLabel(
                'Ma progression',
                trailing: SectionLink(
                  label: 'Détails',
                  onTap: () {
                    ref.read(selectedModuleProvider.notifier).state =
                        AppModule.civique;
                    context.go(AppRoutes.progress);
                  },
                ),
              ),
              const SizedBox(height: 10),
              _MasteryBlock(),
            ],
          ),
        ),
      ),
    );
  }

  String _headerSubtitle(
    TargetProcedure? target,
    AsyncValue<List<ThemeDto>> themesAsync,
  ) {
    final count = themesAsync.maybeWhen(
      data: (l) => l.length,
      orElse: () => null,
    );
    final left = target?.shortLabel ?? 'Civique';
    if (count == null) return '$left · Examen 40 questions';
    return '$left · $count thèmes · Examen 40 Q';
  }

  Widget _themeCard(
    BuildContext context,
    WidgetRef ref,
    ThemeDto theme,
    ThemeStats? stats,
    TargetProcedure? target,
  ) {
    final hasStarted = stats != null && stats.answered > 0;
    // Progression = maîtrise : bonnes réponses / total de questions du thème.
    final ratio = !hasStarted || theme.questionCount == 0
        ? 0.0
        : (stats.correct / theme.questionCount).clamp(0.0, 1.0);
    final iconColor = _accentForOrder(theme.displayOrder);
    final iconBg = _accentBgForOrder(theme.displayOrder);

    return EpreuveCard(
      icon: _iconForTheme(theme.code),
      iconColor: iconColor,
      iconBg: iconBg,
      title: theme.name,
      subtitle: '${theme.questionCount} questions',
      pillLabel: target?.wire,
      progress: ratio,
      onTap: () {
        ref.read(selectedModuleProvider.notifier).state = AppModule.civique;
        context.push(
          AppRoutes.civiqueThemeDetail.replaceFirst(':themeId', theme.id),
        );
      },
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
        return AppColors.amber.withValues(alpha: 0.18);
      case 4:
        return AppColors.green.withValues(alpha: 0.15);
      default:
        return AppColors.blueLight;
    }
  }
}

/// Carte « Maîtrise globale » Civique — % bonnes réponses + couverture.
class _MasteryBlock extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_civiqueStatsProvider);
    final s = async.valueOrNull;
    if (s == null) {
      return const CiviqueMasteryCard(answered: 0, correct: 0, total: 0);
    }
    final answered = s.byTheme.fold<int>(0, (sum, t) => sum + t.answered);
    final correct = s.byTheme.fold<int>(0, (sum, t) => sum + t.correct);
    final total = s.byTheme.fold<int>(0, (sum, t) => sum + t.total);
    return CiviqueMasteryCard(
      answered: answered,
      correct: correct,
      total: total,
    );
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

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
import 'widgets/cecrl_progress_card.dart';
import 'widgets/stats_row.dart';

/// Stats par thème (CO / CE / STRUCTURE) — sert à brancher la barre de
/// progression de chaque card module sur la donnée réelle.
final _tcfStatsProvider = FutureProvider.autoDispose<UserStats>((ref) {
  return ref.watch(userContentRepositoryProvider).stats(module: AppModule.tcf);
});

/// Thèmes TCF — sert à connaître le `questionCount` réel pour calculer la
/// couverture user de chaque card QCM (answered / questionCount).
final _tcfThemesProvider = FutureProvider.autoDispose<List<ThemeDto>>((ref) {
  return ref.watch(themesRepositoryProvider).list(module: AppModule.tcf);
});

/// Résumé de progression TCF — porte le niveau global estimé (dernier
/// examen blanc complet) et le niveau cible CECRL.
final _tcfProgressionProvider =
    FutureProvider.autoDispose<ProgressionSummary>((ref) {
  return ref
      .watch(userContentRepositoryProvider)
      .progression(module: AppModule.tcf);
});

/// Hub TCF : home en single scroll. Header titre dynamique + hero examen
/// blanc complet + 5 épreuves (CO/CE/Structure/EE/EO) + niveau global CECRL
/// + 3 stats. Plus d'onglets, plus de tabs — la maquette `tcf_modules_home_screen.html`
/// privilégie une liste verticale unique.
class TcfScreen extends ConsumerWidget {
  const TcfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final target = user?.targetProcedure;
    final targetLevel = target?.tcfLevel;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.red,
          onRefresh: () async {
            ref.invalidate(_tcfStatsProvider);
            ref.invalidate(_tcfThemesProvider);
            ref.invalidate(_tcfProgressionProvider);
            await Future.wait([
              ref.read(_tcfStatsProvider.future),
              ref.read(_tcfThemesProvider.future),
              ref.read(_tcfProgressionProvider.future),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              HubHomeHeader(
                title: 'Préparer le TCF',
                subtitle: targetLevel == null
                    ? 'IRN · 5 modules · 1h 35'
                    : 'IRN · 5 modules · objectif $targetLevel',
              ),
              const SizedBox(height: 14),
              ExamBlancHero(
                eyebrow: 'Examen blanc complet · 1h 35',
                title: 'Simuler le jour J',
                description:
                    'Les 4 épreuves enchaînées comme à l\'examen réel.',
                ctaLabel: 'Lancer l\'examen blanc',
                onTap: () => context.push(AppRoutes.tcfFullExams),
              ),
              const SizedBox(height: 18),
              SectionLabel(
                "S'entraîner par épreuve",
                trailing: const SectionCounter('5 modules'),
              ),
              const SizedBox(height: 10),
              _ModulesList(targetLevel: targetLevel),
              const SizedBox(height: 18),
              SectionLabel(
                'Ma progression',
                trailing: SectionLink(
                  label: 'Détails',
                  onTap: () {
                    ref.read(selectedModuleProvider.notifier).state =
                        AppModule.tcf;
                    context.go(AppRoutes.progress);
                  },
                ),
              ),
              const SizedBox(height: 10),
              _ProgressionBlock(target: target),
              const SizedBox(height: 10),
              _StatsBlock(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Liste des 5 cartes modules TCF : CO, CE, Structure (bonus), EE, EO.
class _ModulesList extends ConsumerWidget {
  const _ModulesList({required this.targetLevel});

  final String? targetLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themesAsync = ref.watch(_tcfThemesProvider);
    final statsAsync = ref.watch(_tcfStatsProvider);

    final themesByCode = themesAsync.maybeWhen(
      data: (list) => {for (final t in list) t.code: t},
      orElse: () => const <String, ThemeDto>{},
    );
    final statsByThemeId = statsAsync.maybeWhen(
      data: (s) => {for (final ts in s.byTheme) ts.themeId: ts},
      orElse: () => const <String, ThemeStats>{},
    );

    double? qcmProgress(String code) {
      final theme = themesByCode[code];
      if (theme == null) return null;
      final stats = statsByThemeId[theme.id];
      if (stats == null || stats.total == 0) return 0.0;
      return (stats.answered / stats.total).clamp(0.0, 1.0);
    }

    void open(String route) {
      ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
      context.push(route);
    }

    return Column(
      children: [
        EpreuveCard(
          icon: Icons.headphones_rounded,
          iconColor: AppColors.blue,
          iconBg: AppColors.blueLight,
          title: 'Compréhension orale',
          subtitle: '25 QCM · 20 min · audio',
          pillLabel: targetLevel,
          progress: qcmProgress('TCF_CO'),
          onTap: () => open(AppRoutes.tcfCoDetail),
        ),
        EpreuveCard(
          icon: Icons.menu_book_rounded,
          iconColor: AppColors.green,
          iconBg: AppColors.green.withValues(alpha: 0.15),
          title: 'Compréhension écrite',
          subtitle: '25 QCM · 35 min · textes',
          pillLabel: targetLevel,
          progress: qcmProgress('TCF_CE'),
          onTap: () => open(AppRoutes.tcfCeDetail),
        ),
        EpreuveCard(
          icon: Icons.spellcheck_rounded,
          iconColor: AppColors.amber,
          iconBg: AppColors.amber.withValues(alpha: 0.18),
          title: 'Structure de la langue',
          subtitle: 'Grammaire et lexique · bonus',
          pillLabel: 'BONUS',
          progress: qcmProgress('TCF_STRUCTURE'),
          onTap: () => open(AppRoutes.tcfStructureDetail),
        ),
        EpreuveCard(
          icon: Icons.edit_note_rounded,
          iconColor: AppColors.ink2,
          iconBg: AppColors.line2,
          title: 'Expression écrite',
          subtitle: '3 exercices · 30 min · rédaction',
          pillLabel: targetLevel,
          // TODO: brancher sur la couverture des tâches EE quand l'API
          //  exposera un compte de submissions terminées par tâche.
          progress: 0.0,
          onTap: () => open(AppRoutes.tcfEeDetail),
        ),
        EpreuveCard(
          icon: Icons.mic_rounded,
          iconColor: AppColors.redDark,
          iconBg: AppColors.redLight,
          title: 'Expression orale',
          subtitle: '3 tâches · 10 min · oral',
          pillLabel: targetLevel,
          // TODO: idem — couverture des tâches EO non encore exposée.
          progress: 0.0,
          onTap: () => open(AppRoutes.tcfEoDetail),
        ),
      ],
    );
  }
}

/// Carte « Niveau global estimé » alimentée par `/api/me/progression`.
class _ProgressionBlock extends ConsumerWidget {
  const _ProgressionBlock({required this.target});

  final TargetProcedure? target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_tcfProgressionProvider);
    final tcf = async.valueOrNull?.tcf;
    final current = tcf?.lastFullExam?.finalLevel;
    final targetCecrl = tcf?.targetLevel ?? _cecrlForTarget(target);
    final suffix = switch (target) {
      TargetProcedure.csp => 'séjour',
      TargetProcedure.cr => 'résident',
      TargetProcedure.nat => 'naturalisation',
      null => null,
    };

    return CecrlProgressCard(
      current: current,
      target: targetCecrl,
      targetSuffix: suffix,
    );
  }

  /// Fallback quand le backend n'a pas encore résolu `targetLevel` côté
  /// `/api/me/progression` (rare, surtout pendant le boot).
  NiveauCecrl? _cecrlForTarget(TargetProcedure? p) => switch (p) {
        TargetProcedure.csp => NiveauCecrl.a2,
        TargetProcedure.cr => NiveauCecrl.b1,
        TargetProcedure.nat => NiveauCecrl.b2,
        null => null,
      };
}

/// 3 mini-cards stats (Séances / Pratique / Jours actifs). Seul le compteur
/// de séances est branché — les deux autres sont des TODO en attendant que
/// le backend expose `practiceMinutes` et `activeDaysCount` sur `/api/me/stats`.
class _StatsBlock extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_tcfStatsProvider);
    final attempts = async.maybeWhen(
      data: (s) => s.attemptsTotal,
      orElse: () => null,
    );
    return StatsRow(
      sessions: attempts == null ? null : '$attempts',
      practice: null,
      activeDays: null,
    );
  }
}

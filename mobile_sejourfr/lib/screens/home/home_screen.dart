import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  return ref
      .watch(userContentRepositoryProvider)
      .stats(module: AppModule.civique);
});

final _tcfStatsProvider = FutureProvider.autoDispose<UserStats>((ref) {
  return ref.watch(userContentRepositoryProvider).stats(module: AppModule.tcf);
});

/// Snapshot agrégé d'un module pour la card du home : couverture +
/// précision globales. Calculées depuis `byTheme` (somme answered, correct,
/// total) — même logique que les hubs et l'écran Progression pour rester
/// cohérent sur les 3 surfaces.
class _ModuleProgress {
  const _ModuleProgress({
    required this.answered,
    required this.correct,
    required this.total,
    required this.sessions,
  });

  final int answered;
  final int correct;
  final int total;
  final int sessions;

  bool get isStarted => answered > 0;

  // Progression = maîtrise : bonnes réponses / total de questions du module.
  double get mastery => total == 0 ? 0.0 : (correct / total).clamp(0.0, 1.0);

  int get masteryPct => (mastery * 100).round();

  static _ModuleProgress fromStats(UserStats s) {
    final answered = s.byTheme.fold<int>(0, (sum, t) => sum + t.answered);
    final correct = s.byTheme.fold<int>(0, (sum, t) => sum + t.correct);
    final total = s.byTheme.fold<int>(0, (sum, t) => sum + t.total);
    return _ModuleProgress(
      answered: answered,
      correct: correct,
      total: total,
      sessions: s.attemptsTotal,
    );
  }
}

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

    final civiqueIsDemo =
        user != null && !user.canAccessModule(AppModule.civique);
    final tcfIsDemo = user != null && !user.canAccessModule(AppModule.tcf);

    // Compteur global "X vues" rendu en chip top-right du card bleu. Somme
    // des answered des 2 modules (même grammaire que les hubs). null tant
    // qu'au moins un des deux stats charge encore → on attend pour ne pas
    // afficher un sous-total trompeur, et le chip ne paraît pas si le user
    // n'a encore rien vu (évite "0 vues" déprimant à l'onboarding).
    final int? viewedCount = (civiqueStats.valueOrNull != null &&
            tcfStats.valueOrNull != null)
        ? civiqueStats.value!.byTheme
                .fold<int>(0, (sum, t) => sum + t.answered) +
            tcfStats.value!.byTheme.fold<int>(0, (sum, t) => sum + t.answered)
        : null;

    return Scaffold(
      backgroundColor: AppColors.bg,
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _Header(user: user),
              const SizedBox(height: 22),
              _HeroParcoursCard(
                target: user?.targetProcedure,
                viewedCount: viewedCount,
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                label: 'Vos modules',
                trailing: user?.targetProcedure != null
                    ? 'PARCOURS · ${user!.targetProcedure!.shortLabel}'
                    : null,
              ),
              const SizedBox(height: 12),
              _ModuleCard(
                kind: _ModuleKind.civique,
                stats: civiqueStats,
                isDemo: civiqueIsDemo,
                onTap: () => selectAndGo(AppModule.civique, AppRoutes.civique),
              ),
              const SizedBox(height: 10),
              _ModuleCard(
                kind: _ModuleKind.tcf,
                stats: tcfStats,
                isDemo: tcfIsDemo,
                onTap: () => selectAndGo(AppModule.tcf, AppRoutes.tcf),
              ),
              const SizedBox(height: 26),
              const _SectionTitle(label: 'Raccourcis'),
              const SizedBox(height: 12),
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
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ShortcutTile(
                      icon: Icons.edit_note_rounded,
                      title: 'Expression écrite',
                      subtitle: 'corrigée par IA',
                      accent: AppColors.blue,
                      accentBg: AppColors.blueLight,
                      onTap: () {
                        ref.read(selectedModuleProvider.notifier).state =
                            AppModule.tcf;
                        context.push(AppRoutes.tcfEeDetail);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ShortcutTile(
                      icon: Icons.mic_rounded,
                      title: 'Expression orale',
                      subtitle: 'corrigée par IA',
                      accent: AppColors.red,
                      accentBg: AppColors.redLight,
                      onTap: () {
                        ref.read(selectedModuleProvider.notifier).state =
                            AppModule.tcf;
                        context.push(AppRoutes.tcfEoDetail);
                      },
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
// HEADER
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final firstName = user?.firstName?.trim() ?? '';
    final now = DateTime.now();
    final day = _frenchDayLabel(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Cocarde(size: 32),
            const SizedBox(width: 10),
            Text(
              'Sejour',
              style: AppFonts.jakarta(
                size: 17,
                weight: FontWeight.w800,
                color: AppColors.blue,
              ).copyWith(letterSpacing: -0.3),
            ),
            Text(
              'FR',
              style: AppFonts.jakarta(
                size: 17,
                weight: FontWeight.w800,
                color: AppColors.red,
              ).copyWith(letterSpacing: -0.3),
            ),
            const Spacer(),
            _IconChip(
              icon: Icons.person_outline_rounded,
              onTap: () => context.go(AppRoutes.profile),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          day.toUpperCase(),
          style: AppFonts.mono(
            size: 10,
            color: AppColors.muted,
            letterSpacing: 2.0,
            weight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: AppFonts.jakarta(
              size: 26,
              weight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.15,
            ).copyWith(letterSpacing: -0.5),
            children: [
              const TextSpan(text: 'Bonjour'),
              if (firstName.isNotEmpty)
                TextSpan(
                  text: ' $firstName',
                  style: AppFonts.jakarta(
                    size: 26,
                    weight: FontWeight.w800,
                    color: AppColors.blue,
                    height: 1.15,
                  ).copyWith(letterSpacing: -0.5),
                ),
              const TextSpan(text: ',\ncontinuons votre '),
              TextSpan(
                text: 'préparation',
                style: AppFonts.jakarta(
                  size: 26,
                  weight: FontWeight.w800,
                  color: AppColors.blue,
                  height: 1.15,
                ).copyWith(letterSpacing: -0.5),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      ],
    );
  }

  String _frenchDayLabel(DateTime d) {
    const days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    final dayName = days[d.weekday - 1];
    final monthName = months[d.month - 1];
    return '$dayName ${d.day} $monthName';
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.line),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppColors.ink),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HERO PARCOURS — card bleu premium en lecture seule (l'édition de
// l'objectif vit désormais dans le profil, pas dans le home — le home doit
// rester un point d'entrée motivant, pas un panneau de réglages).
// ---------------------------------------------------------------------------

class _HeroParcoursCard extends StatelessWidget {
  const _HeroParcoursCard({required this.target, required this.viewedCount});

  final TargetProcedure? target;

  /// Nombre total de questions vues (civique + tcf). `null` = en cours de
  /// chargement → on n'affiche pas le chip pour ne pas afficher un sous-
  /// total. `0` = pas encore commencé → idem, on cache (évite l'effet
  /// "0 vues" déprimant à l'onboarding).
  final int? viewedCount;

  @override
  Widget build(BuildContext context) {
    final hasTarget = target != null;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue, AppColors.blueDark],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Décors géométriques — cohérence avec les hero des hubs.
            Positioned(
              top: -50,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: -10,
              bottom: -30,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.red.withValues(alpha: 0.22),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'TON PARCOURS',
                        style: AppFonts.mono(
                          size: 10,
                          color: AppColors.white.withValues(alpha: 0.7),
                          letterSpacing: 1.8,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (viewedCount != null && viewedCount! > 0)
                        _ViewedChip(count: viewedCount!),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (hasTarget) ...[
                    Text(
                      target!.shortLabel,
                      style: AppFonts.jakarta(
                        size: 22,
                        weight: FontWeight.w800,
                        color: AppColors.white,
                        height: 1.15,
                      ).copyWith(letterSpacing: -0.4),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'TCF ${target!.tcfLevel}',
                            style: AppFonts.mono(
                              size: 10,
                              color: AppColors.white,
                              letterSpacing: 1.4,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _parcoursPitch(target!),
                            style: AppFonts.jakarta(
                              size: 12.5,
                              color: AppColors.white.withValues(alpha: 0.85),
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'Choisis ton parcours',
                      style: AppFonts.jakarta(
                        size: 22,
                        weight: FontWeight.w800,
                        color: AppColors.white,
                      ).copyWith(letterSpacing: -0.4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CSP · CR · NAT — définis ta cible depuis ton profil pour personnaliser tes entraînements.',
                      style: AppFonts.jakarta(
                        size: 12.5,
                        color: AppColors.white.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _parcoursPitch(TargetProcedure t) {
    switch (t) {
      case TargetProcedure.csp:
        return 'Titre de séjour — niveau A2 visé.';
      case TargetProcedure.cr:
        return 'Carte de résident — niveau B1 visé.';
      case TargetProcedure.nat:
        return 'Naturalisation — niveau B2 visé.';
    }
  }
}

/// Chip top-right du card bleu : compteur global de questions vues (civique
/// + tcf agrégés). Donnée 100 % réelle (somme `byTheme.answered`), pas de
/// fake number. Pluriel à 2+, masqué à 0 (cf. param `viewedCount`).
class _ViewedChip extends StatelessWidget {
  const _ViewedChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 1 ? '$count vues' : '$count vue';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 13,
            color: AppColors.white.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppFonts.jakarta(
              size: 12,
              weight: FontWeight.w800,
              color: AppColors.white,
            ).copyWith(letterSpacing: -0.1),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SECTION TITLE
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, this.trailing});

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: AppFonts.jakarta(
            size: 17,
            weight: FontWeight.w800,
            color: AppColors.ink,
          ).copyWith(letterSpacing: -0.3),
        ),
        const Spacer(),
        if (trailing != null)
          Flexible(
            child: Text(
              trailing!,
              style: AppFonts.mono(
                size: 9.5,
                color: AppColors.muted,
                letterSpacing: 1.8,
                weight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// MODULE CARD COMPACTE — horizontale, ~88px de hauteur, accent latéral
// ---------------------------------------------------------------------------

enum _ModuleKind { civique, tcf }

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.kind,
    required this.stats,
    required this.onTap,
    this.isDemo = false,
  });

  final _ModuleKind kind;
  final AsyncValue<UserStats> stats;
  final VoidCallback onTap;
  final bool isDemo;

  bool get _isCivique => kind == _ModuleKind.civique;

  Color get _accent => _isCivique ? AppColors.blue : AppColors.red;

  Color get _accentLight =>
      _isCivique ? AppColors.blueLight : AppColors.redLight;

  IconData get _icon =>
      _isCivique ? Icons.account_balance_rounded : Icons.translate_rounded;

  String get _title => _isCivique ? 'Examen civique' : 'TCF · Test de français';

  String get _subtitle => _isCivique ? 'CSP · CR · NAT' : 'A2 · B1 · B2';

  @override
  Widget build(BuildContext context) {
    final progress = stats.maybeWhen(
      data: _ModuleProgress.fromStats,
      orElse: () => null,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                // Filet latéral coloré (4px)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 4, color: _accent),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Icône
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: _accentLight,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            alignment: Alignment.center,
                            child: Icon(_icon, size: 22, color: _accent),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _title,
                                        style: AppFonts.jakarta(
                                          size: 15.5,
                                          weight: FontWeight.w800,
                                          color: AppColors.ink,
                                        ).copyWith(letterSpacing: -0.2),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                                          color: AppColors.amber
                                              .withValues(alpha: 0.16),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'DÉMO',
                                          style: AppFonts.mono(
                                            size: 8.5,
                                            color: AppColors.amber,
                                            letterSpacing: 1.2,
                                            weight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _subtitle,
                                  style: AppFonts.mono(
                                    size: 10,
                                    color: AppColors.muted,
                                    letterSpacing: 1.4,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: _accent,
                            size: 22,
                          ),
                        ],
                      ),
                      // Barre de couverture + label si le user a déjà touché
                      // au module. Sinon état "Pas encore commencé" pour
                      // inviter à démarrer. Aligné avec les hubs et l'écran
                      // Progression : `answered/total` du pool.
                      const SizedBox(height: 12),
                      _ModuleProgressStrip(
                        progress: progress,
                        accent: _accent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mini barre de progression (maîtrise = bonnes réponses / total) + label
/// "X/Y réussies · N vues" sous la card module. Quand le user n'a pas encore
/// touché au module, affichage "Pas encore commencé — appuie pour démarrer".
class _ModuleProgressStrip extends StatelessWidget {
  const _ModuleProgressStrip({required this.progress, required this.accent});

  final _ModuleProgress? progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    if (p == null || !p.isStarted) {
      return Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.muted2,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            p == null
                ? 'Chargement…'
                : 'Pas encore commencé · appuie pour démarrer',
            style: AppFonts.jakarta(
              size: 11.5,
              color: AppColors.muted,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barre 4px, accent module.
        Stack(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line2,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: p.mastery.clamp(0.02, 1.0),
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${p.correct}/${p.total} réussies · ${p.masteryPct} % · ${p.answered} vues',
          style: AppFonts.jakarta(
            size: 11.5,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// SHORTCUT TILES
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
              borderRadius: BorderRadius.circular(11),
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
// DAILY TIP
// ---------------------------------------------------------------------------

class _DailyTip extends StatelessWidget {
  const _DailyTip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LE SAVIEZ-VOUS ?',
                  style: AppFonts.mono(
                    size: 9.5,
                    color: AppColors.blue,
                    letterSpacing: 1.8,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '« Liberté, Égalité, Fraternité »',
                  style: AppFonts.fraunces(
                    size: 17,
                    weight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 5),
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
          ),
        ],
      ),
    );
  }
}

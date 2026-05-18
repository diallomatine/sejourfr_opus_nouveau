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

    final tcfIsDemo = user != null && !user.canAccessModule(AppModule.tcf);

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
              _StreakAndTarget(
                streakDays: 7, // TODO: brancher sur backend
                target: user?.targetProcedure,
                onEditTarget: () => context.push(
                  '${AppRoutes.targetPath}?from=${Uri.encodeComponent(AppRoutes.home)}',
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                label: 'Vos modules',
                trailing:
                    user?.targetProcedure != null ? 'PARCOURS · ${user!.targetProcedure!.shortLabel}' : null,
              ),
              const SizedBox(height: 12),
              _ModuleCard(
                kind: _ModuleKind.civique,
                stats: civiqueStats,
                onTap: () => selectAndGo(AppModule.civique, AppRoutes.trainingSetup),
                onExam: () => selectAndGo(AppModule.civique, AppRoutes.examSetup),
              ),
              const SizedBox(height: 10),
              _ModuleCard(
                kind: _ModuleKind.tcf,
                stats: tcfStats,
                isDemo: tcfIsDemo,
                onTap: () => selectAndGo(AppModule.tcf, AppRoutes.trainingSetup),
                onExam: () => selectAndGo(AppModule.tcf, AppRoutes.examSetup),
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
            const _IconChip(icon: Icons.notifications_outlined),
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
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
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
  const _IconChip({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.line),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 16, color: AppColors.ink),
    );
  }
}

// ---------------------------------------------------------------------------
// STREAK + TARGET (inchangée)
// ---------------------------------------------------------------------------

class _StreakAndTarget extends StatelessWidget {
  const _StreakAndTarget({
    required this.streakDays,
    required this.target,
    required this.onEditTarget,
  });

  final int streakDays;
  final TargetProcedure? target;
  final VoidCallback onEditTarget;

  @override
  Widget build(BuildContext context) {
    final hasTarget = target != null;
    final hasStreak = streakDays > 0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue, AppColors.blueDark],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: -18,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.red.withValues(alpha: 0.18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        alignment: Alignment.center,
                        child: hasStreak
                            ? Text(
                                '$streakDays',
                                style: AppFonts.fraunces(
                                  size: 20,
                                  weight: FontWeight.w700,
                                  color: AppColors.white,
                                  height: 1.0,
                                ),
                              )
                            : const Icon(
                                Icons.local_fire_department_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SÉRIE EN COURS',
                              style: AppFonts.mono(
                                size: 9.5,
                                color: AppColors.white.withValues(alpha: 0.65),
                                letterSpacing: 1.8,
                                weight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              hasStreak
                                  ? '$streakDays ${streakDays == 1 ? "jour" : "jours"} d\'affilée'
                                  : 'Commencez votre série',
                              style: AppFonts.jakarta(
                                size: 16,
                                weight: FontWeight.w700,
                                color: AppColors.white,
                              ).copyWith(letterSpacing: -0.2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      height: 1,
                      color: AppColors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: onEditTarget,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              hasTarget ? Icons.flag_rounded : Icons.flag_outlined,
                              size: 15,
                              color: AppColors.white.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: AppFonts.jakarta(
                                    size: 12.5,
                                    color: AppColors.white.withValues(alpha: 0.85),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: hasTarget ? 'Objectif : ' : 'Définir mon objectif',
                                    ),
                                    if (hasTarget)
                                      TextSpan(
                                        text: '${target!.shortLabel} · TCF ${target!.tcfLevel}',
                                        style: AppFonts.jakarta(
                                          size: 12.5,
                                          weight: FontWeight.w700,
                                          color: AppColors.white,
                                        ),
                                      ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              hasTarget ? Icons.edit_outlined : Icons.arrow_forward_rounded,
                              size: 14,
                              color: AppColors.white.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    required this.onExam,
    this.isDemo = false,
  });

  final _ModuleKind kind;
  final AsyncValue<UserStats> stats;
  final VoidCallback onTap;
  final VoidCallback onExam;
  final bool isDemo;

  bool get _isCivique => kind == _ModuleKind.civique;

  Color get _accent => _isCivique ? AppColors.blue : AppColors.red;

  Color get _accentLight => _isCivique ? AppColors.blueLight : AppColors.redLight;

  IconData get _icon => _isCivique ? Icons.account_balance_rounded : Icons.translate_rounded;

  String get _title => _isCivique ? 'Examen civique' : 'TCF · Test de français';

  String get _subtitle => _isCivique ? 'CSP · CR · NAT' : 'A2 · B1 · B2';

  @override
  Widget build(BuildContext context) {
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
                  child: Row(
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
                      // Titre + meta + niveaux
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
                                      color: AppColors.amber.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(4),
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
                            const SizedBox(height: 4),
                            _ModuleMeta(
                              stats: stats,
                              fallback: _subtitle,
                              accent: _accent,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bouton compact examen blanc + chevron
                      _ExamPillButton(accent: _accent, onTap: onExam),
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

class _ModuleMeta extends StatelessWidget {
  const _ModuleMeta({
    required this.stats,
    required this.fallback,
    required this.accent,
  });

  final AsyncValue<UserStats> stats;
  final String fallback;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return stats.when(
      loading: () => Text(
        fallback,
        style: AppFonts.mono(
          size: 10,
          color: AppColors.muted,
          letterSpacing: 1.4,
          weight: FontWeight.w600,
        ),
      ),
      error: (_, __) => Text(
        fallback,
        style: AppFonts.mono(
          size: 10,
          color: AppColors.muted,
          letterSpacing: 1.4,
          weight: FontWeight.w600,
        ),
      ),
      data: (s) {
        if (s.attemptsTotal == 0) {
          // Pas encore commencé : montre les niveaux
          return Text(
            fallback,
            style: AppFonts.mono(
              size: 10,
              color: AppColors.muted,
              letterSpacing: 1.4,
              weight: FontWeight.w600,
            ),
          );
        }
        // En cours : montre les stats
        final percent = (s.successRate * 100).round();
        return RichText(
          text: TextSpan(
            style: AppFonts.jakarta(
              size: 12.5,
              color: AppColors.muted,
            ),
            children: [
              TextSpan(
                text: '$percent% ',
                style: AppFonts.jakarta(
                  size: 12.5,
                  color: accent,
                  weight: FontWeight.w800,
                ),
              ),
              const TextSpan(text: 'de réussite · '),
              TextSpan(
                text: '${s.attemptsTotal}',
                style: AppFonts.jakarta(
                  size: 12.5,
                  color: AppColors.ink,
                  weight: FontWeight.w700,
                ),
              ),
              TextSpan(text: ' session${s.attemptsTotal > 1 ? "s" : ""}'),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

class _ExamPillButton extends StatelessWidget {
  const _ExamPillButton({required this.accent, required this.onTap});

  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
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

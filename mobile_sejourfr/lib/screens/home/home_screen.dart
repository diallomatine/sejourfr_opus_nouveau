import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/dashboard_models.dart';
import '../../core/models/enums.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dashboard_targets.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/list_group.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/stat_value_card.dart';
import '../examens/examens_screen.dart';
import '../reviser/reviser_screen.dart';

/// Accueil de la refonte 2026 (cf. `MHome` maquette) : salutation + avatar,
/// carte « À travailler en priorité » (catégorie la plus faible), 3 stat
/// cards (maîtrise / série / niveau TCF), « Mes parcours », bloc IA (EE/EO)
/// et raccourci examens blancs. Tout vient de `GET /api/me/dashboard`.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final dashboard = ref.watch(dashboardProvider);

    final firstName = user?.firstName?.trim();
    final title = firstName != null && firstName.isNotEmpty
        ? 'Bonjour $firstName 👋'
        : 'Bonjour 👋';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: title,
              sub: 'Prêt pour votre entraînement du jour ?',
              large: true,
              right: _AvatarButton(
                initials: _initials(user?.firstName, user?.lastName,
                    fallback: user?.email),
                onTap: () => context.go(AppRoutes.profile),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.blue,
                onRefresh: () async {
                  ref.invalidate(dashboardProvider);
                  await ref.read(dashboardProvider.future);
                },
                child: dashboard.when(
                  loading: () => ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(top: 120),
                        child: Center(
                          child:
                              CircularProgressIndicator(color: AppColors.blue),
                        ),
                      ),
                    ],
                  ),
                  error: (e, _) => ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      AppCard(
                        child: Column(
                          children: [
                            Text(
                              ApiClient.toApiException(e).message,
                              textAlign: TextAlign.center,
                              style: AppFonts.ui(
                                  size: 13.5, color: AppColors.inkSoft),
                            ),
                            const SizedBox(height: 12),
                            AppButton(
                              label: 'Réessayer',
                              variant: AppButtonVariant.soft,
                              height: 44,
                              fullWidth: false,
                              onPressed: () =>
                                  ref.invalidate(dashboardProvider),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  data: (d) => _HomeBody(summary: d),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String? firstName, String? lastName, {String? fallback}) {
    final f = firstName?.trim();
    final l = lastName?.trim();
    if (f != null && f.isNotEmpty) {
      final second = l != null && l.isNotEmpty ? l[0] : '';
      return '${f[0]}$second'.toUpperCase();
    }
    final email = fallback?.trim();
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return '·';
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.initials, required this.onTap});

  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blue,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Center(
            child: Text(
              initials,
              style: AppFonts.ui(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.summary});

  final DashboardSummary summary;

  /// Catégorie la plus faible à pousser en priorité. Le périmètre dépend de
  /// l'abonnement : un abonné **Civique seul** ne voit que des thèmes civiques ;
  /// tous les autres (Intégral, TCF seul, ou compte gratuit) voient une épreuve
  /// TCF. Sur compte vierge, la première catégorie du périmètre (TCF → CO) pour
  /// amorcer l'entraînement. `TCF_STRUCTURE` est toujours exclu : thème bonus
  /// non évalué au TCF IRN, on ne le pousse jamais comme priorité.
  DashboardCategoryStat _priority({required bool civiqueOnly}) {
    final pool = civiqueOnly ? summary.civique : summary.tcf;
    final worked = pool
        .where((s) => s.percent != null && s.code != 'TCF_STRUCTURE')
        .toList()
      ..sort((a, b) => a.percent!.compareTo(b.percent!));
    if (worked.isNotEmpty) return worked.first;
    final ordered = (civiqueOnly ? pool : orderedTcfCategories(summary.tcf))
        .where((s) => s.code != 'TCF_STRUCTURE')
        .toList();
    return ordered.isNotEmpty ? ordered.first : summary.allCategories.first;
  }

  int? _parcoursAverage(List<DashboardCategoryStat> stats) {
    if (stats.isEmpty) return null;
    final values = stats.map((s) => s.percent ?? 0).toList();
    return (values.reduce((a, b) => a + b) / values.length).round();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final civiqueOnly = user != null && user.hasCivique && !user.hasTcf;
    final priority = _priority(civiqueOnly: civiqueOnly);
    final global = summary.globalSuccessPercent ?? 0;
    final level = summary.estimatedTcfLevel;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _PriorityCard(
          stat: priority,
          onTap: () => context.push(dashboardCategoryRoute(priority)),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ProgressRing(
                      value: global.toDouble(),
                      size: 54,
                      stroke: 6,
                      color: global < 50 ? AppColors.red : AppColors.blue,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Maîtrise',
                      style: AppFonts.ui(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatValueCard(
                value: '${summary.currentStreakDays} j',
                label: 'Série en cours',
                color: AppColors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatValueCard(
                value: level == null
                    ? '—'
                    : level == NiveauCecrl.a1NonAtteint
                        ? '<A1'
                        : level.displayName,
                label: 'Niveau TCF',
                color: AppColors.blue,
              ),
            ),
          ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle(title: 'Mes parcours'),
        const SizedBox(height: 12),
        _ParcoursCard(
          label: 'TCF IRN',
          icon: LucideIcons.audioLines,
          color: AppColors.red,
          average: _parcoursAverage(summary.tcf),
          count: summary.tcf.length,
          onTap: () {
            ref.read(reviserParcoursProvider.notifier).state = AppModule.tcf;
            context.go(AppRoutes.reviser);
          },
        ),
        const SizedBox(height: 12),
        _ParcoursCard(
          label: 'Examen civique',
          icon: LucideIcons.landmark,
          color: AppColors.blue,
          average: _parcoursAverage(summary.civique),
          count: summary.civique.length,
          onTap: () {
            ref.read(reviserParcoursProvider.notifier).state =
                AppModule.civique;
            context.go(AppRoutes.reviser);
          },
        ),
        const SizedBox(height: 20),
        const SectionTitle(title: "Travailler avec l'IA"),
        const SizedBox(height: 12),
        const _AiCard(),
        const SizedBox(height: 16),
        AppCard(
          color: AppColors.surface2,
          onTap: () {
            ref.read(examensParcoursProvider.notifier).state = AppModule.tcf;
            context.go(AppRoutes.examens);
          },
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(LucideIcons.target,
                    size: 23, color: AppColors.blue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Examens blancs complets',
                      style: AppFonts.ui(size: 15, weight: FontWeight.w700),
                    ),
                    Text(
                      '20 épreuves par parcours, conditions réelles',
                      style:
                          AppFonts.ui(size: 12.5, color: AppColors.inkFaint),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight,
                  size: 18, color: AppColors.inkFaint),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _IndependenceNote(),
      ],
    );
  }
}

/// Disclaimer court de non-affiliation (conformité stores). Le « En savoir
/// plus » pousse la page À propos (disclaimer complet + sources officielles).
class _IndependenceNote extends StatelessWidget {
  const _IndependenceNote();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          onTap: () => context.push(AppRoutes.about),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text.rich(
              TextSpan(
                style: AppFonts.ui(
                  size: 11.5,
                  color: AppColors.inkFaint,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text: 'Outil indépendant — non affilié à l\'État '
                        'français · ',
                  ),
                  TextSpan(
                    text: 'En savoir plus',
                    style: AppFonts.ui(
                      size: 11.5,
                      color: AppColors.blue,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte bleue « À travailler en priorité » (cf. maquette) : catégorie la
/// plus faible, barre blanche + %, pied « Continuer ».
class _PriorityCard extends StatelessWidget {
  const _PriorityCard({required this.stat, required this.onTap});

  final DashboardCategoryStat stat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = stat.percent ?? 0;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg - 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.blue,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.zap,
                          size: 15,
                          color: AppColors.white.withValues(alpha: 0.85)),
                      const SizedBox(width: 6),
                      Text(
                        'À TRAVAILLER EN PRIORITÉ',
                        style: AppFonts.ui(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stat.label,
                    style:
                        AppFonts.display(size: 20, color: AppColors.white),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 7,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.25),
                            borderRadius:
                                BorderRadius.circular(AppRadii.pill),
                          ),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: percent / 100,
                            heightFactor: 1,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.all(
                                    Radius.circular(AppRadii.pill)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$percent %',
                        style: AppFonts.ui(
                          size: 13,
                          weight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Continuer',
                    style: AppFonts.ui(
                      size: 14,
                      weight: FontWeight.w600,
                      color: AppColors.blue,
                    ),
                  ),
                  const Icon(LucideIcons.arrowRight,
                      size: 18, color: AppColors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParcoursCard extends StatelessWidget {
  const _ParcoursCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.average,
    required this.count,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final int? average;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sub = average == null
        ? '$count catégories'
        : '$count catégories · $average % de maîtrise';
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, size: 24, color: AppColors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppFonts.ui(size: 16, weight: FontWeight.w700)),
                Text(sub,
                    style:
                        AppFonts.ui(size: 12.5, color: AppColors.inkFaint)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight,
              size: 18, color: AppColors.inkFaint),
        ],
      ),
    );
  }
}

/// Bloc « Travailler avec l'IA » : bandeau gradient bleu + deux entrées
/// Expression écrite / Expression orale côte à côte.
class _AiCard extends StatelessWidget {
  const _AiCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg - 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.blue, AppColors.blueDark],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: const Icon(LucideIcons.sparkles,
                        size: 22, color: AppColors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Améliorez votre expression',
                          style: AppFonts.display(
                              size: 15.5, color: AppColors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Correction détaillée par l'IA et niveau estimé en quelques secondes",
                          style: AppFonts.ui(
                            size: 12.5,
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _AiEntry(
                      icon: LucideIcons.penLine,
                      iconBg: AppColors.blueLight,
                      iconColor: AppColors.blueDark,
                      title: 'Expression écrite',
                      action: 'Rédiger',
                      actionColor: AppColors.blue,
                      onTap: () => context.push(AppRoutes.tcfEeDetail),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _AiEntry(
                      icon: LucideIcons.mic,
                      iconBg: AppColors.redLight,
                      iconColor: AppColors.red,
                      title: 'Expression orale',
                      action: 'Enregistrer',
                      actionColor: AppColors.red,
                      onTap: () => context.push(AppRoutes.tcfEoDetail),
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

class _AiEntry extends StatelessWidget {
  const _AiEntry({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.action,
    required this.actionColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String action;
  final Color actionColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // Deux entrées côte à côte : « Expression écrite » ne
                      // tient pas sur une ligne sous ~400 pt, on l'enroule
                      // plutôt que de la tronquer en « Expression éc… ».
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.ui(size: 14, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Text(
                          action,
                          style: AppFonts.ui(
                            size: 11.5,
                            weight: FontWeight.w600,
                            color: actionColor,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(LucideIcons.arrowRight,
                            size: 12, color: actionColor),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

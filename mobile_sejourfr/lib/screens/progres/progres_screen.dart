import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/models/dashboard_models.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dashboard_targets.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/list_group.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/screen_header.dart';

/// Onglet « Progrès » de la refonte 2026 (cf. `MProgres` maquette) :
/// 3 anneaux de synthèse (global / TCF / Civique), une liste encartée par
/// parcours avec barre de maîtrise colorée par niveau, et l'entrée vers les
/// recommandations. Tout vient de `GET /api/me/dashboard`.
class ProgresScreen extends ConsumerWidget {
  const ProgresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Ma progression',
              large: true,
              // L'écran a quitté la barre du bas (remplacée par « Plan ») : il
              // ne s'atteint plus que poussé depuis le Profil, donc il lui faut
              // sa propre sortie. On dépile si on peut, sinon on retombe sur le
              // Profil — un lien profond arrive avec une pile vide.
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.profile),
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
                  data: (d) => _ProgresBody(summary: d),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _average(List<DashboardCategoryStat> stats) {
  if (stats.isEmpty) return 0;
  final values = stats.map((s) => s.percent ?? 0).toList();
  return (values.reduce((a, b) => a + b) / values.length).round();
}

class _ProgresBody extends StatelessWidget {
  const _ProgresBody({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final global = summary.globalSuccessPercent ?? 0;
    final tcfAvg = _average(summary.tcf);
    final civAvg = _average(summary.civique);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: _SyntheseCard(
                value: global,
                color: AppColors.blue,
                label: 'Réussite globale',
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _SyntheseCard(
                value: tcfAvg,
                color: AppColors.red,
                label: 'TCF IRN',
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _SyntheseCard(
                value: civAvg,
                color: AppColors.blue,
                label: 'Examen civique',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ParcoursSection(
          label: 'TCF IRN',
          color: AppColors.red,
          stats: orderedTcfCategories(summary.tcf),
          examOutOf: 25,
        ),
        const SizedBox(height: 20),
        _ParcoursSection(
          label: 'Examen civique',
          color: AppColors.blue,
          stats: summary.civique,
          examOutOf: 20,
        ),
        const SizedBox(height: 20),
        AppCard(
          color: AppColors.surface2,
          onTap: () => context.push(AppRoutes.progresReco),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(LucideIcons.sparkles,
                    size: 22, color: AppColors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes recommandations',
                      style: AppFonts.ui(size: 15, weight: FontWeight.w700),
                    ),
                    Text(
                      'Plan de révision personnalisé',
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
      ],
    );
  }
}

class _SyntheseCard extends StatelessWidget {
  const _SyntheseCard({
    required this.value,
    required this.color,
    required this.label,
  });

  final int value;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ProgressRing(value: value.toDouble(), size: 56, stroke: 6, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppFonts.ui(
              size: 11.5,
              weight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParcoursSection extends StatelessWidget {
  const _ParcoursSection({
    required this.label,
    required this.color,
    required this.stats,
    required this.examOutOf,
  });

  final String label;
  final Color color;
  final List<DashboardCategoryStat> stats;

  /// Nombre de questions d'un examen blanc de ce parcours : 25 pour un examen
  /// module TCF (CO / CE / Structure), 20 pour un examen de thème civique.
  /// Sans ça un record de 25 bonnes réponses s'affichait « 25/20 ».
  final int examOutOf;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(label, style: AppFonts.display(size: 17, color: color)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ListGroup(
          children: [
            for (final stat in stats)
              _CategoryRow(stat: stat, examOutOf: examOutOf),
          ],
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.stat, required this.examOutOf});

  final DashboardCategoryStat stat;
  final int examOutOf;

  @override
  Widget build(BuildContext context) {
    final percent = stat.percent ?? 0;
    // Accent de marque, pas un verdict : la couleur ne classe plus le
    // pourcentage (§25 bis.3 — le ton se dérive d'un état servi, jamais d'un
    // nombre). Ce chiffre-ci est un taux de réussite brut, pas un état.
    const tone = AppColors.blue;

    final String sub;
    if (stat.isProduction) {
      sub = stat.level != null
          ? 'Niveau estimé ${stat.level!.displayName}'
          : 'Pas encore évalué';
    } else if (stat.mockExams > 0 && stat.bestMockScore != null) {
      final n = stat.mockExams;
      sub = '$n examen${n > 1 ? 's' : ''} · record '
          '${stat.bestMockScore}/$examOutOf';
    } else {
      sub = 'Aucun examen passé';
    }

    return ListRow(
      icon: dashboardCategoryIcon(stat.code),
      iconBg: Color.alphaBlend(
        tone.withValues(alpha: 0.15),
        AppColors.white,
      ),
      iconColor: tone,
      title: stat.label,
      sub: sub,
      onTap: () => context.push(dashboardCategoryRoute(stat)),
      right: SizedBox(
        width: 102,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 64,
              child: Container(
                height: 6,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.surface3,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: percent / 100,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tone,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 34,
              child: Text(
                '$percent%',
                textAlign: TextAlign.right,
                style: AppFonts.ui(
                  size: 13,
                  weight: FontWeight.w700,
                  color: tone,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

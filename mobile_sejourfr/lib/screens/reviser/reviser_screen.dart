import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/models/dashboard_models.dart';
import '../../core/models/enums.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dashboard_targets.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/segmented_tabs.dart';

/// Parcours affiché sur l'onglet Réviser. Partagé (non autoDispose) pour que
/// l'Accueil puisse présélectionner un parcours avant de basculer d'onglet
/// (cf. « Mes parcours » de la maquette).
final reviserParcoursProvider =
    StateProvider<AppModule>((_) => AppModule.tcf);

/// Onglet « Réviser » de la refonte 2026 (cf. `MReviser` maquette) : toggle
/// TCF (rouge) / Civique (bleu) + liste des modules du parcours avec leur
/// maîtrise en anneau. Tap module → écran détail existant.
class ReviserScreen extends ConsumerWidget {
  const ReviserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parcours = ref.watch(reviserParcoursProvider);
    final dashboard = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader(title: 'Réviser', large: true),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.blue,
                onRefresh: () async {
                  ref.invalidate(dashboardProvider);
                  await ref.read(dashboardProvider.future);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    SegmentedTabs<AppModule>(
                      tabs: parcoursSegments(
                        tcf: AppModule.tcf,
                        civique: AppModule.civique,
                      ),
                      value: parcours,
                      onChanged: (p) =>
                          ref.read(reviserParcoursProvider.notifier).state = p,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        parcours == AppModule.tcf
                            ? 'Le test linguistique exigé pour la résidence et la naturalisation.'
                            : 'Les valeurs, institutions et savoirs de la société française.',
                        style:
                            AppFonts.ui(size: 13.5, color: AppColors.inkSoft),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...dashboard.when(
                      loading: () => const [
                        Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.blue),
                          ),
                        ),
                      ],
                      error: (e, _) => [
                        _ErrorCard(
                          message: ApiClient.toApiException(e).message,
                          onRetry: () => ref.invalidate(dashboardProvider),
                        ),
                      ],
                      data: (d) => [
                        for (final (i, entry) in _entriesFor(parcours, d)
                            .indexed) ...[
                          if (i > 0) const SizedBox(height: 12),
                          _ModuleCard(entry: entry, index: i),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_ModuleEntry> _entriesFor(AppModule parcours, DashboardSummary d) {
    final stats = parcours == AppModule.civique
        ? d.civique
        : orderedTcfCategories(d.tcf);
    return [
      for (final stat in stats)
        _ModuleEntry(
          stat: stat,
          icon: dashboardCategoryIcon(stat.code),
          route: dashboardCategoryRoute(stat),
        ),
    ];
  }
}

class _ModuleEntry {
  const _ModuleEntry({
    required this.stat,
    required this.icon,
    required this.route,
  });

  final DashboardCategoryStat stat;
  final IconData icon;
  final String route;
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.entry, required this.index});

  final _ModuleEntry entry;
  final int index;

  @override
  Widget build(BuildContext context) {
    final stat = entry.stat;
    final percent = stat.percent;
    // Rythme bleu-blanc-rouge de la maquette : icônes alternées bleu/rouge.
    final isBlue = index.isEven;
    final iconBg = isBlue ? AppColors.blueLight : AppColors.redLight;
    final iconFg = isBlue ? AppColors.blue : AppColors.red;

    final String sub;
    if (stat.isProduction) {
      sub = stat.level != null
          ? 'Niveau estimé ${stat.level!.displayName}'
          : 'Pas encore évalué';
    } else if (percent != null) {
      sub = '$percent % · ${masteryLabel(percent)}';
    } else {
      sub = 'Pas encore travaillé';
    }

    return AppCard(
      onTap: () => context.push(entry.route),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(entry.icon, size: 22, color: iconFg),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.ui(
                    size: 15,
                    weight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: AppFonts.ui(size: 12.5, color: AppColors.inkFaint),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ProgressRing(
            value: (percent ?? 0).toDouble(),
            size: 42,
            stroke: 5,
            color: iconFg,
          ),
          const SizedBox(width: 8),
          const Icon(
            LucideIcons.chevronRight,
            size: 18,
            color: AppColors.inkFaint,
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.ui(size: 13.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Réessayer',
            variant: AppButtonVariant.soft,
            height: 44,
            fullWidth: false,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

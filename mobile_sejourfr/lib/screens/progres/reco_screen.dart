import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/models/dashboard_models.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dashboard_targets.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/list_group.dart';
import '../../core/widgets/screen_header.dart';

/// Écran « Recommandations » (cf. `MReco` maquette) : la catégorie la plus
/// faible en hero bleu « Priorité n°1 » + les pistes suivantes en liste
/// encartée. Classement = percent croissant (catégories jamais travaillées
/// d'abord, à 0).
class RecoScreen extends ConsumerWidget {
  const RecoScreen({super.key});

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
              title: 'Recommandations',
              sub: "D'après vos résultats",
              onBack: () => context.pop(),
            ),
            Expanded(
              child: dashboard.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.blue),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      ApiClient.toApiException(e).message,
                      textAlign: TextAlign.center,
                      style:
                          AppFonts.ui(size: 13.5, color: AppColors.inkSoft),
                    ),
                  ),
                ),
                data: (d) => _RecoBody(summary: d),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecoBody extends StatelessWidget {
  const _RecoBody({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final ranked = [...summary.allCategories]
      ..sort((a, b) => (a.percent ?? 0).compareTo(b.percent ?? 0));
    if (ranked.isEmpty) return const SizedBox.shrink();
    final top = ranked.first;
    final others = ranked.skip(1).take(4).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        AppCard(
          padding: EdgeInsets.zero,
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
                      const AppTag(
                        label: 'Priorité n°1',
                        tone: TagTone.red,
                        icon: LucideIcons.zap,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        top.label,
                        style: AppFonts.display(
                            size: 20, color: AppColors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Réussite actuelle ${top.percent ?? 0} % — c'est ici que vous avez le plus à gagner.",
                        style: AppFonts.ui(
                          size: 13.5,
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppButton(
                    label: "S'entraîner maintenant",
                    icon: top.isProduction
                        ? LucideIcons.penLine
                        : LucideIcons.target,
                    onPressed: () =>
                        context.push(dashboardCategoryRoute(top)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle(title: 'Autres pistes'),
        const SizedBox(height: 12),
        ListGroup(
          children: [
            for (final stat in others)
              ListRow(
                icon: dashboardCategoryIcon(stat.code),
                iconBg: AppColors.surface2,
                iconColor: AppColors.inkSoft,
                title: stat.label,
                sub: stat.isProduction
                    ? (stat.level != null
                        ? 'Niveau estimé ${stat.level!.displayName}'
                        : 'Pas encore évalué')
                    : '${stat.percent ?? 0} % de réussite',
                onTap: () => context.push(dashboardCategoryRoute(stat)),
              ),
          ],
        ),
      ],
    );
  }
}

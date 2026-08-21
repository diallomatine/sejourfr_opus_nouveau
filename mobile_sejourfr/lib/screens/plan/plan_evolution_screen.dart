import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/list_group.dart';
import '../../core/widgets/screen_header.dart';
import 'learning_plan_provider.dart';
import 'plan_labels.dart';
import 'widgets/plan_changes_section.dart';
import 'widgets/plan_path_section.dart';
import 'widgets/plan_tokens.dart';

/// **« Votre programme évolue »** : le détail de la bascule de palier — d'où
/// part le cycle, ce qu'il construit maintenant, et ce qui a bougé pour le
/// justifier.
///
/// 🛑 **Aucun contenu n'est fabriqué ici.** Les transitions sont celles que le
/// serveur a réellement mesurées (`recentChanges`), le chemin est celui du
/// cycle, et **leur absence est un cas normal** : on le dit en une phrase au
/// lieu d'inventer une évolution.
class PlanEvolutionScreen extends ConsumerWidget {
  const PlanEvolutionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(learningPlanProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: kPlanEvolutionTitle,
              onBack: () => _leave(context),
            ),
            Expanded(
              child: planAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.blue),
                ),
                error: (error, _) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    AppCard(
                      child: Text(
                        ApiClient.toApiException(error).message,
                        textAlign: TextAlign.center,
                        style: AppFonts.ui(
                          size: 13.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
                data: (plan) => _EvolutionBody(
                  plan: plan,
                  onClose: () => _leave(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.plan);
  }
}

class _EvolutionBody extends StatelessWidget {
  const _EvolutionBody({required this.plan, required this.onClose});

  final LearningPlan plan;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cycle = plan.cycle;
    final changes = plan.recentChanges;
    final newPriority = changes?.newPriority;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Column(
          children: [
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: const Icon(
                LucideIcons.sparkles,
                size: 30,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              kPlanEvolutionTitle,
              textAlign: TextAlign.center,
              style: AppFonts.display(size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              planEvolutionSubtitle(cycle),
              textAlign: TextAlign.center,
              style: AppFonts.ui(
                size: 15,
                height: 1.6,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
        if (cycle != null) ...[
          const SizedBox(height: 18),
          AppCard(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: PlanLevelRail(current: cycle.targetLevel),
          ),
        ],
        if (changes == null || changes.isEmpty) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Text(
              kPlanEvolutionEmpty,
              style: AppFonts.ui(
                size: 14,
                height: 1.6,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ] else ...[
          if (changes.transitions.isNotEmpty) ...[
            const SizedBox(height: 20),
            SectionTitle(title: changes.window.label),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < changes.transitions.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    PlanTransitionLine(transition: changes.transitions[i]),
                  ],
                ],
              ),
            ),
          ],
          if (newPriority != null) ...[
            const SizedBox(height: 20),
            SectionTitle(title: 'Votre nouvelle priorité'),
            const SizedBox(height: 10),
            AppCard(
              border: Border.all(
                color: AppColors.blue.withValues(alpha: 0.22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    newPriority.title,
                    style: AppFonts.display(size: 18, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    planSkillMeta(
                      newPriority.skillCode,
                      newPriority.section,
                    ),
                    style: AppFonts.ui(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
        if (cycle != null && cycle.path.isNotEmpty) ...[
          const SizedBox(height: 22),
          PlanPathSection(cycle: cycle),
        ],
        const SizedBox(height: 16),
        const PlanNote(kPlanEvolutionNote),
        const SizedBox(height: 18),
        AppButton(
          label: kPlanEvolutionCta,
          iconRight: LucideIcons.arrowRight,
          onPressed: onClose,
        ),
      ],
    );
  }
}

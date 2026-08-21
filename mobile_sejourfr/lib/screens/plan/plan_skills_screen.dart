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
import 'plan_actions.dart';
import 'plan_labels.dart';
import 'widgets/plan_task_row.dart';
import 'widgets/plan_tokens.dart';

/// **Toutes mes compétences** — l'index complet, derrière « Tout voir » de
/// « Mes priorités ».
///
/// 🛑 **Aucune seconde liste de compétences n'est créée.** Cette page est un
/// aiguillage vers les écrans qui existent déjà : une tâche d'expression ouvre
/// ses huit compétences dans le parcours (`CompetencesTabView`), un domaine de
/// compréhension ouvre sa fiche (`PlanDomainScreen`) et ses paliers. Le dépôt
/// interdit une UX concurrente de celles-là.
///
/// 🛑 **Aucun identifiant ne voyage dans la route** et **aucun appel réseau
/// n'est ajouté** : la page relit le Plan déjà chargé, exactement comme la
/// fiche d'un domaine.
///
/// L'**ordre servi est celui du serveur** ; on se contente de regrouper les
/// domaines par famille — expression d'abord, puis compréhension — parce que
/// les deux ne se travaillent pas de la même façon (petits sujets d'un côté,
/// séries de 20 questions de l'autre). Rien n'est retrié à l'intérieur d'une
/// famille.
class PlanSkillsScreen extends ConsumerWidget {
  const PlanSkillsScreen({super.key});

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
              title: kPlanAllSkillsTitle,
              sub: kPlanAllSkillsSub,
              onBack: () => _leave(context),
            ),
            Expanded(
              child: planAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.blue),
                ),
                error: (error, _) => _Message(
                  text: ApiClient.toApiException(error).message,
                  onRetry: () => ref.invalidate(learningPlanProvider),
                ),
                data: (plan) => _Body(plan: plan),
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

class _Body extends StatelessWidget {
  const _Body({required this.plan});

  final LearningPlan plan;

  @override
  Widget build(BuildContext context) {
    final expression = plan.domaines
        .where((d) => planDomainSection(d.epreuve)?.isProduction ?? false)
        .toList(growable: false);
    final comprehension = plan.domaines
        .where((d) => planDomainSection(d.epreuve)?.isComprehension ?? false)
        .toList(growable: false);

    if (expression.isEmpty && comprehension.isEmpty) {
      return const _Message(text: kPlanAllSkillsEmpty);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        for (final domain in expression)
          if (domain.taches.isNotEmpty) ...[
            SectionTitle(title: planDomainLabel(domain.epreuve)),
            const SizedBox(height: 10),
            _Card(
              children: [
                for (var i = 0; i < domain.taches.length; i++)
                  PlanTaskRow(
                    task: domain.taches[i],
                    epreuve: domain.epreuve,
                    first: i == 0,
                  ),
              ],
            ),
            const SizedBox(height: 22),
          ],
        if (comprehension.isNotEmpty) ...[
          SectionTitle(title: kPlanComprehensionTitle),
          const SizedBox(height: 10),
          _Card(
            children: [
              for (var i = 0; i < comprehension.length; i++)
                _ComprehensionRow(domain: comprehension[i], first: i == 0),
            ],
          ),
          const SizedBox(height: 10),
          const PlanNote(kPlanComprehensionNote),
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(children: children),
      );
}

/// Un domaine de compréhension. **Il n'a pas de tâche** : ses compétences sont
/// des paliers, et c'est sa fiche qui les porte — on n'invente pas ici une
/// liste de compétences CO/CE, elles n'ont aucun petit sujet.
class _ComprehensionRow extends StatelessWidget {
  const _ComprehensionRow({required this.domain, required this.first});

  final PlanDomain domain;
  final bool first;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.white,
        child: InkWell(
          onTap: () => openPlanDomain(context, domain.epreuve),
          child: Container(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
            decoration: BoxDecoration(
              border: first
                  ? null
                  : const Border(top: BorderSide(color: AppColors.lineSoft)),
            ),
            child: Row(
              children: [
                PlanDomainTile(epreuve: domain.epreuve, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planDomainLabel(domain.epreuve),
                        style: AppFonts.ui(
                          size: 14.5,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        planDomainSubtitle(domain),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.ui(
                          size: 12.5,
                          height: 1.35,
                          color: AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PlanDomainPriorityTag(priority: domain.priority),
                const SizedBox(width: 6),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 15,
                  color: AppColors.inkFaint,
                ),
              ],
            ),
          ),
        ),
      );
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              children: [
                const Icon(
                  LucideIcons.cloudOff,
                  size: 26,
                  color: AppColors.inkFaint,
                ),
                const SizedBox(height: 10),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: AppFonts.ui(size: 13.5, color: AppColors.inkSoft),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 14),
                  AppButton(
                    label: 'Réessayer',
                    variant: AppButtonVariant.soft,
                    height: 44,
                    fullWidth: false,
                    onPressed: onRetry,
                  ),
                ],
              ],
            ),
          ),
        ],
      );
}

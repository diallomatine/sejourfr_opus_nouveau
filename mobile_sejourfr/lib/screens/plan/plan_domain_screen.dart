import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/list_group.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/skill_mastery_tag.dart';
import '../../core/router/app_router.dart';
import 'learning_plan_provider.dart';
import 'plan_actions.dart';
import 'plan_labels.dart';
import 'plan_series_launcher.dart';
import 'widgets/plan_task_row.dart';
import 'widgets/plan_tokens.dart';

/// **La fiche d'un des quatre domaines du TCF, vue par le Plan.**
///
/// Elle répond à « qu'est-ce que j'en fais maintenant ? », pas à « quel est mon
/// niveau ? » — cette dernière question a déjà une surface, le tableau de bord.
///
/// 🛑 **Aucun identifiant ne voyage dans la route** : la fiche relit le Plan
/// déjà chargé et y retrouve son domaine. Aucun appel réseau supplémentaire.
///
/// Les deux blocs de détail s'excluent, et c'est le serveur qui tranche :
/// **compréhension** ⇒ ses trois paliers, chacun ouvrant une série ciblée ;
/// **expression** ⇒ ses trois tâches, chacune ouvrant ses compétences.
class PlanDomainScreen extends ConsumerWidget {
  const PlanDomainScreen({super.key, required this.domainKey});

  final String domainKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final epreuve = planDomainFromKey(domainKey);
    final planAsync = ref.watch(learningPlanProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: epreuve == null ? 'Domaine' : planDomainLabel(epreuve),
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
                data: (plan) {
                  final domain = epreuve == null
                      ? null
                      : plan.domaines
                          .where((d) => d.epreuve == epreuve)
                          .firstOrNull;
                  if (domain == null) {
                    return const _Message(
                      text: 'Ce domaine n\'est pas suivi par votre plan.',
                    );
                  }
                  return _DomainBody(plan: plan, domain: domain);
                },
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

class _DomainBody extends ConsumerWidget {
  const _DomainBody({required this.plan, required this.domain});

  final LearningPlan plan;
  final PlanDomain domain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessment = plan.domainesAEvaluer
        .where((a) => a.epreuve == domain.epreuve)
        .firstOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PlanDomainTile(
                    epreuve: domain.epreuve,
                    size: 42,
                    filled: domain.priority == PlanDomainPriority.forte,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          domain.niveau?.displayName ?? 'À évaluer',
                          style: AppFonts.display(size: 21, height: 1.15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          domain.evaluated
                              ? 'niveau estimé'
                              : 'aucune donnée pour le moment',
                          style: AppFonts.ui(
                            size: 12.5,
                            color: AppColors.inkFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PlanDomainPriorityTag(priority: domain.priority),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                planDomainSummary(domain),
                style: AppFonts.ui(
                  size: 14,
                  height: 1.55,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
        if (!domain.evaluated) ...[
          const SizedBox(height: 14),
          AppCard(
            color: AppColors.blueSoft,
            border: Border.all(color: AppColors.blueLight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.sparkles,
                      size: 17,
                      color: AppColors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Comment compléter ce domaine ?',
                        style: AppFonts.ui(
                          size: 14.5,
                          weight: FontWeight.w700,
                          color: AppColors.blueDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  assessment == null
                      ? kPlanNotEvaluatedNote
                      : 'Un ${planAssessmentMeta(assessment).toLowerCase()} '
                          'suffit à le mesurer. C\'est un examen blanc qui '
                          'évalue un domaine — jamais une série d\'entraînement.',
                  style: AppFonts.ui(
                    size: 14,
                    height: 1.6,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          if (assessment != null) ...[
            const SizedBox(height: 12),
            AppButton(
              label: planAssessmentLabel(assessment),
              icon: LucideIcons.play,
              onPressed: () => openPlanAssessment(context, assessment),
            ),
          ],
        ],
        if (domain.paliers.isNotEmpty) ...[
          const SizedBox(height: 20),
          SectionTitle(title: 'Vos paliers sur ce domaine'),
          const SizedBox(height: 10),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                for (var i = 0; i < domain.paliers.length; i++)
                  _LevelRow(level: domain.paliers[i], first: i == 0),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const PlanNote(kPlanComprehensionNote),
        ],
        if (domain.taches.isNotEmpty) ...[
          const SizedBox(height: 20),
          SectionTitle(title: 'Vos tâches sur ce domaine'),
          const SizedBox(height: 10),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                for (var i = 0; i < domain.taches.length; i++)
                  PlanTaskRow(
                    task: domain.taches[i],
                    epreuve: domain.epreuve,
                    first: i == 0,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Un palier de compréhension. Le tap lance sa **série ciblée** : c'est la
/// compétence du palier qui est travaillée, jamais le domaine entier.
class _LevelRow extends ConsumerWidget {
  const _LevelRow({required this.level, required this.first});

  final PlanDomainLevel level;
  final bool first;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Material(
        color: AppColors.white,
        child: InkWell(
          onTap: () => unawaited(
            startTargetedSeries(
              context,
              ref,
              skillId: level.skillId,
              masteryBefore: level.masteryState,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
            decoration: BoxDecoration(
              border: first
                  ? null
                  : const Border(top: BorderSide(color: AppColors.lineSoft)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    level.niveau.wire,
                    style: AppFonts.display(size: 16),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kPlanSeriesCta,
                        style: AppFonts.ui(
                          size: 14.5,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        planLevelSubtitle(level),
                        style: AppFonts.ui(
                          size: 12.5,
                          color: AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (level.blocking)
                  const AppTag(
                    label: kPlanLevelBlockingTag,
                    tone: TagTone.amber,
                    compact: true,
                  )
                else if (level.masteryState != null)
                  SkillMasteryTag(state: level.masteryState!, compact: true),
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

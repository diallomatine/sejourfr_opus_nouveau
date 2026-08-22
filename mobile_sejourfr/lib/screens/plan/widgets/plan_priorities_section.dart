import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/models/diagnostic_models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/blurred_content.dart';
import '../../../core/widgets/list_group.dart';
import '../../../core/widgets/premium_lock.dart';
import '../../../core/widgets/pressable_card.dart';
import '../plan_actions.dart';
import '../plan_groups.dart';
import '../plan_labels.dart';
import '../plan_step_labels.dart';
import 'plan_group_card.dart';
import 'plan_tokens.dart';

/// **Mes priorités**, groupées par épreuve et par tâche.
///
/// Un encart par groupe : fermé, il dit ce qu'il contient (« Raconter une
/// expérience · 1 priorité · 2 à renforcer · 3 solides ») ; ouvert, il déroule
/// ses compétences et propose une action sur la première qui en appelle une.
///
/// 🛑 **Un encart porte TOUTES les compétences de sa tâche**, pas seulement
/// celles sur lesquelles le Plan demande quelque chose : ce qui est **observé**
/// y figure aussi, solides comprises. C'est ce qui a permis de supprimer la
/// section « Mes compétences observées », qui réénumérait les mêmes
/// compétences plus bas dans la page, dans un autre ordre et avec un autre
/// grain. Ne pas la recréer.
///
/// Au-delà de [kPlanPriorityGroupVisibleRows] lignes, l'encart renvoie au reste
/// par un « + N autres compétences » — **N est un vrai nombre**, calculé sur ce
/// que le groupe contient, et le résumé de l'en-tête compte **tout** le groupe.
///
/// L'ordre des compétences est celui **servi** — le serveur trie, le front
/// regroupe. Les étapes **franchies** ne disparaissent pas : elles se replient
/// sous la liste (mises en tête, elles repoussaient la priorité n°1 hors
/// écran).
///
/// « Tout voir » ouvre la page **Toutes mes compétences**, **sans cadenas** :
/// le catalogue et les mesures restent ouverts à tout le monde.
///
/// 🛑 **Un encart n'est verrouillé que si TOUTES ses lignes le sont** — jamais
/// « à partir du 2ᵉ ». Le serveur ouvre la première place du Plan quelle que
/// soit sa nature (`PlanFocusResolver`), et il peut en ouvrir une autre :
/// flouter par l'index cacherait du contenu accessible.
class PlanPrioritiesSection extends ConsumerStatefulWidget {
  const PlanPrioritiesSection({super.key, required this.plan});

  final LearningPlan plan;

  @override
  ConsumerState<PlanPrioritiesSection> createState() =>
      _PlanPrioritiesSectionState();
}

class _PlanPrioritiesSectionState extends ConsumerState<PlanPrioritiesSection> {
  bool _showDone = false;

  /// `null` tant que rien n'a été touché : le premier encart ouvrable fait
  /// alors office de défaut.
  String? _openKey;
  bool _touched = false;

  /// « Tout voir » — **ouvert à tout le monde** (arbitrage du 2026-08-22).
  ///
  /// 🛑 Le catalogue et les mesures ne se ferment pas : *on floute l'action pas
  /// encore accessible, jamais le résultat mesuré*. Le verrou reste là où le
  /// serveur le pose — sur chaque compétence et sur chaque sujet. Ne pas
  /// réintroduire un verrou de navigation ici.
  void _openAll() => context.push(AppRoutes.planSkills);

  String? _defaultKey(List<PlanPriorityGroup> groups) {
    for (final group in groups) {
      if (!group.locked) return group.key;
    }
    // Tout est fermé : on désigne quand même le premier — un encart verrouillé
    // ne se déplie pas de toute façon. Miroir du web.
    return groups.isEmpty ? null : groups.first.key;
  }

  String? _effectiveKey(List<PlanPriorityGroup> groups) {
    if (!_touched) return _defaultKey(groups);
    final key = _openKey;
    if (key == null) return null;
    return groups.any((group) => group.key == key) ? key : _defaultKey(groups);
  }

  void _toggle(PlanPriorityGroup group, String? current) {
    if (group.locked) {
      unawaited(showTcfLockPaywall(
        context,
        ref: ref,
        ctaLocation: AnalyticsCtaLocation.lockedPlan,
      ));
      return;
    }
    setState(() {
      _touched = true;
      _openKey = current == group.key ? null : group.key;
    });
  }

  /// Ce que fait une ligne : la fiche de sa compétence, ou l'offre quand elle
  /// est verrouillée. Un seul chemin, partagé par la ligne et par le bouton de
  /// bas d'encart.
  void _open(PlanPriorityGroupRow row) {
    if (row.locked) {
      unawaited(showTcfLockPaywall(
        context,
        ref: ref,
        ctaLocation: AnalyticsCtaLocation.lockedPlan,
      ));
      return;
    }
    openPlanSkill(context, row.skillId, row.section);
  }

  /// Le reste du groupe : la fiche de son domaine, qui porte **toutes** ses
  /// compétences. Sans domaine servi (cas d'un encart sans épreuve), on retombe
  /// sur « Toutes mes compétences ».
  void _openMore(PlanPriorityGroup group) {
    final epreuve = group.epreuve;
    if (epreuve == null) {
      context.push(AppRoutes.planSkills);
      return;
    }
    openPlanDomain(context, epreuve);
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final groups = planPriorityGroups(plan);
    final completed = plan.completedSteps;

    if (groups.isEmpty && completed.isEmpty) return const SizedBox.shrink();

    final openKey = _effectiveKey(groups);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: kPlanPrioritiesTitle,
          action: TextButton(
            onPressed: _openAll,
            style: _linkStyle,
            child: Text(
              kPlanPrioritiesAll,
              style: AppFonts.ui(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.blue,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            kPlanPrioritiesText,
            style: AppFonts.ui(size: 12, height: 1.35, color: AppColors.inkSoft),
          ),
        ),
        for (final group in groups) ...[
          const SizedBox(height: 10),
          _PriorityGroupCard(
            group: group,
            expanded: openKey == group.key,
            onToggle: () => _toggle(group, openKey),
            onOpenRow: _open,
            onOpenMore: () => _openMore(group),
          ),
        ],
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 12),
          AppButton(
            label: planDoneSectionCta(completed.length, _showDone),
            icon: LucideIcons.check,
            variant: AppButtonVariant.outline,
            height: 46,
            onPressed: () => setState(() => _showDone = !_showDone),
          ),
          if (_showDone)
            for (final step in completed)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _CompletedStepCard(step: step),
              ),
        ],
      ],
    );
  }
}

final ButtonStyle _linkStyle = TextButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 6),
  minimumSize: Size.zero,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
);

/// Un encart de priorités : la carte, ses lignes, et le bouton qui vise la
/// première ligne encore à travailler.
class _PriorityGroupCard extends StatelessWidget {
  const _PriorityGroupCard({
    required this.group,
    required this.expanded,
    required this.onToggle,
    required this.onOpenRow,
    required this.onOpenMore,
  });

  final PlanPriorityGroup group;
  final bool expanded;
  final VoidCallback onToggle;
  final void Function(PlanPriorityGroupRow row) onOpenRow;
  final VoidCallback onOpenMore;

  @override
  Widget build(BuildContext context) {
    final action = group.action;
    final rows = group.visibleRows;
    final hidden = group.hiddenCount;
    final open = expanded && !group.locked;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: open ? AppColors.blue : AppColors.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.card,
      ),
      child: PlanGroupCard(
        epreuve: group.epreuve,
        task: group.task,
        context_: group.context,
        summary: planPrioritiesGroupSummary(
          taskTitle: group.task?.title,
          statuses: planStatusSummary(group.rows.map((row) => row.status)),
        ),
        expanded: expanded,
        locked: group.locked,
        onToggle: onToggle,
        children: [
          for (var i = 0; i < rows.length; i++)
            _PriorityRow(
              row: rows[i],
              first: i == 0,
              onTap: () => onOpenRow(rows[i]),
            ),
          // 🛑 **Un vrai nombre**, calculé sur ce que le groupe contient
          // réellement. `0` ⇒ pas de lien du tout.
          if (hidden > 0)
            _MoreRow(count: hidden, onTap: onOpenMore),
          if (action != null) ...[
            const SizedBox(height: 12),
            AppButton(
              label: planGroupCta(
                locked: action.locked,
                comprehension: action.comprehension,
                acquisition: action.status == PlanRowStatus.aAcquerir,
              ),
              icon: action.comprehension
                  ? LucideIcons.play
                  : LucideIcons.target,
              variant: AppButtonVariant.outline,
              height: 46,
              onPressed: () => onOpenRow(action),
            ),
          ],
        ],
      ),
    );
  }
}

/// Une ligne de priorité : sa compétence, ce qu'il y a à y faire, son statut.
///
/// 🛑 **Verrouillée**, elle garde son statut et son chevron nets et passe sa
/// compétence derrière un rideau de flou (`BlurredContent`) — c'est le **vrai**
/// titre qui est flouté, jamais un décor. Le tap mène à l'offre, pas à des
/// sujets qu'on ne pourrait pas produire.
///
/// ⚠ Le verrou est **lu** sur le DTO. Jamais « à partir de la 2ᵉ ligne ».
class _PriorityRow extends StatelessWidget {
  const _PriorityRow({
    required this.row,
    required this.first,
    required this.onTap,
  });

  final PlanPriorityGroupRow row;
  final bool first;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final priority = row.priority;

    final Widget title = Text(
      row.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppFonts.ui(size: 14.5, weight: FontWeight.w600, height: 1.3),
    );

    // Ce que la ligne travaille — un fait servi, jamais un jugement. Une
    // acquisition dit **ce qu'elle est** (aucun mot de manque), une compétence
    // de compréhension dit sa série, une fragilité son avancement d'étape.
    //
    // 🛑 Une ligne **seulement observée** n'a aucun compteur d'étape servi : on
    // dit d'où vient sa mesure, on n'invente pas un « 0 / 5 » qui se lirait
    // comme un retard.
    final String sub = row.status == PlanRowStatus.aAcquerir
        ? planAcquisitionRowSub(row.level)
        : row.comprehension
            ? planSeriesLabel(priority?.recommendedExercise?.questionCount)
            : priority == null
                ? kPlanObservedRowSub
                : planPromptCountSub(
                    priority.stepAttemptedCount,
                    priority.stepPromptCount,
                  );

    return PlanGroupRow(
      first: first,
      onTap: onTap,
      label: row.locked ? BlurredContent(child: title) : title,
      sub: Text(
        sub,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppFonts.ui(size: 12, height: 1.35, color: AppColors.inkFaint),
      ),
      // 🛑 **Le statut reste NET, même verrouillé** : il dit de quelle sorte
      // d'action il s'agit — c'est exactement ce qui empêche « à acquérir » de
      // se lire « à renforcer » —, jamais ce qu'il y a à y faire. Seul le titre
      // passe derrière le rideau. Le cadenas prend la place du chevron, comme
      // sur le web (`PriorityRow`).
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlanRowStatusTag(status: row.status, level: row.level),
          const SizedBox(width: 8),
          if (row.locked)
            const PremiumLockPill(size: 22)
          else
            const Icon(
              LucideIcons.chevronRight,
              size: 15,
              color: AppColors.inkFaint,
            ),
        ],
      ),
    );
  }
}

/// **Le reste du groupe** : ce que l'encart ne déroule pas, compté pour de vrai
/// et renvoyé vers la fiche du domaine, qui porte toutes ses compétences.
///
/// 🛑 Ce n'est **pas** un verrou : ces compétences sont accessibles, l'encart
/// n'a simplement pas la place de les dérouler toutes.
class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.lineSoft)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    planGroupMoreLabel(count),
                    style: AppFonts.ui(
                      size: 13.5,
                      weight: FontWeight.w700,
                      color: AppColors.blue,
                    ),
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 15,
                  color: AppColors.blue,
                ),
              ],
            ),
          ),
        ),
      );
}

/// Une étape **franchie** : cochée, sobre, **sans aucun bouton d'action** — il
/// n'y a plus rien à y faire, et ce n'est pas une porte commerciale (le DTO ne
/// porte ni exercice ni `locked`). Elle reste tappable, pour se relire.
///
/// ⚠️ La coche ne dépend **pas** de `masteryState` : l'appartenance à
/// `completedSteps` **est** la coche.
class _CompletedStepCard extends StatelessWidget {
  const _CompletedStepCard({required this.step});

  final LearningPlanCompletedStep step;

  @override
  Widget build(BuildContext context) => PressableCard(
        onTap: () => openPlanSkill(context, step.skillId, step.section),
        radius: AppRadii.lg,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              PlanRankBadge(
                rank: 0,
                tone: AppColors.green,
                icon: LucideIcons.check,
                semanticsLabel: kPlanStepDoneMarkLabel,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.ui(
                        size: 13.5,
                        weight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      planSkillMeta(step.skillCode, step.section),
                      style: AppFonts.ui(
                        size: 11,
                        weight: FontWeight.w600,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const AppTag(
                label: kPlanStepBadgeDone,
                tone: TagTone.success,
                compact: true,
              ),
            ],
          ),
        ),
      );
}

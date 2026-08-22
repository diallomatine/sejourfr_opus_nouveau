import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/providers/target_level_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/skill_mastery_tag.dart';
import 'learning_plan_provider.dart';
import 'plan_actions.dart';
import 'plan_labels.dart';
import 'widgets/plan_changes_section.dart';
import 'widgets/plan_tokens.dart';

/// **Ma progression vers le {objectif}** — où en est le candidat, domaine par
/// domaine, sur le chemin de son palier.
///
/// 🛑 **Ce n'est pas l'écran `/progress`**, qui reste : celui-là est la
/// progression **générique** (trois anneaux, parcours civique et TCF), ouverte
/// depuis le Profil. Celui-ci est adossé au Plan et ne parle que du TCF.
///
/// 🛑 **Aucun identifiant ne voyage dans la route, aucun appel réseau n'est
/// ajouté** : l'écran relit le Plan déjà chargé, comme la fiche d'un domaine.
///
/// **Trois éléments de la maquette sont volontairement absents** :
/// - les **barres de pourcentage** par palier — le score interne du moteur de
///   maîtrise n'est exposé à aucun front ; c'est l'**état** de chaque palier
///   ([SkillMasteryTag]) qui porte la même information sans publier un chiffre
///   qu'on n'a pas le droit de rendre ;
/// - **« Voir mon bilan »** — cet écran n'existe ni ici ni au serveur ;
/// - le **compte de jours** (« après 4 séances ») — aucune source ne le sert.
///
/// **Aucun verrou** : l'écran n'affiche que de la **mesure**, et *on floute
/// l'action pas encore accessible, jamais le résultat mesuré*. Les seuls
/// gestes qu'il propose sont des mesures de domaine, offertes par construction
/// (slot 1).
class PlanProgressScreen extends ConsumerWidget {
  const PlanProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(learningPlanProvider);
    // L'objectif vient du **cycle** quand le serveur en sert un ; sinon du
    // palier visé du compte. `null` reste `null` : on ne devine jamais un B2.
    final objective = planAsync.valueOrNull?.cycle?.objectiveLevel ??
        ref.watch(userTargetLevelProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: planProgressTitle(objective),
              sub: kPlanProgressSub,
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
                data: (plan) => _Body(plan: plan, objective: objective),
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
  const _Body({required this.plan, required this.objective});

  final LearningPlan plan;
  final TargetLevel? objective;

  @override
  Widget build(BuildContext context) {
    final cycle = plan.cycle;
    final changes = plan.recentChanges;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        _HeadCard(cycle: cycle, objective: objective),
        for (final domain in plan.domaines) ...[
          const SizedBox(height: 12),
          _DomainCard(
            domain: domain,
            assessment: plan.domainesAEvaluer
                .where((a) => a.epreuve == domain.epreuve)
                .firstOrNull,
          ),
        ],
        // 🛑 Pas de transition réelle, pas de section : son titre est une
        // période, et l'afficher vide annoncerait un bilan là où rien n'a bougé.
        if (changes != null && changes.transitions.isNotEmpty) ...[
          const SizedBox(height: 22),
          PlanChangesSection(
            changes: changes,
            onDetail: () => openPlanEvolution(context),
          ),
        ],
        const SizedBox(height: 16),
        const PlanNote(kPlanProgressNote),
      ],
    );
  }
}

/// D'où part le candidat, où il va, et sur combien de domaines cela repose.
class _HeadCard extends StatelessWidget {
  const _HeadCard({required this.cycle, required this.objective});

  final PlanCycle? cycle;
  final TargetLevel? objective;

  @override
  Widget build(BuildContext context) {
    final starting = cycle?.startingLevel;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _BigLevel(
                label: kPlanProgressLevelLabel,
                value: starting?.displayName ?? kPlanProgressNoLevel,
                color: AppColors.ink,
                labelColor: AppColors.inkFaint,
              ),
              // Sans objectif déclaré, la flèche n'a rien à désigner : les deux
              // disparaissent ensemble plutôt que de pointer vers un palier
              // que personne n'a demandé.
              if (objective != null) ...[
                const SizedBox(width: 14),
                const Padding(
                  padding: EdgeInsets.only(bottom: 7),
                  child: Icon(
                    LucideIcons.arrowRight,
                    size: 18,
                    color: AppColors.inkFaint,
                  ),
                ),
                const SizedBox(width: 14),
                _BigLevel(
                  label: kPlanProgressObjectiveLabel,
                  value: objective!.wire,
                  color: AppColors.blue,
                  labelColor: AppColors.blue,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.lineSoft)),
            ),
            child: PlanLevelRail(current: cycle?.targetLevel),
          ),
          const SizedBox(height: 12),
          Text(
            planProfileCoverage(cycle, 4),
            style: AppFonts.ui(
              size: 12.5,
              weight: FontWeight.w700,
              color: AppColors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}

class _BigLevel extends StatelessWidget {
  const _BigLevel({
    required this.label,
    required this.value,
    required this.color,
    required this.labelColor,
  });

  final String label;
  final String value;
  final Color color;
  final Color labelColor;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppFonts.label(size: 11.5, color: labelColor)),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppFonts.display(size: 30, height: 1.1, color: color),
          ),
        ],
      );
}

/// Un des quatre domaines : son niveau estimé, puis son détail — les trois
/// paliers en compréhension, les trois tâches en expression.
class _DomainCard extends StatelessWidget {
  const _DomainCard({required this.domain, required this.assessment});

  final PlanDomain domain;

  /// Par quoi mesurer ce domaine quand il ne l'a jamais été. `null` dès qu'il
  /// l'est — le cas normal.
  final PlanDomainAssessment? assessment;

  @override
  Widget build(BuildContext context) {
    final measure = assessment;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => openPlanDomain(context, domain.epreuve),
              child: Row(
                children: [
                  PlanDomainTile(
                    epreuve: domain.epreuve,
                    filled: domain.priority == PlanDomainPriority.forte,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          planDomainLabel(domain.epreuve),
                          style: AppFonts.ui(
                            size: 15,
                            weight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          planDomainProgressSubtitle(domain),
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
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 17,
                    color: AppColors.inkFaint,
                  ),
                ],
              ),
            ),
          ),
          if (domain.paliers.isNotEmpty)
            _Detail(
              title: kPlanProgressLevelsTitle,
              children: [
                for (final level in domain.paliers) _LevelLine(level: level),
              ],
            ),
          if (domain.taches.isNotEmpty)
            _Detail(
              title: kPlanProgressTasksTitle,
              children: [
                for (final task in domain.taches) _TaskLine(task: task),
              ],
            ),
          if (!domain.evaluated) ...[
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.only(top: 13),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.lineSoft)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    kPlanDomainNotEvaluated,
                    style: AppFonts.ui(
                      size: 13,
                      height: 1.5,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  if (measure != null) ...[
                    const SizedBox(height: 12),
                    AppButton(
                      label: planAssessmentCta(measure),
                      icon: LucideIcons.play,
                      variant: AppButtonVariant.outline,
                      height: 46,
                      onPressed: () => openPlanAssessment(context, measure),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Le bloc de détail d'un domaine, sous un filet.
class _Detail extends StatelessWidget {
  const _Detail({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 13),
        padding: const EdgeInsets.only(top: 13),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.lineSoft)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppFonts.label(size: 11.5)),
            const SizedBox(height: 8),
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              children[i],
            ],
          ],
        ),
      );
}

/// Un palier de compréhension : son état, **jamais un pourcentage**.
class _LevelLine extends StatelessWidget {
  const _LevelLine({required this.level});

  final PlanDomainLevel level;

  @override
  Widget build(BuildContext context) {
    final mastery = level.masteryState;
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(level.niveau.wire, style: AppFonts.display(size: 15)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            planLevelSubtitle(level),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.ui(
              size: 12.5,
              height: 1.35,
              color: AppColors.inkFaint,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (level.blocking)
          const AppTag(
            label: kPlanLevelBlockingTag,
            tone: TagTone.amber,
            compact: true,
          )
        else if (mastery != null)
          SkillMasteryTag(state: mastery),
      ],
    );
  }
}

/// Une tâche d'expression : son titre éditorial et ses compétences observées.
class _TaskLine extends StatelessWidget {
  const _TaskLine({required this.task});

  final PlanDomainTask task;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          PlanRankBadge(rank: task.tacheNumero, tone: AppColors.blue),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planTaskTitle(task),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.ui(
                    size: 13.5,
                    weight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  planTaskObservedLabel(task),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.ui(size: 12, color: AppColors.inkFaint),
                ),
              ],
            ),
          ),
        ],
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

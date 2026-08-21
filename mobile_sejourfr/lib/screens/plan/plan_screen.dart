import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/api/audience_repository.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/target_level_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_observer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/blurred_content.dart';
import '../../core/widgets/list_group.dart';
import '../../core/widgets/premium_lock.dart';
import '../../core/widgets/screen_header.dart';
import 'learning_plan_provider.dart';
import 'plan_actions.dart';
import 'plan_labels.dart';
import 'plan_milestone_card.dart';
import 'plan_milestone_labels.dart';
import 'plan_seance_state.dart';
import 'widgets/plan_banner.dart';
import 'widgets/plan_changes_section.dart';
import 'widgets/plan_path_section.dart';
import 'widgets/plan_paywall_card.dart';
import 'widgets/plan_priorities_section.dart';
import 'widgets/plan_priority_hero.dart';
import 'widgets/plan_profile_section.dart';
import 'widgets/plan_seance_section.dart';
import 'widgets/plan_tokens.dart';

/// **Le coach adaptatif.** Ce que le candidat fait maintenant, pourquoi, et où
/// ça le mène.
///
/// L'écran ne recalcule **rien** : les priorités sont ordonnées serveur, les
/// quatre domaines sont **déjà triés par urgence**, la séance est composée
/// serveur, et les verrous viennent d'un `locked` par élément.
///
/// Ordre des blocs, du plus immédiat au plus lointain : contexte → bandeau →
/// **priorité actuelle** → **aujourd'hui** → **mes priorités** → jalon → ce qui
/// a changé → **mon profil TCF** → compléter mon profil → **mon chemin** →
/// liens secondaires.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> with RouteAware {
  PageRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(trackPlan(ref, AudienceEvent.planOpened));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _route) {
      if (_route != null) appRouteObserver.unsubscribe(this);
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    // Une production, une série ou un examen joué au-dessus de cette page peut
    // avoir changé le plan. Le retour est le moment fiable pour récupérer le
    // calcul final.
    ref.invalidate(learningPlanProvider);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(learningPlanProvider);
    await ref.read(learningPlanProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(learningPlanProvider);
    // L'objectif vient du **cycle** quand le serveur en sert un ; sinon du
    // palier visé du compte. `null` reste `null` : on ne devine jamais un B2.
    final objective = plan.valueOrNull?.cycle?.objectiveLevel ??
        ref.watch(userTargetLevelProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Mon plan',
              large: true,
              right: _ObjectiveButton(objective: objective),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.blue,
                onRefresh: _refresh,
                child: plan.when(
                  loading: () => const _LoadingPlan(),
                  error: (error, _) => _PlanError(
                    message: ApiClient.toApiException(error).message,
                    onRetry: () => ref.invalidate(learningPlanProvider),
                  ),
                  data: (value) => _PlanContent(
                    plan: value,
                    objective: objective,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le rappel d'objectif, dans l'en-tête. Sans démarche déclarée il **invite à
/// la choisir** au lieu d'afficher un palier que personne n'a demandé.
class _ObjectiveButton extends StatelessWidget {
  const _ObjectiveButton({required this.objective});

  final TargetLevel? objective;

  @override
  Widget build(BuildContext context) {
    final label =
        objective == null ? 'Mon objectif' : 'Objectif ${objective!.wire}';
    return Material(
      color: AppColors.blueLight,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: () => objective == null
            ? context.push(AppRoutes.targetPath)
            : _showObjectiveSheet(context, objective!),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.target, size: 14, color: AppColors.blue),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppFonts.ui(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showObjectiveSheet(
  BuildContext context,
  TargetLevel objective,
) =>
    showAppSheet<void>(
      context,
      icon: LucideIcons.target,
      title: 'Votre objectif : ${objective.wire}',
      sub: 'Le palier qu\'exige votre démarche',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: PlanLevelRail(current: objective),
        ),
        Text(
          'Le ${objective.wire} ouvre ${objective.demarcheLabel}. Votre plan '
          'construit un palier à la fois : il ne vous propose jamais de sauter '
          'une marche.',
          style: AppFonts.ui(size: 14, height: 1.55, color: AppColors.inkSoft),
        ),
        const PlanNote(
          'Le CECRL n\'est pas une progression linéaire : chaque palier se '
          'construit compétence par compétence, et vos quatre domaines '
          'n\'avancent pas à la même vitesse.',
        ),
      ],
    );

class _PlanContent extends StatelessWidget {
  const _PlanContent({required this.plan, required this.objective});

  final LearningPlan plan;
  final TargetLevel? objective;

  @override
  Widget build(BuildContext context) {
    return switch (plan.state) {
      LearningPlanState.needsDiagnostic => _PlanEmptyState(
          title: 'Construisons votre plan personnalisé',
          description:
              'Faites 1 exercice écrit et 1 oral pour identifier vos premières priorités.',
          actionLabel: 'Faire mon diagnostic',
          actionIcon: LucideIcons.sparkles,
          onAction: () => context.push(AppRoutes.diagnostic),
        ),
      LearningPlanState.diagnosticInProgress => _PlanEmptyState(
          title: 'Votre diagnostic est en cours',
          description:
              'Reprenez là où vous vous êtes arrêté. Vos réponses déjà envoyées sont conservées sur votre compte.',
          actionLabel: 'Reprendre le diagnostic',
          actionIcon: LucideIcons.play,
          onAction: () => context.push(AppRoutes.diagnostic),
        ),
      LearningPlanState.active =>
        _ActivePlan(plan: plan, objective: objective),
    };
  }
}

class _ActivePlan extends ConsumerWidget {
  const _ActivePlan({required this.plan, required this.objective});

  final LearningPlan plan;
  final TargetLevel? objective;

  /// Ce que fait le bouton principal, dérivé de la séance **servie** — et
  /// d'elle seule : ce qui est fait se lit sur `lastActivityAt` et
  /// `stepCompleted`, plus sur un marqueur local qui s'évaporait au
  /// redémarrage.
  _SeanceCta _cta(BuildContext context, WidgetRef ref) {
    final items = plan.seance.items;
    final pending =
        items.where((item) => !planSeanceItemDone(item)).toList(growable: false);

    if (pending.isNotEmpty) {
      final next = pending.first;
      // Une **mesure** compte ses minutes comme le reste — et zéro quand elle
      // n'en a pas (diagnostic, production : rien n'y est chronométré par
      // épreuve), jamais un chiffre inventé.
      final minutes = pending.fold<int>(
        0,
        (sum, item) =>
            sum +
            (item.exercise?.estimatedMinutes ??
                item.milestone?.estimatedMinutes ??
                item.assessment?.estimatedMinutes ??
                0),
      );
      final locked = planSeanceItemLocked(next);
      final started = pending.length != items.length;
      final label = locked
          ? 'Débloquer cet entraînement'
          : started
              ? 'Reprendre · $minutes min'
              : '$kPlanSeanceStart · $minutes min';
      return _SeanceCta(
        label: label,
        locked: locked,
        onTap: () => startPlanSeanceItem(context, ref, next),
      );
    }

    // Tout est fait aujourd'hui. « Refaire ma séance » RELANCE réellement le
    // premier entraînement : il n'y a plus de marqueur local à effacer, et un
    // bouton qui décochait des lignes sans rien faire d'autre n'avait plus
    // d'objet. Rien n'est réinventé — c'est le premier entraînement de la
    // séance, lancé directement (la ligne, elle, ouvre la fiche).
    if (items.isNotEmpty) {
      final first = items.first;
      final locked = planSeanceItemLocked(first);
      return _SeanceCta(
        label: locked ? 'Débloquer cet entraînement' : kPlanSeanceRestart,
        locked: locked,
        onTap: () => startPlanSeanceItem(context, ref, first),
      );
    }

    final exercise = plan.currentPriority?.recommendedExercise;
    if (exercise != null) {
      return _SeanceCta(
        label: exercise.locked ? 'Débloquer cet entraînement' : 'Commencer',
        locked: exercise.locked,
        onTap: () => openPlanExercise(context, ref, exercise),
      );
    }
    return const _SeanceCta(label: kPlanSeanceStart, onTap: null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final hasTcf = auth is AuthAuthenticated && auth.user.hasTcf;
    final estimated =
        ref.watch(dashboardProvider).valueOrNull?.estimatedTcfLevel;
    final cta = _cta(context, ref);
    final changes = plan.recentChanges;
    final current = plan.currentPriority;
    final milestone = plan.milestone;
    // Un jalon déjà présent dans la séance ne se répète pas en carte : ce
    // serait le même examen blanc annoncé deux fois sur le même écran.
    final milestoneInSeance = milestone != null &&
        plan.seance.items.any(
          (item) =>
              item.milestone?.epreuve == milestone.epreuve &&
              item.milestone?.slotNumber == milestone.slotNumber,
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            planContextLine(estimated),
            style: AppFonts.ui(
              size: 13.5,
              height: 1.4,
              color: AppColors.inkSoft,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Le bandeau dit ce qui a bougé ; sinon, un compte gratuit voit
        // pourquoi certains entraînements portent un cadenas. Jamais les deux.
        if (changes != null && !changes.isEmpty)
          PlanUpdatedBanner(
            changes: changes,
            onTap: () => openPlanEvolution(context),
          )
        else if (!hasTcf)
          PlanFreeBar(onTap: () => unawaited(showTcfLockPaywall(context))),
        const SizedBox(height: 14),
        PlanPriorityHero(
          priority: current,
          cycle: plan.cycle,
          objective: objective,
          ctaLabel: cta.label,
          ctaLocked: cta.locked,
          onCta: cta.onTap,
          onWhy: () => unawaited(_showWhySheet(context, plan)),
          onDetail: current == null
              ? null
              : () => openPlanSkill(context, current.skillId, current.section),
        ),
        const SizedBox(height: 18),
        PlanSeanceSection(
          plan: plan,
          onWhy: () => unawaited(_showWhySheet(context, plan)),
        ),
        const SizedBox(height: 22),
        PlanPrioritiesSection(plan: plan),
        // La carte d'offre suit les priorités, à l'endroit exact où le compte
        // gratuit vient de voir ce qu'il ne peut pas encore ouvrir. Elle ne
        // double pas la barre « Version gratuite » du haut : celle-ci explique
        // les cadenas, celle-là dit ce que l'abonnement ouvre.
        if (!hasTcf) ...[
          const SizedBox(height: 18),
          PlanPaywallCard(
            onSubscribe: () => unawaited(showTcfLockPaywall(context)),
          ),
        ],
        if (milestone != null && !milestoneInSeance) ...[
          const SizedBox(height: 22),
          SectionTitle(title: kPlanMilestoneSectionTitle),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              kPlanMilestoneSectionText,
              style: AppFonts.ui(
                size: 12,
                height: 1.35,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          const SizedBox(height: 10),
          PlanMilestoneCard(milestone: milestone),
        ],
        // 🛑 **Pas de transition réelle, pas de section.** Le titre de ce bloc
        // est une période (« Cette semaine ») : l'afficher pour une seule
        // nouvelle priorité — la compétence déjà nommée par la carte du haut —
        // annonçait un bilan de la semaine là où rien n'avait encore bougé.
        // Une première mesure n'est jamais une transition ; le bandeau du haut,
        // lui, continue de signaler la nouvelle priorité en une ligne.
        if (changes != null && changes.transitions.isNotEmpty) ...[
          const SizedBox(height: 22),
          PlanChangesSection(
            changes: changes,
            onDetail: () => openPlanEvolution(context),
          ),
        ],
        const SizedBox(height: 22),
        PlanProfileSection(plan: plan),
        if (plan.domainesAEvaluer.isNotEmpty) ...[
          const SizedBox(height: 22),
          PlanCompleteProfileSection(assessments: plan.domainesAEvaluer),
        ],
        if (plan.cycle != null) ...[
          const SizedBox(height: 22),
          PlanPathSection(cycle: plan.cycle!),
        ],
        const SizedBox(height: 22),
        ListGroup(
          children: [
            ListRow(
              icon: LucideIcons.trendingUp,
              iconBg: AppColors.surface2,
              iconColor: AppColors.inkSoft,
              title: 'Ma progression',
              sub: 'Domaine par domaine, niveau par niveau',
              onTap: () => context.push(AppRoutes.progress),
            ),
            ListRow(
              icon: LucideIcons.clipboardCheck,
              iconBg: AppColors.surface2,
              iconColor: AppColors.inkSoft,
              title: 'Mon diagnostic',
              sub: plan.diagnosticCompletedAt == null
                  ? 'Résultat de départ et priorités initiales'
                  : 'Passé le ${_shortDate(plan.diagnosticCompletedAt!)}',
              onTap: () => context.push(AppRoutes.diagnostic),
            ),
          ],
        ),
      ],
    );
  }
}

class _SeanceCta {
  const _SeanceCta({
    required this.label,
    required this.onTap,
    this.locked = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool locked;
}

/// « Pourquoi cette séance ? » — composé **des faits servis**, jamais d'une
/// phrase venue du serveur (il n'en produit aucune pour la séance).
Future<void> _showWhySheet(BuildContext context, LearningPlan plan) =>
    showAppSheet<void>(
      context,
      icon: LucideIcons.sparkles,
      title: kPlanSeanceWhy,
      sub: plan.seance.isEmpty ? null : planSeanceMeta(plan.seance),
      children: [
        for (final line in planSeanceRationale(plan))
          Text(
            line,
            style: AppFonts.ui(size: 14, height: 1.6, color: AppColors.inkSoft),
          ),
        if (plan.seance.items.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Column(
              children: [
                for (var i = 0; i < plan.seance.items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _WhyRow(item: plan.seance.items[i]),
                ],
              ],
            ),
          ),
        AppButton(
          label: 'J\'ai compris',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );

/// Le récapitulatif d'une ligne de séance dans la feuille « Pourquoi cette
/// séance ? ».
///
/// 🛑 **Il floute exactement ce que la séance floute.** Cette feuille reprend
/// les mêmes lignes que la carte « Aujourd'hui » : y montrer en clair le titre
/// d'un entraînement verrouillé démentirait le rideau posé dix lignes plus
/// haut. Ce n'est pas une extension du verrou — c'est la même ligne, vue deux
/// fois.
class _WhyRow extends StatelessWidget {
  const _WhyRow({required this.item});

  final PlanSeanceItem item;

  @override
  Widget build(BuildContext context) {
    final milestone = item.milestone;
    final assessment = item.assessment;
    final minutes = item.exercise?.estimatedMinutes ??
        milestone?.estimatedMinutes ??
        assessment?.estimatedMinutes ??
        0;
    final epreuve = milestone?.epreuve ??
        assessment?.epreuve ??
        (item.section == null ? null : planEpreuveOfSection(item.section!));
    final locked = planSeanceItemLocked(item);

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          planItemTitle(item),
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
          '${item.nature.label} · ${planItemEyebrow(item)} · '
          '${planItemKindLabel(item)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.ui(size: 12, color: AppColors.inkFaint),
        ),
      ],
    );

    return Row(
      children: [
        PlanDomainTile(epreuve: epreuve, size: 32),
        const SizedBox(width: 11),
        Expanded(child: locked ? BlurredContent(child: body) : body),
        if (locked) ...[
          const SizedBox(width: 8),
          const PremiumLockPill(size: 22),
        ] else if (minutes > 0) ...[
          const SizedBox(width: 8),
          Text(
            '$minutes min',
            style: AppFonts.ui(
              size: 12.5,
              weight: FontWeight.w700,
              color: AppColors.inkFaint,
            ),
          ),
        ],
      ],
    );
  }
}

class _PlanEmptyState extends StatelessWidget {
  const _PlanEmptyState({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  final String title;
  final String description;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
        children: [
          AppCard(
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    color: AppColors.blueLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.map,
                    size: 29,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(height: 17),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppFonts.display(size: 21),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: AppFonts.ui(
                    size: 13.5,
                    color: AppColors.inkSoft,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: actionLabel,
                  icon: actionIcon,
                  onPressed: onAction,
                ),
              ],
            ),
          ),
        ],
      );
}

class _LoadingPlan extends StatelessWidget {
  const _LoadingPlan();

  @override
  Widget build(BuildContext context) => ListView(
        children: const [
          Padding(
            padding: EdgeInsets.only(top: 120),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.blue),
            ),
          ),
        ],
      );
}

class _PlanError extends StatelessWidget {
  const _PlanError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              children: [
                const Icon(
                  LucideIcons.cloudOff,
                  size: 28,
                  color: AppColors.inkFaint,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppFonts.ui(size: 13.5, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: 'Réessayer',
                  variant: AppButtonVariant.soft,
                  height: 44,
                  fullWidth: false,
                  onPressed: onRetry,
                ),
              ],
            ),
          ),
        ],
      );
}

String _shortDate(DateTime date) {
  final local = date.toLocal();
  const months = <String>[
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
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

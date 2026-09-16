import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/models/diagnostic_models.dart';
import '../../../core/models/journey_models.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/skill_models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/list_group.dart';
import '../../../core/widgets/premium_lock.dart';
import '../../../core/widgets/paywall_context.dart';
import '../../../core/widgets/sejour/sejour_kit.dart';
import '../plan_actions.dart';
import '../plan_groups.dart';
import '../journey_labels.dart';
import '../plan_labels.dart';
import '../plan_milestone_labels.dart';
import '../plan_milestone_launcher.dart';
import '../plan_now_card.dart';
import '../plan_task_path.dart';

/// **Le plan TCF**, dans l'ordre de la maquette : d'où l'on part, ce qu'on fait
/// maintenant, le parcours de la tâche en cours, les priorités, ce qui est
/// acquis, ce qui a bougé.
///
/// 🛑 **Rien n'est recalculé.** Les priorités sont ordonnées serveur, le
/// groupement « épreuve → tâche » est une vue de `domaines[]`
/// ([planPriorityGroups]), le compteur d'étape est lu sur `domaines[].taches[]`,
/// et chaque verrou vient d'un `locked` **servi** — jamais du rang d'une ligne.
///
/// Deux mises en page, une seule lecture des données : un compte **sans accès
/// TCF** voit son constat entier (objectif, priorités, première étape) et la
/// porte d'abonnement ; un abonné voit en plus ce qu'il peut lancer.
class PlanTcfView extends ConsumerWidget {
  const PlanTcfView({
    super.key,
    required this.plan,
    this.journey,
    required this.objective,
    this.affiner,
    this.trailing = const <Widget>[],
  });

  final LearningPlan plan;

  /// **Le parcours TCF**, quand il est chargé.
  ///
  /// 🛑 `null` est un cas NORMAL — pas encore lu, ou backend antérieur à
  /// l'endpoint : la timeline disparaît, elle n'affiche jamais un squelette.
  final Journey? journey;
  final TargetLevel? objective;

  /// **L'invitation au diagnostic complet**, posée à l'emplacement de l'ancien
  /// « Compléter mon profil » (supprimé le 2026-09-13).
  ///
  /// 🛑 **Une seule occurrence par écran.** C'est désormais le SEUL appel à
  /// compléter son profil : les cartes d'épreuve et leurs CTA « Passer l'examen
  /// blanc » / « Faire une production » ont disparu avec la section. Servi ou
  /// rien — à 4 / 4 l'autorité `affinerPlan` rend `null` et l'hôte passe `null`.
  final Widget? affiner;

  /// Ce qui se pose **après** le contenu du Plan, dans le MÊME défilement —
  /// aujourd'hui le lien « Revoir mon diagnostic rapide ».
  ///
  /// 🛑 Un slot, pas un widget imposé : ce que le Plan **est** ne dépend pas de
  /// ce qui l'accompagne, et deux listes qui recopieraient la même carte
  /// auraient fini par en montrer deux versions. Même motif que les slots
  /// `leading`/`trailing` de `DiagnosticResultView`, pour la même raison : cette
  /// vue **EST** la `ListView`, imbriquer deux scrollables était le risque.
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final hasTcf = auth is AuthAuthenticated && auth.user.hasTcf;

    if (!hasTcf) {
      return Column(
        children: [
          Expanded(child: ListView(children: _free(context))),
          SfStickyBar(
            child: SfButton(
              label: _unlockCta(objective),
              caption: kPlanUnlockCaption,
              onPressed: () => unawaited(showTcfLockPaywall(
                context,
                ref: ref,
                ctaLocation: AnalyticsCtaLocation.lockedPlan,
                origin: PaywallOrigin.plan,
              )),
            ),
          ),
        ],
      );
    }
    return ListView(children: _premium(context, ref));
  }

  /* ------------------------------------------------------------- abonné --- */

  List<Widget> _premium(BuildContext context, WidgetRef ref) {
    final changes = plan.recentChanges;
    final milestone = plan.milestone;

    return <Widget>[
      SfTop(kicker: planTopKicker(objective), title: kPlanTitle),
      const SizedBox(height: 14),
      _goalStrip(context),
      SfSection(
        title: kPlanNowTitle,
        flush: true,
        child: _nowCard(context, ref),
      ),
      ..._journeySection(context),
      ..._prioritiesSection(free: false),
      ..._doneSection(),
      ..._changesSection(changes),
      if (milestone != null) _milestoneSection(context, ref, milestone),
      // 🛑 L'emplacement de l'ancien « Compléter mon profil » : c'est ici que
      // se complète un profil, et il n'y a plus qu'une façon de le faire.
      if (affiner != null) affiner!,
      _links(context),
      ...trailing,
      const SizedBox(height: 28),
    ];
  }

  /* -------------------------------------------------------- sans accès ---- */

  /// Le Plan d'un compte **sans accès** : un constat, et une seule porte.
  ///
  /// 🛑 Il ne prend plus de `WidgetRef` — plus rien ici ne démarre quoi que ce
  /// soit, et c'est la garantie la plus solide qu'on puisse en donner.
  List<Widget> _free(BuildContext context) => <Widget>[
        SfTop(kicker: kPlanTopKickerFree, title: planTitleFree(objective)),
        const SizedBox(height: 14),
        _goalStrip(context, engineLine: false),
        ..._prioritiesSection(free: true),
        SfSection(
          title: kPlanFreeFirstStepTitle,
          flush: true,
          child: _freeStepCard(),
        ),
        ..._journeySection(context),
        const SfSection(
          flush: true,
          child: SfUnlockHero(
            title: kPlanUnlockHeroTitle,
            text: kPlanUnlockHeroText,
            checks: kPlanUnlockHeroChecks,
          ),
        ),
        // 🛑 APRÈS le hero d'abonnement, et c'est délibéré : sur un Plan
        // gratuit, le seul bouton ROUGE reste « Débloquer mon plan », en barre
        // basse. Le diagnostic complet porte le bleu plein — visible, jamais
        // concurrent.
        if (affiner != null) affiner!,
        ...trailing,
        const SizedBox(height: 24),
      ];

  /* ------------------------------------------------------------ blocs ----- */

  /// « Niveau actuel → objectif ». Les deux paliers sont **servis** ; absents,
  /// ils s'écrivent « — » : *null = inconnu, jamais mauvais*.
  Widget _goalStrip(BuildContext context, {bool engineLine = true}) {
    final cycle = plan.cycle;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SfGoalStrip(
            current: cycle?.startingLevel?.displayName ?? kPlanGoalUnknown,
            goal: objective?.wire ?? kPlanGoalUnknown,
          ),
          if (objective == null) ...[
            const SizedBox(height: 10),
            SfButton(
              label: kPlanGoalPick,
              variant: SfButtonVariant.line,
              onPressed: () => context.push(AppRoutes.targetPath),
            ),
          ],
          if (engineLine) ...[
            const SizedBox(height: 10),
            const SfTiny(kPlanEngineLine),
            if (cycle != null) ...[
              const SizedBox(height: 6),
              SfTiny(planCycleStateText(cycle.state)),
            ],
          ],
        ],
      ),
    );
  }

  /// **« Votre première étape est prête »**, la carte d'un compte SANS accès.
  ///
  /// Elle suit la maquette du propriétaire (`~/Desktop/capture_plan_gratuit.png`)
  /// et **ne ressemble pas** à la carte d'un abonné : pastille de domaine,
  /// l'étape nommée, puis les **trois bénéfices verrouillés**. C'est tout.
  ///
  /// ⚠️ Elle empruntait `_nowCard` avec un drapeau `free`, donc elle héritait de
  /// tout ce qu'une carte d'abonné porte — pastille « Priorité 1 », encart
  /// « Compétence actuelle », méta « 5 sujets · ≈ 4 min », explication du
  /// correcteur — et les trois cadenas ne s'affichaient **que** sur un verrou
  /// servi, donc presque jamais. Le candidat sans accès voyait la carte d'un
  /// abonné. Deux mises en page différentes, deux fonctions.
  ///
  /// 🛑 **AUCUN geste ne part d'ici** (arbitrage du propriétaire, 2026-09-12 :
  /// « dans le plan, on ne travaille rien si on n'est pas abonné ; on passe par
  /// Réviser pour voir ce qu'on peut utiliser gratuitement »).
  ///
  /// ⚠️ Cela **révoque**, pour cette carte seulement, « ne pas coder : l'étape 1
  /// est toujours ouverte — l'app lit `locked`, toujours ». Le Plan d'un compte
  /// sans accès est un **constat**, pas un point de départ : il montre ce qui
  /// l'attend et la porte d'abonnement, rien d'autre.
  ///
  /// 🛑 **Ce n'est pas un verrou** : on ne ferme aucun droit, on retire un
  /// chemin. Ce que le serveur ouvre gratuitement reste accessible par
  /// **Réviser**, et c'est lui qui reste l'arbitre (403).
  Widget _freeStepCard() {
    final priority = plan.currentPriority;
    if (priority == null) {
      return const SfNoteCard(
        icon: LucideIcons.circleCheck,
        title: kPlanNowEmptyTitle,
        child: SfTiny(kPlanSeanceEmpty),
      );
    }

    final epreuve = planEpreuveOfSection(priority.section);
    final task = SkillTaskCode.fromSkillCode(priority.skillCode);

    return SfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(planDomainIcon(epreuve),
                    size: 24, color: AppColors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planPriorityGroupTitle(
                        epreuve: epreuve,
                        task: task,
                        context: null,
                      ),
                      style: AppFonts.display(
                          size: 16, weight: FontWeight.w700, height: 1.25),
                    ),
                    const SizedBox(height: 3),
                    SfTiny(priority.title),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 🛑 **Les trois bénéfices, et c'est tout** : c'est ce que
          // l'abonnement ouvre sur CETTE étape, et c'est la raison d'être de la
          // carte. Le seul geste de l'écran est la barre basse, « Débloquer mon
          // plan ».
          for (final label in kPlanFreeStepLocks) SfLockItem(label: label),
        ],
      ),
    );
  }

  /// La carte d'action d'un **abonné**. ⚠️ Elle portait un drapeau `free` et
  /// servait aussi le plan gratuit : ce chemin est parti avec
  /// [_freeStepCard] — deux mises en page différentes, deux fonctions.
  ///
  /// 🛑 **Son contenu est décidé par [planNowCard], pas ici** — la même autorité
  /// que l'Accueil (`_actionTcf`) et que les deux cartes du web. L'écran
  /// assemble le kit, il ne choisit ni l'identité de la carte ni ce qu'elle
  /// lance.
  Widget _nowCard(BuildContext context, WidgetRef ref) {
    final carte = planNowCard(plan);
    if (carte == null) {
      return const SfNoteCard(
        icon: LucideIcons.circleCheck,
        title: kPlanNowEmptyTitle,
        child: SfTiny(kPlanSeanceEmpty),
      );
    }

    final mesure = carte.mesure;
    final exercise = carte.exercise;

    final meta = <SfMeta>[
      if (carte.minutesLabel != null)
        SfMeta(LucideIcons.clock, carte.minutesLabel!),
      if (carte.kindLabel != null) SfMeta(LucideIcons.target, carte.kindLabel!),
    ];

    return SfNowCard(
      variant: carte.estVerification
          ? SfNowCardVariant.verify
          : SfNowCardVariant.standard,
      icon: carte.icon,
      title: carte.title,
      subtitle: carte.subtitle,
      badge: carte.badge,
      objectiveLabel: carte.objectiveLabel,
      objective: carte.objective,
      meta: meta,
      action: SfButton(
        label: carte.locked ? kPlanNowLockedCta : carte.cta,
        onPressed: mesure != null
            // Le lanceur de mesure est une AUTORITÉ EXISTANTE
            // (`startPlanSeanceItem` → `openPlanAssessment`) : on ne réécrit
            // aucun aiguillage ici, le mobile lit et exécute.
            ? () => unawaited(startPlanSeanceItem(context, ref, mesure))
            : exercise == null
                ? null
                : () => unawaited(openPlanExercise(
                      context,
                      ref,
                      exercise,
                      masteryBefore: carte.priority.masteryState,
                    )),
      ),
      // Deux lignes DISTINCTES : ce que le correcteur a constaté, et où en est
      // la série. Concaténées, la seconde se lisait comme la suite de la
      // première phrase.
      caption: carte.lines.isEmpty ? null : carte.lines.join('\n'),
    );
  }

  /// **La file d'étapes**, telle que le serveur l'a construite (spec §12-14).
  ///
  /// 🛑 **Rien n'est décidé ici** : ni l'ordre (c'est la position, et elle ne se
  /// recalcule pas), ni le statut, ni le verrou, ni ce qui est affiché — le
  /// serveur a déjà coupé selon §14. L'écran ne fait que peindre.
  ///
  /// 🛑 **Une étape verrouillée reste à sa place**, avec son cadenas : le Plan
  /// reste intégralement visible, sans accès comme avec (contradiction #1,
  /// tranchée le 2026-08-21). C'est pourquoi la **même** section sert les deux
  /// variantes de l'écran — un parcours amputé pour un compte gratuit serait un
  /// second parcours.
  List<Widget> _journeySection(BuildContext context) {
    final parcours = journey;
    if (parcours == null) return const <Widget>[];

    // 🛑 **Aucun objectif déclaré ⇒ aucun parcours en base** (arbitrage D-3).
    // Ce n'est pas un parcours vide : c'est l'absence de parcours, et le
    // distinguer évite de féliciter un candidat qui n'a rien commencé.
    if (parcours.state == JourneyState.needsObjective) {
      return <Widget>[
        SfSection(
          title: kJourneyNeedsObjectiveTitle,
          child: SfStack(
            children: [
              const SfCard(
                child: Text(kJourneyNeedsObjectiveText),
              ),
              SfButton(
                label: kJourneyNeedsObjectiveCta,
                onPressed: () => context.push(AppRoutes.targetPath),
              ),
            ],
          ),
        ),
      ];
    }

    // Plus rien d'ouvert. 🛑 La **suggestion** est hors file : elle n'a pas de
    // position, elle ne se clôt pas, et l'ignorer ne laisse rien « en attente ».
    if (parcours.state == JourneyState.upToDate) {
      return <Widget>[
        SfSection(
          title: kJourneyUpToDateTitle,
          child: SfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kJourneyUpToDateText,
                  style: AppFonts.ui(size: 14, color: AppColors.inkSoft),
                ),
                if (parcours.suggestion == JourneySuggestionType.mockExam) ...[
                  const SizedBox(height: 8),
                  Text(
                    kJourneySuggestionMockExam,
                    style: AppFonts.ui(size: 12, color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
        ),
      ];
    }

    if (parcours.steps.isEmpty) return const <Widget>[];
    final more = journeyMoreLabel(parcours.hiddenUpcomingCount);
    return <Widget>[
      SfSection(
        title: journeyTitle(parcours.targetLevel),
        flush: true,
        child: SfCard(
          child: SfJourneyList(
            children: [
              for (final step in parcours.steps)
                SfJourneyRow(
                  title: journeyStepTitle(step),
                  subtitle: journeyStepSubtitle(step),
                  state: journeyKitState(step),
                  kind: journeyKind(step),
                  badge: journeyBadge(step),
                  locked: step.locked,
                ),
            ],
          ),
        ),
      ),
      // 🛑 Le compte des étapes repliées est **servi** : le déduire de la
      // longueur de la liste donnerait un nombre faux dès que le filtrage
      // d'affichage retient une étape verrouillée hors fenêtre.
      if (more != null) ...[
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(more, style: AppFonts.ui(size: 12, color: AppColors.muted)),
        ),
      ],
      // 🛑 Des étapes restent, mais **aucune n'est exécutable** : on le dit au
      // lieu de laisser une file sans étape courante, qui se lirait comme un
      // parcours en panne.
      if (parcours.state == JourneyState.locked) ...[
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            kJourneyLockedCaption,
            style: AppFonts.ui(size: 12, color: AppColors.muted),
          ),
        ),
      ],
    ];
  }

  List<Widget> _prioritiesSection({required bool free}) {
    final groups = planPriorityGroups(plan);
    if (groups.isEmpty) return const <Widget>[];
    final shown = groups.take(3).toList(growable: false);
    // 🛑 RÉTRACTABLES DÈS QU'IL Y EN A PLUS D'UN (2026-09-13, demande du
    // propriétaire). Une priorité seule n'a aucune raison de se replier : elle
    // EST l'écran. À partir de deux, trois encarts de huit compétences empilés
    // dépliés poussent la priorité n°2 hors de vue.
    final repliables = shown.length > 1;
    return <Widget>[
      SfSection(
        // Un compte sans accès ne lit pas encore un objectif chiffré : son
        // bloc s'appelle simplement « Vos priorités », comme la maquette.
        title: free ? kPlanPrioritiesShort : planPrioritiesSectionTitle(objective),
        child: SfStack(
          children: [
            for (var i = 0; i < shown.length; i++)
              _priorityCard(shown[i], i + 1,
                  free: free, repliable: repliables),
          ],
        ),
      ),
    ];
  }

  Widget _priorityCard(
    PlanPriorityGroup group,
    int rank, {
    required bool free,
    bool repliable = false,
  }) {
    final dto = group.task == null ? null : _taskDto(group.task!);
    final statuses = planStatusSummary(group.rows.map((row) => row.status));
    // Un compte sans accès ne voit aucune ligne : il n'y a donc rien à replier,
    // et le bouton n'apparaît pas.
    final replie = repliable && !free && group.foldedCount > 0;
    final visibles = replie ? group.collapsedRows : group.visibleRows;
    return SfPrio(
      rank: rank,
      tag: planPriorityRankTag(rank),
      title: planPriorityGroupTitle(
        epreuve: group.epreuve,
        task: group.task,
        context: group.context,
      ),
      text: dto != null
          ? planTaskObservedLabel(dto)
          : (statuses.isEmpty ? null : statuses),
      // 🛑 Le compteur du bouton porte sur ce qui est RÉELLEMENT replié —
      // jamais une constante, jamais le `hiddenCount` d'un autre plafond.
      moreLabel: replie ? planGroupMoreLabel(group.foldedCount) : null,
      lessLabel: replie ? kPlanGroupLessLabel : null,
      details: replie
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final row in group.foldedRows)
                  SfSkillRow(label: row.title, state: _rowState(row)),
              ],
            )
          : null,
      child: free
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dto != null && dto.totalSkills > 0)
                  SfProgressMini(
                    ratio: dto.observedSkills / dto.totalSkills,
                    semanticsLabel: planTaskObservedLabel(dto),
                  ),
                for (final row in visibles)
                  SfSkillRow(label: row.title, state: _rowState(row)),
                // Encart rétractable : le reste est derrière le bouton, pas
                // derrière une ligne de texte inerte.
                if (!replie && group.hiddenCount > 0) ...[
                  const SizedBox(height: 6),
                  SfTiny(planGroupMoreLabel(group.hiddenCount)),
                ],
              ],
            ),
    );
  }

  List<Widget> _doneSection() {
    if (plan.completedSteps.isEmpty) return const <Widget>[];
    return <Widget>[
      SfSection(
        title: kPlanDoneTitle,
        flush: true,
        child: SfCard(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final step in plan.completedSteps)
                SfCheckRow(label: planDoneRowLabel(step), large: true),
            ],
          ),
        ),
      ),
    ];
  }

  /// L'encart vert. 🛑 **`recentChanges == null` est le cas normal** : le bloc
  /// disparaît, il ne s'affiche pas vide. Seules les transitions que le serveur
  /// dit **positives** (`progress`) y entrent — une régression n'est pas une
  /// progression détectée.
  List<Widget> _changesSection(PlanRecentChanges? changes) {
    if (changes == null || changes.isEmpty) return const <Widget>[];
    final progress = changes.transitions
        .where((transition) => transition.progress)
        .toList(growable: false);
    final next = planChangesNext(changes);
    if (progress.isEmpty && next == null) return const <Widget>[];
    return <Widget>[
      SfSection(
        flush: true,
        child: SfCard(
          variant: SfCardVariant.ok,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SfLabel(kPlanChangesTitle, color: AppColors.greenDark),
              const SizedBox(height: 4),
              for (final transition in progress)
                SfCheckRow(
                  label:
                      '${transition.title} — ${planTransitionLabel(transition)}',
                  large: true,
                ),
              if (next != null) ...[
                const SizedBox(height: 8),
                SfInsight(next),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  /// Le **jalon** : un examen blanc que le serveur juge mérité. Il n'a aucun
  /// équivalent dans la maquette, et il porte une information qu'elle ne couvre
  /// pas — d'où sa place, en fin d'écran.
  Widget _milestoneSection(
    BuildContext context,
    WidgetRef ref,
    PlanMilestone milestone,
  ) {
    return SfSection(
      title: kPlanMilestoneSectionTitle,
      flush: true,
      child: SfNoteCard(
        icon: LucideIcons.graduationCap,
        title: milestone.displayTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SfTiny(milestone.displayText),
            const SizedBox(height: 4),
            SfTiny(milestone.displayMeta),
            const SizedBox(height: 12),
            SfButton(
              label:
                  milestone.locked ? kPlanMilestoneLockedCta : kPlanMilestoneCta,
              variant: SfButtonVariant.blue,
              onPressed: () => unawaited(
                milestone.locked
                    ? showTcfLockPaywall(
                        context,
                        ref: ref,
                        ctaLocation: AnalyticsCtaLocation.lockedPlan,
                        origin: PaywallOrigin.plan,
                      )
                    : startPlanMilestone(context, ref, milestone),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Les accès secondaires du Plan. La maquette n'en montre aucun : ils restent
  /// parce que ce sont les **seules** portes vers le référentiel complet, la
  /// progression par domaine et le diagnostic.
  Widget _links(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, sfSectionGap, 16, 0),
      child: ListGroup(
        children: [
          ListRow(
            icon: LucideIcons.layoutGrid,
            iconBg: AppColors.surface2,
            iconColor: AppColors.muted,
            title: kPlanAllSkillsTitle,
            sub: kPlanAllSkillsSub,
            onTap: () => context.push(AppRoutes.planSkills),
          ),
          ListRow(
            icon: LucideIcons.trendingUp,
            iconBg: AppColors.surface2,
            iconColor: AppColors.muted,
            title: planProgressTitle(objective),
            sub: planProfileCoverage(plan.cycle, plan.domaines.length),
            onTap: () => context.push(AppRoutes.planProgress),
          ),
          ListRow(
            icon: LucideIcons.graduationCap,
            iconBg: AppColors.surface2,
            iconColor: AppColors.muted,
            title: kPlanExamsTitle,
            sub: kPlanExamsSub,
            onTap: () => context.go(AppRoutes.examens),
          ),
          ListRow(
            icon: LucideIcons.clipboardCheck,
            iconBg: AppColors.surface2,
            iconColor: AppColors.muted,
            title: kPlanDiagnosticTitle,
            sub: kPlanDiagnosticSub,
            onTap: () => context.push(AppRoutes.diagnostic),
          ),
        ],
      ),
    );
  }

  /* ------------------------------------------------------------ lecture --- */

  /// 🛑 **La coche d'une ligne de priorité se lit sur le STATUT SERVI de la
  /// ligne, et sur rien d'autre** — miroir strict de `PriorityCard` côté web
  /// (`LearningPlanView.tsx` : `row.status === "SOLIDE" ? "done" : "todo"`).
  ///
  /// Elle croisait aussi `plan.completedSteps` — la liste des **étapes
  /// franchies**, qui sert la carte « Déjà travaillé et validé » : deux règles
  /// pour la même coche, donc deux encarts de priorités différents pour le même
  /// candidat selon le front. Une étape franchie n'est pas un statut de ligne,
  /// et le serveur publie déjà celui-ci.
  SfStepState _rowState(PlanPriorityGroupRow row) {
    if (row.skillId == plan.currentPriority?.skillId) return SfStepState.now;
    return row.status == PlanRowStatus.solide
        ? SfStepState.done
        : SfStepState.todo;
  }

  PlanDomainTask? _taskDto(SkillTaskCode task) => planTaskDto(plan, task);

}

/// Le geste de la barre basse : il nomme le palier visé quand il est connu,
/// jamais un palier deviné. Le libellé de base reste celui de
/// [kUnlockPlanCta] — l'app n'a qu'une formule pour cette action.
String _unlockCta(TargetLevel? objective) =>
    objective == null ? kUnlockPlanCta : '$kUnlockPlanCta ${objective.wire}';


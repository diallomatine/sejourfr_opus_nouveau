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
import '../journey_labels.dart';
import '../plan_actions.dart';
import '../plan_labels.dart';
import '../plan_milestone_labels.dart';
import '../plan_milestone_launcher.dart';
import '../plan_now_card.dart';
import 'plan_cycle_section.dart';

/// **Le plan TCF**, dans l'ordre de la maquette : d'où l'on part, ce qu'on fait
/// maintenant, le cycle par épreuve.
///
/// 🛑 **Le bas de l'écran a été VIDÉ** (arbitrage du propriétaire,
/// 2026-09-19) : « Déjà travaillé et validé », « Progression détectée », la
/// carte du diagnostic complet en cours, « Toutes mes compétences », « Mes
/// examens blancs » et « Revoir mon diagnostic rapide » ont été supprimés.
/// Sous le cycle il ne reste que « Ma progression » et « Mon diagnostic ». Ne
/// pas les réintroduire.
///
/// 🛑 **Le bloc « Vos priorités pour atteindre … » n'existe plus** (arbitrage du
/// propriétaire, 2026-09-18) : il disait la même chose que les blocs d'épreuve
/// du cycle, en moins précis — mêmes compétences, sans leur position dans le
/// cycle, sans leur examen, et plafonné à trois groupes. Ne pas le
/// réintroduire.
///
/// 🛑 **Rien n'est recalculé.** L'ordre des blocs, l'état de chaque étape et
/// chaque verrou viennent d'un fait **servi** — jamais du rang d'une ligne.
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
  });

  final LearningPlan plan;

  /// **Le parcours TCF**, quand il est chargé.
  ///
  /// 🛑 `null` est un cas NORMAL — pas encore lu, ou backend antérieur à
  /// l'endpoint : la timeline disparaît, elle n'affiche jamais un squelette.
  final Journey? journey;
  final TargetLevel? objective;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final hasTcf = auth is AuthAuthenticated && auth.user.hasTcf;

    if (!hasTcf) {
      return Column(
        children: [
          Expanded(child: ListView(children: _free(context, ref))),
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
      // 🛑 **Le CYCLE remplace la file plate** (D-12 / D-22, 2026-09-18) : un
      // bloc par épreuve, l'examen en fin de bloc, et la fin de cycle avec ses
      // deux issues.
      PlanCycleSection(plan: plan, journey: journey),
      if (milestone != null) _milestoneSection(context, ref, milestone),
      _links(context),
      const SizedBox(height: 28),
    ];
  }

  /* -------------------------------------------------------- sans accès ---- */

  /// Le Plan d'un compte **sans accès** : un constat, et une seule porte.
  ///
  /// 🛑 Il ne prend plus de `WidgetRef` — plus rien ici ne démarre quoi que ce
  /// soit, et c'est la garantie la plus solide qu'on puisse en donner.
  List<Widget> _free(BuildContext context, WidgetRef ref) => <Widget>[
        SfTop(kicker: kPlanTopKickerFree, title: planTitleFree(objective)),
        const SizedBox(height: 14),
        _goalStrip(context),
        SfSection(
          title: kPlanFreeFirstStepTitle,
          flush: true,
          child: _freeStepCard(context, ref),
        ),
        // 🛑 **Le cycle reste ENTIER, même sans accès** : ses quatre blocs et
        // toutes leurs étapes sont affichés à leur place, avec leur cadenas. Le
        // masquer priverait le candidat de l'information la plus utile qu'il
        // possède — c'est la contradiction #1 du dépôt, tranchée le 2026-08-21.
        // Le bouton « Débloquer mon plan » est **ancré en barre basse**.
        PlanCycleSection(plan: plan, journey: journey),
        const SfSection(
          flush: true,
          child: SfUnlockHero(
            title: kPlanUnlockHeroTitle,
            text: kPlanUnlockHeroText,
            checks: kPlanUnlockHeroChecks,
          ),
        ),
        const SizedBox(height: 24),
      ];

  /* ------------------------------------------------------------ blocs ----- */

  /// « Niveau actuel → objectif ». Les deux paliers sont **servis** ; absents,
  /// ils s'écrivent « — » : *null = inconnu, jamais mauvais*.
  Widget _goalStrip(BuildContext context) {
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
  /// 🛑 **AUCUN ENTRAÎNEMENT ne part d'ici** (arbitrage du propriétaire,
  /// 2026-09-12 : « dans le plan, on ne travaille rien si on n'est pas abonné ;
  /// on passe par Réviser pour voir ce qu'on peut utiliser gratuitement »). Le
  /// seul geste est l'**offre**, exigé par la spec §7 depuis D-18 : la carte
  /// nomme la première étape verrouillée, le tap ouvre « Débloquer mon plan ».
  /// Il ne travaille rien — il ne contredit donc pas l'arbitrage.
  ///
  /// ⚠️ Cela **révoque**, pour cette carte seulement, « ne pas coder : l'étape 1
  /// est toujours ouverte — l'app lit `locked`, toujours ». Le Plan d'un compte
  /// sans accès est un **constat**, pas un point de départ : il montre ce qui
  /// l'attend et la porte d'abonnement, rien d'autre.
  ///
  /// 🛑 **Ce n'est pas un verrou** : on ne ferme aucun droit, on retire un
  /// chemin. Ce que le serveur ouvre gratuitement reste accessible par
  /// **Réviser**, et c'est lui qui reste l'arbitre (403).
  Widget _freeStepCard(BuildContext context, WidgetRef ref) {
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
          // 🛑 **Les trois bénéfices** : c'est ce que l'abonnement ouvre sur
          // CETTE étape, et c'est la raison d'être de la carte.
          for (final label in kPlanFreeStepLocks) SfLockItem(label: label),
          const SizedBox(height: 12),
          // 🛑 **Le tap ouvre le paywall EXISTANT** (spec §7 / D-18), avec le
          // contexte du Plan — aucune modale nouvelle. En **bleu** : le seul
          // bouton rouge de cet écran reste « Débloquer mon plan », en barre
          // basse.
          SfButton(
            label: kPlanNowLockedCta,
            variant: SfButtonVariant.blue,
            onPressed: () => unawaited(showTcfLockPaywall(
              context,
              ref: ref,
              ctaLocation: AnalyticsCtaLocation.lockedPlan,
              origin: PaywallOrigin.plan,
            )),
          ),
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
    final carte = planNowCard(plan, journey: journey);
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
      // 🛑 **Le geste vient de [planNowCard], il ne se redéduit pas ici.**
      // `aucun` ⇒ aucun bouton : l'action ne se résout pas, et la version
      // d'avant lançait pire — la compétence que le Plan priorisait ce jour-là,
      // pendant que la carte en annonçait une autre. `debloquer` ⇒ le paywall
      // **existant** du Plan, avec son contexte (spec §7 / D-18).
      action: switch (carte.geste) {
        PlanNowGeste.aucun => null,
        PlanNowGeste.debloquer => SfButton(
            label: carte.cta,
            variant: SfButtonVariant.blue,
            onPressed: () => unawaited(showTcfLockPaywall(
              context,
              ref: ref,
              ctaLocation: AnalyticsCtaLocation.lockedPlan,
              origin: PaywallOrigin.plan,
            )),
          ),
        PlanNowGeste.lancer => SfButton(
            label: carte.cta,
            onPressed: mesure != null
                // Le lanceur de mesure est une AUTORITÉ EXISTANTE
                // (`startPlanSeanceItem` → `openPlanAssessment`) : on ne
                // réécrit aucun aiguillage ici, le mobile lit et exécute.
                ? () => unawaited(startPlanSeanceItem(context, ref, mesure))
                : exercise == null
                    ? null
                    : () => unawaited(openPlanExercise(
                          context,
                          ref,
                          exercise,
                          masteryBefore: carte.priority?.masteryState,
                        )),
          ),
      },
      // Deux lignes DISTINCTES : ce que le correcteur a constaté, et où en est
      // la série. Concaténées, la seconde se lisait comme la suite de la
      // première phrase.
      caption: carte.lines.isEmpty ? null : carte.lines.join('\n'),
    );
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
              label: milestone.locked
                  ? kPlanMilestoneLockedCta
                  : kPlanMilestoneCta,
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

  /// Les accès secondaires du Plan.
  ///
  /// 🛑 **Deux accès, et deux seulement** (arbitrage du propriétaire,
  /// 2026-09-19) : « Toutes mes compétences » et « Mes examens blancs » ont été
  /// retirés — le premier avec son écran, le second parce que l'onglet Examens
  /// de la barre de navigation y mène déjà. Ne pas les réintroduire.
  Widget _links(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, sfSectionGap, 16, 0),
      child: ListGroup(
        children: [
          ListRow(
            icon: LucideIcons.trendingUp,
            iconBg: AppColors.surface2,
            iconColor: AppColors.muted,
            title: kJourneyHistoryTitle,
            sub: kJourneyHistorySub,
            onTap: () => context.push(AppRoutes.planProgress),
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

}

/// Le geste de la barre basse : il nomme le palier visé quand il est connu,
/// jamais un palier deviné. Le libellé de base reste celui de
/// [kUnlockPlanCta] — l'app n'a qu'une formule pour cette action.
String _unlockCta(TargetLevel? objective) =>
    objective == null ? kUnlockPlanCta : '$kUnlockPlanCta ${objective.wire}';

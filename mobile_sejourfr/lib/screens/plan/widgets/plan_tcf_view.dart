import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/models/diagnostic_models.dart';
import '../../../core/models/journey_models.dart';
import '../../../core/models/enums.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium_lock.dart';
import '../../../core/widgets/sejour/sejour_kit.dart';
import '../journey_labels.dart';
import '../learning_plan_provider.dart';
import '../plan_actions.dart';
import '../plan_cta.dart';
import '../plan_labels.dart';
import '../plan_now_card.dart';
import 'examen_complet_jalon.dart';
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
///
/// 🛑 **D-69** : l'écran s'affiche aussi sans diagnostic (le cycle est alors un
/// cycle d'examens), et le diagnostic n'y est plus proposé : sous « À faire
/// maintenant » il ne reste que le jalon éventuel et le cycle.
class PlanTcfView extends ConsumerWidget {
  const PlanTcfView({
    super.key,
    required this.plan,
    this.journey,
    required this.objective,
    this.diagnosticFait = false,
  });

  final LearningPlan plan;

  /// Un diagnostic **clos** existe-t-il à relire ? Décidé par `diagnosticFait`
  /// (`preparation_labels.dart`), jamais ici : sans lui, la ligne « Mon
  /// diagnostic » est masquée.
  final bool diagnosticFait;

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
          // 🛑 **Le geste ouvre l'écran de TRANSITION**, plus l'offre
          // directement (demande du propriétaire, 2026-09-20) : le candidat y
          // relit ce que son diagnostic a trouvé, puis il choisit son pass.
          SfStickyBar(
            child: SfButton(
              label: _unlockCta(objective),
              onPressed: () => context.push(
                AppRoutes.planUnlockPath(civique: false),
              ),
            ),
          ),
        ],
      );
    }
    return ListView(children: _premium(context, ref));
  }

  /* ------------------------------------------------------------- abonné --- */

  List<Widget> _premium(BuildContext context, WidgetRef ref) {

    return <Widget>[
      const SizedBox(height: 14),
      ..._enTete(context, ref),
      SfSection(
        title: kPlanNowTitle,
        flush: true,
        lead: true,
        child: _nowCard(context, ref),
      ),
      // 🛑 **Le jalon d'examen complet** (D-68) : sous « À faire maintenant »,
      // au-dessus du cycle — servi, jamais décidé ici.
      ExamenCompletJalon(journey: journey, module: AppModule.tcf),
      // 🛑 **Le CYCLE remplace la file plate** (D-12 / D-22, 2026-09-18) : un
      // bloc par épreuve, l'examen en fin de bloc, et la fin de cycle
      // (« Actualiser mon plan », D-66). Sa carte « Cycle » est en tête.
      PlanCycleSection(plan: plan, journey: journey, carteDeCycle: false),
      _links(context),
      const SizedBox(height: 28),
    ];
  }

  /* -------------------------------------------------------- sans accès ---- */

  /// Le Plan d'un compte **sans accès** : le même écran, une seule porte.
  ///
  /// 🛑 **La carte « À faire maintenant » est celle d'un abonné** (demande du
  /// propriétaire, 2026-09-20) — même titre de section, même pastille de
  /// priorité, mêmes métas, même explication du correcteur, même progression.
  /// Seul le **geste** change, et il vient de [planNowCard] : `free: true` y
  /// force [PlanNowGeste.debloquer], donc aucun lanceur n'est joignable d'ici.
  /// 🛑 **Depuis le Plan, TOUT chemin vers le paywall passe par l'ÉCRAN DE
  /// TRANSITION** (demande du propriétaire, 2026-09-20, TCF **et** civique) :
  /// il dit au candidat ce qu'il achète — ses priorités, son écart à
  /// l'objectif, le prix d'entrée — avant de lui montrer des durées et des
  /// montants. Deux chemins vers le même achat, dont un plus pauvre, c'est la
  /// porte que personne ne pense à corriger.
  ///
  /// ⚠️ Les paywalls qui répondent à un **403** restent en place : ce sont des
  /// refus, pas des gestes d'achat.

  List<Widget> _free(BuildContext context, WidgetRef ref) => <Widget>[
        const SizedBox(height: 14),
        ..._enTete(context, ref),
        SfSection(
          title: kPlanNowTitle,
          flush: true,
          lead: true,
          child: _nowCard(context, ref, free: true),
        ),
        // Le jalon ne porte aucun verrou (D-68) : le cycle d'examens qu'il
        // ouvre porte, lui, les verrous d'accès servis de chaque examen.
        ExamenCompletJalon(journey: journey, module: AppModule.tcf),
        // 🛑 **Le cycle reste ENTIER, même sans accès** : ses quatre blocs et
        // toutes leurs étapes sont affichés à leur place, avec leur cadenas. Le
        // masquer priverait le candidat de l'information la plus utile qu'il
        // possède — c'est la contradiction #1 du dépôt, tranchée le 2026-08-21.
        // Le bouton « Débloquer mon plan » est **ancré en barre basse**.
        // 🛑 **La carte bleue « Passez du diagnostic à la progression » est
        // SUPPRIMÉE** (demande du propriétaire, 2026-09-20) : sa promesse et
        // ses trois puces vivent désormais sur l'écran de transition, et la
        // dire ici puis là-bas la disait deux fois de suite. Ne pas la
        // réintroduire.
        PlanCycleSection(plan: plan, journey: journey, carteDeCycle: false),
        // ✅ **Visibles aussi sans accès** (demande du propriétaire,
        // 2026-09-20) : ce sont deux **constats** — ce qui a été mesuré, ce qui
        // a été fait — et rien ne s'y travaille. Les en priver n'ouvrait aucun
        // droit, ça retirait la lecture de son propre parcours à celui qui en a
        // le plus besoin. La barre « Débloquer mon plan » reste la seule
        // **action** dominante de l'écran.
        _links(context),
        const SizedBox(height: 24),
      ];

  /* ------------------------------------------------------------ blocs ----- */

  /// **La tête du Plan TCF** (Navigation v2, maquette « Mon plan ») : la
  /// carte « Cycle » ([PlanCycleCard]), puis, sans objectif déclaré, l'accès
  /// au choix de la démarche.
  ///
  /// ⚠️ **Le bandeau « Niveau actuel → Objectif » (`SfGoalStrip`) est retiré**
  /// (Navigation v2, phase 4) : la carte « Ma progression » de l'en-tête du module dit déjà
  /// « niveau actuel → objectif », et le bandeau y opposait un AUTRE « niveau
  /// actuel » (le niveau de départ du cycle). Le bouton « Choisir mon
  /// objectif » qu'il portait reste.
  ///
  /// 🛑 **Le parcours a ses états** (brief §7) : lecture en cours ⇒ squelette
  /// de la carte, échec ⇒ erreur + « Réessayer » dans le bloc.
  List<Widget> _enTete(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(journeyProvider);
    final parcours = journey;
    final Widget? carte = parcours != null
        ? PlanCycleCard(journey: parcours, module: AppModule.tcf)
        : etat.hasError
            ? SfBlockError(
                message: kPlanJourneyError,
                retryLabel: kPlanErrorRetry,
                onRetry: () => ref.invalidate(journeyProvider),
              )
            : etat.isLoading
                ? const SfBlockSkeleton(height: 150, radius: AppRadii.lg)
                : null;
    return <Widget>[
      if (carte != null) Padding(padding: sfGutter, child: carte),
      if (objective == null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, sfGap, 16, 0),
          child: SfButton(
            label: kPlanGoalPick,
            variant: SfButtonVariant.line,
            onPressed: () =>
                context.push(AppRoutes.targetPathFrom(AppRoutes.tcfPlan)),
          ),
        ),
    ];
  }

  /// La carte d'action — **la même pour un abonné et pour un compte sans
  /// accès** (2026-09-20). ⚠️ Le plan gratuit avait sa propre mise en page
  /// (`_freeStepCard`, ses trois bénéfices verrouillés, son titre de section
  /// « Votre première étape est prête ») : elle est **supprimée**, elle taisait
  /// des **résultats mesurés** que la contradiction #1 demande de montrer.
  ///
  /// 🛑 **Son contenu ET son geste sont décidés par [planNowCard], pas ici** —
  /// la même autorité que l'Accueil (`_actionTcf`) et que les deux cartes du
  /// web. L'écran assemble le kit, il ne choisit ni l'identité de la carte ni
  /// ce qu'elle lance. Il n'y a donc **aucun `if (free)` ici** : le drapeau est
  /// passé tel quel et ne sert qu'à l'autorité.
  /// La porte unique vers l'offre, depuis le Plan TCF.
  void _versEcranDeDeblocage(BuildContext context) =>
      context.push(AppRoutes.planUnlockPath(civique: false));

  Widget _nowCard(BuildContext context, WidgetRef ref, {bool free = false}) {
    final carte = planNowCard(plan, journey: journey, free: free);
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
            variant: SfButtonVariant.tcf,
            onPressed: () => _versEcranDeDeblocage(context),
          ),
        // 🛑 **`ouvrirEtape` ouvre l'écran de l'étape**, il ne lance rien : une
        // compétence de compréhension se travaille par séries, et le candidat
        // les choisit là-bas. La destination est **servie** par [planNowCard].
        PlanNowGeste.ouvrirEtape => SfButton(
            label: carte.cta,
            variant: SfButtonVariant.tcf,
            onPressed: carte.etapeRoute == null
                ? null
                : () => context.push(carte.etapeRoute!),
          ),
        PlanNowGeste.lancer => SfButton(
            label: carte.cta,
            variant: SfButtonVariant.tcf,
            onPressed: mesure != null
                // Le lanceur de mesure est une AUTORITÉ EXISTANTE
                // (`startPlanSeanceItem` → `openPlanAssessment`) : on ne
                // réécrit aucun aiguillage ici, le mobile lit et exécute.
                ? () => unawaited(startPlanSeanceItem(
                      context,
                      ref,
                      mesure,
                      origine: PlanOrigine.plan,
                      onVerrou: () => _versEcranDeDeblocage(context),
                    ))
                : exercise == null
                    ? null
                    : () => unawaited(openPlanExercise(
                          context,
                          ref,
                          exercise,
                          origine: PlanOrigine.plan,
                          masteryBefore: carte.priority?.masteryState,
                          onVerrou: () => _versEcranDeDeblocage(context),
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
  /// Les accès secondaires du Plan.
  ///
  /// 🛑 **Deux accès au plus** (arbitrage du propriétaire,
  /// 2026-09-19) : « Toutes mes compétences » et « Mes examens blancs » ont été
  /// retirés — le premier avec son écran, le second parce que l'onglet Examens
  /// de la barre de navigation y mène déjà. Ne pas les réintroduire.
  Widget _links(BuildContext context) {
    // Les liens gardés, sous l'anatomie `.info-card` de la maquette.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, sfSectionGap, 16, 0),
      child: SfStack(
        pad: false,
        children: [
          SfInfoCard(
            icon: LucideIcons.trendingUp,
            title: kJourneyHistoryTitle,
            meta: journeyHistorySub(),
            trailing: const SfChevron(),
            onTap: () =>
                context.push(AppRoutes.planProgressPath(civique: false)),
          ),
          // 🛑 **Seulement s'il y a un diagnostic CLOS à relire** : le
          // diagnostic n'est plus proposé sur le Plan.
          if (diagnosticFait)
            SfInfoCard(
              icon: LucideIcons.clipboardCheck,
              title: kPlanDiagnosticTitle,
              meta: kPlanDiagnosticSub,
              trailing: const SfChevron(),
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

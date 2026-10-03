import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/models/dashboard_models.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/journey_models.dart';
import '../../core/models/preparation_labels.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/target_level_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/router/shell_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/civique_examen.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../diagnostic/diagnostic_courant_provider.dart';
import '../module/module_labels.dart';
import '../module_detail/civique_theme_exam_launcher.dart';
import '../plan/civic_plan_labels.dart';
import '../plan/civic_plan_provider.dart';
import '../plan/journey_labels.dart';
import '../plan/learning_plan_provider.dart';
import '../plan/now_card_gestes.dart';
import '../plan/plan_now_card.dart';
import '../reviser/reviser_labels.dart';
import 'home_labels.dart';
import 'widgets/home_blocks.dart';

/// **L'Accueil** — Navigation v2, phase 3 (2026-10-03). Maquette :
/// `docs/redesign/sejourfr-navigation-mobile.html`, écran `#accueil`.
///
/// ## L'ordre, de haut en bas
///
/// Bandeau « Choisissez votre parcours » (compte sans démarche) → kicker
/// « Objectif · {mention} », « Bonjour {nom} » et le sous-titre statique → la
/// carte du diagnostic rapide en cours, quand il y en a un → **À faire
/// maintenant** (deux cartes : TCF puis civique) → l'invitation à déclarer un
/// objectif → **Mes objectifs** (une carte, deux lignes : TCF puis civique) →
/// la note de non-affiliation. Même ordre que le web (2026-10-03, demande du
/// propriétaire — révoque D2 A, l'ordre propre à chaque maquette).
///
/// 🛑 **Aucune bascule de module** : les deux parcours se lisent ensemble, la
/// barre d'onglets porte la navigation. « Où vous en êtes » est supprimé — la
/// carte « Mes objectifs » le remplace, et le détail vit sur les écrans de
/// progression.
///
/// 🛑 **Chaque bloc a ses états** (brief §7) : squelette aux dimensions du
/// composant pendant le chargement, message + « Réessayer » sur erreur, sans
/// toucher aux autres blocs.
///
/// 🛑 **[_IndependenceNote] ne se touche pas** : exigence de conformité store
/// (Misleading Claims).
/// 🛑 **Carte « Reprenez votre diagnostic » MASQUÉE pour tous** (2026-10-03,
/// décision du propriétaire) : une fois le compte créé, le diagnostic, ce sont
/// les examens blancs du premier cycle du Plan (D-69). Le diagnostic rapide se
/// passe AVANT le compte, depuis le web. Code gardé : repasser à `true` suffit.
/// Miroir web : `ACCUEIL_SHOW_DIAGNOSTIC_CARD`.
const bool kHomeShowDiagnosticCard = false;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Un lanceur est en vol : un second toucher ne relance rien.
  bool _lancement = false;

  /// Le tiré-pour-rafraîchir : les sources du compte (le même point que le
  /// Plan), plus le tableau de bord, qui suit le même signal.
  Future<void> _refresh() async {
    final sources = relireSourcesDuCompte(ref);
    await Future.wait<void>([
      sources,
      ref.read(dashboardProvider.future).then((_) {}, onError: (Object _) {}),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final procedure = user?.targetProcedure;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.blue,
          onRefresh: _refresh,
          child: ListView(
            children: [
              if (user != null && procedure == null)
                HomeBanner(
                  onTap: () =>
                      context.push(AppRoutes.targetPathFrom(AppRoutes.home)),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: SfModuleHeader(
                  civique: false,
                  kicker: objectifKicker(procedure),
                  title: homeHello(user?.firstName, user?.lastName),
                  lead: kHomeLead,
                ),
              ),
              ..._diagnosticEnCours(context),
              SfSection(
                title: kHomeNowTitle,
                lead: true,
                flush: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _actionTcf(context),
                    const SizedBox(height: 12),
                    _actionCivique(context),
                  ],
                ),
              ),
              ..._objectifADeclarer(context),
              SfSection(
                title: kHomeObjectivesTitle,
                lead: true,
                flush: true,
                child: _objectifs(context),
              ),
              const SizedBox(height: 24),
              const _IndependenceNote(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /* -------------------------------------------------------- mes objectifs */

  /// **Mes objectifs** — la carte groupée de la maquette mobile.
  ///
  /// - TCF : « Atteindre {cible} partout », `{actuel|—} → {cible}`. Le niveau
  ///   cible vient de `userTargetLevelProvider` (seule source, X13), le niveau
  ///   actuel de `estimatedTcfLevel` servi (`null` ⇒ « — »).
  /// - Civique : « Être prêt pour l'examen », seuil et nombre de questions de
  ///   l'examen officiel, et l'avancement en séries par
  ///   [avancementSeriesCivique], la fonction unique (0 % jamais vide).
  Widget _objectifs(BuildContext context) {
    final async = ref.watch(dashboardProvider);
    final dashboard = async.valueOrNull;
    if (dashboard == null) {
      if (async.hasError) {
        return SfBlockError(
          message: kHomeBlockError,
          retryLabel: kHomeRetry,
          onRetry: () => ref.invalidate(dashboardProvider),
        );
      }
      return const SfBlockSkeleton(height: 202);
    }
    return SfObjectivesCard(
      rows: [
        _objectifTcf(context, dashboard),
        _objectifCivique(context, dashboard),
      ],
    );
  }

  SfObjectiveRow _objectifTcf(
      BuildContext context, DashboardSummary dashboard) {
    final cible = ref.watch(userTargetLevelProvider)?.wire;
    final actuel = dashboard.estimatedTcfLevel?.shortName;
    return SfObjectiveRow(
      civique: false,
      icon: LucideIcons.map,
      label: kHomeTcfLabel,
      // Sans démarche déclarée, aucun palier n'est visé : on invite à le
      // choisir plutôt que d'écrire « Atteindre — partout ».
      title: cible == null ? kJourneyNeedsObjectiveTitle : homeGoalText(cible),
      meta: kHomeTcfObjectiveMeta,
      value: homeTcfObjectiveValue(
        actuel ?? kModuleProgressUnknown,
        cible ?? kModuleProgressUnknown,
      ),
      onTap: () => pousserOuAller(context, AppRoutes.progressionTcf),
    );
  }

  SfObjectiveRow _objectifCivique(
    BuildContext context,
    DashboardSummary dashboard,
  ) {
    final avancement = avancementSeriesCivique(dashboard.civique);
    return SfObjectiveRow(
      civique: true,
      icon: LucideIcons.shieldCheck,
      label: kHomeCiviqueLabel,
      title: kHomeCiviqueObjectiveTitle,
      meta: homeCiviqueObjectiveMeta(
        CivicExamFormat.seuil,
        CivicExamFormat.questions,
      ),
      value: moduleCiviqueProgressValue(avancement.pourcentage),
      onTap: () => pousserOuAller(context, AppRoutes.progressionCivique),
    );
  }

  /* ------------------------------------------- le diagnostic rapide en cours */

  /// La reprise d'un diagnostic rapide commencé, ou son analyse en
  /// préparation — **au-dessus** de « À faire maintenant », et seulement quand
  /// elle existe. Chargement ou erreur : rien (c'est un bloc facultatif).
  List<Widget> _diagnosticEnCours(BuildContext context) {
    if (!kHomeShowDiagnosticCard) return const <Widget>[];
    final journey = ref.watch(diagnosticCourantProvider).valueOrNull;
    if (journey == null ||
        journey.status == DiagnosticJourneyStatus.notStarted ||
        journey.status == DiagnosticJourneyStatus.completed) {
      return const <Widget>[];
    }
    final analyse = journey.status == DiagnosticJourneyStatus.analyzing ||
        journey.nextStep == DiagnosticStep.analysis;
    return <Widget>[
      SfSection(
        flush: true,
        child: SfNowCard(
          icon: LucideIcons.sparkles,
          title: analyse ? kHomeDiagAnalyzingTitle : kHomeDiagResumeTitle,
          subtitle: homeDiagCount(
            journey.completedExerciseCount,
            journey.exerciseCount,
          ),
          badge: kHomeDiagBadge,
          objective: analyse
              ? homeDiagAnalyzingObjective(journey.format)
              : kHomeDiagResumeObjective,
          action: SfButton(
            label: analyse ? kHomeDiagAnalyzingCta : kHomeDiagResumeCta,
            variant: SfButtonVariant.tcf,
            // « Reprendre » nomme le geste, donc il le pose ; « Voir
            // l'analyse » ne lance rien et ouvre l'écran tel quel.
            onPressed: () => context.push(
              analyse ? AppRoutes.diagnostic : AppRoutes.diagnosticDemarrer,
            ),
          ),
        ),
      ),
    ];
  }

  /* ------------------------------------------- à faire maintenant — TCF */

  /// **La carte d'action TCF** — l'étape courante du parcours
  /// (`journey.current`), décidée par [planNowCard], la même autorité que le
  /// Plan et l'Entraînement.
  ///
  /// 🛑 **Le geste est SERVI** : `debloquer` ouvre l'écran de transition,
  /// `ouvrirEtape` l'écran de l'étape (adresse servie), `lancer` démarre la
  /// mesure ou l'exercice par les lanceurs du Plan, `aucun` ⇒ carte neutre,
  /// sans bouton.
  Widget _actionTcf(BuildContext context) {
    final planAsync = ref.watch(learningPlanProvider);
    final journeyAsync = ref.watch(journeyProvider);
    final plan = planAsync.valueOrNull;
    final parcours = journeyAsync.valueOrNull;
    if (plan == null || parcours == null) {
      if (planAsync.hasError || journeyAsync.hasError) {
        return SfBlockError(
          message: kHomeBlockError,
          retryLabel: kHomeRetry,
          onRetry: () {
            ref.invalidate(learningPlanProvider);
            ref.invalidate(journeyProvider);
          },
        );
      }
      return const SfBlockSkeleton(height: 160);
    }

    final carte = planNowCard(plan, journey: parcours);

    // Plus d'étape à faire (cycle terminé, parcours à jour) : la carte le dit
    // et mène au Plan, où se trouve « Actualiser mon plan ».
    if (carte == null) {
      return SfActionCard(
        civique: false,
        icon: LucideIcons.circleCheck,
        label: kHomeTcfLabel,
        title: kJourneyUpToDateTitle,
        cta: kHomeTcfCta,
        onPressed: () =>
            pousserOuAller(context, AppRoutes.modulePlan(civique: false)),
      );
    }

    return SfActionCard(
      civique: false,
      icon: carte.icon,
      label: kHomeTcfLabel,
      title: carte.title,
      meta: homeActionMeta([
        carte.kindLabel ?? carte.subtitle,
        carte.minutesLabel,
      ]),
      note: carte.note,
      cta: carte.geste == PlanNowGeste.debloquer ? carte.cta : kHomeTcfCta,
      onPressed: gesteEtapeTcf(context, ref, carte, lancer: _lancer),
    );
  }

  /* --------------------------------------- à faire maintenant — CIVIQUE */

  /// **La carte d'action civique** — l'étape courante du cycle civique, par
  /// [civicNowCard] : son titre, sa méta et son geste dépendent du **type**
  /// servi de l'étape (examen de thème, unité à travailler par séries, ou
  /// cible du plan dérivé).
  ///
  /// 🛑 **L'Accueil porte le lanceur d'examen de thème** (`lancerExamen`) : il
  /// emploie déjà [launchCiviqueThemeExam], le même que la ligne du cycle.
  /// Sans lui, l'étape d'examen — celle du premier cycle de tout compte —
  /// rendrait une carte sans bouton.
  Widget _actionCivique(BuildContext context) {
    final planAsync = ref.watch(civicPlanProvider);
    final journeyAsync = ref.watch(journeyCiviqueProvider);
    final plan = planAsync.valueOrNull;
    final parcours = journeyAsync.valueOrNull;
    if (plan == null || parcours == null) {
      if (planAsync.hasError || journeyAsync.hasError) {
        return SfBlockError(
          message: kHomeBlockError,
          retryLabel: kHomeRetry,
          onRetry: () {
            ref.invalidate(civicPlanProvider);
            ref.invalidate(journeyCiviqueProvider);
          },
        );
      }
      return const SfBlockSkeleton(height: 160);
    }

    final carte = civicNowCard(
      plan,
      journey: parcours,
      lancerExamen: true,
    );

    if (carte == null) {
      return SfActionCard(
        civique: true,
        icon: LucideIcons.circleCheck,
        label: kHomeCiviqueLabel,
        title: kJourneyUpToDateTitle,
        cta: kHomeCiviqueCta,
        onPressed: () =>
            pousserOuAller(context, AppRoutes.modulePlan(civique: true)),
      );
    }

    return SfActionCard(
      civique: true,
      icon: LucideIcons.shieldCheck,
      label: kHomeCiviqueLabel,
      title: carte.title,
      meta: homeActionMeta([carte.subtitle, carte.meta]),
      note: carte.note,
      cta: carte.geste == PlanNowGeste.debloquer ? carte.cta : kHomeCiviqueCta,
      onPressed: gesteEtapeCivique(context, ref, carte, lancer: _lancer),
    );
  }

  Future<void> _lancer(Future<void> Function() geste) async {
    if (_lancement) return;
    setState(() => _lancement = true);
    try {
      await geste();
    } finally {
      if (mounted) setState(() => _lancement = false);
    }
  }

  /* ------------------------------------------------------- l'objectif ---- */

  /// **L'invitation à déclarer un objectif**, quand le parcours TCF le
  /// demande. Elle n'enlève rien : la carte d'action reste au-dessus.
  List<Widget> _objectifADeclarer(BuildContext context) {
    final parcours = ref.watch(journeyProvider).valueOrNull;
    if (parcours == null || parcours.state != JourneyState.needsObjective) {
      return const <Widget>[];
    }
    return <Widget>[
      SfSection(
        title: kJourneyNeedsObjectiveTitle,
        flush: true,
        child: SfStack(
          pad: false,
          children: [
            const SfCard(child: Text(kJourneyNeedsObjectiveText)),
            SfButton(
              label: kJourneyNeedsObjectiveCta,
              onPressed: () =>
                  context.push(AppRoutes.targetPathFrom(AppRoutes.home)),
            ),
          ],
        ),
      ),
    ];
  }
}

/// Disclaimer court de non-affiliation (conformité stores). Le « En savoir
/// plus » pousse la page À propos (disclaimer complet + sources officielles).
class _IndependenceNote extends StatelessWidget {
  const _IndependenceNote();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          onTap: () => context.push(AppRoutes.about),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text.rich(
              TextSpan(
                style: AppFonts.ui(
                  size: 11.5,
                  color: AppColors.inkFaint,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text: 'Outil indépendant — non affilié à l\'État '
                        'français · ',
                  ),
                  TextSpan(
                    text: 'En savoir plus',
                    style: AppFonts.ui(
                      size: 11.5,
                      color: AppColors.blue,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

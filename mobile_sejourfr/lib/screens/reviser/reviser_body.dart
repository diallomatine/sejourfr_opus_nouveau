import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/analytics/analytics_events.dart';
import '../../core/models/civic_plan_models.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/dashboard_models.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/progress_models.dart';
import '../../core/models/question_models.dart' show ThemeDto;
import '../../core/models/skill_models.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/progress_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dashboard_targets.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../module/module_labels.dart';
import '../module_detail/civique_hub_data.dart';
import '../plan/civic_plan_labels.dart';
import '../plan/widgets/plan_reco_card.dart';
import '../plan/civic_plan_provider.dart';
import '../../core/router/app_router.dart';
import '../plan/civic_serie_launcher.dart';
import '../plan/journey_labels.dart';
import '../../core/models/journey_models.dart';
import '../plan/learning_plan_provider.dart';
import '../plan/plan_actions.dart';
import '../plan/plan_cta.dart';
import '../plan/plan_labels.dart';
import '../plan/plan_now_card.dart';
import '../progres/progres_labels.dart';
import 'reviser_labels.dart';

/// **Le corps du segment « Entraînement »** d'un écran de module
/// (Navigation v2) — l'ancien onglet « Réviser », sans en-tête ni bascule :
/// c'est l'onglet TCF ou Civique de la barre qui choisit le module.
///
/// Deux blocs : la carte **« Reprendre là où vous vous êtes arrêté »**, puis la
/// grille des épreuves (TCF, `.metric`) ou les cartes des thèmes (civique,
/// `.theme-card`) — gabarit Navigation v2, phase 4.
///
/// 🛑 **« Reprendre » vient du PLAN** (demande du propriétaire, 2026-09-12) :
/// côté TCF c'est [planNowCard] — la **même** autorité que la carte « À faire
/// maintenant » du Plan et de l'Accueil —, le cycle civique côté civique.
/// Réviser ne tient aucun historique à lui. Rien à reprendre ⇒ pas de carte.
///
/// 🛑 **Aucune phrase n'est composée ici** : elles vivent dans
/// `reviser_labels.dart`, miroir mot pour mot de `web_sejoufr/lib/reviser.ts`.
class ReviserBody extends ConsumerStatefulWidget {
  const ReviserBody({super.key, required this.civique});

  final bool civique;

  @override
  ConsumerState<ReviserBody> createState() => _ReviserBodyState();
}

class _ReviserBodyState extends ConsumerState<ReviserBody> {
  /// Le lancement en cours, pour ne pas démarrer deux fois la même reprise.
  bool _lancement = false;

  Future<void> _refresh() async {
    ref.invalidate(dashboardProvider);
    await ref.read(dashboardProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardProvider);
    final plan = ref.watch(learningPlanProvider).valueOrNull;
    // 🛑 Le parcours, lu au **même endroit** que le Plan : les deux alimentent
    // la même carte de reprise, et n'en observer qu'un rouvrirait l'écart.
    final parcours = ref.watch(journeyProvider).valueOrNull;
    final civicPlan = ref.watch(civicPlanProvider).valueOrNull;
    // 🛑 **Le CYCLE civique, comme sur le Plan** : « À faire maintenant » y lit
    // `journey.current`. Sans lui, Réviser annoncerait la cible du plan dérivé
    // pendant que le Plan annonce l'étape du cycle.
    final parcoursCivique = ref.watch(journeyCiviqueProvider).valueOrNull;
    final civique = widget.civique;

    return RefreshIndicator(
      color: AppColors.module(civique: civique),
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          ...dashboard.when(
            loading: () => [_Loading(civique: civique)],
            error: (_, __) => [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SfBlockError(
                  message: kModuleBlockError,
                  retryLabel: kModuleRetry,
                  onRetry: () => ref.invalidate(dashboardProvider),
                ),
              ),
            ],
            data: (d) => civique
                ? _civique(d, civicPlan, parcoursCivique)
                : _tcf(context, d, plan, parcours),
          ),
        ],
      ),
    );
  }

  /* ------------------------------------------------------------------ TCF */

  List<Widget> _tcf(
    BuildContext context,
    DashboardSummary dashboard,
    LearningPlan? plan,
    Journey? parcours,
  ) {
    // 🛑 **Le drapeau d'accès descend jusqu'à l'autorité**, il n'est pas relu
    // ici : c'est `planNowCard` qui en tire le geste, comme sur le Plan.
    final auth = ref.watch(authControllerProvider);
    final free = !(auth is AuthAuthenticated && auth.user.hasTcf);
    final resume = reviserResumeTcf(plan, journey: parcours, free: free);
    final stats = orderedTcfCategories(dashboard.tcf);
    final complementaire = complementaireCategory(dashboard.tcf);
    final profil = dashboard.tcfDomainProfile;
    return <Widget>[
      if (resume != null)
        PlanRecoCard(
          label: kReviserResumeLabel,
          title: resume.title,
          subtitle: resume.subtitle,
          cta: resume.cta,
          // L'icône du domaine, la même que sur le Plan et sur son hub — le
          // candidat doit reconnaître ce qu'il reprend. C'est le domaine
          // **réellement lancé** : celui de la mesure quand elle passe devant.
          icon: planDomainIcon(sectionEpreuve(resume.section)),
          variant: SfButtonVariant.tcf,
          // 🛑 **Le geste vient du Plan, il ne se redéduit pas ici** — et un
          // geste d'achat passe par l'écran de transition (A145), jamais par
          // le paywall d'un coup. `ouvrirEtape` ouvre l'écran de l'étape (ses
          // deux séries), `lancer` démarre l'action : aucune condition sur
          // « est-ce une série ? » ici.
          onContinue: switch (resume.geste) {
            PlanNowGeste.debloquer => () =>
                context.push(AppRoutes.planUnlockPath(civique: false)),
            PlanNowGeste.ouvrirEtape when resume.etapeRoute != null => () =>
                context.push(resume.etapeRoute!),
            _ => () => _reprendreTcf(resume.carte!),
          },
        ),
      // 🛑 **L'invitation à déclarer un objectif se lit ici aussi** (arbitrage
      // du propriétaire, 2026-09-17). Réviser est la porte d'entrée d'un compte
      // gratuit : sans elle, un candidat sans démarche déclarée n'apprenait
      // nulle part qu'elle lui ouvre un parcours. Elle n'enlève rien — la
      // reprise ci-dessus reste servie, le Plan n'exige pas d'objectif.
      if (parcours?.state == JourneyState.needsObjective)
        SfSection(
          title: kJourneyNeedsObjectiveTitle,
          child: SfStack(
            children: [
              const SfCard(child: Text(kJourneyNeedsObjectiveText)),
              SfButton(
                label: kJourneyNeedsObjectiveCta,
                onPressed: () => context
                    .push(AppRoutes.targetPathFrom(AppRoutes.tcfEntrainement)),
              ),
            ],
          ),
        ),
      // 🛑 **La grille des épreuves officielles** (`.grid-2` de `.metric`) :
      // niveau servi, état servi et son ton (`etatEpreuveTcf`, la seule
      // correspondance), compteurs servis, CTA vers le hub existant.
      SfSection(
        title: kModuleTcfEpreuvesTitle,
        flush: true,
        lead: true,
        child: _Grille2(
          children: [
            for (final stat in stats)
              _epreuveMetric(
                stat,
                domainForCode(plan, stat.code),
                profil,
                prioritaire: _prioritaire(parcours),
              ),
          ],
        ),
      ),
      // Le hero « Entretien en temps réel » (D3 B) : un lien vers le hub de
      // l'expression orale, où la simulation se lance sur une tâche. Ordre de
      // la maquette (et du web) : grille → hero → « Renforcer mon français ».
      SfSection(
        title: kModuleRealtimeTitle,
        flush: true,
        lead: true,
        child: SfHero(
          civique: false,
          icon: LucideIcons.sparkles,
          label: kModuleRealtimeLabel,
          title: kModuleRealtimeHeadline,
          sub: kModuleRealtimeSub,
          stat: (value: SkillSection.eo.wire, label: kModuleRealtimeStat),
          cta: kModuleRealtimeCta,
          onPressed: () => context.push(AppRoutes.tcfEoEntry),
        ),
      ),
      // 🛑 Structure de la langue n'est PAS une cinquième épreuve du TCF IRN :
      // elle sort de la grille et prend sa propre section, avec la note qui le
      // dit. Miroir web : ReviserScreen, section « Renforcer mon français ».
      if (complementaire != null)
        SfSection(
          title: kTcfComplementaireSectionTitle,
          flush: true,
          lead: true,
          child: SfStack(
            pad: false,
            children: [
              SfInfoCard(
                icon: dashboardCategoryIcon(complementaire.code),
                title: complementaire.label,
                meta: [
                  epreuveStatus(complementaire, null, profil),
                  epreuveMeta(complementaire),
                ].whereType<String>().join(' · '),
                trailing: const SfChevron(),
                onTap: () =>
                    context.push(dashboardCategoryRoute(complementaire)),
              ),
              const SfTipCard(
                icon: LucideIcons.info,
                label: kTcfComplementaireNoteTitle,
                text: kTcfComplementaireNoteReviser,
              ),
            ],
          ),
        ),
    ];
  }

  /// La carte d'un thème — même composition que le web (`ReviserScreen`) : la
  /// ligne d'état est composée sur des faits servis ([themeStatus]), jamais
  /// déduite de l'anneau ; sans série servie, elle prend la place du compteur.
  Widget _themeCard(
    BuildContext context,
    DashboardCategoryStat stat,
    List<CivicPlanThemeLigne> themes,
    List<ThemeDto>? descriptions,
  ) {
    final statut = themeStatus(themeLigneFor(themes, stat.themeId), stat);
    final compteur = epreuveMeta(stat);
    return SfThemeCard(
      icon: dashboardCategoryIcon(stat.code),
      title: stat.label,
      description: _description(descriptions, stat.themeId),
      ring: avancementSeriesCivique([stat]).pourcentage,
      count: compteur ?? statut,
      state: compteur == null ? null : (label: statut, tone: SfTone.muted),
      cta: kModuleThemeCta,
      onPressed: () => context.push(dashboardCategoryRoute(stat)),
    );
  }

  /// **L'épreuve que le serveur désigne** — celle de l'étape « À faire
  /// maintenant » du parcours (`journey.current`), la même autorité que le
  /// Plan et l'Accueil. `null` ⇒ aucune tuile n'a l'emphase pleine.
  String? _prioritaire(Journey? parcours) {
    final bloc = parcours?.current?.bloc;
    return bloc != null && bloc.estEpreuve ? bloc.code : null;
  }

  /// La tuile d'une épreuve officielle.
  ///
  /// 🛑 Le **niveau** vient de [niveauActuelEpreuve] (l'autorité d'affichage) ;
  /// l'**état** du `StatutObjectif` servi, lu par [etatEpreuveTcf] — rien
  /// n'est classé ici. La méta garde ce que la ligne d'avant disait : le nom,
  /// les séries ou sujets servis, et sur une production l'étape que le Plan
  /// construit (« Prochaine étape : Tâche 2 », « 3 compétences acquises »).
  Widget _epreuveMetric(
    DashboardCategoryStat stat,
    PlanDomain? domain,
    TcfDomainProfile? profil, {
    required String? prioritaire,
  }) {
    final epreuve = EpreuveType.fromWire(stat.code);
    final niveau = niveauActuelEpreuve(profil, stat.code);
    ProgressEpreuve? servie;
    for (final e in ref.watch(progressProvider).valueOrNull?.tcf.epreuves ??
        const <ProgressEpreuve>[]) {
      if (e.epreuve == epreuve) servie = e;
    }
    final plan =
        isProductionCode(stat.code) ? epreuveStatus(stat, domain, null) : null;
    return SfMetric(
      civique: false,
      fill: true,
      code: planDomainSection(epreuve)?.wire ?? stat.label,
      value: niveau?.shortName ?? kModuleProgressUnknown,
      state: servie == null
          ? null
          : etatEpreuveTcf(servie.status, servie.niveau),
      meta: [
        stat.label,
        epreuveMeta(stat),
        if (plan != null && plan != kReviserNotStarted) plan,
      ].whereType<String>().join(' · '),
      cta: kModuleTrainCta,
      ctaEmphasis:
          stat.code == prioritaire ? SfCtaEmphasis.solid : SfCtaEmphasis.soft,
      onPressed: () => context.push(dashboardCategoryRoute(stat)),
    );
  }

  /// Lance ce que le Plan désigne — le **même** geste que le bouton principal
  /// du Plan (`startPlanSeanceItem` / `openPlanExercise`), sur la **même**
  /// action (`planNowCard`), jamais un second chemin écrit ici.
  ///
  /// 🛑 **Une MESURE passe devant tout le reste**, ici comme sur le Plan et sur
  /// l'Accueil : c'est [planNowCard] qui l'a tranché, l'écran exécute.
  ///
  /// 🛑 **« Reprendre » n'est PAS le Plan** (consigne du propriétaire,
  /// contrôle F, D113) : il ne compterait comme tel que si l'exercice repris
  /// avait été lancé depuis le Plan avec un marqueur PERSISTÉ au lancement, et
  /// ce marqueur n'existe pas — la carte relance l'action calculée à la
  /// lecture, pas une tentative en cours. [PlanOrigine.horsPlan] : une offre
  /// ouverte en chemin prend le CTA de l'écran d'arrivée, sans parcours
  /// (`OTHER` pour un exercice, `MOCK_EXAM` pour une mesure) — miroir du web.
  Future<void> _reprendreTcf(PlanNowCard carte) async {
    if (_lancement) return;
    setState(() => _lancement = true);
    final mesure = carte.mesure;
    final exercice = carte.exercise;
    if (mesure != null) {
      await startPlanSeanceItem(context, ref, mesure,
          origine: PlanOrigine.horsPlan);
    } else if (exercice != null) {
      await openPlanExercise(
        context,
        ref,
        exercice,
        origine: PlanOrigine.horsPlan,
        masteryBefore: carte.priority?.masteryState,
      );
    }
    if (!mounted) return;
    setState(() => _lancement = false);
  }

  /* -------------------------------------------------------------- Civique */

  List<Widget> _civique(
    DashboardSummary dashboard,
    CivicPlan? civicPlan,
    Journey? parcours,
  ) {
    final auth = ref.watch(authControllerProvider);
    final free = !(auth is AuthAuthenticated && auth.user.hasCivique);
    final resume =
        reviserResumeCivique(civicPlan, journey: parcours, free: free);
    final themes = civicPlan?.themes ?? const <CivicPlanThemeLigne>[];
    final global = avancementSeriesCivique(dashboard.civique);
    // Observée, jamais attendue : sans elle, les cartes n'ont pas de
    // description, rien d'autre.
    final descriptions = ref.watch(civiqueThemesProvider).valueOrNull;
    return <Widget>[
      if (resume != null)
        PlanRecoCard(
          label: kReviserResumeLabel,
          title: resume.title,
          subtitle: resume.subtitle,
          cta: resume.cta,
          // Le pictogramme du thème quand la reprise en a un ; une **unité**
          // du cycle n'en porte pas, on reprend alors la boussole du parcours.
          icon: civicPlan?.prochaine == null
              ? LucideIcons.compass
              : dashboardCategoryIcon(civicPlan!.prochaine!.themeCode),
          variant: SfButtonVariant.civique,
          onContinue: switch (resume.geste) {
            PlanNowGeste.debloquer => () =>
                context.push(AppRoutes.planUnlockPath(civique: true)),
            PlanNowGeste.ouvrirEtape when resume.etapeRoute != null => () =>
                context.push(resume.etapeRoute!),
            _ => () => _reprendreCivique(resume.source),
          },
        ),
      // Les thèmes en `.theme-card` : nom servi, description servie
      // (`ThemeUserResponse.description`, masquée si absente), anneau et
      // compteur sur les séries du thème (`avancementSeriesCivique([stat])`, la
      // fonction unique), ligne d'état existante (`themeStatus`, faits servis)
      // au ton neutre de la maquette — jamais déduite du %.
      SfSection(
        title: reviserSectionTitle(AppModule.civique, dashboard.civique.length),
        flush: true,
        lead: true,
        child: SfStack(
          pad: false,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SfBadge(
                moduleCiviqueSeriesBadge(global.terminees, global.total),
                civique: true,
              ),
            ),
            for (final stat in dashboard.civique)
              _themeCard(context, stat, themes, descriptions),
          ],
        ),
      ),
    ];
  }

  /// La description **servie** d'un thème, ou `null` (absente, vide, ou
  /// liste des thèmes pas encore lue) — la carte la masque alors.
  String? _description(List<ThemeDto>? descriptions, String? themeId) {
    for (final theme in descriptions ?? const <ThemeDto>[]) {
      if (theme.id != themeId) continue;
      final texte = theme.description?.trim();
      return texte == null || texte.isEmpty ? null : texte;
    }
    return null;
  }

  /// 🛑 **Un lanceur par GRAIN** (A87), comme sur le Plan civique : l'unité
  /// officielle du cycle et la cible du plan dérivé sont deux routes serveur
  /// distinctes. La source est **servie** par `civicNowCard`, l'écran exécute.
  Future<void> _reprendreCivique(CivicNowSource? source) async {
    if (_lancement || source == null) return;
    setState(() => _lancement = true);
    // Contrôle F (D113) : sans marqueur persisté de lancement depuis le Plan,
    // la reprise n'est pas le Plan — le CTA d'une série (`OTHER`), sans parcours.
    final cta = planCta(ref, PlanOrigine.horsPlan,
        horsPlan: AnalyticsCtaLocation.other, civique: true);
    switch (source) {
      case CivicNowUnite(code: final code):
        await startCivicUniteSerie(
          context,
          ref,
          code,
          ctaLocation: cta.ctaLocation,
          journeyId: cta.journeyId,
        );
      case CivicNowCible(cible: final cible):
        await startCivicSerie(
          context,
          ref,
          cible,
          ctaLocation: cta.ctaLocation,
          journeyId: cta.journeyId,
        );
    }
    if (!mounted) return;
    setState(() => _lancement = false);
  }
}

/// Le segment en cours de lecture : les squelettes de la grille des épreuves
/// (TCF) ou des cartes de thème (civique), jamais une roue plein écran (§7).
class _Loading extends StatelessWidget {
  const _Loading({required this.civique});

  final bool civique;

  @override
  Widget build(BuildContext context) {
    final rangee = civique
        ? const SfBlockSkeleton(height: 168)
        : const Row(
            children: [
              Expanded(
                  child: SfBlockSkeleton(height: 190, radius: AppRadii.lg)),
              SizedBox(width: 12),
              Expanded(
                  child: SfBlockSkeleton(height: 190, radius: AppRadii.lg)),
            ],
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, sfSectionGap, 16, 0),
      child: Column(
        children: [rangee, const SizedBox(height: 12), rangee],
      ),
    );
  }
}

/// La grille portrait à deux colonnes (`.grid-2`, gap 12) : les tuiles d'une
/// rangée prennent la hauteur de la plus haute, le CTA reste en bas.
class _Grille2 extends StatelessWidget {
  const _Grille2({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: children[i]),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < children.length
                      ? children[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

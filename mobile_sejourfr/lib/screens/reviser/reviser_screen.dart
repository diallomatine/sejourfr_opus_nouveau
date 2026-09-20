import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/models/civic_plan_models.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/dashboard_models.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/preparation_labels.dart';
import '../../core/models/preparation_models.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/preparation_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dashboard_targets.dart';
import '../../core/utils/parcours_affiche.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../plan/civic_plan_labels.dart';
import '../plan/widgets/plan_reco_card.dart';
import '../plan/civic_plan_provider.dart';
import '../../core/router/app_router.dart';
import '../plan/civic_serie_launcher.dart';
import '../plan/journey_labels.dart';
import '../../core/models/journey_models.dart';
import '../plan/learning_plan_provider.dart';
import '../plan/plan_actions.dart';
import '../plan/plan_labels.dart';
import '../plan/plan_now_card.dart';
import 'reviser_labels.dart';

/// **L'onglet « Réviser »** — la maquette du propriétaire
/// (`~/Desktop/sejourfr_ecrans/reviser_{tcf,civique}.png`), montée sur le KIT.
///
/// Trois blocs, et rien d'autre : l'en-tête et sa bascule de parcours, la carte
/// **« Reprendre là où vous vous êtes arrêté »**, puis la liste des cinq
/// épreuves (TCF) ou des cinq thèmes (civique).
///
/// 🛑 **« Reprendre » vient du PLAN** (demande du propriétaire, 2026-09-12) :
/// côté TCF c'est [planNowCard] — la **même** autorité que la carte « À faire
/// maintenant » du Plan et de l'Accueil, donc la même action, mesure de domaine
/// prioritaire comprise —, la cible de rang 1 côté civique. Réviser ne tient
/// aucun historique à lui, et les trois écrans ne peuvent donc pas désigner
/// trois choses différentes.
///
/// 🛑 **Sans diagnostic, la carte de tête PROPOSE LE DIAGNOSTIC** (demande du
/// propriétaire, 2026-09-13) — elle n'invente toujours aucune reprise, mais elle
/// ne disparaît plus : l'écran s'ouvrait sur sa liste d'épreuves sans jamais
/// nommer le geste qui débloque le reste. Le fait lu reste
/// **`prep.planDisponible`**, jamais `etape` — c'est lui qui rend mot pour mot
/// la condition du moteur —, et les phrases de la porte viennent de
/// [planIndisponible], la même autorité que l'Accueil et l'écran Plan.
///
/// 🛑 **Aucune phrase n'est composée ici** : elles vivent dans
/// `reviser_labels.dart`, miroir mot pour mot de `web_sejoufr/lib/reviser.ts`.
class ReviserScreen extends ConsumerStatefulWidget {
  const ReviserScreen({super.key});

  @override
  ConsumerState<ReviserScreen> createState() => _ReviserScreenState();
}

class _ReviserScreenState extends ConsumerState<ReviserScreen> {
  /// Le lancement en cours, pour ne pas démarrer deux fois la même reprise.
  bool _lancement = false;

  Future<void> _refresh() async {
    ref.invalidate(dashboardProvider);
    ref.invalidate(preparationProvider);
    await ref.read(dashboardProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    // 🛑 **Les DEUX parcours sont observés en permanence**, comme sur le Plan :
    // ces providers sont `autoDispose`, donc n'en observer qu'un laissait
    // l'autre se jeter à la bascule — et revenir dessus rappelait son endpoint
    // pour une réponse identique. La bascule ne coûte aucun appel.
    final dashboard = ref.watch(dashboardProvider);
    final plan = ref.watch(learningPlanProvider).valueOrNull;
    // 🛑 Le parcours, lu au **même endroit** que le Plan : les deux alimentent
    // la même carte de reprise, et n'en observer qu'un rouvrirait l'écart.
    final parcours = ref.watch(journeyProvider).valueOrNull;
    final civicPlan = ref.watch(civicPlanProvider).valueOrNull;
    // 🛑 **Le CYCLE civique, comme sur le Plan** : « À faire maintenant » y lit
    // `journey.current` depuis D-50 §2. Sans lui, Réviser annoncerait la cible
    // du plan dérivé pendant que le Plan annonce l'étape du cycle — deux
    // reprises différentes pour le même candidat, au même instant.
    final parcoursCivique = ref.watch(journeyCiviqueProvider).valueOrNull;
    final prep = ref.watch(preparationProvider).valueOrNull;

    // 🛑 **Le parcours affiché est celui de l'Accueil et du Plan**
    // ([parcoursCiviqueProvider]) : une seule mécanique, comme le `?module=`
    // du web. Un état local de plus aurait fini par montrer deux parcours
    // différents au même candidat selon l'écran.
    final civique = ref.watch(parcoursCiviqueProvider) ?? false;
    final module = civique ? AppModule.civique : AppModule.tcf;

    final toggle = Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            reviserSubtitle(module),
            style: AppFonts.ui(size: 13.5, color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          SegmentedTabs<bool>(
            tabs: parcoursSegments(tcf: false, civique: true),
            value: civique,
            onChanged: (v) =>
                ref.read(parcoursCiviqueProvider.notifier).state = v,
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: SfTopSlot(
          below: toggle,
          child: RefreshIndicator(
            color: AppColors.blue,
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                const SfTop(title: kReviserTitle),
                ...dashboard.when(
                  loading: () => const [_Loading()],
                  error: (e, _) => [
                    _ErrorCard(
                      message: ApiClient.toApiException(e).message,
                      onRetry: () => ref.invalidate(dashboardProvider),
                    ),
                  ],
                  data: (d) => civique
                      ? _civique(d, civicPlan, parcoursCivique, prep?.civique)
                      : _tcf(context, d, plan, parcours, prep?.tcf),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /* ------------------------------------------------------------------ TCF */

  List<Widget> _tcf(
    BuildContext context,
    DashboardSummary dashboard,
    LearningPlan? plan,
    Journey? parcours,
    ModulePreparation? prep,
  ) {
    // 🛑 `planDisponible` est **le fait à lire**. Sans lui, on n'a rien à
    // reprendre — et on ne l'invente pas : la carte de tête devient la porte du
    // diagnostic, avec les mots de [planIndisponible].
    final disponible = prep?.planDisponible == true;
    // 🛑 **Le drapeau d'accès descend jusqu'à l'autorité**, il n'est pas relu
    // ici : c'est `planNowCard` qui en tire le geste, comme sur le Plan.
    final auth = ref.watch(authControllerProvider);
    final free = !(auth is AuthAuthenticated && auth.user.hasTcf);
    final resume = disponible
        ? reviserResumeTcf(plan, journey: parcours, free: free)
        : null;
    final porte = prep == null ? null : planIndisponible(prep, civique: false);
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
          variant: SfButtonVariant.primary,
          // 🛑 **Le geste vient du Plan, il ne se redéduit pas ici** — et un
          // geste d'achat passe par l'écran de transition (A145), jamais par
          // le paywall d'un coup.
          onContinue: resume.geste == PlanNowGeste.debloquer
              ? () => context.push(AppRoutes.planUnlockPath(civique: false))
              : () => _reprendreTcf(resume.carte!),
        )
      else if (porte != null)
        _GateCard(porte: porte, variant: SfButtonVariant.primary),
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
                onPressed: () => context.push(AppRoutes.targetPath),
              ),
            ],
          ),
        ),
      SfSection(
        title: reviserSectionTitle(AppModule.tcf, stats.length),
        flush: true,
        child: SfStack(
          pad: false,
          children: [
            for (final stat in stats)
              _epreuveRow(stat, domainForCode(plan, stat.code), profil),
          ],
        ),
      ),
      // 🛑 Structure de la langue n'est PAS une cinquième épreuve du TCF IRN :
      // elle sort de la liste et prend sa propre section, avec la note qui le
      // dit. Miroir web : ReviserScreen, section « Renforcer mon français ».
      if (complementaire != null)
        SfSection(
          title: kTcfComplementaireSectionTitle,
          flush: true,
          child: SfStack(
            pad: false,
            children: [
              _epreuveRow(complementaire, null, profil),
              const SfNoteCard(
                icon: LucideIcons.info,
                title: kTcfComplementaireNoteTitle,
                child: Text(kTcfComplementaireNoteReviser),
              ),
            ],
          ),
        ),
    ];
  }

  /// 🛑 [profil] est **l'autorité d'AFFICHAGE du niveau**, servie par le
  /// tableau de bord déjà chargé — donc **aucun appel de plus**. C'est la même
  /// valeur que l'Accueil, le Profil, l'écran Progrès et l'écran Diagnostic
  /// (`TcfProfileService.levelProfileAccueil`). Réviser lisait le niveau du
  /// Plan puis `stat.level` : trois autorités pour une phrase.
  /// → `docs/regles/progression.md`.
  Widget _epreuveRow(
    DashboardCategoryStat stat,
    PlanDomain? domain,
    TcfDomainProfile? profil,
  ) {
    return SfEpreuveRow(
      icon: dashboardCategoryIcon(stat.code),
      title: stat.label,
      status: epreuveStatus(stat, domain, profil),
      meta: epreuveMeta(stat, domain),
      ratio: epreuveRatio(stat, domain),
      onTap: () => context.push(dashboardCategoryRoute(stat)),
    );
  }

  /// Lance ce que le Plan désigne — le **même** geste que le bouton principal
  /// du Plan (`startPlanSeanceItem` / `openPlanExercise`), sur la **même**
  /// action (`planNowCard`), jamais un second chemin écrit ici.
  ///
  /// 🛑 **Une MESURE passe devant tout le reste**, ici comme sur le Plan et sur
  /// l'Accueil : c'est [planNowCard] qui l'a tranché, l'écran exécute.
  Future<void> _reprendreTcf(PlanNowCard carte) async {
    if (_lancement) return;
    setState(() => _lancement = true);
    final mesure = carte.mesure;
    final exercice = carte.exercise;
    if (mesure != null) {
      await startPlanSeanceItem(context, ref, mesure);
    } else if (exercice != null) {
      await openPlanExercise(
        context,
        ref,
        exercice,
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
    ModulePreparation? prep,
  ) {
    final disponible = prep?.planDisponible == true;
    final auth = ref.watch(authControllerProvider);
    final free = !(auth is AuthAuthenticated && auth.user.hasCivique);
    final resume = disponible
        ? reviserResumeCivique(civicPlan, journey: parcours, free: free)
        : null;
    final porte = prep == null ? null : planIndisponible(prep, civique: true);
    final themes = civicPlan?.themes ?? const <CivicPlanThemeLigne>[];
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
          variant: SfButtonVariant.blue,
          onContinue: resume.geste == PlanNowGeste.debloquer
              ? () => context.push(AppRoutes.planUnlockPath(civique: true))
              : () => _reprendreCivique(resume.source),
        )
      else if (porte != null)
        _GateCard(porte: porte, variant: SfButtonVariant.blue),
      SfSection(
        title: reviserSectionTitle(AppModule.civique, dashboard.civique.length),
        flush: true,
        child: SfStack(
          pad: false,
          children: [
            for (final stat in dashboard.civique)
              SfEpreuveRow(
                icon: dashboardCategoryIcon(stat.code),
                title: stat.label,
                status: themeStatus(themeLigneFor(themes, stat.themeId), stat),
                onTap: () => context.push(dashboardCategoryRoute(stat)),
              ),
          ],
        ),
      ),
    ];
  }

  /// 🛑 **Un lanceur par GRAIN** (A87), comme sur le Plan civique : l'unité
  /// officielle du cycle et la cible du plan dérivé sont deux routes serveur
  /// distinctes. La source est **servie** par `civicNowCard`, l'écran exécute.
  Future<void> _reprendreCivique(CivicNowSource? source) async {
    if (_lancement || source == null) return;
    setState(() => _lancement = true);
    switch (source) {
      case CivicNowUnite(code: final code):
        await startCivicUniteSerie(context, ref, code);
      case CivicNowCible(cible: final cible):
        await startCivicSerie(context, ref, cible);
    }
    if (!mounted) return;
    setState(() => _lancement = false);
  }
}

/// **La carte de tête** — « Reprendre là où vous vous êtes arrêté », ou la porte
/// du diagnostic quand il n'y a rien à reprendre.
///
/// Même anatomie que la carte « À faire maintenant » du Plan : c'est la même
/// action, vue depuis un autre écran.
///
/// 🛑 **Une seule carte pour les deux états**, pas deux widgets presque
/// identiques : ce sont les mêmes quatre lignes — sur-titre, pictogramme, titre
/// et sous-titre, bouton — et seul leur contenu change.

/// **La porte du diagnostic**, à la place de la reprise.
///
/// 🛑 **Aucune phrase n'est écrite ici** : [planIndisponible] porte le titre, le
/// texte, le libellé du bouton et sa destination — la **même autorité** que
/// l'Accueil et l'écran Plan. C'est elle qui distingue « faire » de
/// « reprendre » quand un diagnostic est déjà commencé, et qui sait que le
/// civique a **sa** porte (`/diagnostic-civique`).
class _GateCard extends StatelessWidget {
  const _GateCard({required this.porte, required this.variant});

  final PlanIndisponible porte;
  final SfButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    return PlanRecoCard(
      label: kReviserDepartLabel,
      title: porte.titre,
      subtitle: porte.texte,
      cta: porte.cta,
      icon: LucideIcons.compass,
      variant: variant,
      onContinue: () => context.push(porte.route),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SfCard(
        child: Column(
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.ui(size: 13.5, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            SfButton(
              label: 'Réessayer',
              variant: SfButtonVariant.line,
              icon: null,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

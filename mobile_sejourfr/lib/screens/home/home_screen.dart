import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/analytics/analytics.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/civic_plan_models.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/preparation_labels.dart';
import '../../core/providers/preparation_provider.dart';
import '../../core/providers/progress_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/parcours_affiche.dart';
import '../../core/widgets/affiner_plan_card.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../diagnostic/diagnostic_controller.dart';
import '../diagnostic/diagnostic_courant_provider.dart';
import '../plan/civic_plan_labels.dart';
import '../plan/civic_plan_provider.dart';
import '../plan/learning_plan_provider.dart';
import '../plan/plan_actions.dart';
import '../plan/plan_labels.dart';
import '../plan/plan_task_path.dart';
import 'home_labels.dart';
import 'widgets/home_blocks.dart';

/// **L'Accueil**, refait sur la maquette du propriétaire (`~/Desktop/grok_ecran`
/// — `src/components/sejour/screens/accueil.tsx`, captures
/// `screenshots/accueil-mobile.png` et `accueil-civ-mobile.png`), assemblé avec
/// le KIT (`core/widgets/sejour/sejour_kit.dart`).
///
/// ## L'ordre vient de la maquette, et de rien d'autre
///
/// En-tête → bascule → **À faire maintenant** → **Votre Plan** → **Votre
/// progression** → **Affiner votre Plan** → **Vos parcours**.
///
/// ⚠️ Une première passe avait suivi la structure du **web** plutôt que la
/// maquette : « Ma préparation » et « À renforcer en priorité » en plus, quatre
/// tuiles d'indicateurs au lieu des deux compteurs, des cartes de parcours à
/// barres de catégories, et « Affiner votre Plan » **avant** la progression.
/// Le propriétaire a tranché sur capture (2026-09-12) : c'est la maquette.
/// Ces blocs sont **retirés**, pas déplacés.
/// « Ma préparation » reste la porte du **Plan** et des **Examens** ; sur
/// l'Accueil, « À faire maintenant » porte déjà cette porte (les trois états du
/// diagnostic TCF, et `planIndisponible` côté civique).
///
/// ## Un écran, deux parcours
///
/// 🛑 **La bascule change ce que l'Accueil AFFICHE**, elle ne navigue pas. Le
/// parcours affiché vit dans [parcoursCiviqueProvider], **partagé avec le
/// Plan** : c'est le pendant du `?module=` du web, et la raison est la même —
/// deux mécaniques auraient fini par afficher deux parcours différents sur deux
/// écrans du même compte. Le défaut est **servi** (`moduleCiviqueParDefaut`).
///
/// 🛑 **« Vos parcours » N'EST PAS scopé** : c'est le bloc qui garde la vue
/// d'ensemble des deux modules.
///
/// ## Ce que la maquette ne décide PAS
///
/// 🛑 Elle est une référence de **mise en page**, jamais une source de données.
/// Une seule action dominante — « À faire maintenant » —, un en-tête sans CTA,
/// une priorité TCF verrouillée qui n'est **pas nommée**, et le diagnostic
/// complet qui reste secondaire.
///
/// ⚠️ **Trois écarts assumés, et leurs raisons** :
/// - la **troisième colonne « validations »** du trio de progression n'est
///   **servie par rien** (`GET /api/me/progress` publie `travaillees` et
///   `maitrisees`, pas un compte de validations) : elle est **omise**, pas
///   fabriquée. `SfStatGrid` suit la liste qu'on lui donne ;
/// - les **raccourcis du bas** (Réviser · Examens blancs · Mes résultats) sont
///   omis : la bottom nav les porte déjà, et le propriétaire a écarté une
///   rangée de raccourcis redondante le 2026-09-12 ;
/// - la pastille d'objectif nomme la **démarche** servie ([objectifLabel]) et
///   non le module, que la bascule juste en dessous annonce déjà.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_poserDefaut());
  }

  /// Le parcours ouvert par défaut est **servi** : celui qui a déjà quelque
  /// chose à dire. `??=` n'écrase jamais un choix déjà fait par le candidat sur
  /// le Plan.
  Future<void> _poserDefaut() async {
    try {
      final prep = await ref.read(preparationProvider.future);
      if (!mounted) return;
      ref.read(parcoursCiviqueProvider.notifier).state ??=
          moduleCiviqueParDefaut(prep);
    } catch (_) {
      // 🛑 L'échec n'ouvre pas sur un module au hasard : on retombe sur le TCF,
      // exactement comme le Plan.
      if (mounted) ref.read(parcoursCiviqueProvider.notifier).state ??= false;
    }
  }

  /// 🛑 **Le seul point de fraîcheur de l'Accueil**, avec le signal du Plan :
  /// ses quatre sources sont gardées en vie pour la session, donc revenir sur
  /// l'onglet ne redemande plus rien. Ici on vide tout, puis on attend la plus
  /// lente pour que l'indicateur de rafraîchissement dure le temps du travail.
  Future<void> _refresh() async {
    ref.invalidate(preparationProvider);
    ref.invalidate(progressProvider);
    ref.invalidate(civicPlanProvider);
    ref.invalidate(learningPlanProvider);
    ref.invalidate(diagnosticCourantProvider);
    await Future.wait<void>([
      ref.read(progressProvider.future).then((_) {}).catchError((_) {}),
      ref.read(diagnosticCourantProvider.future).then((_) {}).catchError((_) {}),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final civique = ref.watch(parcoursCiviqueProvider) ?? false;

    // 🛑 **Le MÊME toggle que le Plan, les Examens et Réviser**, et pas une
    // copie : `SegmentedTabs` + `parcoursSegments` portent déjà les deux
    // couleurs du produit (rouge = TCF, bleu = civique).
    final toggle = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SegmentedTabs<bool>(
        tabs: parcoursSegments(tcf: false, civique: true),
        value: civique,
        onChanged: (v) => ref.read(parcoursCiviqueProvider.notifier).state = v,
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
            child: ListView(children: _contenu(context, civique)),
          ),
        ),
      ),
    );
  }

  List<Widget> _contenu(BuildContext context, bool civique) {
    final auth = ref.watch(authControllerProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;

    // 🛑 **Les DEUX parcours sont observés en permanence**, et c'est ce qui rend
    // la bascule gratuite. Ces providers sont `autoDispose` : n'observer que le
    // parcours affiché laissait l'autre se jeter à chaque bascule, et revenir
    // dessus rappelait son endpoint — pour une réponse identique, puisque ni le
    // plan TCF ni le plan civique ne dépendent de l'onglet ouvert. Les lire ici
    // ne coûte rien de plus : ils sont de toute façon chargés dès qu'on ouvre
    // leur parcours.
    ref.watch(learningPlanProvider);
    ref.watch(civicPlanProvider);
    ref.watch(diagnosticCourantProvider);

    return <Widget>[
      if (user != null && user.targetProcedure == null)
        HomeBanner(onTap: () => context.push(AppRoutes.targetPath)),
      SfTop(
        title: homeHello(user?.firstName),
        badges: [objectifLabel(user?.targetProcedure)],
      ),
      ..._blocs(context, civique),
      const SizedBox(height: 24),
      const _IndependenceNote(),
      const SizedBox(height: 20),
    ];
  }

  /// 🛑 **Chaque bloc apparaît quand SA source est là**, et disparaît quand elle
  /// n'a rien à dire : pas de squelette global, pas de section au-dessus du
  /// vide. Miroir du web, dont chaque appel retombe sur `null` en best-effort.
  List<Widget> _blocs(BuildContext context, bool civique) {
    final prep = ref.watch(preparationProvider).valueOrNull;
    final action = civique ? _actionCivique(context) : _actionTcf(context);
    final apercu = civique ? _apercuCivique(context) : _apercuTcf(context);
    final progression = _progression(civique);

    // 🛑 **TCF seulement** : le diagnostic 4 épreuves est un objet TCF, il n'a
    // pas de pendant civique. `abonne: false` — sur l'Accueil la carte ne
    // s'affiche que lorsque le complet est COMMENCÉ, et ce libellé-là ne dépend
    // pas de l'abonnement.
    final affiner = !civique && prep != null
        ? affinerPlan(prep.tcf, accueil: true, abonne: false)
        : null;

    return <Widget>[
      if (action != null)
        SfSection(title: kHomeNowTitle, flush: true, child: action),
      if (apercu != null)
        SfSection(title: kHomePlanTitle, flush: true, child: apercu),
      if (progression != null)
        SfSection(title: kHomeProgressTitle, flush: true, child: progression),
      if (affiner != null)
        SfSection(flush: true, child: AffinerPlanCard(info: affiner, pad: false)),
      SfSection(
        title: kHomeTracksTitle,
        child: SfStack(
          children: [
            HomeTrackRow(
              title: kTcfLabel,
              onTap: () => _ouvrirPlan(context, civique: false),
            ),
            HomeTrackRow(
              title: kCiviqueLabel,
              onTap: () => _ouvrirPlan(context, civique: true),
            ),
          ],
        ),
      ),
    ];
  }

  /// « Voir mon Plan » sur une ligne de parcours : le Plan **du module de la
  /// ligne**. La bascule du Plan lit le même provider que celle d'ici, donc
  /// choisir la ligne suffit à ouvrir le bon onglet — aucun paramètre de route
  /// n'est inventé.
  void _ouvrirPlan(BuildContext context, {required bool civique}) {
    ref.read(parcoursCiviqueProvider.notifier).state = civique;
    context.go(AppRoutes.plan);
  }

  /* ------------------------------------------- l'action du jour — TCF ----- */

  /// 🛑 Les trois états et leurs phrases sont **ceux du web**, mot pour mot.
  /// Sans diagnostic servi, la section n'existe pas : pas de titre au-dessus du
  /// vide.
  Widget? _actionTcf(BuildContext context) {
    final journey = ref.watch(diagnosticCourantProvider).valueOrNull;
    if (journey == null) return null;

    final auth = ref.watch(authControllerProvider);
    final cle = auth is AuthAuthenticated ? auth.user.id : 'anonymous';

    if (journey.status == DiagnosticJourneyStatus.notStarted) {
      if (ref.watch(diagnosticHomeDismissedProvider(cle))) return null;
      return SfNowCard(
        icon: LucideIcons.clipboardCheck,
        title: kHomeDiagStartTitle,
        subtitle: kHomeDiagStartSubtitle,
        badge: kHomeStartBadge,
        objective: kHomeDiagStartObjective,
        action: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SfButton(
              label: kHomeDiagStartCta,
              onPressed: () {
                // Le clic qui ouvre le funnel du diagnostic. La variante n'est
                // pas encore choisie ici : `UNKNOWN` est la seule valeur vraie.
                ref.read(analyticsServiceProvider).track(
                      AnalyticsEvent.diagnosticCtaClicked,
                      ctaLocation: AnalyticsCtaLocation.hero,
                      diagnosticType: AnalyticsDiagnosticType.unknown,
                    );
                context.push(AppRoutes.diagnostic);
              },
            ),
            HomeSoftAction(
              label: kHomeLaterCta,
              onTap: () => ref
                  .read(diagnosticHomeDismissedProvider(cle).notifier)
                  .state = true,
            ),
          ],
        ),
      );
    }

    if (journey.status != DiagnosticJourneyStatus.completed) {
      final fait = journey.completedExerciseCount;
      final analyse = journey.status == DiagnosticJourneyStatus.analyzing ||
          journey.nextStep == DiagnosticStep.analysis;
      return SfNowCard(
        icon: LucideIcons.sparkles,
        title: analyse ? kHomeDiagAnalyzingTitle : kHomeDiagResumeTitle,
        subtitle: homeDiagCount(fait),
        badge: kHomeDiagBadge,
        objective:
            analyse ? kHomeDiagAnalyzingObjective : kHomeDiagResumeObjective,
        action: SfButton(
          label: analyse ? kHomeDiagAnalyzingCta : kHomeDiagResumeCta,
          onPressed: () => context.push(AppRoutes.diagnostic),
        ),
      );
    }

    final live = ref.watch(learningPlanProvider).valueOrNull?.currentPriority;
    // 🛑 **Une priorité verrouillée n'est jamais NOMMÉE ici.** Depuis que le
    // Plan sait aussi désigner une compétence *à acquérir*, la priorité n°1
    // peut porter un cadenas — et « Mes priorités » la floute alors. L'écrire
    // en clair sur l'Accueil démentirait ce rideau. Miroir du web.
    final priorite = live != null && !live.locked ? live : null;
    final exercice = priorite?.recommendedExercise;
    // 🛑 **Un raccourci verrouillé n'en est pas un** : « Commencer directement »
    // enverrait un compte gratuit droit sur un 403. Le Plan, lui, reste ouvert.
    final lancable = exercice != null && !exercice.locked;

    return SfNowCard(
      icon: LucideIcons.target,
      // Le titre de la priorité, et rien d'autre : l'explication du correcteur
      // est le constat d'une production déjà faite — elle raconte le passé sur
      // une carte qui annonce l'action à mener, et elle vit déjà dans le Plan.
      title: priorite?.title ?? kHomePriorityFallback,
      subtitle: exercice == null
          ? null
          : homeExerciseMeta(exercice.title, exercice.estimatedMinutes),
      badge: kHomePriorityBadge,
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SfButton(
            label: kHomePlanCta,
            onPressed: () => _ouvrirPlan(context, civique: false),
          ),
          if (lancable)
            HomeSoftAction(
              label: kHomeStartDirectCta,
              onTap: () => unawaited(openPlanExercise(
                context,
                ref,
                exercice,
                masteryBefore: priorite?.masteryState,
              )),
            ),
        ],
      ),
    );
  }

  /* --------------------------------------- l'action du jour — CIVIQUE ----- */

  /// 🛑 **Aucune règle nouvelle, aucun libellé nouveau.** Deux autorités déjà en
  /// place, celles du Plan civique : [planIndisponible] quand le plan n'est pas
  /// encore constructible, et `CivicPlan.prochaine` — la cible de rang 1,
  /// **désignée par le serveur** — sinon.
  ///
  /// 🛑 **Cette carte ne DÉMARRE rien** : elle mène au Plan civique, qui porte
  /// le seul lanceur de série. Un second point de départ aurait dupliqué la
  /// gestion du 403 et du paywall.
  ///
  /// 🛑 **Le verrou civique porte sur la SÉRIE, jamais sur le constat** : une
  /// cible verrouillée garde son nom et son état — c'est la règle du module
  /// civique, et elle diffère volontairement de celle du TCF.
  Widget? _actionCivique(BuildContext context) {
    final prep = ref.watch(preparationProvider).valueOrNull;
    final porte =
        prep == null ? null : planIndisponible(prep.civique, civique: true);
    if (porte != null) {
      return SfNowCard(
        icon: LucideIcons.landmark,
        title: porte.titre,
        badge: kHomeStartBadge,
        objective: porte.texte,
        action: SfButton(
          label: porte.cta,
          variant: SfButtonVariant.blue,
          onPressed: () => context.push(porte.route),
        ),
      );
    }

    final CivicPlanCible? cible =
        ref.watch(civicPlanProvider).valueOrNull?.prochaine;
    if (cible == null) return null;

    return SfNowCard(
      icon: LucideIcons.landmark,
      title: cible.themeLabel,
      subtitle: civicPlanRaison(cible),
      badge: kHomePriorityBadge,
      objectiveLabel: kHomeCivicObservedLabel,
      objective: '${cible.maitrise.label} · ${civicSerieLabel(cible)}',
      action: SfButton(
        label: kHomeCiviquePlanCta,
        variant: SfButtonVariant.blue,
        onPressed: () => _ouvrirPlan(context, civique: true),
      ),
    );
  }

  /* ------------------------------------------------------- votre plan ----- */

  /// L'aperçu du Plan TCF : la priorité actuelle et le parcours de sa tâche.
  ///
  /// 🛑 **Une priorité verrouillée n'est pas nommée ici non plus** : le bloc
  /// entier disparaît. Il nommerait en clair, sur l'écran d'accueil, ce que
  /// « Mes priorités » floute un écran plus loin.
  ///
  /// 🛑 **Rien n'est dérivé ici** : [planTaskPath] est l'autorité partagée avec
  /// l'écran Plan, et le compteur est **lu** sur la tâche servie.
  Widget? _apercuTcf(BuildContext context) {
    final plan = ref.watch(learningPlanProvider).valueOrNull;
    final priorite = plan?.currentPriority;
    if (plan == null || priorite == null || priorite.locked) return null;
    final chemin = planTaskPath(plan);
    if (chemin == null) return null;
    final epreuve = planEpreuveOfSection(priorite.section);
    return HomeMiniPlan(
      title: epreuve == null
          ? priorite.title
          : homePlanTaskTitle(
              planDomainLabel(epreuve), chemin.task.tacheNumero),
      subtitle: priorite.title,
      counter: planPathCounter(chemin.dto),
      steps: planPathSteps(plan, chemin),
      onOpen: () => _ouvrirPlan(context, civique: false),
    );
  }

  /// L'aperçu du Plan civique : la cible de rang 1 et les cinq étapes de son
  /// parcours.
  ///
  /// 🛑 **Le numéro de boîte ne s'affiche jamais** : ce qu'on montre est une
  /// **position dans un parcours nommé**, et ses états sont servis
  /// (`Cible.parcours`). Un parcours vide — client servi par un backend
  /// antérieur au champ — n'affiche aucune carte.
  Widget? _apercuCivique(BuildContext context) {
    final cible = ref.watch(civicPlanProvider).valueOrNull?.prochaine;
    if (cible == null) return null;
    final etapes = civicPath(cible);
    if (etapes.isEmpty) return null;
    return HomeMiniPlan(
      title: cible.themeLabel,
      subtitle: cible.label == cible.themeLabel ? null : cible.label,
      counter: civicPathCounter(cible),
      steps: etapes,
      onOpen: () => _ouvrirPlan(context, civique: true),
    );
  }

  /* ------------------------------------------------------ progression ----- */

  /// **Votre progression** — les compteurs de la maquette, puis « Progression
  /// détectée ».
  ///
  /// 🛑 **Les deux compteurs sont SERVIS** (`GET /api/me/progress`), pour les
  /// deux parcours, et **servis même verrouillés** : c'est le *détail* qui est
  /// premium, pas le fait d'avoir progressé. Rien n'est recompté ici.
  ///
  /// ⚠️ **La troisième colonne « validations » de la maquette n'est servie par
  /// rien** : elle est **omise**, pas fabriquée. `SfStatGrid` suit la liste
  /// qu'on lui donne.
  ///
  /// 🛑 **Le civique compte des notions OU des thèmes** selon ce que le tagging
  /// permet (`grainNotion`, servi) : son libellé le dit, au lieu d'écrire
  /// « compétences » à tort.
  Widget? _progression(bool civique) {
    final progres = ref.watch(progressProvider).valueOrNull;
    if (progres == null) return null;

    final (travaillees, maitrisees, notion) = civique
        ? (
            progres.civique.travaillees,
            progres.civique.maitrisees,
            progres.civique.grainNotion,
          )
        : (
            progres.tcf.competences.travaillees,
            progres.tcf.competences.maitrisees,
            false,
          );

    // Rien de mesuré : le bloc n'a rien à dire.
    if (travaillees <= 0) return null;

    return SfCard(
      child: SfStatGrid(
        stats: [
          (
            value: '$travaillees',
            label:
                homeWorkedLabel(travaillees, civique: civique, notion: notion),
          ),
          (
            value: '$maitrisees',
            label: homeMasteredLabel(maitrisees,
                civique: civique, notion: notion),
          ),
        ],
      ),
    );
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

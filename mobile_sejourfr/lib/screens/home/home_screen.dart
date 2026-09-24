import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/analytics/analytics.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/civic_diagnostic_models.dart';
import '../../core/models/civic_plan_models.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/preparation_labels.dart';
import '../../core/models/progress_models.dart';
import '../../core/providers/preparation_provider.dart';
import '../../core/providers/progress_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/parcours_affiche.dart';
import '../../core/utils/situation_icons.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../diagnostic/diagnostic_controller.dart';
import '../diagnostic/diagnostic_courant_provider.dart';
import '../plan/civic_plan_labels.dart';
import '../plan/civic_plan_provider.dart';
import '../../core/models/journey_models.dart';
import '../plan/journey_labels.dart';
import '../plan/learning_plan_provider.dart';
import '../plan/plan_actions.dart';
import '../plan/plan_labels.dart';
import '../plan/plan_now_card.dart';
import '../progres/progres_labels.dart';
import 'home_labels.dart';
import 'widgets/home_blocks.dart';

/// **L'Accueil**, refait sur la maquette du propriétaire (`~/Desktop/grok_ecran`
/// — `src/components/sejour/screens/accueil.tsx`, captures
/// `screenshots/accueil-mobile.png` et `accueil-civ-mobile.png`), assemblé avec
/// le KIT (`core/widgets/sejour/sejour_kit.dart`).
///
/// ## L'ordre, de haut en bas (2026-09-19)
///
/// Bandeau « Choisissez votre parcours » → en-tête « Bonjour X » + pastille
/// d'objectif → **bascule TCF / Examen civique** → **À faire maintenant**
/// (+ l'invitation à choisir un objectif) → **Où vous en êtes** → la note de
/// non-affiliation. Et rien d'autre.
///
/// 🛑 **Le bas de l'Accueil est SUPPRIMÉ** (arbitrage du propriétaire,
/// 2026-09-19, verbatim : « Dans Accueil aussi supprime tout ça sauf le "outil
/// indépendant non affilié…" ») : l'aperçu **« Votre Plan »** (`HomeMiniPlan`),
/// les deux compteurs de **« Votre progression »**, la carte **« Continuez
/// votre diagnostic complet »** (`AffinerPlanCard`, supprimée avec son autorité
/// `affinerPlan`) et les deux lignes de **« Vos parcours »** (`HomeTrackRow`) —
/// la bascule juste au-dessus fait déjà ce travail. **Ne pas les
/// réintroduire** : le Plan se lit sur `/plan`, la progression sur les écrans
/// de progression (`screens/progression/`, ouverts par « Voir mes résultats »
/// et depuis le Profil), et le diagnostic complet garde sa porte (`/diagnostic-tcf`) depuis Réviser, le
/// Plan et le rapport de diagnostic. Même passe côté web.
///
/// 🛑 **[_IndependenceNote] ne se touche pas** : c'est une exigence de
/// conformité store (Misleading Claims).
///
/// ✅ **« Où vous en êtes » ajouté le 2026-09-16** (maquette du propriétaire) :
/// une carte par épreuve (grille, maquette v3 du 2026-09-24) — palier,
/// échelle, état en un mot, action. C'est
/// désormais le **seul constat** de l'écran.
///
/// ⚠️ Une première passe avait suivi la structure du **web** plutôt que la
/// maquette : « Ma préparation » et « À renforcer en priorité » en plus, quatre
/// tuiles d'indicateurs au lieu des deux compteurs, des cartes de parcours à
/// barres de catégories. Le propriétaire a tranché sur capture (2026-09-12) :
/// c'est la maquette. Ces blocs sont **retirés**, pas déplacés.
///
/// ## Un écran, deux parcours
///
/// 🛑 **La bascule change ce que l'Accueil AFFICHE**, elle ne navigue pas. Le
/// parcours affiché vit dans [parcoursCiviqueProvider], **partagé avec le
/// Plan** : c'est le pendant du `?module=` du web, et la raison est la même —
/// deux mécaniques auraient fini par afficher deux parcours différents sur deux
/// écrans du même compte. Le défaut est **servi** (`moduleCiviqueParDefaut`).
///
/// ## Ce que la maquette ne décide PAS
///
/// 🛑 Elle est une référence de **mise en page**, jamais une source de données.
/// Une seule action dominante — « À faire maintenant » —, un en-tête sans CTA,
/// une priorité TCF verrouillée qui n'est **pas nommée**, et le diagnostic
/// complet qui reste secondaire.
///
/// ⚠️ **Deux écarts assumés, et leurs raisons** :
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
      ref
          .read(diagnosticCourantProvider.future)
          .then((_) {})
          .catchError((_) {}),
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
    // 🛑 **La préparation est observée ICI depuis le 2026-09-19** : elle était
    // lue par `_blocs` pour la carte « Continuez votre diagnostic complet »,
    // supprimée. Seule `_actionCivique` la lit encore, donc en TCF plus rien ne
    // l'observait — et `_poserDefaut` compte sur elle.
    ref.watch(preparationProvider);

    return <Widget>[
      if (user != null && user.targetProcedure == null)
        HomeBanner(onTap: () => context.push(AppRoutes.targetPathFrom(AppRoutes.home))),
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
    final action = civique ? _actionCivique(context) : _actionTcf(context);
    final objectif = civique ? null : _objectifTcf(context);
    final situation = _ouVousEnEtes(context, civique);

    return <Widget>[
      if (action != null)
        SfSection(title: kHomeNowTitle, flush: true, child: action),
      if (objectif != null)
        SfSection(
            title: kJourneyNeedsObjectiveTitle, flush: true, child: objectif),
      if (situation != null)
        SfSection(
          title: kHomeSituationTitle,
          flush: true,
          lead: true,
          action: SfSectionAction(
            label: kHomeSituationPlanLink,
            onTap: () => _ouvrirPlan(context, civique: civique),
          ),
          child: situation,
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
        // 🛑 L'effort annoncé est DÉRIVÉ du format servi, jamais écrit : le
        // diagnostic actif n'a qu'une production écrite, et la carte
        // promettait « 2 exercices · ≈ 8 à 10 min ».
        subtitle: homeDiagStartSubtitle(journey.format),
        badge: kHomeStartBadge,
        objective: homeDiagStartObjective(journey.format),
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
                // 🛑 **Le bouton porte déjà la décision** (arbitrage du
                // 2026-09-12) : « Faire mon diagnostic » LANCE le diagnostic,
                // il n'ouvre pas une page qui redemande de le lancer. Ce
                // marqueur manquait ici — un compte neuf atterrissait sur
                // « Quel examen préparez-vous ? » alors qu'il venait de
                // choisir son parcours dans la bascule juste au-dessus.
                context.push(AppRoutes.diagnosticDemarrer);
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
        subtitle: homeDiagCount(fait, journey.exerciseCount),
        badge: kHomeDiagBadge,
        objective: analyse
            ? homeDiagAnalyzingObjective(journey.format)
            : kHomeDiagResumeObjective,
        action: SfButton(
          label: analyse ? kHomeDiagAnalyzingCta : kHomeDiagResumeCta,
          // « Reprendre mon diagnostic » nomme le geste, donc il le pose ;
          // « Voir l'analyse » ne lance rien et ouvre l'écran tel quel.
          // ⚠️ Sans effet quand le candidat est déjà plus loin que la
          // présentation : l'écran ne saute que ce qu'il y a à sauter.
          onPressed: () => context.push(
            analyse ? AppRoutes.diagnostic : AppRoutes.diagnosticDemarrer,
          ),
        ),
      );
    }

    // 🛑 **L'Accueil et le Plan annoncent la MÊME action**, et c'est
    // [planNowCard] qui la décide — pour les deux écrans, des deux côtés. Sans
    // elle, l'Accueil ne lisait que `currentPriority` : il annonçait une tâche
    // d'expression orale pendant que le Plan, au même instant, demandait de
    // compléter une mesure de compréhension écrite.
    final plan = ref.watch(learningPlanProvider).valueOrNull;
    // 🛑 **Le parcours est lu ici aussi** : sans lui, l'Accueil retomberait sur
    // la règle du Plan pendant que le Plan suivrait le parcours — la même
    // contradiction, à un étage de plus.
    final parcours = ref.watch(journeyProvider).valueOrNull;
    // 🛑 **Le drapeau d'accès descend jusqu'à l'autorité** (2026-09-20) : sans
    // lui, l'Accueil ne savait pas qu'il fallait proposer de débloquer, et il
    // annonçait « Commencer » là où le Plan disait « Débloquer ».
    final compte = ref.watch(authControllerProvider);
    final free = !(compte is AuthAuthenticated && compte.user.hasTcf);
    final carte = plan == null
        ? null
        : planNowCard(plan, journey: parcours, free: free);

    // 🛑 **Une priorité verrouillée se NOMME ici comme sur le Plan** (demande
    // du propriétaire, 2026-09-20).
    //
    // ⚠️ **Révoque** « une priorité verrouillée n'est jamais nommée ici » : la
    // règle protégeait le rideau de « Mes priorités », qui n'existe plus — le
    // Plan nomme l'étape depuis le 2026-09-19 et Réviser depuis le 20. Le seul
    // écran à se taire encore était celui-ci, et il annonçait « Continuez votre
    // plan personnalisé » pendant que le Plan disait « Expression écrite ·
    // Tâche 3 ». Deux écrans, deux réponses, au même instant.
    final nommable = carte != null;

    final mesure = carte?.mesure;
    final exercice = carte?.exercise;
    // 🛑 **Le geste vient de l'autorité**, jamais redéduit : un verrou ouvre
    // l'écran de transition (A145), une action ouvre l'action.
    final debloquer = carte?.geste == PlanNowGeste.debloquer;
    // 🛑 **Une étape de séries ouvre son écran**, elle ne se lance plus d'ici.
    // Le geste ET sa destination viennent de [planNowCard] : cet écran ne
    // redéduit ni « est-ce une série ? » ni l'adresse.
    final ouvrirEtape =
        carte?.geste == PlanNowGeste.ouvrirEtape ? carte?.etapeRoute : null;
    final lancable = carte != null &&
        carte.geste == PlanNowGeste.lancer &&
        (mesure != null ? !carte.locked : exercice != null && !exercice.locked);

    return SfNowCard(
      // Quand la série se termine, la carte change de nature : sans son accent
      // propre, elle se lirait « rien n'a bougé » — ici comme sur le Plan.
      variant: nommable && carte.estVerification
          ? SfNowCardVariant.verify
          : SfNowCardVariant.standard,
      icon: nommable ? carte.icon : LucideIcons.target,
      // Le titre de l'action, et rien d'autre : l'explication du correcteur est
      // le constat d'une production déjà faite — elle raconte le passé sur une
      // carte qui annonce l'action à mener, et elle vit déjà dans le Plan.
      title: nommable ? carte.title : kHomePriorityFallback,
      subtitle: nommable ? carte.subtitle : null,
      // 🛑 Une mesure n'est pas « votre priorité du jour » : sa pastille dit sa
      // nature servie, exactement comme sur le Plan.
      badge: nommable ? carte.badge : kHomePriorityBadge,
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SfButton(
            label: debloquer ? carte!.cta : kHomePlanCta,
            onPressed: debloquer
                ? () => context.push(AppRoutes.planUnlockPath(civique: false))
                : () => _ouvrirPlan(context, civique: false),
          ),
          // 🛑 **Le raccourci OUVRE l'étape** au lieu de lancer sa série :
          // même écran que la ligne du cycle, même destination servie.
          if (ouvrirEtape != null)
            HomeSoftAction(
              label: carte!.cta,
              onTap: () => context.push(ouvrirEtape),
            ),
          if (lancable)
            HomeSoftAction(
              // Le raccourci **nomme ce qu'il lance** : « Compléter la mesure »
              // quand c'est une mesure, sinon le libellé générique de l'Accueil.
              label: carte.estMesure ? carte.cta : kHomeStartDirectCta,
              onTap: () => unawaited(
                mesure != null
                    // Les deux lanceurs du Plan, jamais un second chemin.
                    ? startPlanSeanceItem(context, ref, mesure)
                    : openPlanExercise(
                        context,
                        ref,
                        exercice!,
                        masteryBefore: carte.priority?.masteryState,
                      ),
              ),
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

    // 🛑 **L'Accueil lit le CYCLE, comme le Plan civique** (2026-09-20).
    // ⚠️ **Révoque** la lecture de `plan.prochaine` : le Plan civique annonce
    // l'étape du cycle depuis D-50 §2, donc les deux écrans annonçaient deux
    // reprises différentes au même candidat, au même instant. C'est la
    // troisième fois que ce même écart se rouvre par la bande — après Réviser
    // (A149), après le Plan lui-même.
    final plan = ref.watch(civicPlanProvider).valueOrNull;
    if (plan == null) return null;
    final compte = ref.watch(authControllerProvider);
    final free = !(compte is AuthAuthenticated && compte.user.hasCivique);
    final carte = civicNowCard(
      plan,
      journey: ref.watch(journeyCiviqueProvider).valueOrNull,
      free: free,
    );
    // `null` est un cas NORMAL : plus rien à faire, la carte disparaît.
    if (carte == null) return null;
    final debloquer = carte.geste == PlanNowGeste.debloquer;
    // 🛑 **Une unité qui se travaille par séries ouvre son écran** — le geste et
    // sa destination viennent de [civicNowCard], jamais d'une condition écrite
    // ici.
    final ouvrirEtape =
        carte.geste == PlanNowGeste.ouvrirEtape ? carte.etapeRoute : null;

    return SfNowCard(
      icon: LucideIcons.landmark,
      title: carte.title,
      subtitle: carte.subtitle,
      badge: carte.badge ?? kHomePriorityBadge,
      objectiveLabel: carte.objectiveLabel ?? kHomeCivicObservedLabel,
      objective: carte.objective,
      // 🛑 **Cette carte ne DÉMARRE toujours rien** : elle mène au Plan
      // civique, seul porteur du lanceur de série — un second point de départ
      // dupliquerait la gestion du 403. Seul le geste d'ACHAT part d'ici, vers
      // l'écran de transition (A145).
      action: SfButton(
        label: debloquer || ouvrirEtape != null
            ? carte.cta
            : kHomeCiviquePlanCta,
        variant: SfButtonVariant.blue,
        onPressed: debloquer
            ? () => context.push(AppRoutes.planUnlockPath(civique: true))
            : ouvrirEtape != null
                ? () => context.push(ouvrirEtape)
                : () => _ouvrirPlan(context, civique: true),
      ),
    );
  }

  /* --------------------------------------------------- où vous en êtes ---- */

  /// **Où vous en êtes** — le titre et son lien « Mon plan », le bandeau
  /// d'objectif, puis **une carte par épreuve** en grille de deux colonnes,
  /// chacune portant son palier en gros et son **échelle CECRL**.
  ///
  /// ⚠️ **Refait le 2026-09-24 sur la maquette v3 du propriétaire** : la liste
  /// verticale dans une seule carte (v2, 2026-09-16) devient une grille de
  /// cartes séparées.
  ///
  /// 🛑 **Aucun appel de plus** : `progressProvider` est déjà observé par
  /// l'écran, et le même `ProgressDto` porte déjà les 4 épreuves. Cette section
  /// ne coûte rien au réseau.
  ///
  /// 🛑 **Rien n'est classé ici.** Libellé, pastille, ton, échelle et CTA
  /// viennent tous de `accueilEpreuve*` / `accueilEchelons`
  /// (`screens/progres/progres_labels.dart`),
  /// l'autorité **partagée avec l'écran Progrès**, qui ne lit que deux faits
  /// servis : `status` et `evolution`. Aucun palier n'est comparé à un autre —
  /// cette comparaison vit côté serveur, dans `StatutObjectifResolver`.
  ///
  /// 🛑 **La section n'existe pas tant que rien n'est servi** : pas de titre
  /// au-dessus du vide, comme tous les blocs de cet écran.
  Widget? _ouVousEnEtes(BuildContext context, bool civique) {
    final progres = ref.watch(progressProvider).valueOrNull;
    if (progres == null) return null;
    return civique
        ? _situationCivique(context, progres)
        : _situationTcf(context, progres);
  }

  Widget? _situationTcf(BuildContext context, Progress progres) {
    final epreuves = progres.tcf.epreuves;
    // Les 4 épreuves sont **toujours** servies : depuis le 2026-09-16 elles ne
    // dépendent plus du diagnostic 4 épreuves. Une liste vide ne devrait donc
    // plus arriver — mais un client servi par un backend antérieur au
    // correctif la verrait, et le bloc se tait plutôt que d'afficher un titre
    // au-dessus du vide.
    if (epreuves.isEmpty) return null;

    final objectif = progres.tcf.objectif;
    final compte = accueilEvaluees(epreuves);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 🛑 **Le bandeau passe AU-DESSUS des cartes** (maquette) : il annonce
        // vers quoi on va avant de montrer où on en est. Sans démarche
        // déclarée, pas de bandeau — on ne devine pas l'objectif d'un candidat
        // qui n'en a pas donné, et le compteur part avec lui.
        if (objectif != null) ...[
          SfGoalBanner(
            label: kHomeGoalLabel,
            value: homeGoalText(objectif.shortName),
            count: compte?.faites,
            total: compte?.total,
            caption: kAccueilEvalueesCaption,
          ),
          const SizedBox(height: 12),
        ],
        SfLevelCardGrid(
          children: [
            for (final epreuve in epreuves)
              SfLevelCard(
                mark: planDomainSection(epreuve.epreuve)?.wire ?? '',
                icon: situationEpreuveIcon(planDomainSection(epreuve.epreuve)),
                title: epreuve.epreuve.displayLabel,
                status: accueilEpreuveStatut(epreuve),
                tone: accueilEpreuveTon(epreuve),
                level: accueilEpreuveBadge(epreuve),
                measured: epreuve.niveau != null,
                scale: SfLevelLadder(
                  steps: accueilEchelons(epreuve, objectif),
                  label: accueilEchelleLabel(epreuve, objectif),
                  dim: epreuve.niveau == null,
                ),
                cta: accueilEpreuveCta(epreuve),
                // Le bouton plein est réservé à l'action qui MANQUE : mesurer
                // une épreuve jamais évaluée. Relire un résultat reste un lien.
                ctaPrimary: epreuve.niveau == null,
                onTap: () => _ouvrirEpreuve(context, epreuve),
              ),
          ],
        ),
        const SizedBox(height: 14),
        // ⚠️ **Hors maquette, et conservée volontairement** : elle dit ce qui
        // fait bouger le palier (diagnostics et épreuves complètes, pas les
        // séries). Sans elle, un candidat qui vient d'enchaîner des
        // entraînements lit un niveau inchangé et croit à une panne.
        const SfMicroNote(kHomeSituationNote),
      ],
    );
  }

  /// Le pendant civique — **la même anatomie** (arbitrage du propriétaire,
  /// 2026-09-16) : bande de tête, puis une carte par thème avec son repère,
  /// son pictogramme, son statut à pastille colorée, ses crans et son action.
  ///
  /// 🛑 **Adapté, jamais transposé.** Le civique n'a **ni palier CECRL ni
  /// objectif CECRL servi** : pas de palier en gros, pas d'« Atteindre B2
  /// partout ». La bande de tête dit ce qui EST servi — le dernier résultat et
  /// son seuil (`progresCiviqueScore`, l'autorité déjà en place) — et le
  /// compteur porte sur les **thèmes** de la liste servie.
  Widget? _situationCivique(BuildContext context, Progress progres) {
    final themes = progres.civique.themes;
    if (themes.isEmpty) return null;
    // 🛑 Rien n'est fabriqué : sans examen civique passé, le serveur ne sert ni
    // score ni seuil, et la bande disparaît — exactement comme le bandeau TCF
    // sans démarche déclarée.
    final dernier = progresCiviqueScore(progres.civique);
    final compte = accueilEvaluesCivique(themes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dernier != null) ...[
          SfGoalBanner(
            label: kHomeSituationCivicResultLabel,
            value: dernier,
            count: compte?.faites,
            total: compte?.total,
            caption: kAccueilEvaluesCaptionCivique,
          ),
          const SizedBox(height: 12),
        ],
        SfLevelCardGrid(
          children: [
            for (var rang = 0; rang < themes.length; rang++)
              _carteThemeCivique(context, themes[rang], rang),
          ],
        ),
      ],
    );
  }

  /// La carte d'un thème civique.
  ///
  /// 🛑 **Le repère est le RANG SERVI**, pas un code abrégé : un thème n'a aucun
  /// code de deux lettres servi (`CIV_PRINCIPES` n'en est pas un), et en
  /// inventer un serait fabriquer un libellé. Le produit numérote déjà les cinq
  /// thèmes du livret citoyen — on montre leur position dans la liste que le
  /// serveur ordonne, rien de plus.
  Widget _carteThemeCivique(
    BuildContext context,
    CivicPlanThemeLigne theme,
    int rang,
  ) {
    return SfLevelCard(
      mark: '${rang + 1}',
      icon: situationThemeIcon(theme.code),
      title: theme.label,
      // 🛑 L'état arrive **servi** : on pose son libellé gelé, on ne classe
      // aucun nombre. `NON_EVALUE` reste neutre, jamais ambre.
      status: theme.etat == CivicThemeState.nonEvalue
          ? kNonMesureLabel
          : theme.etat.label,
      tone: civicThemeBarTone(theme.etat),
      // 🛑 **Aucun palier CECRL en civique** : le civique se mesure en thèmes,
      // jamais en paliers. La carte n'a donc pas de valeur en gros.
      level: null,
      measured: theme.etat != CivicThemeState.nonEvalue,
      // 🛑 **Le même cran segmenté que le TCF**, sur la seule donnée servie
      // pour un thème : son `etat` (`accueilEchelonsCivique`). Sans libellés :
      // les trois états ne tiennent pas sous une demi-carte, et la pastille de
      // statut les dit déjà.
      scale: SfLevelLadder(
        steps: accueilEchelonsCivique(theme.etat),
        label: accueilEchelleLabelCivique(theme.etat),
        dim: theme.etat == CivicThemeState.nonEvalue,
        labels: false,
      ),
      cta: kHomeSituationCivicCta,
      // 🛑 **L'écran de progression du thème** (D17, 2026-09-24), le pendant
      // civique de l'écran de progression d'une épreuve TCF.
      onTap: () =>
          context.push(AppRoutes.progressionThemePath(theme.themeId)),
    );
  }

  /// Ce qu'ouvre la carte d'une épreuve.
  ///
  /// 🛑 **Trois issues, aucune inventée** :
  /// 1. épreuve **jamais mesurée** dont le serveur dit par quoi la mesurer ⇒ on
  ///    **lance** cette mesure par [openPlanAssessment], l'autorité unique déjà
  ///    en place — la même que « Compléter mon profil », la fiche d'un domaine
  ///    et la ligne `A_EVALUER` de la séance. Aucun second chemin n'est écrit
  ///    ici, et aucune étape intermédiaire ne s'intercale ;
  /// 2. quelque chose à faire mais rien à lancer (épreuve en progression ;
  ///    descripteur absent, cas d'un client servi par un backend antérieur) ⇒
  ///    la fiche du domaine, le comportement historique ;
  /// 3. rien à faire ⇒ l'écran de progression de l'épreuve (D17, 2026-09-24 :
  ///    seule cette issue a changé de destination).
  ///
  /// Le choix se lit sur l'état **servi**, jamais sur un texte de bouton.
  void _ouvrirEpreuve(BuildContext context, ProgressEpreuve epreuve) {
    final mesure = epreuve.niveau == null ? epreuve.evaluation : null;
    if (mesure != null) {
      openPlanAssessment(context, ref, mesure);
      return;
    }
    if (accueilEpreuveOuvreLExercice(epreuve)) {
      openPlanDomain(context, epreuve.epreuve);
      return;
    }
    context.push(
        AppRoutes.progressionEpreuvePath(planDomainKey(epreuve.epreuve)));
  }

  /* ------------------------------------------------------- l'objectif ---- */

  /// **L'invitation à déclarer un objectif**, quand le candidat n'en a pas.
  ///
  /// 🛑 **Elle n'enlève rien** (arbitrage du propriétaire, 2026-09-17) : le Plan
  /// n'exige **pas** d'objectif déclaré, sa carte d'action reste au-dessus,
  /// entière. C'est une invitation, jamais une porte fermée — et elle doit se
  /// lire partout où une carte « À faire maintenant » se lit, sans quoi le
  /// candidat ne découvre jamais que déclarer sa démarche lui ouvre un parcours.
  Widget? _objectifTcf(BuildContext context) {
    final parcours = ref.watch(journeyProvider).valueOrNull;
    if (parcours == null || parcours.state != JourneyState.needsObjective) {
      return null;
    }
    return SfStack(
      children: [
        const SfCard(child: Text(kJourneyNeedsObjectiveText)),
        SfButton(
          label: kJourneyNeedsObjectiveCta,
          onPressed: () => context.push(AppRoutes.targetPathFrom(AppRoutes.home)),
        ),
      ],
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

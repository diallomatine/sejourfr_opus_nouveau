import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/analytics/analytics.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/preparation_labels.dart';
import '../../core/models/preparation_models.dart';
import '../../core/providers/target_level_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_observer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/affiner_plan_card.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../diagnostic/widgets/diagnostic_result.dart';
import 'civic_plan_view.dart';
import 'learning_plan_provider.dart';
import 'plan_labels.dart';
import 'widgets/plan_tcf_view.dart';

/// **Le coach adaptatif.** Ce que le candidat fait maintenant, pourquoi, et où
/// ça le mène.
///
/// L'écran ne recalcule **rien** : les priorités sont ordonnées serveur, les
/// quatre domaines sont **déjà triés par urgence**, et les verrous viennent
/// d'un `locked` par élément.
///
/// Il ne porte que la **bascule de parcours** et l'état de chargement : le
/// contenu de chaque parcours vit dans sa vue — [PlanTcfView] et
/// [CivicPlanView] —, qui reproduisent la maquette de référence à l'aide du kit
/// `sejour_kit.dart`.
///
/// 🛑 **L'en-tête de page vient EN PREMIER, la bascule se pose dessous** :
/// l'écran s'annonce (eyebrow + « Mon plan du jour »), puis on choisit son
/// parcours. Les deux sont **dans** le scroll, pas en bandeau fixe.
///
/// L'en-tête appartient à l'état affiché — son eyebrow et son titre changent
/// avec lui —, donc la bascule descend par [SfTopSlot] : c'est [SfTop] qui la
/// place, dans toutes les variantes à la fois, sans qu'aucune ne la recopie.
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
    // L'état UNIQUE des deux préparations : il décide de ce que chaque onglet
    // affiche, et il est chargé une fois pour l'écran.
    unawaited(_chargerPreparation());
    // Une mesure d'usage, à côté du contenu de l'écran : elle ne sert aucun
    // bloc affiché, elle existe pour ne pas perdre ce qui se comptait déjà
    // dans l'ancien `page_views`.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(analyticsServiceProvider).track(
            AnalyticsEvent.planOpened,
            path: AnalyticsPath.plan,
          );
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

  /// L'état UNIQUE des deux préparations. 🛑 Le MÊME que celui de l'Accueil et
  /// des Examens : trois écrans qui déduiraient chacun leur version
  /// proposeraient trois choses différentes au même candidat.
  PreparationDto? _prep;

  /// L'onglet ouvert. `null` tant que l'état n'est pas connu — on n'ouvre pas
  /// par défaut sur un module qui n'a rien à dire.
  bool? _civique;

  Future<void> _chargerPreparation() async {
    try {
      final prep = await ref.read(userContentRepositoryProvider).preparation();
      if (!mounted) return;
      setState(() {
        _prep = prep;
        _civique ??= moduleCiviqueParDefaut(prep);
      });
    } catch (_) {
      // 🛑 L'échec ne masque pas le plan TCF : il existait avant cet onglet et
      // doit rester atteignable.
      if (mounted) setState(() => _civique ??= false);
    }
  }

  Widget _onglet(AsyncValue<LearningPlan> plan, TargetLevel? objective) {
    final prep = _prep;
    final civique = _civique ?? false;

    // 🛑 La raison pour laquelle le plan n'est pas prêt vient de l'état UNIQUE,
    // pas d'une déduction locale.
    //
    // 🛑 La porte d'entrée reçoit cet état EN ENTIER : l'étape dit lequel des
    // trois écrans rendre, et `sessionId` désigne le diagnostic rapide à
    // relire. Miroir du web (`PlanModules` → `PlanGate`).
    final modulePrep = prep == null ? null : (civique ? prep.civique : prep.tcf);
    final indisponible = modulePrep == null
        ? null
        : planIndisponible(modulePrep, civique: civique);
    if (indisponible != null) {
      return _PlanIndisponible(info: indisponible, prep: modulePrep);
    }
    if (civique) {
      // 🛑 Le plan civique lit SA propre source (`/api/me/civic-plan`, L10) :
      // c'est un moteur, plus un echo du diagnostic.
      return const CivicPlanView();
    }
    return plan.when(
      loading: () => const _LoadingPlan(),
      error: (error, _) => _PlanError(
        message: ApiClient.toApiException(error).message,
        onRetry: () => ref.invalidate(learningPlanProvider),
      ),
      data: (value) => switch (value.state) {
        // 🛑 Sans diagnostic, il n'y a pas de plan à habiller : on dit par quoi
        // il commence et on ouvre la seule porte. Aucun contenu n'est inventé.
        //
        // ⚠️ Ce repli ne se déclenche plus qu'en DÉSACCORD entre les deux
        // lectures : `planDisponible` rend la condition exacte du moteur, donc
        // le Plan est normalement `active` dès que la porte s'ouvre. `prep` lui
        // est passé pour que, dans ce cas-là, le candidat retrouve au moins le
        // rapport de son diagnostic rapide plutôt qu'un écran qui ne dit rien.
        LearningPlanState.needsDiagnostic => _PlanIndisponible(
            info: (
              titre: kPlanNeedsDiagnosticTitle,
              texte: kPlanNeedsDiagnosticText,
              cta: kPlanNeedsDiagnosticCta,
              route: AppRoutes.diagnostic,
            ),
            prep: modulePrep,
          ),
        LearningPlanState.diagnosticInProgress => _PlanIndisponible(
            info: (
              titre: kPlanDiagnosticRunningTitle,
              texte: kPlanDiagnosticRunningText,
              cta: kPlanDiagnosticRunningCta,
              route: AppRoutes.diagnostic,
            ),
            prep: modulePrep,
          ),
        // 🛑 **Le diagnostic complet n'est qu'une façon d'AFFINER** (arbitrage
        // du 2026-09-12). La carte se pose donc APRÈS le contenu du Plan, dans
        // le même défilement, et disparaît d'elle-même à 4 / 4 : c'est
        // `affinerPlan` qui rend `null`, sur des faits servis.
        LearningPlanState.active => PlanTcfView(
            plan: value,
            objective: objective,
            trailing: _affiner(modulePrep),
          ),
      },
    );
  }

  /// La carte « Affiner votre Plan », en action **secondaire**.
  ///
  /// 🛑 L'abonnement se **lit** (`user.hasTcf`), il ne se devine pas : il ne
  /// décide ici que d'une formulation, jamais d'un verrou — ceux-là arrivent
  /// servis, ligne par ligne.
  List<Widget> _affiner(ModulePreparation? prep) {
    if (prep == null) return const <Widget>[];
    final auth = ref.read(authControllerProvider);
    final info = affinerPlan(
      prep,
      accueil: false,
      abonne: auth is AuthAuthenticated && auth.user.hasTcf,
    );
    return info == null
        ? const <Widget>[]
        : <Widget>[const SizedBox(height: 6), AffinerPlanCard(info: info)];
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(learningPlanProvider);
    // L'objectif vient du **cycle** quand le serveur en sert un ; sinon du
    // palier visé du compte. `null` reste `null` : on ne devine jamais un B2.
    final objective = plan.valueOrNull?.cycle?.objectiveLevel ??
        ref.watch(userTargetLevelProvider);
    final civique = _civique ?? false;

    // 🛑 **Le MÊME toggle que les Examens et Réviser**, et pas une copie :
    // `SegmentedTabs` + `parcoursSegments` portent déjà les deux couleurs du
    // produit (rouge = TCF, bleu = civique).
    //
    // 🛑 Il s'affiche DÈS LE PREMIER RENDU, avant même que l'état soit connu :
    // c'est une navigation, pas un résultat. C'est pourquoi les états de
    // chargement et d'erreur rendent eux aussi leur en-tête — sans `SfTop`,
    // le candidat n'aurait plus aucune porte vers l'autre parcours.
    final toggle = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SegmentedTabs<bool>(
        tabs: parcoursSegments(tcf: false, civique: true),
        value: civique,
        onChanged: (v) => setState(() => _civique = v),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: SfTopSlot(
          below: toggle,
          child: civique
              ? _onglet(plan, objective)
              : RefreshIndicator(
                  color: AppColors.blue,
                  onRefresh: _refresh,
                  child: _onglet(plan, objective),
                ),
        ),
      ),
    );
  }
}

/// Le plan se charge. L'en-tête est rendu **avant** la donnée : c'est lui qui
/// porte la bascule de parcours ([SfTopSlot]), et une navigation ne se fait
/// jamais attendre. Miroir de l'état de chargement du web, qui rend déjà son
/// `Top` seul.
///
/// L'eyebrow ne nomme aucun palier tant que rien n'est lu — `planTopKicker`
/// sans objectif, pas un niveau deviné.
class _LoadingPlan extends StatelessWidget {
  const _LoadingPlan();

  @override
  Widget build(BuildContext context) => ListView(
        children: [
          SfTop(kicker: planTopKicker(null), title: kPlanTitle),
          const SizedBox(height: 40),
          const Center(
            child: CircularProgressIndicator(color: AppColors.blue),
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
        children: [
          // L'en-tête porte la bascule de parcours : une panne du plan TCF ne
          // doit pas fermer la porte du parcours civique.
          SfTop(kicker: planTopKicker(null), title: kPlanTitle),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: SfNoteCard(
              icon: LucideIcons.cloudOff,
              title: kPlanErrorTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SfTiny(message),
                  const SizedBox(height: 12),
                  SfButton(
                    label: kPlanErrorRetry,
                    variant: SfButtonVariant.line,
                    onPressed: onRetry,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

/// Le plan d'un module n'est pas encore constructible : on dit POURQUOI, et on
/// ouvre la seule porte qui débloque.
///
/// 🛑 **Aucun contenu inventé** : ni priorité, ni parcours, ni niveau. Le titre,
/// le texte, le geste et sa destination viennent tous de [planIndisponible],
/// l'état unique des deux préparations — **aucun état n'est déduit d'un
/// compteur**.
///
/// 🛑 **Dès que le diagnostic RAPIDE est fait et tant que le Plan n'est pas
/// prêt, cette porte affiche SON RAPPORT** (arbitrage du propriétaire). Le
/// déclencheur n'est pas une étape mais un **fait servi** :
/// [ModulePreparation.estimationSessionId], l'identifiant de la session rapide
/// close, servi à **toutes** les étapes. Il couvre donc aussi bien « rapide
/// fait, complet pas commencé » que « complet entamé, 0 à 3 épreuves sur 4 » —
/// c'est le second cas qui manquait, parce que l'étape y bascule sur
/// `DIAGNOSTIC_EN_COURS` et que [ModulePreparation.sessionId] y désigne le
/// **complet**. Le seul état sans rapport est celui où aucun rapide n'a été
/// clos : il n'y a rien à montrer.
///
/// 🛑 **Le rapport est l'ÉCRAN DE `/diagnostic`, encastré**
/// ([DiagnosticResultView] et ses slots) — pas un résumé écrit ici : deux
/// lectures du même diagnostic auraient fini par en dire deux choses. Et **la
/// porte garde le geste de fin** (`closingCta: false`) : sa phrase dépend de
/// l'étape servie, alors que le bouton du rapport dit toujours « Faire mon
/// diagnostic complet » — un contresens une fois le complet entamé, où l'étape
/// sert « Reprendre mon diagnostic ».
class _PlanIndisponible extends ConsumerStatefulWidget {
  const _PlanIndisponible({required this.info, this.prep});

  final PlanIndisponible info;

  /// L'état servi du module affiché. Absent sur les deux replis dérivés de
  /// l'état du Plan lui-même : la porte se réduit alors à sa forme minimale,
  /// elle n'invente rien.
  final ModulePreparation? prep;

  @override
  ConsumerState<_PlanIndisponible> createState() => _PlanIndisponibleState();
}

class _PlanIndisponibleState extends ConsumerState<_PlanIndisponible> {
  /// Le résultat du diagnostic RAPIDE déjà passé. `null` = rien à afficher —
  /// état normal, la porte n'en a jamais dépendu.
  DiagnosticResult? _rapide;

  @override
  void initState() {
    super.initState();
    unawaited(_chargerRapide());
  }

  @override
  void didUpdateWidget(_PlanIndisponible old) {
    super.didUpdateWidget(old);
    if (old.prep?.estimationSessionId != widget.prep?.estimationSessionId) {
      unawaited(_chargerRapide());
    }
  }

  /// 🛑 On relit **la session que le serveur a désignée**
  /// (`prep.estimationSessionId`), pas « la session courante » : `current()`
  /// est borné au couple (code, version) actif et répondrait « pas commencé »
  /// sur une version antérieure du diagnostic.
  ///
  /// 🛑 **Aucun repli en cas d'échec** : le rapport n'apparaît pas, la porte
  /// retombe sur sa forme minimale avec son geste. Un rapport absent est un
  /// état normal ; un rapport reconstitué de mémoire ne l'est pas.
  Future<void> _chargerRapide() async {
    final sessionId = widget.prep?.estimationSessionId;
    if (sessionId == null) {
      if (mounted && _rapide != null) setState(() => _rapide = null);
      return;
    }
    try {
      final journey =
          await ref.read(diagnosticRepositoryProvider).detail(sessionId);
      if (!mounted) return;
      setState(() => _rapide = journey.result);
    } catch (_) {
      // Le rapport disparaît, la porte reste : elle n'a jamais dépendu de lui.
    }
  }

  /// L'en-tête de l'écran et l'explication, posés avant tout le reste.
  ///
  /// L'explication vient EN TÊTE : le rapport dit où en est le candidat, il ne
  /// dit pas pourquoi son plan manque encore.
  List<Widget> _tete() => [
        const SfTop(kicker: kPlanEmptyKicker, title: kPlanTitle),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SfCard(
            variant: SfCardVariant.hero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.info.titre,
                  style: AppFonts.display(
                    size: 20,
                    weight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                SfInsight(widget.info.texte),
              ],
            ),
          ),
        ),
      ];

  /// Le geste de fin, porté par la porte : sa phrase vient de l'étape servie.
  List<Widget> _action() => [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SfButton(
            label: widget.info.cta,
            onPressed: () => context.push(widget.info.route),
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final rapide = _rapide;
    if (rapide != null) {
      return DiagnosticResultView(
        result: rapide,
        // 🛑 La MÊME source de palier que l'écran `/diagnostic` : l'objectif
        // vient du compte, jamais d'un second champ qui dériverait.
        objective: ref.watch(userTargetLevelProvider),
        leading: _tete(),
        closingCta: false,
        trailing: [..._action(), const SizedBox(height: 16)],
      );
    }

    return ListView(
      children: [
        ..._tete(),
        ..._action(),
        const SizedBox(height: 28),
      ],
    );
  }
}

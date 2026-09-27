import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/analytics/analytics.dart';
import '../../core/api/api_client.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/preparation_labels.dart';
import '../../core/providers/preparation_provider.dart';
import '../../core/providers/target_level_provider.dart';
import '../../core/router/route_observer.dart';
import '../../core/utils/parcours_affiche.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import 'civic_plan_provider.dart';
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
  }

  /// `PLAN_OPENED` part **une fois par ouverture** de l'écran, comme avant ;
  /// il attend seulement de savoir QUEL plan est affiché.
  bool _planOuvertTrace = false;

  /// Étape 5 du tunnel « Suivi » (« plan vu ») : l'ouverture du Plan, avec le
  /// `journeyId` servi du parcours affiché (`plan_id`, Q8) — **et rien
  /// d'autre** : le serveur résout lui-même la run fondatrice. Parcours
  /// injoignable ⇒ l'événement part quand même, sans contexte : on ne perd pas
  /// la mesure d'usage que l'ancien `page_views` portait déjà.
  void _tracerPlanOuvert(bool civique) {
    if (_planOuvertTrace) return;
    _planOuvertTrace = true;
    unawaited(() async {
      String? journeyId;
      try {
        final journey = await ref
            .read(civique ? journeyCiviqueProvider.future : journeyProvider.future)
            .timeout(const Duration(seconds: 10));
        journeyId = journey.journeyId;
      } catch (_) {
        journeyId = null;
      }
      if (!mounted) return;
      ref.read(analyticsServiceProvider).track(
            AnalyticsEvent.planOpened,
            path: AnalyticsPath.plan,
            journeyId: journeyId,
          );
    }());
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
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// 🛑 Relit le serveur pour TOUT l'écran — Plan, parcours, préparation, et
  /// l'autre parcours avec eux. Ne relire que le Plan laissait la carte « À
  /// faire maintenant » et le cycle sur l'instantané d'avant l'examen.
  Future<void> _refresh() => relireSourcesDuCompte(ref);

  @override
  void didPopNext() {
    // Un diagnostic, une production, une série ou un examen joué au-dessus de
    // cette page peut avoir changé l'un ou l'autre plan. Le retour est le
    // moment fiable pour récupérer le calcul final — par le même point que le
    // tiré-pour-rafraîchir, pour que les deux relisent exactement les mêmes
    // sources (Plan, les DEUX cycles, préparation, Accueil).
    unawaited(relireSourcesDuCompte(ref));
  }

  /// ⚠️ **Plus de copie locale de la préparation.** Elle vivait dans un
  /// `setState` alimenté une seule fois par `initState` : l'écran restait donc
  /// figé sur l'état lu à son premier montage. Au retour d'un diagnostic
  /// terminé, le Plan continuait de réclamer « Faire mon diagnostic » — il
  /// fallait tuer l'app pour en sortir. L'écran **observe** désormais
  /// [preparationProvider], l'état UNIQUE que lisent aussi l'Accueil et les
  /// Examens.

  /// 🛑 **L'onglet ouvert vit dans [parcoursCiviqueProvider]**, partagé avec
  /// l'Accueil : deux états locaux auraient fini par afficher deux parcours
  /// différents au même candidat selon l'écran où il arrive. `null` tant que
  /// l'état n'est pas connu — on n'ouvre pas par défaut sur un module qui n'a
  /// rien à dire.
  ///
  /// Le défaut est **servi**, et il ne s'impose qu'une fois : `??=` n'écrase
  /// jamais un choix déjà fait par le candidat sur l'Accueil.
  void _poserDefaut(bool civique) {
    final notifier = ref.read(parcoursCiviqueProvider.notifier);
    notifier.state ??= civique;
  }

  /// Ne sert plus qu'à **poser l'onglet par défaut** : le contenu, lui, est
  /// observé dans `build`.
  Future<void> _chargerPreparation() async {
    try {
      // 🛑 **Le provider partagé, pas un appel à soi.** Cet écran lisait le
      // repository directement — un appel de plus à chaque ouverture du Plan,
      // pour l'état que l'Accueil venait de lire.
      final prep = await ref.read(preparationProvider.future);
      if (!mounted) return;
      _poserDefaut(moduleCiviqueParDefaut(prep));
    } catch (_) {
      // 🛑 L'échec ne masque pas le plan TCF : il existait avant cet onglet et
      // doit rester atteignable.
      if (mounted) _poserDefaut(false);
    }
  }

  Widget _onglet(
    AsyncValue<LearningPlan> plan,
    TargetLevel? objective,
    bool civique,
  ) {
    // 🛑 **D-69 (2026-09-28) : plus aucune porte.** Le Plan s'affiche pour tout
    // compte, diagnostic fait ou non ; la préparation ne sert plus qu'à la
    // proposition SECONDAIRE de diagnostic ([diagnosticAAffiner]). Observée,
    // jamais copiée : la proposition disparaît dès que le diagnostic est fait.
    final prep = ref.watch(preparationProvider).valueOrNull;
    final modulePrep = prep == null ? null : (civique ? prep.civique : prep.tcf);
    final affiner = modulePrep == null
        ? null
        : diagnosticAAffiner(modulePrep, civique: civique);
    if (civique) {
      // 🛑 Le plan civique lit SA propre source (`/api/me/civic-plan`, L10) :
      // c'est un moteur, plus un echo du diagnostic.
      return CivicPlanView(affiner: affiner);
    }
    return plan.when(
      loading: () => const _LoadingPlan(),
      error: (error, _) => _PlanError(
        message: ApiClient.toApiException(error).message,
        onRetry: () => ref.invalidate(learningPlanProvider),
      ),
      // 🛑 **Aucune invitation au diagnostic complet ici** (arbitrage du
      // propriétaire, 2026-09-19) ; le parcours complet est retiré des fronts
      // depuis le 2026-09-26. Les épreuves non mesurées se mesurent par
      // l'examen blanc que propose le cycle.
      data: (value) => PlanTcfView(
        plan: value,
        // 🛑 Le parcours est **observé**, jamais attendu : son absence ne
        // doit pas retarder le Plan d'une seconde, et un backend antérieur
        // à l'endpoint garde un écran entier.
        journey: ref.watch(journeyProvider).valueOrNull,
        objective: objective,
        affiner: affiner,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(learningPlanProvider);
    // 🛑 **Les DEUX parcours sont observés en permanence** : leurs providers
    // sont `autoDispose`, donc n'en observer qu'un laissait l'autre se jeter à
    // la bascule — et revenir dessus rappelait son endpoint pour une réponse
    // identique. La bascule ne coûte plus aucun appel. Le prix est nul : le
    // plan civique était de toute façon chargé à l'ouverture de son onglet.
    ref.watch(civicPlanProvider);
    // 🛑 **Les deux CYCLES aussi** (P8.7) : ils sont `autoDispose`, donc n'en
    // observer qu'un laissait l'autre se jeter à la bascule — et revenir dessus
    // rappelait `/api/me/plan/journey?module=` pour une réponse identique. C'est
    // le pendant Dart des clés de cache par module du web.
    ref.watch(journeyCiviqueProvider);
    // L'objectif vient du **cycle** quand le serveur en sert un ; sinon du
    // palier visé du compte. `null` reste `null` : on ne devine jamais un B2.
    final objective = plan.valueOrNull?.cycle?.objectiveLevel ??
        ref.watch(userTargetLevelProvider);
    final parcours = ref.watch(parcoursCiviqueProvider);
    final civique = parcours ?? false;
    if (parcours != null) _tracerPlanOuvert(parcours);

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
        onChanged: (v) => ref.read(parcoursCiviqueProvider.notifier).state = v,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: SfTopSlot(
          below: toggle,
          child: civique
              ? _onglet(plan, objective, civique)
              : RefreshIndicator(
                  color: AppColors.blue,
                  onRefresh: _refresh,
                  child: _onglet(plan, objective, civique),
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

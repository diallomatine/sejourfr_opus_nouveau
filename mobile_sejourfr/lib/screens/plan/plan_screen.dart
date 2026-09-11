import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/analytics/analytics.dart';
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
import '../../core/widgets/segmented_tabs.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
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
/// 🛑 **La bascule est au-dessus de l'en-tête**, et l'en-tête est **dans** le
/// scroll : c'est l'ordre de la maquette (`<ModuleToggle>` puis `<Top>`), pas
/// un bandeau fixe.
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
    final indisponible = prep == null
        ? null
        : planIndisponible(civique ? prep.civique : prep.tcf, civique: civique);
    if (indisponible != null) {
      return _PlanIndisponible(info: indisponible);
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
        LearningPlanState.needsDiagnostic => const _PlanIndisponible(
            info: (
              titre: kPlanNeedsDiagnosticTitle,
              texte: kPlanNeedsDiagnosticText,
              cta: kPlanNeedsDiagnosticCta,
              route: AppRoutes.diagnostic,
            ),
          ),
        LearningPlanState.diagnosticInProgress => const _PlanIndisponible(
            info: (
              titre: kPlanDiagnosticRunningTitle,
              texte: kPlanDiagnosticRunningText,
              cta: kPlanDiagnosticRunningCta,
              route: AppRoutes.diagnostic,
            ),
          ),
        LearningPlanState.active =>
          PlanTcfView(plan: value, objective: objective),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(learningPlanProvider);
    // L'objectif vient du **cycle** quand le serveur en sert un ; sinon du
    // palier visé du compte. `null` reste `null` : on ne devine jamais un B2.
    final objective = plan.valueOrNull?.cycle?.objectiveLevel ??
        ref.watch(userTargetLevelProvider);
    final civique = _civique ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 🛑 **Le MÊME toggle que les Examens et Réviser**, et pas une
            // copie : `SegmentedTabs` + `parcoursSegments` portent déjà les
            // deux couleurs du produit (rouge = TCF, bleu = civique).
            //
            // 🛑 Il s'affiche DÈS LE PREMIER RENDU, avant même que l'état soit
            // connu : c'est une navigation, pas un résultat.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SegmentedTabs<bool>(
                tabs: parcoursSegments(tcf: false, civique: true),
                value: civique,
                onChanged: (v) => setState(() => _civique = v),
              ),
            ),
            Expanded(
              child: civique
                  ? _onglet(plan, objective)
                  : RefreshIndicator(
                      color: AppColors.blue,
                      onRefresh: _refresh,
                      child: _onglet(plan, objective),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingPlan extends StatelessWidget {
  const _LoadingPlan();

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: AppColors.blue),
      );
}

class _PlanError extends StatelessWidget {
  const _PlanError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          SfNoteCard(
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
        ],
      );
}

/// Le plan d'un module n'est pas encore constructible : on dit POURQUOI, et on
/// ouvre la seule porte qui débloque.
///
/// 🛑 **Aucun contenu inventé** : ni priorité, ni parcours, ni niveau. Le titre,
/// le texte, le geste et sa destination viennent tous de [planIndisponible],
/// l'état unique des deux préparations.
class _PlanIndisponible extends StatelessWidget {
  const _PlanIndisponible({required this.info});

  final PlanIndisponible info;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
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
                  info.titre,
                  style: AppFonts.display(
                    size: 20,
                    weight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                SfInsight(info.texte),
                const SizedBox(height: 16),
                SfButton(
                  label: info.cta,
                  onPressed: () => context.push(info.route),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

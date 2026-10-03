import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/preparation_labels.dart';
import '../../core/providers/preparation_provider.dart';
import '../../core/providers/target_level_provider.dart';
import '../../core/router/route_observer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import 'civic_plan_provider.dart';
import 'civic_plan_view.dart';
import 'learning_plan_provider.dart';
import 'plan_labels.dart';
import 'widgets/plan_tcf_view.dart';

/// **Le corps du segment « Plan »** d'un écran de module (Navigation v2).
///
/// Le coach adaptatif : ce que le candidat fait maintenant, pourquoi, et où ça
/// le mène. Il remplace `PlanScreen` — même contenu, **sans** en-tête ni
/// bascule de parcours : c'est l'onglet de la barre (TCF / Civique) qui choisit
/// le module, et l'en-tête de module ([SfModuleHeader]) qui annonce l'écran.
///
/// L'écran ne recalcule **rien** : les priorités sont ordonnées serveur, les
/// verrous viennent d'un `locked` par élément. Le contenu de chaque parcours
/// vit dans sa vue — [PlanTcfView] et [CivicPlanView].
class PlanBody extends ConsumerStatefulWidget {
  const PlanBody({super.key, required this.civique});

  final bool civique;

  @override
  ConsumerState<PlanBody> createState() => _PlanBodyState();
}

class _PlanBodyState extends ConsumerState<PlanBody> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    suivreLeRetour(this, context);
  }

  @override
  void dispose() {
    cesserDeSuivreLeRetour(this);
    super.dispose();
  }

  /// 🛑 Relit le serveur pour TOUT l'écran — Plan, parcours, préparation, et
  /// l'autre parcours avec eux. Ne relire que le Plan laissait la carte « À
  /// faire maintenant » et le cycle sur l'instantané d'avant l'examen.
  Future<void> _refresh() => relireSourcesDuCompte(ref);

  @override
  void didPopNext() {
    // Un diagnostic, une production, une série ou un examen joué au-dessus de
    // ce segment peut avoir changé l'un ou l'autre plan : le retour est le
    // moment fiable pour récupérer le calcul final, par le même point que le
    // tiré-pour-rafraîchir.
    unawaited(relireSourcesDuCompte(ref));
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(learningPlanProvider);
    // 🛑 **Les DEUX parcours et les DEUX cycles restent observés** : ces
    // providers sont `autoDispose`, et l'onglet de l'autre module peut être
    // démonté — les garder ici évite de rappeler leur endpoint pour une réponse
    // identique au prochain passage.
    ref.watch(civicPlanProvider);
    ref.watch(journeyCiviqueProvider);
    // L'objectif vient du **cycle** quand le serveur en sert un ; sinon du
    // palier visé du compte. `null` reste `null` : on ne devine jamais un B2.
    final objective = plan.valueOrNull?.cycle?.objectiveLevel ??
        ref.watch(userTargetLevelProvider);

    // 🛑 **D-69 : plus aucune porte.** La préparation ne décide plus que d'une
    // chose : la ligne « Mon diagnostic » n'apparaît que s'il y a un
    // diagnostic CLOS à relire. Observée, jamais copiée ; non chargée ⇒ masquée.
    final prep = ref.watch(preparationProvider).valueOrNull;
    final modulePrep =
        prep == null ? null : (widget.civique ? prep.civique : prep.tcf);
    final fait = modulePrep != null &&
        diagnosticFait(modulePrep, civique: widget.civique);

    if (widget.civique) {
      // Le plan civique lit SA propre source (`/api/me/civic-plan`) et porte
      // son propre tiré-pour-rafraîchir.
      return CivicPlanView(diagnosticFait: fait);
    }
    return RefreshIndicator(
      color: AppColors.moduleTcf,
      onRefresh: _refresh,
      child: plan.when(
        loading: () => const _LoadingPlan(),
        error: (_, __) => _PlanError(
          onRetry: () => ref.invalidate(learningPlanProvider),
        ),
        data: (value) => PlanTcfView(
          plan: value,
          // 🛑 Le parcours est **observé**, jamais attendu : son absence ne
          // retarde pas le Plan d'une seconde.
          journey: ref.watch(journeyProvider).valueOrNull,
          objective: objective,
          diagnosticFait: fait,
        ),
      ),
    );
  }
}

/// Le Plan en cours de lecture : un squelette par bloc, aux dimensions de la
/// carte « Cycle », de « À faire maintenant » et des blocs du cycle (brief §7).
class _LoadingPlan extends StatelessWidget {
  const _LoadingPlan();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: const [
          SfBlockSkeleton(height: 150, radius: AppRadii.lg),
          SizedBox(height: sfSectionGap),
          SfBlockSkeleton(height: 220),
          SizedBox(height: sfSectionGap),
          SfBlockSkeleton(height: 84, radius: AppRadii.lg),
          SizedBox(height: sfGap),
          SfBlockSkeleton(height: 84, radius: AppRadii.lg),
        ],
      );
}

/// Le Plan illisible : l'erreur et « Réessayer » dans le bloc, l'en-tête du
/// module et son segment restent utilisables (brief §7).
class _PlanError extends StatelessWidget {
  const _PlanError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          SfBlockError(
            message: kPlanErrorTitle,
            retryLabel: kPlanErrorRetry,
            onRetry: onRetry,
          ),
        ],
      );
}

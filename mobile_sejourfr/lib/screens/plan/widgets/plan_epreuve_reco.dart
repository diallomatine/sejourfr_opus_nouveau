import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/sejour/sejour_kit.dart';
import '../../reviser/reviser_labels.dart' show kReviserResumeLabel;
import '../learning_plan_provider.dart';
import '../plan_actions.dart';
import '../plan_now_card.dart';
import 'plan_reco_card.dart';

/// **Ce que le cycle propose pour CETTE épreuve**, en tête de son écran
/// d'entraînement (demande du propriétaire, 2026-09-20).
///
/// 🛑 **Le tap fait exactement ce que ferait la même étape tapée depuis le
/// Plan** : l'étape vient de [planEpreuveCarte], son action de
/// `planStepAction`, et le lancement des **mêmes lanceurs** que le Plan
/// ([openPlanExercise], [openPlanAssessment]). Aucun second chemin ici.
///
/// 🛑 **Rien ne s'affiche quand il n'y a rien à dire**, et c'est fréquent :
/// pas de compte, une épreuve sans bloc dans ce cycle — « Structure de la
/// langue » n'en a **jamais**, elle est hors des quatre épreuves du TCF IRN —,
/// un bloc terminé, ou une action qui ne se résout pas. On ne fabrique ni
/// squelette ni bouton mort.
///
/// ⚠️ **Aucun appel de plus dans le cas courant** : le Plan et le parcours sont
/// **gardés en vie** pour la session, le candidat arrivant d'un écran qui les a
/// déjà chargés.
///
/// Miroir web : `app/_components/plan/PlanEpreuveReco.tsx`.
class PlanEpreuveReco extends ConsumerWidget {
  const PlanEpreuveReco({
    super.key,
    required this.blocCode,
    required this.icon,
    this.variant = SfButtonVariant.primary,
  });

  /// Le code du bloc du cycle : `TCF_CO`, `TCF_CE`, `TCF_EE`, `TCF_EO`.
  final String blocCode;
  final IconData icon;
  final SfButtonVariant variant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (auth is! AuthAuthenticated) return const SizedBox.shrink();
    final carte = planEpreuveCarte(
      ref.watch(learningPlanProvider).valueOrNull,
      ref.watch(journeyProvider).valueOrNull,
      blocCode,
      free: !auth.user.hasTcf,
    );
    if (carte == null) return const SizedBox.shrink();
    // 🛑 La carte porte **sa** marge basse et **aucune** marge latérale : les
    // deux écrans qui la montent ont déjà la gouttière de leur liste.
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PlanRecoCard(
        pad: false,
        label: kReviserResumeLabel,
        title: carte.title,
        subtitle: carte.subtitle,
        cta: carte.cta,
        icon: icon,
        variant: variant,
        // 🛑 **Le geste vient du Plan, il ne se redéduit pas ici** — et un
        // geste d'achat passe par l'écran de transition (A145), jamais par le
        // paywall d'un coup. `ouvrirEtape` ouvre l'écran de l'étape (sa
        // compétence, ses deux séries) : l'écran d'épreuve ne teste rien
        // lui-même et ne recompose aucune adresse.
        onContinue: switch (carte.geste) {
          PlanNowGeste.debloquer => () =>
              context.push(AppRoutes.planUnlockPath(civique: false)),
          PlanNowGeste.ouvrirEtape when carte.etapeRoute != null => () =>
              context.push(carte.etapeRoute!),
          _ => () => _lancer(context, ref, carte),
        },
      ),
    );
  }

  /// 🛑 **Les mêmes lanceurs que le cycle du Plan**, dans le même ordre : une
  /// **mesure** passe devant, l'exercice sinon. Le geste d'achat qu'ils
  /// pourraient rencontrer repart vers l'écran de transition.
  void _lancer(BuildContext context, WidgetRef ref, PlanEpreuveCarte carte) {
    void versDeblocage() =>
        context.push(AppRoutes.planUnlockPath(civique: false));
    final action = carte.action;
    if (action == null) return;
    final mesure = action.mesure;
    if (mesure != null) {
      unawaited(startPlanSeanceItem(context, ref, mesure,
          onVerrou: versDeblocage));
      return;
    }
    final exercice = action.exercise;
    if (exercice != null) {
      unawaited(openPlanExercise(
        context,
        ref,
        exercice,
        masteryBefore: action.priority?.masteryState,
        onVerrou: versDeblocage,
      ));
    }
  }
}

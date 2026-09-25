import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_events.dart';
import 'learning_plan_provider.dart' show planJourneyId;

/// **D'où part un geste des lanceurs du Plan** — ce qui décide le CTA d'une
/// offre ouverte sur un verrou ou sur un 403 (contrôle F, 2026-09-25).
///
/// Les lanceurs du Plan (`openPlanExercise`, `startPlanSeanceItem`,
/// `openPlanAssessment`) sont aussi appelés hors du Plan. Ils ne peuvent donc
/// plus imposer `LOCKED_PLAN` : c'est l'appelant qui dit d'où il part.
///
/// 🛑 La simple présence d'un `journeyId` en cache ne prouve **jamais**
/// l'origine : seul l'appelant la connaît.
enum PlanOrigine {
  /// Un écran du Plan, ou un écran ouvert **depuis** lui par un marqueur de
  /// route explicite (`?etape=1`) : `LOCKED_PLAN` + le parcours, même inconnu
  /// (D63 : le serveur range alors l'achat en `UNKNOWN`, jamais `OTHER_CTA`).
  plan,

  /// L'action **du Plan** relayée par un autre écran : la carte « À faire
  /// maintenant » de l'Accueil, « Reprendre » et la reco d'épreuve de
  /// Réviser. Du Plan **seulement si son parcours est connu** ; sinon le CTA
  /// de l'écran d'arrivée.
  relais,

  /// Tout autre point d'entrée (carte d'épreuve de l'Accueil…) : le CTA de
  /// l'écran d'arrivée, sans parcours.
  horsPlan,
}

/// Le CTA et le parcours d'une offre ouverte par un geste d'[origine].
/// [horsPlan] est le CTA que l'écran d'arrivée passe sur son propre verrou
/// avant démarrage (`MOCK_EXAM` pour un examen, `OTHER` pour un exercice).
({AnalyticsCtaLocation? ctaLocation, String? journeyId}) planCta(
  WidgetRef ref,
  PlanOrigine origine, {
  required AnalyticsCtaLocation? horsPlan,
  bool civique = false,
}) {
  final journeyId = planJourneyId(ref, civique: civique);
  final duPlan = switch (origine) {
    PlanOrigine.plan => true,
    PlanOrigine.relais => journeyId != null,
    PlanOrigine.horsPlan => false,
  };
  return duPlan
      ? (ctaLocation: AnalyticsCtaLocation.lockedPlan, journeyId: journeyId)
      : (ctaLocation: horsPlan, journeyId: null);
}

/// Le CTA d'un écran que le Plan peut ouvrir avec son marqueur d'étape
/// (`planStep`) : `LOCKED_PLAN` + le parcours s'il vient du Plan, sinon le CTA
/// qu'il passe sur son propre verrou ([horsPlan]).
({AnalyticsCtaLocation? ctaLocation, String? journeyId}) planStepCta(
  WidgetRef ref, {
  required bool planStep,
  required AnalyticsCtaLocation? horsPlan,
}) =>
    planCta(
      ref,
      planStep ? PlanOrigine.plan : PlanOrigine.horsPlan,
      horsPlan: horsPlan,
    );

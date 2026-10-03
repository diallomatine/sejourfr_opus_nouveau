import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_events.dart';
import '../../core/router/app_router.dart';
import '../../core/router/shell_navigation.dart';
import '../module_detail/civique_theme_exam_launcher.dart';
import 'civic_plan_labels.dart';
import 'civic_serie_launcher.dart';
import 'plan_actions.dart';
import 'plan_cta.dart';
import 'plan_now_card.dart';

/// Lance un geste une seule fois à la fois (l'appelant tient son verrou).
typedef LancerUneFois = Future<void> Function(Future<void> Function() geste);

/// **Le geste de l'étape courante TCF** (`journey.current`, décidée par
/// [planNowCard]), hors du Plan : Accueil, « Prochaine étape » de la
/// Progression. Extrait de l'Accueil à son 2ᵉ lecteur.
///
/// 🛑 **Le geste est SERVI** : `debloquer` ouvre l'écran de transition,
/// `ouvrirEtape` l'écran de l'étape (adresse servie), `lancer` démarre la
/// mesure ou l'exercice par les lanceurs du Plan, `aucun` ⇒ `null` (jamais un
/// bouton mort). Contrôle F : hors du Plan, la carte RELAIE l'action du Plan
/// ([PlanOrigine.relais]).
VoidCallback? gesteEtapeTcf(
  BuildContext context,
  WidgetRef ref,
  PlanNowCard carte, {
  required LancerUneFois lancer,
}) {
  switch (carte.geste) {
    case PlanNowGeste.aucun:
      return null;
    case PlanNowGeste.debloquer:
      return () =>
          pousserOuAller(context, AppRoutes.planUnlockPath(civique: false));
    case PlanNowGeste.ouvrirEtape:
      final route = carte.etapeRoute;
      return route == null ? null : () => pousserOuAller(context, route);
    case PlanNowGeste.lancer:
      final mesure = carte.mesure;
      final exercice = carte.exercise;
      if (mesure == null && exercice == null) return null;
      return () => unawaited(lancer(() => mesure != null
          ? startPlanSeanceItem(context, ref, mesure,
              origine: PlanOrigine.relais)
          : openPlanExercise(
              context,
              ref,
              exercice!,
              origine: PlanOrigine.relais,
              masteryBefore: carte.priority?.masteryState,
            )));
  }
}

/// **Le geste de l'étape courante civique** ([civicNowCard], appelée avec
/// `lancerExamen: true` hors du Plan comme sur le Plan — DEC-18).
///
/// 🛑 **Un lanceur par GRAIN** (A87) : l'examen de thème, l'unité du cycle et
/// la cible du plan dérivé sont trois routes serveur distinctes.
VoidCallback? gesteEtapeCivique(
  BuildContext context,
  WidgetRef ref,
  CivicNowCard carte, {
  required LancerUneFois lancer,
}) {
  switch (carte.geste) {
    case PlanNowGeste.aucun:
      return null;
    case PlanNowGeste.debloquer:
      return () =>
          pousserOuAller(context, AppRoutes.planUnlockPath(civique: true));
    case PlanNowGeste.ouvrirEtape:
      final route = carte.etapeRoute;
      return route == null ? null : () => pousserOuAller(context, route);
    case PlanNowGeste.lancer:
      final examen = carte.examen;
      if (examen != null) {
        return () => unawaited(lancer(() => launchCiviqueThemeExam(
              context,
              ref,
              themeId: examen.themeId,
              themeName: examen.themeName,
              slotNumber: examen.slotNumber,
            )));
      }
      final source = carte.source;
      if (source == null) return null;
      return () =>
          unawaited(lancer(() => _lancerSerieCivique(context, ref, source)));
  }
}

Future<void> _lancerSerieCivique(
  BuildContext context,
  WidgetRef ref,
  CivicNowSource source,
) {
  final cta = planCta(ref, PlanOrigine.relais,
      horsPlan: AnalyticsCtaLocation.other, civique: true);
  return switch (source) {
    CivicNowUnite(code: final code) => startCivicUniteSerie(
        context,
        ref,
        code,
        ctaLocation: cta.ctaLocation,
        journeyId: cta.journeyId,
      ),
    CivicNowCible(cible: final cible) => startCivicSerie(
        context,
        ref,
        cible,
        ctaLocation: cta.ctaLocation,
        journeyId: cta.journeyId,
      ),
  };
}

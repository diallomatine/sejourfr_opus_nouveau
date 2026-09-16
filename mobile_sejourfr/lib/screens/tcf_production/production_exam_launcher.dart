import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/enums.dart';
import '../../core/utils/selected_module.dart';
import '../../core/utils/start_failure.dart';
import 'ee_session_controller.dart';
import 'eo_session_controller.dart';
import 'production_nav.dart';
import 'tcf_production_module.dart';

/// **Démarrer un examen blanc de production** (les 3 tâches EE ou EO
/// enchaînées), et ouvrir son écran de session.
///
/// ⚠️ **Rien n'est décidé ici** : l'épreuve et le slot viennent de l'appelant,
/// qui les tient lui-même d'un descripteur **servi** (`PlanMilestone.slotNumber`
/// pour le jalon, `PlanDomainAssessment.slotNumber` pour une mesure de domaine,
/// la grille pour l'onglet « Examens blancs »). On n'apporte que le **chemin de
/// démarrage**, et c'est celui des écrans d'examen existants, réutilisé tel
/// quel — aucune route n'est créée, aucun appel n'est réinventé.
///
/// Extrait à la **3ᵉ occurrence** (2026-09-16) : le jalon du Plan, la grille
/// d'examens de l'épreuve et — depuis l'arbitrage sur « Évaluer mon niveau » —
/// la mesure d'un domaine d'expression démarrent exactement la même session.
/// Trois copies auraient fini par ouvrir trois sessions différentes.
///
/// 🛑 **La session Riverpod est démarrée AVANT le push** : le sujet ne voyage
/// jamais dans l'URL (cf. [productionSessionPath]).
///
/// Un **403** n'est pas une panne, c'est le verrou freemium que le serveur
/// oppose : il ouvre l'offre ([showPaywallOrError]), jamais un message d'erreur
/// technique.
Future<void> startProductionExam(
  BuildContext context,
  WidgetRef ref, {
  required EpreuveType epreuve,
  required int slotNumber,
}) async {
  final module = epreuve == EpreuveType.tcfEo
      ? TcfProductionModule.eo
      : TcfProductionModule.ee;
  ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
  try {
    if (module.isEo) {
      await ref.read(eoSessionProvider.notifier).startExam(slotNumber: slotNumber);
    } else {
      await ref.read(eeSessionProvider.notifier).startExam(slotNumber: slotNumber);
    }
    if (!context.mounted) return;
    context.push(productionSessionPath(module));
  } catch (error) {
    if (!context.mounted) return;
    showPaywallOrError(context, error);
  }
}

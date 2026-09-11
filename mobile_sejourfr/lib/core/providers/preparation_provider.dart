import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/repositories.dart';
import '../models/preparation_models.dart';

/// **L'état UNIQUE des deux préparations**, lu une seule fois par écran.
///
/// 🛑 **Trois portes, un seul état** (arbitrage du 2026-09-10). Sur l'Accueil,
/// deux blocs le lisent — « Ma préparation » et « Continuez votre diagnostic
/// complet ». Deux appels séparés auraient pu répondre deux états différents
/// dans la même seconde, donc proposer deux prochaines actions : ce provider
/// garantit qu'ils lisent la **même** réponse.
///
/// ⚠️ L'écran Plan garde sa propre lecture (`PlanScreen._chargerPreparation`) :
/// elle décide de l'onglet ouvert **avant** le premier rendu et ne peut pas
/// s'exprimer en `AsyncValue` sans faire clignoter la bascule de parcours.
final preparationProvider = FutureProvider.autoDispose<PreparationDto>(
  (ref) => ref.watch(userContentRepositoryProvider).preparation(),
);

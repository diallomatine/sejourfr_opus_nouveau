import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/models/progression_models.dart';
import '../plan/learning_plan_provider.dart';

/// Les quatre lectures des écrans de progression — une par écran, le même
/// endpoint que le web (`/api/me/progression/*`).
///
/// 🛑 **`autoDispose`, jamais gardées en vie** : ce sont des détails qu'on
/// ouvre, pas une source d'accueil — un cache retiendrait un historique
/// périmé après un examen blanc passé entre-temps. Tant que l'écran est
/// monté, trois signaux les relisent :
/// - le **compte** (`compteIdProvider`) — jamais les résultats d'un autre ;
/// - l'**avancement** (`learningPlanRevisionProvider`) — une mesure écrite ;
/// - l'**accès** (`accesRevisionProvider`) — le `cta.locked` servi (D20) ne
///   doit pas survivre à un achat.
void _signaux(Ref ref) {
  ref.watch(compteIdProvider);
  ref.watch(learningPlanRevisionProvider);
  ref.watch(accesRevisionProvider);
}

/// TCF global. Le paramètre est `tous` (D8 : l'historique complet).
final progressionTcfProvider =
    FutureProvider.autoDispose.family<ProgressionTcf, bool>((ref, tous) {
  _signaux(ref);
  return ref.watch(progressRepositoryProvider).progressionTcf(tous: tous);
});

final progressionEpreuveProvider = FutureProvider.autoDispose
    .family<ProgressionEpreuve, EpreuveType>((ref, epreuve) {
  _signaux(ref);
  return ref.watch(progressRepositoryProvider).progressionEpreuve(epreuve);
});

/// Civique global. Le paramètre est `tous`, comme le TCF.
final progressionCiviqueProvider =
    FutureProvider.autoDispose.family<ProgressionCivique, bool>((ref, tous) {
  _signaux(ref);
  return ref.watch(progressRepositoryProvider).progressionCivique(tous: tous);
});

final progressionThemeProvider =
    FutureProvider.autoDispose.family<ProgressionTheme, String>((ref, themeId) {
  _signaux(ref);
  return ref.watch(progressRepositoryProvider).progressionTheme(themeId);
});

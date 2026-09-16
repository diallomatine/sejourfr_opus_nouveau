import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/repositories.dart';
import '../../core/models/tcf_diagnostic_models.dart';

/// Ce que l'écran des 4 sections a besoin de savoir : le diagnostic courant
/// (`null` = aucun, le serveur rend 204) et l'éligibilité **servie** à une
/// réévaluation.
class TcfDiagnosticCurrent {
  const TcfDiagnosticCurrent({this.diagnostic, this.eligibilite});

  final TcfDiagnosticDto? diagnostic;

  /// 🛑 Jamais déduite du diagnostic : le serveur connaît aussi la dérogation
  /// du Plan, que cet écran ne voit pas. `null` = appel en échec — l'écran
  /// dégrade vers ce qu'il sait, il n'invente aucun droit.
  final TcfReassessmentEligibilityDto? eligibilite;
}

/// L'état de `/diagnostic-tcf`, **derrière un provider donc invalidable de
/// l'extérieur**.
///
/// 🛑 **C'est le point de fraîcheur de l'écran, et il n'en existe pas d'autre.**
/// Cet état vivait en `setState` local alimenté une seule fois par `initState` :
/// ni `RouteAware`, ni provider, donc rien à invalider depuis un flux de
/// passation. Les deux chemins de retour rendaient un écran périmé — le `pop`
/// d'une section poussée en `context.push`, et le `context.go(tcfDiagnostic)`
/// des fins de section, qui **réutilise le `State` existant**. Un candidat
/// terminait sa compréhension orale et relisait « Non commencée ».
///
/// **Ses points de fraîcheur** : `TcfDiagnosticScreen.didPopNext` (retour par
/// `pop`) et l'invalidation explicite **avant** chaque `context.go` vers cet
/// écran (`runner_screen`, `eo_briefing_screen`, `ee_briefing_writing_screen`).
/// 🛑 **Les deux sont nécessaires** : `didPopNext` ne voit pas un `go`, et une
/// invalidation avant `go` ne voit pas un `pop`.
///
/// `autoDispose` sans `keepAlive` : la donnée ne sert qu'à cet écran, et son
/// chrono bouge à chaque section — on la veut fraîche à chaque ouverture.
final tcfDiagnosticCurrentProvider =
    FutureProvider.autoDispose<TcfDiagnosticCurrent>((ref) async {
  final repo = ref.read(tcfDiagnosticRepositoryProvider);
  // L'éligibilité est **best-effort** : son échec ne doit pas priver le
  // candidat de son diagnostic.
  final resultats = await Future.wait<Object?>([
    repo.current(),
    repo.eligibility().then<Object?>((e) => e).catchError((_) => null),
  ]);
  return TcfDiagnosticCurrent(
    diagnostic: resultats[0] as TcfDiagnosticDto?,
    eligibilite: resultats[1] as TcfReassessmentEligibilityDto?,
  );
});

/// **Rejoindre une route en laissant l'écran des 4 sections FRAIS.**
///
/// 🛑 Un `context.go` ne remonte pas un écran : il **réutilise le `State`
/// existant** de `/diagnostic-tcf`, encore présent dans l'arbre. Sans cette
/// invalidation, une section qu'on vient de terminer, de clore ou de reprendre
/// se relit exactement comme avant — le défaut constaté sur les trois écrans de
/// passation (runner CO/CE, briefing EE, briefing EO).
///
/// La route est passée telle quelle : les écrans de production calculent un
/// repli contextuel qui ne mène pas toujours au diagnostic (examen complet,
/// épreuve seule). Invalider un provider `autoDispose` qui n'est pas vivant ne
/// coûte rien, et le geste reste déclaré **à un seul endroit**.
///
/// ⚠️ **Ne remplace pas le `RouteAware` de l'écran** : `didPopNext` couvre le
/// retour par `pop`, que cette fonction ne voit jamais.
void allerEnRafraichissantLeDiagnostic(
  BuildContext context,
  WidgetRef ref,
  String route,
) {
  ref.invalidate(tcfDiagnosticCurrentProvider);
  context.go(route);
}
